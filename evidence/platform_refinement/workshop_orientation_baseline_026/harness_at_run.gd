extends SceneTree
## Focused native timing fixtures, not physical rotation or player testing.
## Policy: a Workshop scene switch must not commit in a portrait touch viewport.
## Actual window resizes and production commands; no HUD/layout state is patched.

const Workshop = preload("res://scenes/chapter/workshop.tscn")
const LANDSCAPE := Vector2i(844, 390)
const PORTRAIT := Vector2i(390, 844)
var output_dir := "res://evidence/platform_refinement/workshop_orientation_baseline_026"
var checks: Array[Dictionary] = []
var trace: Array[Dictionary] = []
var failures := 0
var context := "setup"
var profile_path := ""
var settings_path := ""
var demo_path := ""
var original_inputs: Dictionary = {}
var original_buses: AudioBusLayout


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless" or not "--touch-ui" in OS.get_cmdline_user_args():
		print("Workshop orientation timing test requires native rendering and -- --touch-ui.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output_dir = arg.trim_prefix("--evidence-dir=")
	if FileAccess.file_exists(output_dir.path_join("orientation_report.json")):
		push_error("Choose a fresh evidence directory; the previous timing result is retained.")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK:
		quit(2)
		return
	original_buses = AudioServer.generate_bus_layout()
	for action in InputMap.get_actions():
		original_inputs[action] = {"deadzone": InputMap.action_get_deadzone(action), "events": InputMap.action_get_events(action)}
	var suffix := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	profile_path = "user://workshop_orientation_" + suffix + ".json"
	settings_path = "user://workshop_orientation_" + suffix + ".cfg"
	demo_path = "user://workshop_orientation_demo_" + suffix + ".json"
	var settings := ConfigFile.new()
	settings.set_value("comfort", "text_scale", 1.25)
	settings.set_value("comfort", "reduced_motion", true)
	settings.set_value("sound", "music", 0.0)
	settings.set_value("sound", "effects", 0.0)
	_check(settings.save(settings_path) == OK, "Unique settings file saved")
	await _landscape_control()
	await _portrait_before_layout()
	await _portrait_during_navigation()
	context = "cleanup"
	_cleanup_files()
	_check(not FileAccess.file_exists(profile_path) and not FileAccess.file_exists(settings_path) and not FileAccess.file_exists(demo_path), "All disposable profile/settings files removed")
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.erase_action(action)
	for action in original_inputs:
		InputMap.add_action(action, original_inputs[action].deadzone)
		for event: InputEvent in original_inputs[action].events: InputMap.action_add_event(action, event)
	AudioServer.set_bus_layout(original_buses)
	var identity: Array[Dictionary] = []
	for path: String in ["res://scripts/chapter/workshop.gd", "res://scripts/chapter/chapter_navigation.gd", "res://scripts/hud.gd", "res://scripts/main.gd"]:
		var stored_path: String = path if FileAccess.file_exists(path) else path.trim_suffix(".gd") + ".gdc"
		identity.append({"requested": path, "stored_resource": stored_path, "sha256": FileAccess.get_sha256(stored_path)})
	var report := {"result": "PASS" if failures == 0 else "FAIL", "assertions": checks.size(), "failures": failures,
		"application_version": ProjectSettings.get_setting("application/config/version", "unknown"), "engine": Engine.get_version_info(),
		"executable": OS.get_executable_path(), "display_driver": DisplayServer.get_name(), "source_identity": identity,
		"policy": "A scene switch may start in landscape, but may not commit while the actual touch viewport is portrait.",
		"scope": "Native macOS window resizing with direct production navigation commands. Unique disposable saves/settings. No physical rotation, human input, camera patch, layout patch, performance or aesthetic claim.",
		"checks": checks, "trace": trace}
	var file := FileAccess.open(output_dir.path_join("orientation_report.json"), FileAccess.WRITE)
	if file == null:
		push_error("Could not write orientation timing report.")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("WORKSHOP ORIENTATION: %s / %d checks / %d failures" % [report.result, checks.size(), failures])
	quit(0 if failures == 0 else 1)


func _spawn_hub() -> Node3D:
	root.size = LANDSCAPE
	var hub: Node3D = Workshop.instantiate()
	hub.chapter_profile_path = profile_path
	hub.settings_path = settings_path
	hub.save_path = demo_path
	root.add_child(hub)
	current_scene = hub
	await _settle(0.3)
	_check(hub.hud.touch_mode and not hub.hud.rotation_guard.visible and not _portrait(), "Fixture begins in a settled landscape touch Workshop")
	_check(hub.chapter_profile.save_path == profile_path and hub.settings_path == settings_path and hub.save_path == demo_path, "All three isolated paths reach the Workshop before readiness")
	_check(hub.text_scale == 1.25 and hub.hud.text_scale == 1.25, "Saved text scale reaches both scene and HUD")
	return hub


func _landscape_control() -> void:
	context = "ordinary_landscape_control"
	var hub: Node3D = await _spawn_hub()
	var old_id: int = hub.get_instance_id()
	_record("before_command", hub)
	hub.on_command("crumb", null)
	await _settle(0.3)
	_record("after_command", current_scene)
	_check(is_instance_valid(current_scene) and current_scene.get_instance_id() != old_id and current_scene.scene_file_path == "res://scenes/chapter/crumb_crossing.tscn", "Ordinary landscape command opens actual Crumb Crossing")
	if is_instance_valid(current_scene):
		_check(current_scene.chapter_profile_path == profile_path and current_scene.settings_path == settings_path and current_scene.save_path == demo_path, "Ordinary navigation preserves all isolated paths")
		_check(current_scene.text_scale == 1.25 and current_scene.hud.text_scale == 1.25, "Ordinary navigation preserves saved scene/HUD scale")
	_check(not is_instance_valid(hub), "Successful navigation frees its previous Workshop")
	await _dispose_scene()


func _portrait_before_layout() -> void:
	context = "portrait_before_deferred_layout"
	var hub: Node3D = await _spawn_hub()
	var old_id: int = hub.get_instance_id()
	root.size = PORTRAIT
	# Deliberately no await: verify the viewport changed before the queued HUD
	# layout catches up, then enter the production command handler in that gap.
	_check(_portrait(), "Actual viewport is portrait immediately after native resize")
	_record("portrait_before_command", hub)
	hub.on_command("crumb", null)
	_record("immediately_after_command", hub)
	await _settle(0.3)
	_record("after_deferred_work", current_scene)
	_check(is_instance_valid(current_scene) and current_scene.get_instance_id() == old_id, "Portrait rejects a command even before deferred HUD layout runs")
	if is_instance_valid(hub):
		_check(not hub.transitioning and hub.hud.rotation_guard.visible, "Rejected early command leaves the guarded Workshop usable")
	await _dispose_scene()


func _portrait_during_navigation() -> void:
	context = "portrait_during_audio_drain"
	var hub: Node3D = await _spawn_hub()
	var old_id: int = hub.get_instance_id()
	hub.on_command("crumb", null)
	_check(hub.transitioning, "Landscape command entered the asynchronous navigation interval")
	_record("navigation_pending", hub)
	root.size = PORTRAIT
	_check(_portrait(), "Actual viewport becomes portrait while navigation is pending")
	_record("rotated_while_pending", hub)
	await process_frame
	_record("next_process_frame", current_scene)
	await _settle(0.3)
	_record("after_audio_drain", current_scene)
	_check(is_instance_valid(current_scene) and current_scene.get_instance_id() == old_id, "Pending navigation does not commit after rotation to portrait")
	if is_instance_valid(hub):
		_check(not hub.transitioning and not hub.stage_button.disabled and hub.hud.rotation_guard.visible, "Cancelled transition restores a usable guarded Workshop")
		root.size = LANDSCAPE
		await _settle(0.2)
		hub.on_command("crumb", null)
		await _settle(0.3)
		_check(is_instance_valid(current_scene) and current_scene.get_instance_id() != old_id, "Returning to landscape can navigate after cancellation")
	await _dispose_scene()


func _portrait() -> bool:
	var extent: Vector2 = root.get_visible_rect().size
	return extent.y > extent.x


func _record(label: String, scene: Node) -> void:
	var extent: Vector2 = root.get_visible_rect().size
	var row := {"context": context, "label": label, "ticks_usec": Time.get_ticks_usec(), "viewport": [extent.x, extent.y]}
	if is_instance_valid(scene):
		row["scene"] = scene.scene_file_path
		row["instance_id"] = scene.get_instance_id()
		row["guard_visible"] = scene.hud.rotation_guard.visible
		row["layout_pending"] = scene.hud.layout_pending
		row["started"] = scene.started
		row["paused"] = scene.paused
		if scene.get_script().resource_path == "res://scripts/chapter/workshop.gd": row["transitioning"] = scene.transitioning
	trace.append(row)


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame
	await process_frame


func _dispose_scene() -> void:
	if is_instance_valid(current_scene):
		await current_scene.stop_audio()
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame


func _cleanup_files() -> void:
	for path: String in [profile_path, settings_path, demo_path]:
		for extension: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + extension): DirAccess.remove_absolute(path + extension)


func _check(passed: bool, description: String) -> void:
	checks.append({"context": context, "passed": passed, "description": description})
	if not passed:
		failures += 1
		push_error(context + ": " + description)
