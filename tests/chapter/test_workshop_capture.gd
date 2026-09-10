extends SceneTree
## Native visual fixtures, not a gameplay route or performance benchmark.
## Reproduce: ./run.command --script res://tests/chapter/test_workshop_capture.gd
## All settings and profile files are unique and removed after capture.

const Workshop = preload("res://scenes/chapter/workshop.tscn")
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
var output_dir := "res://evidence/workshop_ballast"
var profile_path: String
var settings_path: String
var demo_path: String
var checks: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var failures := 0
var hub: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("Workshop capture needs a native renderer; omit --headless.")
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output_dir = arg.trim_prefix("--evidence-dir=")
	var suffix := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	profile_path = "user://workshop_capture_" + suffix + ".json"
	settings_path = "user://workshop_capture_" + suffix + ".cfg"
	demo_path = "user://workshop_demo_" + suffix + ".json"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK:
		push_error("Could not create workshop evidence directory.")
		quit(1)
		return
	var profile = Progress.new()
	profile.save_path = profile_path
	for fixture: String in ["fresh", "saved", "cleared"]:
		if fixture == "saved":
			_check(profile.complete_stage("W01S01"), "Prerequisite completion fixture persists")
			_write_settings(1.25)
			await _test_ballast_navigation()
		elif fixture == "cleared":
			_check(profile.load_profile(), "Navigation-created stage snapshot reloads into visual fixture")
			for stage_id: String in Progress.STAGE_IDS:
				_check(profile.complete_stage(stage_id), "Completion visual fixture persists: " + stage_id)
		_write_settings(1.0 if fixture == "fresh" else 1.25)
		for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = resolution
			hub = _spawn_hub()
			await create_timer(0.4).timeout
			_validate_menu(fixture)
			if fixture == "fresh":
				hub.ballast_button.pressed.emit()
				await process_frame
				_check(current_scene == hub and not hub.transitioning, "Locked ballast command cannot bypass prerequisite even through a forced button signal")
				_check(not FileAccess.file_exists(profile_path), "Locked command never creates chapter progress")
			await _capture("%s_%d" % [fixture, resolution.x], resolution, fixture)
			await hub.stop_audio()
			hub.queue_free()
			await process_frame
	_cleanup()
	var report := {"result": "PASS" if failures == 0 else "FAIL", "checks": checks, "captures": captures,
		"kind": "Actual native workshop rendering, menu bounds and Button.pressed navigation; seeded profile fixtures, no stage-solution or performance claim",
		"engine": Engine.get_version_info().string, "display_driver": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(), "profiles": "unique disposable user:// paths; real saves untouched"}
	var file := FileAccess.open(output_dir.path_join("capture_report.json"), FileAccess.WRITE)
	if file == null:
		push_error("Could not write workshop capture report.")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("WORKSHOP CAPTURE: %s / %d checks / %d native frames" % [report["result"], checks.size(), captures.size()])
	quit(0 if failures == 0 else 1)


func _validate_menu(fixture: String) -> void:
	var panel: Rect2 = hub.hud.menu.get_global_rect()
	var viewport: Rect2 = root.get_visible_rect()
	_check(viewport.encloses(panel), "Menu fits logical viewport: " + fixture)
	_check(absf(panel.size.x - 470.0) < 0.1, "Menu keeps 470px width: " + fixture)
	for child in hub.hud.menu_box.get_children():
		if child is Control:
			_check(panel.encloses(child.get_global_rect()), "Menu child stays within panel: " + child.name)
	var verb: String = "Play" if fixture == "fresh" else "Replay"
	_check(hub.stage_button.text.begins_with(verb), "Stage button reflects " + fixture + " progress")
	_check(not hub.stage_button.disabled, "Crumb Crossing remains available")
	_check(hub.stage_button.has_focus(), "First playable stage owns initial keyboard focus")
	var ballast_verb: String = {"fresh": "Blueberry Ballast · Locked", "saved": "Continue", "cleared": "Replay"}[fixture]
	_check(hub.ballast_button.text.begins_with(ballast_verb), "Ballast button reflects " + fixture + " progress")
	_check(hub.ballast_button.disabled == (fixture == "fresh"), "Ballast availability follows completed Crumb Crossing prerequisite")
	_check(hub.future_buttons.size() == 3, "Exactly three unimplemented stages are listed")
	for button: Button in hub.future_buttons:
		_check(button.disabled and button.text.contains("Unavailable"), "Unbuilt stage remains disabled: " + button.text)
	for child in hub.hud.root.get_children():
		if child is CanvasItem and child != hub.hud.overlay:
			_check(not child.visible, "Gameplay HUD remains hidden: " + child.name)
	var pip_screen: Vector2 = hub.camera.unproject_position(hub.pip.global_position + Vector3(0, 0.55, 0))
	_check(viewport.has_point(pip_screen) and pip_screen.x < panel.position.x - 32, "Pip projects visibly left of menu")
	_check(hub.get_node("OpenMatchbox/OpenDrawer").get_child_count() >= 10, "Open drawer is authored 3D geometry")
	_check(hub.reduced_motion and hub.music_volume == 0 and hub.effects_volume == 0, "Isolated silent reduced-motion settings load before ready")


func _capture(name: String, resolution: Vector2i, fixture: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	_check(frame.get_size() == resolution, "Native capture matches requested pixels: " + name)
	var path: String = output_dir.path_join(name + ".png")
	_check(frame.save_png(path) == OK, "Native PNG saved: " + name)
	var rect: Rect2 = hub.hud.menu.get_global_rect()
	captures.append({"path": path, "pixels": [frame.get_width(), frame.get_height()], "fixture": fixture,
		"text_scale": hub.text_scale, "menu_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"focused": DisplayServer.window_is_focused(), "stage_button": hub.stage_button.text,
		"ballast_button": hub.ballast_button.text, "ballast_disabled": hub.ballast_button.disabled})


func _spawn_hub() -> Node3D:
	var scene: Node3D = Workshop.instantiate()
	scene.chapter_profile_path = profile_path
	scene.settings_path = settings_path
	scene.save_path = demo_path
	root.add_child(scene)
	current_scene = scene
	return scene


func _test_ballast_navigation() -> void:
	var workshop: Node3D = _spawn_hub()
	await process_frame
	_check(not workshop.ballast_button.disabled and workshop.ballast_button.text.begins_with("Play"), "Completed prerequisite exposes Play for a fresh Blueberry Ballast stage")
	_check(workshop.chapter_profile.stage_snapshot("W01S02").is_empty(), "Fresh unlocked stage has no invented snapshot")
	var stage: Node = await _press_and_switch(workshop, workshop.ballast_button)
	if stage == null: return
	_check(stage.scene_file_path == "res://scenes/chapter/blueberry_ballast.tscn", "Ballast button loads the actual stage2 scene")
	_check(not stage.has_save and not stage.state.completed, "Fresh stage2 navigation starts actual unsolved rules")
	_check_paths(stage, "Fresh ballast entry")
	workshop = await _press_and_switch(stage, _menu_button(stage, "Matchbox Workshop"))
	if workshop == null: return
	_check(workshop.ballast_button.text.begins_with("Continue"), "Returning through the real stage menu exposes Continue")
	_check_paths(workshop, "Ballast return to workshop")
	var demo: Node = await _press_and_switch(workshop, _menu_button(workshop, "Original Toast Express demo"))
	if demo == null: return
	_check(demo.scene_file_path == "res://scenes/main.tscn", "Original demo button loads the actual demo scene")
	_check_paths(demo, "Demo entry")
	workshop = await _press_and_switch(demo, _menu_button(demo, "Visit the Matchbox Workshop"))
	if workshop == null: return
	_check_paths(workshop, "Demo return to workshop")
	stage = await _press_and_switch(workshop, workshop.ballast_button)
	if stage == null: return
	_check(stage.scene_file_path == "res://scenes/chapter/blueberry_ballast.tscn" and stage.has_save, "Continue button reloads the actual saved stage2 scene")
	_check(stage.chapter_profile.is_completed("W01S01") and not stage.chapter_profile.is_completed("W01S02"), "Navigation preserves earned prerequisite without inventing a stage2 clear")
	_check_paths(stage, "Ballast re-entry")
	await stage.stop_audio()
	stage.queue_free()
	await process_frame


func _press_and_switch(scene: Node, button: Button) -> Node:
	if button == null:
		_check(false, "Required navigation button exists")
		await scene.stop_audio()
		scene.queue_free()
		await process_frame
		return null
	var previous_id: int = scene.get_instance_id()
	button.pressed.emit()
	var deadline: int = Time.get_ticks_msec() + 4000
	while is_instance_valid(current_scene) and current_scene.get_instance_id() == previous_id and Time.get_ticks_msec() < deadline:
		await process_frame
	var switched: bool = is_instance_valid(current_scene) and current_scene.get_instance_id() != previous_id
	_check(switched, "Button.pressed completes a real scene transition")
	await process_frame
	_check(not is_instance_valid(scene), "Previous scene is freed after its audio drains")
	if not switched:
		if is_instance_valid(scene):
			await scene.stop_audio()
			scene.queue_free()
			await process_frame
		return null
	return current_scene


func _menu_button(scene: Node, label: String) -> Button:
	for child in scene.hud.menu_box.get_children():
		if child is Button and child.text == label: return child
	return null


func _check_paths(scene: Node, context: String) -> void:
	_check(scene.chapter_profile_path == profile_path and scene.settings_path == settings_path and scene.save_path == demo_path, context + ": chapter/settings/demo paths survive before-ready transition")
	_check(scene.text_scale == 1.25 and scene.reduced_motion and scene.music_volume == 0 and scene.effects_volume == 0, context + ": isolated settings actually loaded")


func _write_settings(scale: float) -> void:
	var config := ConfigFile.new()
	config.set_value("comfort", "reduced_motion", true)
	config.set_value("comfort", "text_scale", scale)
	config.set_value("sound", "music", 0.0)
	config.set_value("sound", "effects", 0.0)
	_check(config.save(settings_path) == OK, "Isolated capture settings saved")


func _cleanup() -> void:
	for base: String in [profile_path, demo_path]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(base + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(base + suffix))
	if FileAccess.file_exists(settings_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))


func _check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "check": description})
	if not passed:
		failures += 1
		push_error(description)
