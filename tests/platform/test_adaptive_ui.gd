extends SceneTree
## Native macOS rendering and injected-touch viewport simulations ONLY.
## Not iOS Simulator, physical touch, device safe-area, or performance evidence.
## Reproduce: ./run.command --script res://tests/platform/test_adaptive_ui.gd -- --touch-ui
## Seeds a legal Crumb Crossing checkpoint to isolate input checks; not a route.

const Crumb = preload("res://scenes/chapter/crumb_crossing.tscn")
const Rules = preload("res://scripts/chapter/crumb_state.gd")
const MOVEMENT = ["move_left", "move_right", "move_up", "move_down"]
const WINDOWS = [Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(844, 390), Vector2i(667, 375)]
var output_dir := "res://evidence/platform_ui"
var checks: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var failures := 0
var scene: Node3D
var profile_path: String
var settings_path: String
var demo_path: String
var original_inputs: Dictionary = {}
var original_buses: AudioBusLayout
var context := "initialization"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless" or not "--touch-ui" in OS.get_cmdline_user_args():
		print("Adaptive UI capture requires native rendering and -- --touch-ui.")
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output_dir = arg.trim_prefix("--evidence-dir=")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK:
		push_error("Could not create adaptive UI evidence directory.")
		quit(1)
		return
	_snapshot_globals()
	var suffix := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	profile_path = "user://adaptive_ui_" + suffix + ".json"
	settings_path = "user://adaptive_ui_" + suffix + ".cfg"
	demo_path = "user://adaptive_ui_demo_" + suffix + ".json"
	var config := ConfigFile.new()
	config.set_value("sound", "music", 0.0)
	config.set_value("sound", "effects", 0.0)
	config.set_value("comfort", "reduced_motion", true)
	config.set_value("comfort", "text_scale", 1.25)
	config.set_value("keys", "jump", KEY_K)
	config.set_value("keys", "interact", KEY_L)
	_check(config.save(settings_path) == OK, "Disposable silent max-text settings saved")
	root.size = WINDOWS[0]
	scene = Crumb.instantiate()
	scene.chapter_profile_path = profile_path
	scene.settings_path = settings_path
	scene.save_path = demo_path
	root.add_child(scene)
	current_scene = scene
	await _settle()
	_check(scene.hud.touch_mode and scene.hud.input_mode == "touch", "Command-line override creates the production touch interface")
	_check(scene.chapter_profile.save_path == profile_path and scene.settings_path == settings_path and scene.save_path == demo_path, "Live stage uses three isolated save/settings paths")
	_check(not scene.has_save and not FileAccess.file_exists(profile_path), "Fresh test scene never loads or invents player progress")
	_check(scene.text_scale == 1.25 and scene.music_volume == 0 and scene.effects_volume == 0, "Isolated comfort and audio settings reach the live scene")
	for resolution: Vector2i in WINDOWS:
		context = "%dx%d" % [resolution.x, resolution.y]
		root.size = resolution
		scene.hud.safe_insets_override = Vector4(48, 16, 32, 24)
		scene.hud._queue_layout()
		await _settle()
		scene.on_command("title", null)
		await _settle()
		_validate_menu("title")
		await _capture(context + "_title", resolution, "max-text title, isolated fresh/continued stage fixture")
		scene.on_command("start", null)
		await _settle()
		_seed_spoon_fixture()
		await _settle()
		_validate_landscape()
		await _capture(context + "_play", resolution, "legal checkpoint-1 spoon interaction fixture; not a stage route")
		await _test_card_shrink()
		scene.text_scale = 1.0
		scene.apply_text_size()
		await _settle()
		_validate_landscape()
		await _capture(context + "_play_default_text", resolution, "same legal input fixture with default text scale")
		await _test_card_shrink()
		scene.text_scale = 1.25
		scene.apply_text_size()
		await _settle()
		await _test_touch_actions()
		await _test_mode_switch(resolution)
		await _test_pause_and_reset(resolution)
	await _test_portrait()
	context = "cleanup"
	scene.hud.touch_controls.release_all()
	_check(_movement_clear(), "No movement action remains held after all touch scenarios")
	_check(not scene.chapter_profile.is_completed("W01S01"), "Input fixtures never invent stage completion")
	await scene.stop_audio()
	scene.queue_free()
	await process_frame
	await process_frame
	_restore_globals()
	_cleanup()
	_check(not FileAccess.file_exists(profile_path) and not FileAccess.file_exists(settings_path) and not FileAccess.file_exists(demo_path), "Disposable profile/settings/demo files removed")
	var report := {
		"result": "PASS" if failures == 0 else "FAIL", "assertions": checks.size(), "failures": failures,
		"kind": "Native macOS desktop viewport simulations with injected InputEventScreenTouch/Drag and actual Crumb Crossing actions",
		"limitations": ["Not iOS Simulator or physical iPhone/iPad execution", "Safe insets are explicit logical fixtures, not device safe-area observations", "Rendered pixels are not physical iOS points", "Native macOS backing-store rounding may reduce an odd requested dimension by one pixel; requested and captured dimensions are recorded separately", "Focus loss and touch cancellation are injected notifications/events", "Pause uses injected touch; reset/resume menu actions use actual Button.pressed signals; menu scroll extent is exercised programmatically", "Checkpoint and player placement fixtures isolate controls; this is not an ordinary-input route", "No performance, thermal, hardware-controller, subjective-audio, or human readability claim"],
		"engine": Engine.get_version_info().string, "host_os": OS.get_name(), "display_driver": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(), "captures": captures, "checks": checks,
		"profiles": "unique disposable user:// paths, removed; real user saves untouched",
		"minimum_target_policy": "88 logical units; at the 375-pixel-high landscape window require at least 44 rendered pixels, without equating pixels to physical-device points"
	}
	var file := FileAccess.open(output_dir.path_join("capture_report.json"), FileAccess.WRITE)
	if file == null:
		push_error("Could not write adaptive UI report.")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("ADAPTIVE UI: %s / %d checks / %d native captures; macOS desktop viewport simulations only" % [report.result, checks.size(), captures.size()])
	quit(0 if failures == 0 else 1)


func _seed_spoon_fixture() -> void:
	scene.hud.touch_controls.release_all()
	scene.state = Rules.new()
	_check(scene.state.resize("sugar", 0).ok and scene.state.pass_sugar().ok, "Explicit legal state fixture creates checkpoint 1")
	scene.sync_props(false)
	scene.pip.position = Vector3(-6.6, 0.06, 3.7)
	scene.vertical_speed = 0.0
	scene.jump_buffer = 0.0
	scene.target = "spoon"
	scene.hud.toast_time = 0.0
	scene.update_target()
	scene.save_game()
	_check(scene.last_save_ok, "Fixture persists through the actual isolated chapter writer")


func _validate_landscape() -> void:
	var hud = scene.hud
	var touch = hud.touch_controls
	var extent: Vector2 = root.get_visible_rect().size
	var expected := Rect2(Vector2(48, 16), extent - Vector2(80, 40))
	_check(hud.safe_rect.is_equal_approx(expected), "Asymmetric logical safe-inset override is applied exactly")
	_check(not hud.rotation_guard.visible and touch.enabled and not scene.paused, "Landscape permits gameplay and touch controls")
	_check(not hud.controls.visible, "Keyboard footer is hidden in the touch interface")
	_check(expected.encloses(Rect2(touch.pad_center - Vector2.ONE * touch.pad_radius, Vector2.ONE * touch.pad_radius * 2)), "Movement pad stays inside the safe rectangle")
	var keys: Array = touch.actions.keys()
	for key: String in keys:
		var rect: Rect2 = touch.actions[key]
		_check(expected.encloses(rect), key + " touch rectangle stays inside the safe area")
		_check(rect.size.x >= 88 and rect.size.y >= 88, key + " provides at least 88 logical units in both directions")
		var pixels: Vector2 = _pixel_size(touch, rect.size)
		_check(pixels.x >= 44 and pixels.y >= 44, key + " renders at least 44 pixels in both directions")
		for other: String in keys:
			if keys.find(other) > keys.find(key):
				_check(not rect.intersects(touch.actions[other]), key + " does not overlap " + other)
		if hud.pause_button.visible:
			_check(not rect.intersects(hud.pause_button.get_global_rect()), key + " does not overlap the visible Pause button")
		_check(not rect.intersects(hud.target_card.get_global_rect()), key + " does not overlap the current target card")
	_check(expected.encloses(hud.pause_button.get_global_rect()), "Pause remains inside the safe area")
	_check(hud.pause_button.size.x >= 88 and hud.pause_button.size.y >= 88, "Pause meets the same logical touch target minimum")
	for card: Control in [hud.top_card, hud.target_card]:
		_check(expected.encloses(card.get_global_rect()), card.name + " fits the safe gameplay rectangle")
	_check(not hud.top_card.get_global_rect().intersects(hud.target_card.get_global_rect()), "Objective and target cards do not overlap")
	for label: Label in [hud.objective, hud.subgoal, hud.target_title, hud.target_help]:
		_check(label.size.y + 0.1 >= label.get_minimum_size().y, label.name + " text has its required wrapped height")
		var rendered_font := _pixel_size(label, Vector2.ONE * label.get_theme_font_size("font_size"))
		_check(rendered_font.y >= 12.0, label.name + " font renders at least 12 pixels high in this desktop fixture")
	_check(hud.target_help.text.contains("Small") and hud.target_help.text.contains("Use") and not hud.target_help.text.contains(" E "), "Live spoon prompt uses touch action names")


func _test_touch_actions() -> void:
	var touch = scene.hud.touch_controls
	var pad: Vector2 = touch.pad_center
	await _touch(7, pad, true)
	_check(touch.pad_finger == 7 and _movement_clear(), "First finger claims the dead-zone center without movement")
	await _drag(7, pad + Vector2(54, 0), pad)
	_check(touch.pad_finger == 7 and scene.movement_input().x > 0.2, "Screen drag drives the existing movement action")
	var before: Vector3 = scene.pip.position
	await create_timer(0.1).timeout
	_check(scene.pip.position.distance_to(before) > 0.03, "Injected pad input moves the actual 3D character")
	await _touch(9, touch.actions.size_small.get_center(), true)
	_check(scene.state.sizes.spoon == 0 and touch.pad_finger == 7 and scene.movement_input().x > 0.2, "Second finger shrinks the live spoon while movement remains held")
	await _touch(9, touch.actions.size_small.get_center(), false)
	_check(touch.pad_finger == 7 and not touch.fingers.has(9), "Releasing the size finger preserves the movement finger")
	await _touch(9, touch.actions.size_normal.get_center(), true)
	await _touch(9, touch.actions.size_normal.get_center(), false)
	_check(scene.state.sizes.spoon == 1 and scene.movement_input().x > 0.2, "Normal touch restores the live spoon while the pad remains held")
	await _touch(9, touch.actions.size_large.get_center(), true)
	await _touch(9, touch.actions.size_large.get_center(), false)
	_check(scene.state.sizes.spoon == 1 and scene.hud.message.text.contains("big bridge"), "Large touch reaches the actual tray guard and explains why growth is refused")
	_validate_toast()
	await _touch(9, touch.actions.size_small.get_center(), true)
	await _touch(9, touch.actions.size_small.get_center(), false)
	await _touch(10, touch.actions.interact.get_center(), true)
	_check(scene.state.carried == "spoon" and scene.movement_input().x > 0.2, "Concurrent Use picks up the actual small spoon")
	await _touch(10, touch.actions.interact.get_center(), false)
	var floor_y: float = scene.surface_height(scene.pip.position)
	await _touch(11, touch.actions.jump.get_center(), true)
	await create_timer(0.1).timeout
	_check(scene.pip.position.y > floor_y + 0.08 and scene.movement_input().x > 0.2, "Concurrent Hop raises the actual character while movement remains held")
	await _touch(11, touch.actions.jump.get_center(), false)
	await _touch(7, pad + Vector2(54, 0), false)
	_check(touch.pad_finger == -1 and touch.fingers.is_empty() and _movement_clear(), "Releasing all fingers clears all movement state")
	await create_timer(0.7).timeout
	await _touch(12, pad + Vector2(-60, 0), true)
	_check(scene.movement_input().x < -0.2, "Fresh touch can move after all previous fingers release")
	await _touch(12, pad + Vector2(-60, 0), false, true)
	_check(touch.pad_finger == -1 and touch.fingers.is_empty() and _movement_clear(), "Canceled ScreenTouch release clears movement and finger tracking")
	await _touch(15, pad + Vector2(-60, 0), true)
	await _touch(15, pad + Vector2(-60, 0), true, true)
	_check(touch.pad_finger == -1 and touch.fingers.is_empty() and _movement_clear(), "Canceled event clears movement even when its pressed flag is true")
	await _touch(13, pad + Vector2(0, -60), true)
	_check(scene.movement_input().y < -0.2, "Focus-loss fixture starts with a held movement finger")
	touch.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await process_frame
	_check(touch.pad_finger == -1 and touch.fingers.is_empty() and _movement_clear(), "Injected window-focus-loss notification clears all movement and fingers")
	await _touch(13, pad, false)
	await _touch(14, pad + Vector2(55, 0), true)
	await _drag(14, pad + Vector2(280, -200), pad + Vector2(55, 0))
	_check(touch.pad_vector.length() <= 1.001, "Dragging beyond the pad clamps analog movement")
	await _touch(14, pad + Vector2(280, -200), false)
	_check(_movement_clear() and touch.fingers.is_empty(), "Releasing outside the original pad clears captured movement")


func _test_mode_switch(resolution: Vector2i) -> void:
	var hud = scene.hud
	var touch = hud.touch_controls
	await _touch(40, touch.pad_center + Vector2(55, 0), true)
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_RIGHT_STICK
	joy.pressed = true
	Input.parse_input_event(joy)
	await _settle()
	_check(hud.input_mode == "controller" and not touch.enabled and hud.controls.visible, "Injected controller event replaces virtual controls with controller hints")
	_check(_movement_clear() and touch.fingers.is_empty(), "Controller mode change clears the previous touch movement")
	_check(hud.controls.text.contains("A Hop") and hud.controls.text.contains("X Use"), "Controller footer reflects actual controller action labels")
	_check(hud.target_help.text.begins_with("X  "), "Controller mode updates the live carried-spoon context")
	_validate_input_footer("controller")
	if resolution.x == 844: await _capture(context + "_controller_hints", resolution, "injected gamepad event changed prompts; no controller hardware test")
	joy.pressed = false
	Input.parse_input_event(joy)
	await _touch(41, touch.pad_center + Vector2(55, 0), true)
	await _settle()
	_check(hud.input_mode == "touch" and touch.enabled and not hud.controls.visible, "A screen touch restores the virtual controls")
	_check(touch.pad_finger == 41 and scene.movement_input().x > 0.2, "The first touch after controller mode immediately claims and moves the pad")
	await _touch(41, touch.pad_center, false)
	joy.pressed = true
	Input.parse_input_event(joy)
	await _settle()
	joy.pressed = false
	Input.parse_input_event(joy)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	await _settle()
	_check(hud.input_mode == "keyboard" and not touch.enabled and hud.controls.visible, "External-keyboard event replaces virtual controls with keyboard hints")
	_check(Input.is_action_pressed("move_up") and scene.movement_input().y < -0.2, "Changing mode preserves a separately held keyboard movement action")
	touch.release_all()
	_check(Input.is_action_pressed("move_up") and scene.movement_input().y < -0.2, "Releasing touch state cannot erase a real keyboard action")
	_check(hud.controls.text.contains("K") and hud.controls.text.contains("L") and not hud.controls.text.contains("Space"), "Keyboard footer uses isolated persisted K/L remaps")
	_check(hud.target_help.text.begins_with("L  "), "Keyboard mode updates the live context to the remapped interact key")
	_validate_input_footer("keyboard")
	key.pressed = false
	Input.parse_input_event(key)
	await _settle()
	_check(_movement_clear(), "Releasing the physical-key event clears its movement contribution")
	if resolution.x == 844: await _capture(context + "_keyboard_hints", resolution, "injected keyboard event with persisted K/L bindings; no accessory keyboard hardware test")
	await _touch(42, touch.pad_center + Vector2(-55, 0), true)
	_check(hud.input_mode == "touch" and touch.enabled and touch.pad_finger == 42 and scene.movement_input().x < -0.2, "The first touch after keyboard mode immediately restores and moves the pad")
	await _touch(42, touch.pad_center, false)
	await _settle()
	_check(hud.target_help.text.begins_with("Use  ") and _movement_clear(), "Touch context returns to Use and no movement remains held")


func _validate_input_footer(kind: String) -> void:
	var hud = scene.hud
	_check(hud.safe_rect.encloses(hud.controls.get_global_rect()), kind + " footer fits the safe rectangle")
	_check(hud.controls.size.y >= hud.controls.get_minimum_size().y, kind + " footer fits its required wrapped text height")
	_check(_pixel_size(hud.controls, Vector2.ONE * hud.controls.get_theme_font_size("font_size")).y >= 12, kind + " footer has at least 12 rendered-pixel font size")
	_check(not hud.controls.get_global_rect().intersects(hud.target_card.get_global_rect()), kind + " footer does not cover the current target card")


func _test_pause_and_reset(resolution: Vector2i) -> void:
	var touch = scene.hud.touch_controls
	await _touch(20, touch.pad_center + Vector2(55, 0), true)
	await _touch(21, touch.actions.pause.get_center(), true)
	await _settle()
	_check(scene.paused and scene.hud.overlay.visible and not touch.enabled, "Concurrent Pause touch disables controls while opening the menu")
	_check(_movement_clear() and touch.fingers.is_empty(), "Pausing with a held pad releases all movement")
	_validate_menu("pause")
	await _capture(context + "_pause", resolution, "max-text pause menu top; concurrent injected Pause touch opened it while a movement finger was held")
	var scroll: ScrollContainer = scene.hud.menu_scroll
	var bar := scroll.get_v_scroll_bar()
	_check(bar.max_value > bar.page, "Max-text pause menu exposes vertical scroll overflow")
	scroll.scroll_vertical = int(bar.max_value)
	await _settle()
	var last_button: Button = _button("Save & return to title")
	_check(last_button != null, "Pause menu exposes its final title-return action")
	if last_button != null:
		_check(scroll.get_global_rect().intersects(last_button.get_global_rect()) and last_button.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1, "Scrolling reaches the final action without clipping its bottom")
	await _capture(context + "_pause_scrolled", resolution, "max-text pause menu programmatically scrolled to its final action")
	var reset_button: Button = _button("Reset this puzzle")
	_check(reset_button != null, "Actual checkpoint-reset button exists")
	if reset_button != null: reset_button.pressed.emit()
	await _settle()
	_check(not scene.paused and touch.enabled and _movement_clear() and touch.fingers.is_empty(), "Checkpoint reset resumes safely without restoring the old held finger")
	_check(scene.state.checkpoint == 1 and scene.state.carried == "" and scene.state.sizes.spoon == 1, "Reset restores the legal checkpoint through the actual scene command")
	var before: Vector3 = scene.pip.position
	await _drag(20, touch.pad_center + Vector2(70, 0), touch.pad_center)
	await create_timer(0.1).timeout
	_check(_movement_clear() and scene.pip.position.distance_to(before) < 0.03, "A stale pre-pause drag cannot resume movement after reset")
	await _touch(20, touch.pad_center, false)
	scene.on_command("pause", null)
	scene.on_command("controls", null)
	await _settle()
	_validate_menu("controls")
	scene.hud.menu_scroll.scroll_vertical = int(scene.hud.menu_scroll.get_v_scroll_bar().max_value)
	await _settle()
	await _capture(context + "_controls_scrolled", resolution, "max-text controls menu scrolled to bottom; keyboard rebinding is not physical touch verification")
	scene.on_command("resume", null)
	await _settle()


func _test_portrait() -> void:
	context = "390x844_portrait"
	_seed_spoon_fixture()
	await _settle()
	var touch = scene.hud.touch_controls
	await _touch(31, touch.pad_center + Vector2(60, 0), true)
	root.size = Vector2i(390, 844)
	await _settle()
	_check(scene.hud.rotation_guard.visible and scene.paused, "Portrait transition displays guidance and pauses active gameplay")
	_check(not touch.enabled and _movement_clear() and touch.fingers.is_empty(), "Portrait guard disables touch and releases the held finger")
	var before: Vector3 = scene.pip.position
	var snapshot: Dictionary = scene.state.to_dict()
	scene.on_command("resume", null)
	scene.on_command("start", null)
	await _touch(32, touch.actions.size_small.get_center(), true)
	await _touch(32, touch.actions.size_small.get_center(), false)
	await create_timer(0.15).timeout
	_check(scene.paused and scene.pip.position.is_equal_approx(before) and scene.state.to_dict() == snapshot, "Portrait blocks forced start/resume and injected gameplay controls")
	_check(root.get_visible_rect().encloses(scene.hud.rotation_guard.get_global_rect()), "Portrait guidance covers the viewport")
	await _capture("390x844_portrait_guard", Vector2i(390, 844), "portrait guidance; simulated rotation paused the live scene")
	root.size = Vector2i(844, 390)
	await _settle()
	_check(not scene.hud.rotation_guard.visible and scene.paused and not touch.enabled, "Rotating back keeps gameplay paused until explicit resume")
	var resume_button: Button = _button("Back to Pip")
	_check(resume_button != null, "Landscape return offers an explicit resume button")
	if resume_button != null: resume_button.pressed.emit()
	await _settle()
	_check(not scene.paused and touch.enabled and _movement_clear(), "Explicit resume after rotation restores touch without stale movement")
	await _capture("844x390_rotation_recovered", Vector2i(844, 390), "landscape recovery after explicit resume")


func _validate_menu(kind: String) -> void:
	var hud = scene.hud
	var scroll: ScrollContainer = hud.menu_scroll
	_check(scroll != null and hud.overlay.visible and not hud.touch_controls.enabled, kind + " uses the production scroll container and suppresses gameplay touches")
	if scroll == null: return
	_check(hud.safe_rect.encloses(scroll.get_global_rect()), kind + " scroll viewport stays inside safe insets")
	_check(hud.menu.size.x <= scroll.size.x + 0.1 and hud.menu.position.x >= -0.1, kind + " menu requires no horizontal scrolling")
	_check(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, kind + " horizontal scrolling is disabled")
	_check(not hud.message.visible or hud.message.modulate.a <= 0.01 or hud.message.size.y <= 180, kind + " has no stale oversized toast panel behind the menu")
	for child: Control in _interactive_children(hud.menu_box):
		_check(child.size.y >= 88, kind + " interactive target meets 88 logical height: " + child.name)
		_check(child.get_global_rect().position.x >= scroll.get_global_rect().position.x - 0.1 and child.get_global_rect().end.x <= scroll.get_global_rect().end.x + 0.1, kind + " interactive target fits horizontally: " + child.name)
		if child is Button:
			var font: Font = child.get_theme_font("font")
			var text_width: float = font.get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, child.get_theme_font_size("font_size")).x
			_check(text_width <= child.size.x - 12, kind + " button label fits available width: " + child.text)


func _test_card_shrink() -> void:
	# Isolate a long-to-short guidance transition while the real HUD containers
	# and deferred layout continue processing at this viewport and text scale.
	var was_processing: bool = scene.is_processing()
	scene.set_process(false)
	var hud = scene.hud
	var previous: Array[String] = [hud.objective.text, hud.subgoal.text, hud.target_help.text]
	hud.objective.text = "Milk Harbor"
	hud.subgoal.text = "Carry the little parcel across the shallow milk to reach the folded spoon dock. The raft needs a lighter load before Pip can cross."
	hud.target_help.text = "Choose Small to make the parcel light enough, then Use to continue across the shallow milk."
	await _settle()
	var tall_objective: float = hud.top_card.size.y
	var tall_target: float = hud.target_card.size.y
	hud.objective.text = "Milk Harbor"
	hud.subgoal.text = "The dock is open."
	hud.target_help.text = "Use to step ashore."
	await _settle()
	_check(hud.top_card.size.y < tall_objective - 10, "Shorter objective releases the previous wrapped card height at text scale " + str(scene.text_scale))
	_check(hud.target_card.size.y < tall_target - 10, "Shorter target guidance releases the previous wrapped card height")
	_check(hud.top_card.size.y >= hud.top_card.get_combined_minimum_size().y and hud.target_card.size.y >= hud.target_card.get_combined_minimum_size().y, "Refitted cards still enclose their current content")
	hud.objective.text = previous[0]
	hud.subgoal.text = previous[1]
	hud.target_help.text = previous[2]
	scene.set_process(was_processing)
	await _settle()


func _validate_toast() -> void:
	var hud = scene.hud
	var rect: Rect2 = hud.message.get_global_rect()
	_check(hud.message.visible and hud.message.modulate.a > 0.1, "Actual refusal feedback becomes visible")
	_check(hud.message.get_theme_font_size("font_size") == int(24 * scene.text_scale), "Transient feedback honors the current readable text scale")
	_check(hud.safe_rect.encloses(rect) and rect.size.y <= 180, "Actual refusal toast fits safe bounds after prior viewport changes")
	_check(not rect.intersects(hud.top_card.get_global_rect()) and not rect.intersects(hud.target_card.get_global_rect()), "Visible refusal feedback does not cover the objective or target text")
	for action: String in hud.touch_controls.actions:
		_check(not rect.intersects(hud.touch_controls.actions[action]), "Visible refusal toast does not overlap touch target " + action)


func _interactive_children(node: Node) -> Array[Control]:
	var found: Array[Control] = []
	for child in node.get_children():
		if child is Button or child is Slider: found.append(child)
		found.append_array(_interactive_children(child))
	return found


func _touch(index: int, point: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform() * scene.hud.touch_controls.get_global_transform_with_canvas() * point
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _drag(index: int, point: Vector2, previous: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	var transform: Transform2D = root.get_final_transform() * scene.hud.touch_controls.get_global_transform_with_canvas()
	event.index = index
	event.position = transform * point
	event.relative = (transform * point) - (transform * previous)
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _pixel_size(control: Control, logical: Vector2) -> Vector2:
	var transform: Transform2D = root.get_final_transform() * control.get_global_transform_with_canvas()
	return Vector2(transform.basis_xform(Vector2(logical.x, 0)).length(), transform.basis_xform(Vector2(0, logical.y)).length())


func _movement_clear() -> bool:
	for action: String in MOVEMENT:
		if Input.is_action_pressed(action): return false
	return scene.movement_input().is_zero_approx()


func _button(label: String) -> Button:
	for child: Control in _interactive_children(scene.hud.menu_box):
		if child is Button and child.text == label: return child
	return null


func _settle() -> void:
	await create_timer(0.18).timeout
	await process_frame
	await process_frame


func _capture(name: String, pixels: Vector2i, fixture: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var difference: Vector2i = frame.get_size() - pixels
	_check(difference.x >= -1 and difference.x <= 0 and difference.y >= -1 and difference.y <= 0, "Native framebuffer matches requested desktop dimensions within at most one pixel of macOS backing-store rounding: " + name)
	var path := output_dir.path_join(name + ".png")
	_check(frame.save_png(path) == OK, "Native PNG written: " + name)
	var touch = scene.hud.touch_controls
	var target_sizes: Dictionary = {}
	for action: String in touch.actions:
		var size: Vector2 = _pixel_size(touch, touch.actions[action].size)
		target_sizes[action] = [size.x, size.y]
	captures.append({"path": path, "requested_window_pixels": [pixels.x, pixels.y], "pixels": [frame.get_width(), frame.get_height()], "logical_viewport": _rect(root.get_visible_rect()), "safe_rect": _rect(scene.hud.safe_rect), "safe_insets_override_ltrb": [48, 16, 32, 24], "text_scale": scene.text_scale, "fixture": fixture, "focused": DisplayServer.window_is_focused(), "touch_enabled": touch.enabled, "touch_target_rendered_pixels": target_sizes, "target_card": _rect(scene.hud.target_card.get_global_rect()), "menu_scroll": _rect(scene.hud.menu_scroll.get_global_rect()), "menu_scroll_vertical": scene.hud.menu_scroll.scroll_vertical, "platform": "macOS desktop viewport simulation; not iOS Simulator or physical device"})


func _rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _snapshot_globals() -> void:
	original_buses = AudioServer.generate_bus_layout()
	for action in InputMap.get_actions():
		original_inputs[action] = {"deadzone": InputMap.action_get_deadzone(action), "events": InputMap.action_get_events(action)}


func _restore_globals() -> void:
	for action in InputMap.get_actions(): InputMap.erase_action(action)
	for action in original_inputs:
		InputMap.add_action(action, original_inputs[action].deadzone)
		for event: InputEvent in original_inputs[action].events: InputMap.action_add_event(action, event)
	AudioServer.set_bus_layout(original_buses)


func _cleanup() -> void:
	for path: String in [profile_path, settings_path, demo_path]:
		for extension: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + extension): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + extension))


func _check(condition: bool, message: String) -> void:
	checks.append({"pass": condition, "context": context, "message": message})
	if not condition:
		failures += 1
		push_error(context + ": " + message)
