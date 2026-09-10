extends SceneTree
## Isolated settings integration checks. Uses a complete headless scene, test-only
## user:// paths, and restores InputMap/audio buses before exiting.

const Main = preload("res://scripts/main.gd")
var checks: int = 0
var failures: int = 0
var settings_path: String
var save_path: String
var original_inputs: Dictionary = {}
var original_bus_layout: AudioBusLayout


func _initialize() -> void:
	settings_path = "user://settings_test_%d.cfg" % OS.get_process_id()
	save_path = "user://settings_test_%d.json" % OS.get_process_id()
	_snapshot_globals()
	_cleanup()
	call_deferred("_run")


func _run() -> void:
	var scene = _spawn()
	await process_frame
	_expect(scene.settings_path == settings_path and scene.save_path == save_path, "Scene uses isolated settings and progress paths")
	_expect(not scene.has_save, "Settings test never loads the real player save")
	_expect(is_equal_approx(scene.music_volume, 0.55), "Missing settings keep default music level")
	_expect(is_equal_approx(scene.effects_volume, 0.8), "Missing settings keep default effects level")
	_expect(not scene.reduced_motion and is_equal_approx(scene.text_scale, 1.0), "Missing settings keep default comfort values")
	scene.on_command("start", true)
	scene.on_command("pause", null)
	_expect(scene.paused and scene.hud.menu_mode == "pause", "Settings are exercised in the live pause interface")

	_slider(scene, "Music").value = 0.25
	_slider(scene, "Effects").value = 0.7
	_expect(is_equal_approx(scene.music_volume, 0.25) and is_equal_approx(scene.effects_volume, 0.7), "Music and effects retain independent values")
	_expect(_near(_bus_linear("Music"), 0.125), "Music slider immediately applies its scene mix gain")
	_expect(_near(_bus_linear("Effects"), 0.7), "Effects slider immediately applies its separate bus gain")
	_expect(FileAccess.file_exists(settings_path), "A settings change writes its isolated ConfigFile")
	_slider(scene, "Music").value = 0.0
	_expect(_bus_linear("Music") <= 0.0001, "Music can be muted")
	_expect(_near(_bus_linear("Effects"), 0.7), "Muting music leaves effects audible")
	_slider(scene, "Music").value = 0.4
	_slider(scene, "Effects").value = 0.0
	_expect(_bus_linear("Effects") <= 0.0001, "Effects can be muted")
	_expect(_near(_bus_linear("Music"), 0.2), "Muting effects leaves music audible")
	_slider(scene, "Music").value = 0.35
	_slider(scene, "Effects").value = 0.65

	_reduced_toggle(scene).button_pressed = true
	_expect(scene.reduced_motion and bool(_saved("comfort", "reduced_motion")), "Reduced motion enables and saves immediately")
	_reduced_toggle(scene).button_pressed = false
	_expect(not scene.reduced_motion and not bool(_saved("comfort", "reduced_motion")), "Reduced motion can be disabled and saved")
	_reduced_toggle(scene).button_pressed = true
	_slider(scene, "Text size").value = 1.2
	_expect(is_equal_approx(float(_saved("comfort", "text_scale")), 1.2), "Text size persists")
	_expect(scene.hud.target_help.get_theme_font_size("font_size") == 18, "Text setting reaches target-help text")
	_expect(scene.hud.subgoal.get_theme_font_size("font_size") == 19, "Text setting reaches objective text")

	scene.on_command("controls", null)
	scene.on_command("rebind", "jump")
	var before_rebind: String = FileAccess.get_file_as_string(settings_path)
	for reserved: int in [KEY_1, KEY_2, KEY_3]:
		await _key(reserved)
		_expect(scene.pending_rebind == "jump", "Reserved size key %d keeps remapping open" % (reserved - KEY_1 + 1))
		_expect(scene.hud.message.text.contains("quick size keys"), "Reserved size key refusal explains the conflict")
		_expect(_matches(KEY_SPACE, "jump") and not _matches(reserved, "jump"), "Reserved size key cannot replace jump")
		_expect(FileAccess.get_file_as_string(settings_path) == before_rebind, "Rejected key leaves saved bindings unchanged")
	await _key(KEY_W)
	_expect(scene.pending_rebind == "jump", "Duplicate movement key keeps remapping open")
	_expect(scene.hud.message.text.contains("already used") and scene.hud.message.text.contains("move up"), "Duplicate key names the conflicting action")
	_expect(_matches(KEY_W, "move_up") and not _matches(KEY_W, "jump"), "Duplicate refusal preserves both action mappings")
	_expect(FileAccess.get_file_as_string(settings_path) == before_rebind, "Duplicate refusal does not persist an invalid binding")
	await _key(KEY_K)
	_expect(scene.pending_rebind.is_empty(), "Unused key completes rebinding")
	_expect(_matches(KEY_K, "jump"), "Accepted physical key maps to jump")
	_expect(not _matches(KEY_SPACE, "jump"), "Old physical key no longer maps to jump")
	_expect(_has_jump_button(), "Keyboard rebinding preserves the controller jump button")
	_expect(int(_saved("keys", "jump")) == KEY_K, "Accepted binding persists")
	_expect(scene.binding_names().get("jump") == "K", "Control labels show the accepted key")
	_expect(scene.hud.controls.text.contains("K  Hop") and not scene.hud.controls.text.contains("Space  Hop"), "Footer immediately shows the remapped jump key")
	scene.on_command("rebind", "interact")
	await _key(KEY_ESCAPE)
	_expect(scene.pending_rebind.is_empty() and _matches(KEY_E, "interact"), "Escape cancels remapping without replacing interact")
	scene.on_command("rebind", "interact")
	await _key(KEY_L)
	_expect(_matches(KEY_L, "interact") and not _matches(KEY_E, "interact"), "Interact accepts a distinct replacement key")
	_expect(scene.hud.controls.text.contains("L  Carry / Place"), "Footer immediately shows the remapped interact key")
	scene.hud.update_target("Spoon", "E  Pick up • Tab  Change target", 0)
	_expect(scene.hud.target_help.text == "L  Pick up • Tab  Change target", "Contextual target prompt uses the remapped interact key")
	var target_style: StyleBox = scene.hud.size_buttons[0].get_theme_stylebox("normal")
	scene.hud.update_target("Spoon", "E  Pick up • Tab  Change target", 0)
	_expect(scene.hud.size_buttons[0].get_theme_stylebox("normal") == target_style, "Unchanged target signature reuses existing size-button style")
	scene.hint_step = 2
	scene.show_hint()
	_expect(scene.hud.message.text.contains("press 1 then L."), "Authored hint shows the replacement key while retaining numeric sizes")
	var actual_names: Dictionary = scene.binding_names()
	var swapped_names: Dictionary = actual_names.duplicate()
	swapped_names["interact"] = "Q"
	swapped_names["shrink"] = "E"
	scene.hud.set_bindings(swapped_names)
	_expect(scene.hud.target_help.text == "Q  Pick up • Tab  Change target", "Binding changes reformat an already visible target from its original text")
	scene.hud.toast("E / Q / F • Space • 1 / 2 / 3 • SPOON REST")
	_expect(scene.hud.message.text == "Q / E / F • K • 1 / 2 / 3 • SPOON REST", "Key-token swaps format once without cascading or changing ordinary words/numbers")
	scene.hud.set_bindings(actual_names)
	_expect(scene.hud.target_help.text == "L  Pick up • Tab  Change target", "Restoring bindings reformats original target text instead of replacing prior output")

	await scene.stop_audio()
	scene.queue_free()
	await process_frame
	_restore_inputs()
	var restored = _spawn()
	await process_frame
	_expect(is_equal_approx(restored.music_volume, 0.35), "A fresh scene reloads music volume")
	_expect(is_equal_approx(restored.effects_volume, 0.65), "A fresh scene reloads effects volume")
	_expect(_near(_bus_linear("Music"), 0.175) and _near(_bus_linear("Effects"), 0.65), "Restored preferences reach live audio buses")
	_expect(restored.reduced_motion, "A fresh scene reloads reduced motion")
	_expect(is_equal_approx(restored.text_scale, 1.2), "A fresh scene reloads text size")
	_expect(restored.hud.target_help.get_theme_font_size("font_size") == 18, "Restored text size reaches the rebuilt interface")
	_expect(_matches(KEY_K, "jump") and not _matches(KEY_SPACE, "jump"), "A fresh scene preserves the replacement key without restoring the old key")
	_expect(_has_jump_button(), "Restored keyboard preferences preserve controller mapping")
	_expect(restored.hud.controls.text.contains("K  Hop") and restored.hud.controls.text.contains("L  Carry / Place"), "Fresh-scene footer displays persisted jump and interact bindings")
	restored.hud.update_target("Spoon", "E  Pick up • Tab  Change target", 0)
	_expect(restored.hud.target_help.text == "L  Pick up • Tab  Change target", "Fresh-scene context displays the persisted interact binding")
	await _test_prompt_layout(restored)
	await restored.stop_audio()
	restored.queue_free()
	await process_frame

	_test_numeric_recovery()
	_restore_inputs()
	_restore_buses()
	_cleanup()
	_expect(_inputs_match_snapshot(), "Global InputMap restored after settings tests")
	_expect(not FileAccess.file_exists(settings_path), "Isolated settings file removed after tests")
	print("%s: %d settings checks; independent audio, comfort persistence, remapping feedback, reload, and invalid-number recovery." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_numeric_recovery() -> void:
	var config = ConfigFile.new()
	config.set_value("sound", "music", 4.0)
	config.set_value("sound", "effects", -2.0)
	config.set_value("comfort", "text_scale", 8.0)
	config.save(settings_path)
	var scene = Main.new()
	scene.settings_path = settings_path
	scene.load_settings()
	_expect(is_equal_approx(scene.music_volume, 1.0), "Finite excessive music value clamps to its maximum")
	_expect(is_equal_approx(scene.effects_volume, 0.0), "Finite negative effects value clamps to mute")
	_expect(is_equal_approx(scene.text_scale, 1.25), "Finite excessive text value clamps to supported size")
	scene.free()
	config.set_value("sound", "music", NAN)
	config.set_value("sound", "effects", INF)
	config.set_value("comfort", "text_scale", NAN)
	config.save(settings_path)
	# Validate the loader before any corrupted numeric value reaches an audio
	# bus or font override; the live scene/reload path was exercised above.
	scene = Main.new()
	scene.settings_path = settings_path
	scene.load_settings()
	_expect(is_equal_approx(scene.music_volume, 0.55), "Non-finite music config recovers to the default level")
	_expect(is_equal_approx(scene.effects_volume, 0.8), "Non-finite effects config recovers to the default level")
	_expect(is_equal_approx(scene.text_scale, 1.0), "Non-finite text config recovers to the default size")
	scene.free()
	config.set_value("sound", "music", "loud")
	config.set_value("sound", "effects", [0.5])
	config.set_value("comfort", "text_scale", {"scale": 1.1})
	config.save(settings_path)
	scene = Main.new()
	scene.settings_path = settings_path
	scene.load_settings()
	_expect(is_equal_approx(scene.music_volume, 0.55), "Wrong-type music config safely uses its default")
	_expect(is_equal_approx(scene.effects_volume, 0.8), "Wrong-type effects config safely uses its default")
	_expect(is_equal_approx(scene.text_scale, 1.0), "Wrong-type text config safely uses its default")
	scene.free()
	for invalid_code: Variant in [0, -1, 0x800000, "not a key", []]:
		_restore_inputs()
		config.set_value("keys", "jump", invalid_code)
		config.save(settings_path)
		scene = Main.new()
		scene.settings_path = settings_path
		scene.configure_inputs()
		scene.load_settings()
		_expect(_matches(KEY_SPACE, "jump") and _has_jump_button(), "Invalid saved key %s keeps default keyboard and controller bindings" % str(invalid_code))
		scene.free()


func _test_prompt_layout(scene: Node) -> void:
	var original_size: Vector2i = root.size
	var names: Dictionary = scene.binding_names()
	var long_names: Dictionary = names.duplicate()
	long_names["jump"] = OS.get_keycode_string(KEY_PAGEUP)
	long_names["move_left"] = OS.get_keycode_string(KEY_BRACKETLEFT)
	scene.hud.set_bindings(long_names)
	scene.on_command("text", 1.25)
	scene.hud.hide_menu()
	scene.hud.update_target("Blueberry · carrying", "1 / Q  Shrink the berry to launch!   E  Step off", 0)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		for frame in 4:
			await process_frame
		var viewport: Rect2 = scene.hud.root.get_global_rect()
		var card: Rect2 = scene.hud.target_card.get_global_rect()
		var footer: Rect2 = scene.hud.controls.get_global_rect()
		_expect(viewport.encloses(card), "Maximum-size target card fits %s" % str(resolution))
		_expect(absf(card.end.y - (viewport.end.y - 52.0)) <= 0.1, "Wrapped target card retains its fixed bottom gap")
		_expect(card.end.y + 12.0 <= footer.position.y, "Wrapped target card stays above the controls footer")
		_expect(card.encloses(scene.hud.target_help.get_global_rect()) and card.encloses(scene.hud.target_title.get_global_rect()), "Maximum-size title and prompt remain within their card")
		var footer_width: float = scene.hud.controls.get_theme_font("font").get_string_size(scene.hud.controls.text, HORIZONTAL_ALIGNMENT_LEFT, -1, scene.hud.controls.get_theme_font_size("font_size")).x
		_expect(footer_width <= viewport.size.x - 16.0, "Footer including PageUp and bracket movement key fits %s" % str(resolution))
	root.size = original_size
	scene.hud.set_bindings(names)
	await process_frame


func _spawn() -> Node3D:
	var scene = Main.new()
	scene.settings_path = settings_path
	scene.save_path = save_path
	root.add_child(scene)
	return scene


func _slider(scene: Node, name: String) -> HSlider:
	for row in scene.hud.menu_box.get_children():
		if row is HBoxContainer and row.get_child_count() == 2:
			if row.get_child(0) is Label and row.get_child(0).text == name:
				return row.get_child(1) as HSlider
	return null


func _reduced_toggle(scene: Node) -> CheckButton:
	for control in scene.hud.menu_box.get_children():
		if control is CheckButton and control.text == "Reduced motion":
			return control
	return null


func _key(code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _matches(code: int, action: String) -> bool:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return InputMap.event_is_action(event, action)


func _has_jump_button() -> bool:
	for event in InputMap.action_get_events("jump"):
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A:
			return true
	return false


func _saved(section: String, key: String) -> Variant:
	var config = ConfigFile.new()
	_expect(config.load(settings_path) == OK, "Written settings remain readable")
	return config.get_value(section, key)


func _bus_linear(name: String) -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(name)))


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


func _snapshot_globals() -> void:
	for action in InputMap.get_actions():
		var events: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			events.append(event.duplicate())
		original_inputs[action] = {"deadzone": InputMap.action_get_deadzone(action), "events": events}
	# At SceneTree initialization the project's named buses may not exist yet.
	# Snapshot the whole layout instead of assuming Music/Effects are present.
	original_bus_layout = AudioServer.generate_bus_layout()


func _restore_inputs() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.erase_action(action)
	for action in original_inputs:
		InputMap.add_action(action, original_inputs[action]["deadzone"])
		for event in original_inputs[action]["events"]:
			InputMap.action_add_event(action, event.duplicate())


func _inputs_match_snapshot() -> bool:
	if InputMap.get_actions().size() != original_inputs.size():
		return false
	for action in original_inputs:
		if not InputMap.has_action(action):
			return false
		if not is_equal_approx(InputMap.action_get_deadzone(action), original_inputs[action]["deadzone"]):
			return false
		var actual: Array[InputEvent] = InputMap.action_get_events(action)
		var expected: Array[InputEvent] = original_inputs[action]["events"]
		if actual.size() != expected.size():
			return false
		for i in actual.size():
			if actual[i].as_text() != expected[i].as_text():
				return false
	return true


func _restore_buses() -> void:
	AudioServer.set_bus_layout(original_bus_layout)


func _cleanup() -> void:
	for path: String in [settings_path, save_path, save_path + ".bak", save_path + ".tmp", save_path + ".bak.tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
