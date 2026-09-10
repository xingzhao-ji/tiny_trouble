extends SceneTree
## Injected application notifications in real scenes, not physical iOS testing.
## ./run.command --headless --script res://tests/platform/test_lifecycle.gd -- --touch-ui
## Unique disposable profiles/settings; original InputMap and audio buses restored.

const SCENES = [
	preload("res://scenes/main.tscn"),
	preload("res://scenes/chapter/crumb_crossing.tscn"),
	preload("res://scenes/chapter/blueberry_ballast.tscn"),
	preload("res://scenes/chapter/milk_harbor.tscn")]
const IDS = ["VS01", "W01S01", "W01S02", "W01S03"]
const PROPS = ["spoon", "spoon", "berry_a", "cereal"]
const NEW_SIZES = [0, 0, 2, 2]
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
const HarborRules = preload("res://scripts/chapter/harbor_state.gd")
var game: Node3D
var checks := 0
var failures := 0
var index := 0
var profile_path: String
var settings_path: String
var demo_path: String
var inputs: Dictionary = {}
var buses: AudioBusLayout


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not "--touch-ui" in OS.get_cmdline_user_args():
		print("Lifecycle test requires -- --touch-ui to include held touch state.")
		quit(2)
		return
	buses = AudioServer.generate_bus_layout()
	for action in InputMap.get_actions():
		inputs[action] = {"deadzone": InputMap.action_get_deadzone(action), "events": InputMap.action_get_events(action)}
	root.size = Vector2i(1280, 720)
	for stage_index in range(SCENES.size()):
		index = stage_index
		var suffix := "%d_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec(), index]
		profile_path = "user://lifecycle_chapter_" + suffix + ".json"
		settings_path = "user://lifecycle_settings_" + suffix + ".cfg"
		demo_path = "user://lifecycle_demo_" + suffix + ".json"
		var config := ConfigFile.new()
		config.set_value("sound", "music", 0.0)
		config.set_value("sound", "effects", 0.0)
		config.set_value("comfort", "reduced_motion", false)
		_check(config.save(settings_path) == OK, "Isolated silent settings saved with real animation enabled")
		var profile := Progress.new()
		profile.save_path = profile_path
		for previous in range(maxi(0, index - 1)):
			_check(profile.complete_stage(IDS[previous + 1]), "Explicit fixture seeds only the required earlier chapter completion")
		game = _spawn()
		await _settle(0.12)
		_check(not game.started and not game.has_save, "Fresh isolated scene starts at its title without saved stage progress")
		game.on_command("start", null)
		await _settle(0.05)
		await _test_resize_interruption()
		if index == 3: await _test_harbor_transit()
		await game.stop_audio()
		game.queue_free()
		await process_frame
		_cleanup()
		_check(not FileAccess.file_exists(profile_path) and not FileAccess.file_exists(demo_path) and not FileAccess.file_exists(settings_path), "Disposable files removed after scene lifecycle checks")
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.erase_action(action)
	for action in inputs:
		InputMap.add_action(action, inputs[action].deadzone)
		for event: InputEvent in inputs[action].events: InputMap.action_add_event(action, event)
	AudioServer.set_bus_layout(buses)
	print("%s: %d lifecycle checks; all four source scenes, injected app focus/pause/resume, real resize tweens, held input release, synchronous isolated saves, and interrupted Harbor disk recovery. Not physical mobile testing." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _spawn() -> Node3D:
	var scene: Node3D = SCENES[index].instantiate()
	scene.save_path = demo_path
	scene.chapter_profile_path = profile_path
	scene.settings_path = settings_path
	root.add_child(scene)
	current_scene = scene
	_check(scene.save_path == demo_path and scene.settings_path == settings_path and scene.chapter_profile_path == profile_path, "All storage paths are isolated before scene readiness")
	return scene


func _test_resize_interruption() -> void:
	var kind: String = PROPS[index]
	game.target = kind
	game.pip.position = game.props[kind].position + Vector3(-1.5, 0, 1.2)
	if index == 3: game.pip.position = game.NEAR_BANK
	game.pip.position.y = game.surface_height(game.pip.position)
	game.vertical_speed = 0
	var original: Transform3D = game.props[kind].transform
	game.resize_target(NEW_SIZES[index])
	await _settle(0.07)
	_check(int(game.state.sizes[kind]) == NEW_SIZES[index], "Production resize changes the intended puzzle state")
	_check(not game.props[kind].transform.is_equal_approx(original), "Production resize has actually started animating before interruption")
	# Hold one real parsed keyboard event and one parsed touch finger together.
	await _key(KEY_W, true)
	var pad: Vector2 = game.hud.touch_controls.pad_center + Vector2(55, 0)
	await _touch(5, pad, true)
	_check(Input.is_action_pressed("move_up") and game.hud.touch_controls.pad_finger == 5, "Interruption starts with both physical-action and touch movement held")
	game.jump_buffer = 0.15
	# Remove only this disposable save, proving the notification writes now.
	_remove_save_files()
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var transforms: Dictionary = _transforms()
	var paused_count: int = game.paused_tweens.size()
	_check(game.paused and game.hud.overlay.visible and game.hud.menu_mode == "pause", "App focus loss opens the actual pause menu")
	_check(paused_count > 0, "App focus loss retains a suspended production resize tween")
	_check(_held_clear(), "App focus loss clears physical actions, touch fingers/vector and jump buffer")
	_check(FileAccess.file_exists(_active_save()), "App focus loss writes the isolated save synchronously")
	_check(_audio_paused(true), "App focus loss pauses every active AudioStreamPlayer")
	await _settle(0.18)
	_check(_transforms() == transforms, "All prop and player transforms remain exactly frozen while backgrounded")
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await _settle(0.08)
	_check(game.paused and game.paused_tweens.size() == paused_count and _transforms() == transforms, "Duplicate OS pause notification preserves the suspended resize and exact transforms")
	_check(_audio_paused(true) and _held_clear(), "OS pause remains silent and cannot restore held input")
	var reloaded := _spawn()
	await _settle(0.06)
	_check(reloaded.has_save and int(reloaded.state.sizes[kind]) == NEW_SIZES[index], "A fresh scene actually reloads the resize state from notification-written disk data")
	_check(not reloaded.started and reloaded.hud.overlay.visible, "Disk reload stays at a visible title rather than starting gameplay")
	reloaded.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await process_frame
	_check(not reloaded.started and reloaded.hud.overlay.visible, "App resume does not auto-start a newly loaded title")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame
	current_scene = game
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	game.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _settle(0.16)
	_check(game.paused and game.hud.overlay.visible and _transforms() == transforms, "Foreground/resume notifications do not auto-play paused gameplay or resize motion")
	_check(_audio_paused(false) and _held_clear(), "Foreground restores audio availability while leaving input released")
	var resume: Button = _button("Back to Pip")
	_check(resume != null, "Visible pause menu offers explicit Back to Pip")
	if resume != null: resume.pressed.emit()
	await _settle(0.7)
	_check(not game.paused and not game.hud.overlay.visible and game.paused_tweens.is_empty(), "Explicit menu resume releases the suspended animation")
	var expected_scale := 2.0 if NEW_SIZES[index] == 2 else 0.5
	_check(game.props[kind].scale.is_equal_approx(Vector3.ONE * expected_scale), "Resumed resize settles at its exact authored target scale")
	_check(_held_clear(), "Explicit resume does not replay stale movement or jump")
	await _key(KEY_W, false)
	await _touch(5, pad, false)
	_check(not game.state.completed, "Lifecycle test does not fabricate a stage clear")


func _test_harbor_transit() -> void:
	for checkpoint: int in [1, 2]:
		var fixture := HarborRules.new()
		_check(fixture.resize("cereal", 2).ok and fixture.board().ok, "Explicit Harbor fixture boards a legally enlarged raft")
		if checkpoint == 2:
			_check(fixture.depart().ok and fixture.arrive().ok and fixture.resize("cargo", 0).ok, "Explicit second-voyage fixture reaches the shoal and lightens cargo")
		game.state = fixture
		game.sync_props(false)
		game.respawn()
		game.on_command("resume", null)
		game.interact()
		await _settle(0.12)
		_check(game.in_transit() and game.state.phase == ("to_shoal" if checkpoint == 1 else "to_far"), "Production interaction starts the real interrupted Harbor voyage")
		_remove_save_files()
		game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		var transforms: Dictionary = _transforms()
		var before_phase: String = game.state.phase
		_check(FileAccess.file_exists(profile_path), "OS pause synchronously stores the in-transit Harbor snapshot")
		await _settle(0.18)
		_check(game.paused and _transforms() == transforms and game.state.phase == before_phase, "Background pause freezes actual raft, rider, dock and cargo during transit")
		var reloaded := _spawn()
		await _settle(0.06)
		_check(reloaded.has_save and reloaded.state.recovered_motion and reloaded.state.checkpoint == checkpoint, "Fresh disk load recognizes interrupted transit and retains the last checkpoint")
		_check(reloaded.state.phase == ("near" if checkpoint == 1 else "shoal") and reloaded.state.aboard == (checkpoint == 2), "Interrupted disk load restores the canonical mooring and rider state")
		_check(int(reloaded.state.sizes.cargo) == 1 and not reloaded.in_transit() and not reloaded.busy(), "Interrupted disk load restores canonical cargo and contains no live travel callback")
		_check(reloaded.save_notice.contains("last mooring") and not reloaded.started, "Recovery notice explains the canonical reset without auto-starting")
		reloaded.on_command("start", null)
		_check(reloaded.hud.message.text.contains("last mooring"), "Actual start presents the interrupted-voyage explanation")
		_check(not reloaded.obstructed(reloaded.pip.position) and is_equal_approx(reloaded.pip.position.y, reloaded.surface_height(reloaded.pip.position)), "Recovered rider has an actual safe authored support")
		await reloaded.stop_audio()
		reloaded.queue_free()
		await process_frame
		current_scene = game
		game.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		await _settle(0.12)
		_check(game.paused and game.state.phase == before_phase and _transforms() == transforms, "Returning to the still-live app leaves the interrupted voyage paused")
		var resume: Button = _button("Back to Pip")
		if resume != null: resume.pressed.emit()
		var deadline := Time.get_ticks_msec() + 5000
		while game.in_transit() and Time.get_ticks_msec() < deadline: await process_frame
		_check(not game.paused and game.state.phase == ("shoal" if checkpoint == 1 else "far"), "Explicit resume completes the original live voyage at its intended destination")
		await _settle(0.6)


func _transforms() -> Dictionary:
	var values: Dictionary = {"pip": game.pip.transform}
	for kind in game.props: values[kind] = game.props[kind].transform
	if index == 3: values["dock"] = game.dock_leaf.transform
	return values


func _held_clear() -> bool:
	for action in game.DEFAULT_KEYS:
		if Input.is_action_pressed(action): return false
	return game.hud.touch_controls.pad_finger == -1 and game.hud.touch_controls.fingers.is_empty() and game.hud.touch_controls.pad_vector.is_zero_approx() and game.jump_buffer == 0 and game.movement_input().is_zero_approx()


func _audio_paused(expected: bool) -> bool:
	var count := 0
	for child in game.get_children():
		if child is AudioStreamPlayer:
			# An idle pool slot has no pausable playback; Godot reports its
			# stream_paused as false. It must still remain entirely inactive.
			if not child.has_stream_playback():
				if child.playing: return false
				continue
			count += 1
			if child.stream_paused != expected: return false
	return count > 0


func _button(label: String) -> Button:
	for child in game.hud.menu_box.get_children():
		if child is Button and child.text == label: return child
	return null


func _active_save() -> String:
	return demo_path if index == 0 else profile_path


func _remove_save_files() -> void:
	for extension: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(_active_save() + extension): DirAccess.remove_absolute(ProjectSettings.globalize_path(_active_save() + extension))


func _cleanup() -> void:
	for path: String in [profile_path, settings_path, demo_path]:
		for extension: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + extension): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + extension))


func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _touch(finger: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.position = root.get_final_transform() * game.hud.touch_controls.get_global_transform_with_canvas() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(IDS[index] + ": " + message)
