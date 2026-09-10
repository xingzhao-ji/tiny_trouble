extends SceneTree
## Native visual fixtures, not a gameplay route or performance benchmark.
## Reproduce: ./run.command --script res://tests/chapter/test_workshop_capture.gd
## All settings and profile files are unique and removed after capture.

const Workshop = preload("res://scenes/chapter/workshop.tscn")
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
const CrumbState = preload("res://scripts/chapter/crumb_state.gd")
const OUTPUT := "res://evidence/workshop"
var profile_path: String
var settings_path: String
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
	var suffix := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	profile_path = "user://workshop_capture_" + suffix + ".json"
	settings_path = "user://workshop_capture_" + suffix + ".cfg"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var profile = Progress.new()
	profile.save_path = profile_path
	for fixture: String in ["fresh", "saved", "cleared"]:
		if fixture == "saved":
			_check(profile.save_stage("W01S01", CrumbState.new().to_dict()), "Saved-run visual fixture persists")
		elif fixture == "cleared":
			for stage_id: String in Progress.STAGE_IDS:
				_check(profile.complete_stage(stage_id), "Completion visual fixture persists: " + stage_id)
		_write_settings(1.0 if fixture == "fresh" else 1.25)
		for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = resolution
			hub = Workshop.instantiate()
			hub.chapter_profile_path = profile_path
			hub.settings_path = settings_path
			root.add_child(hub)
			current_scene = hub
			await create_timer(0.4).timeout
			_validate_menu(fixture)
			await _capture("%s_%d" % [fixture, resolution.x], resolution, fixture)
			await hub.stop_audio()
			hub.queue_free()
			await process_frame
	_cleanup()
	var report := {"result": "PASS" if failures == 0 else "FAIL", "checks": checks, "captures": captures,
		"kind": "Actual native workshop rendering and menu bounds; seeded profile fixtures, no gameplay or performance claim",
		"engine": Engine.get_version_info().string, "display_driver": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(), "profiles": "unique disposable user:// paths; real saves untouched"}
	var file := FileAccess.open(OUTPUT.path_join("capture_report.json"), FileAccess.WRITE)
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
	var verb: String = {"fresh": "Play", "saved": "Continue", "cleared": "Replay"}[fixture]
	_check(hub.stage_button.text.begins_with(verb), "Stage button reflects " + fixture + " progress")
	_check(not hub.stage_button.disabled, "Crumb Crossing remains available")
	_check(hub.stage_button.has_focus(), "First playable stage owns initial keyboard focus")
	_check(hub.future_buttons.size() == 4, "Exactly four future stages are listed")
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
	var path: String = OUTPUT.path_join(name + ".png")
	_check(frame.save_png(path) == OK, "Native PNG saved: " + name)
	var rect: Rect2 = hub.hud.menu.get_global_rect()
	captures.append({"path": path, "pixels": [frame.get_width(), frame.get_height()], "fixture": fixture,
		"text_scale": hub.text_scale, "menu_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"focused": DisplayServer.window_is_focused(), "stage_button": hub.stage_button.text})


func _write_settings(scale: float) -> void:
	var config := ConfigFile.new()
	config.set_value("comfort", "reduced_motion", true)
	config.set_value("comfort", "text_scale", scale)
	config.set_value("sound", "music", 0.0)
	config.set_value("sound", "effects", 0.0)
	_check(config.save(settings_path) == OK, "Isolated capture settings saved")


func _cleanup() -> void:
	for path: String in [profile_path, profile_path + ".bak", profile_path + ".tmp", profile_path + ".bak.tmp", settings_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "check": description})
	if not passed:
		failures += 1
		push_error(description)
