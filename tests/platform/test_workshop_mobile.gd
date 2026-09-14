extends SceneTree
## Native Workshop viewport audit, not a gameplay or device test.
## Source: --path . --script tests/platform/test_workshop_mobile.gd -- --touch-ui.
## Exported content: additionally use --main-pack <pack> and --audited-pack=<pack>.
## No production scene, layout, camera or text-scale state is patched by this test.

const Workshop = preload("res://scenes/chapter/workshop.tscn")
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
const HarborRules = preload("res://scripts/chapter/harbor_state.gd")
const WINDOWS = [Vector2i(1024, 768), Vector2i(844, 390), Vector2i(667, 375)]
const INSETS := Vector4(48, 16, 32, 24)
const NAVIGATION_PROBES = [
	{"label": "Enter", "key": KEY_ENTER, "action": "", "destination": "res://scenes/chapter/milk_harbor.tscn"},
	{"label": "Space", "key": KEY_SPACE, "action": "", "destination": "res://scenes/chapter/milk_harbor.tscn"},
	{"label": "Escape", "key": KEY_ESCAPE, "action": "", "destination": "res://scenes/chapter/workshop.tscn"},
	{"label": "direct crumb", "key": 0, "action": "crumb", "destination": "res://scenes/chapter/crumb_crossing.tscn"},
	{"label": "direct ballast", "key": 0, "action": "ballast", "destination": "res://scenes/chapter/blueberry_ballast.tscn"},
	{"label": "direct harbor", "key": 0, "action": "harbor", "destination": "res://scenes/chapter/milk_harbor.tscn"},
	{"label": "direct demo", "key": 0, "action": "demo", "destination": "res://scenes/main.tscn"}
]
var output_dir := "res://evidence/platform_refinement/workshop_mobile_026_source"
var profile_path: String
var settings_path: String
var demo_path: String
var pack_path := ""
var hub: Node3D
var context := "setup"
var checks: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var observations: Array[Dictionary] = []
var failures := 0
var original_inputs: Dictionary = {}
var original_buses: AudioBusLayout


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless" or not "--touch-ui" in OS.get_cmdline_user_args():
		print("Workshop mobile audit needs a native renderer and -- --touch-ui.")
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output_dir = arg.trim_prefix("--evidence-dir=")
		if arg.begins_with("--audited-pack="): pack_path = arg.trim_prefix("--audited-pack=")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK:
		quit(2)
		return
	original_buses = AudioServer.generate_bus_layout()
	for action in InputMap.get_actions():
		original_inputs[action] = {"deadzone": InputMap.action_get_deadzone(action), "events": InputMap.action_get_events(action)}
	var suffix := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	profile_path = "user://workshop_mobile_" + suffix + ".json"
	settings_path = "user://workshop_mobile_" + suffix + ".cfg"
	demo_path = "user://workshop_mobile_demo_" + suffix + ".json"
	for scale: float in [1.0, 1.25]:
		for resolution: Vector2i in WINDOWS:
			await _audit_landscape(resolution, scale, "saved")
	await _audit_landscape(Vector2i(844, 390), 1.25, "fresh")
	await _audit_landscape(Vector2i(1024, 768), 1.25, "cleared")
	await _audit_portrait()
	await _audit_navigation_guards()
	context = "cleanup"
	_cleanup_files()
	_check(not FileAccess.file_exists(profile_path) and not FileAccess.file_exists(settings_path) and not FileAccess.file_exists(demo_path), "Disposable saves/settings removed")
	for action in InputMap.get_actions(): InputMap.erase_action(action)
	for action in original_inputs:
		InputMap.add_action(action, original_inputs[action].deadzone)
		for event: InputEvent in original_inputs[action].events: InputMap.action_add_event(action, event)
	AudioServer.set_bus_layout(original_buses)
	var source_hashes: Dictionary = {}
	for path: String in ["res://scripts/chapter/workshop.gd", "res://scripts/hud.gd", "res://scripts/main.gd", "res://scripts/platform/design_tokens.gd"]:
		source_hashes[path] = FileAccess.get_sha256(path)
	var report := {"result": "PASS" if failures == 0 else "FAIL", "assertions": checks.size(), "failures": failures,
		"kind": "Native macOS Workshop tablet/phone viewport simulation with isolated profile fixtures; execution host and content scope recorded separately",
		"execution": _execution_metadata(),
		"application_version": ProjectSettings.get_setting("application/config/version"), "pack_path": pack_path,
		"pack_sha256": FileAccess.get_sha256(pack_path) if pack_path != "" else "",
		"loaded_source_sha256": source_hashes, "engine": Engine.get_version_info().string,
		"display_driver": DisplayServer.get_name(), "renderer": RenderingServer.get_video_adapter_name(),
		"profiles": "Unique disposable chapter/demo/settings paths assigned before readiness and removed; real saves untouched",
		"limitations": ["Not physical mobile or iOS Simulator evidence", "Safe insets are explicit logical fixtures; rendered pixels are not iOS points", "Saved/cleared prerequisites are authored profile fixtures, not earned gameplay", "Top/bottom and control-reach scrolling is programmatic; keyboard portrait probe uses injected InputEventKey", "Muted/reduced-motion settings isolate layout; no motion, subjective audio, performance or human aesthetic approval"],
		"captures": captures, "checks": checks, "observations": observations}
	var file := FileAccess.open(output_dir.path_join("capture_report.json"), FileAccess.WRITE)
	if file == null:
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("WORKSHOP MOBILE: %s / %d checks / %d failures / %d captures" % [report.result, checks.size(), failures, captures.size()])
	quit(0 if failures == 0 else 1)


func _audit_landscape(resolution: Vector2i, scale: float, fixture: String) -> void:
	context = "%dx%d_text%s_%s" % [resolution.x, resolution.y, str(scale).replace(".", "_"), fixture]
	_seed_fixture(fixture, scale)
	var previous_profile := FileAccess.get_sha256(profile_path) if FileAccess.file_exists(profile_path) else "absent"
	root.size = resolution
	hub = _spawn_hub()
	await _settle()
	_validate_menu(scale, fixture)
	for child in hub.hud.menu_box.get_children():
		if child is Button:
			hub.hud.menu_scroll.ensure_control_visible(child)
			await process_frame
			await process_frame
			_check(hub.hud.menu_scroll.get_global_rect().grow(1).encloses(child.get_global_rect()), "Each button can be fully exposed by scrolling: " + child.name)
	hub.hud.menu_scroll.scroll_vertical = 0
	await _settle()
	_check(hub.hud.menu_scroll.get_global_rect().grow(1).encloses(hub.hud.menu_box.get_child(0).get_global_rect()), "Top scroll exposes the heading")
	await _capture(context + "_top", resolution, fixture)
	hub.hud.menu_scroll.scroll_vertical = 100000
	await _settle()
	var last: Control = hub.hud.menu_box.get_child(hub.hud.menu_box.get_child_count() - 1)
	_check(hub.hud.menu_scroll.get_global_rect().grow(1).encloses(last.get_global_rect()), "Bottom scroll exposes the final explanatory label")
	await _capture(context + "_bottom", resolution, fixture)
	var current_profile := FileAccess.get_sha256(profile_path) if FileAccess.file_exists(profile_path) else "absent"
	_check(previous_profile == current_profile and not FileAccess.file_exists(demo_path), "Browsing and scrolling do not mutate progress or create demo saves")
	await _dispose_scene()


func _seed_fixture(fixture: String, scale: float) -> void:
	_cleanup_files()
	var config := ConfigFile.new()
	config.set_value("comfort", "text_scale", scale)
	config.set_value("comfort", "reduced_motion", true)
	config.set_value("sound", "music", 0.0)
	config.set_value("sound", "effects", 0.0)
	_check(config.save(settings_path) == OK, "Isolated silent settings saved")
	if fixture == "fresh": return
	var profile = Progress.new()
	profile.save_path = profile_path
	_check(profile.complete_stage("W01S01") and profile.complete_stage("W01S02"), "Two predecessor completions explicitly seeded")
	if fixture == "cleared":
		_check(profile.complete_stage("W01S03"), "Only the three implemented stages marked cleared in this visual fixture")
	else:
		_check(profile.save_stage("W01S03", HarborRules.new().to_dict()), "Canonical saved Harbor fixture creates Continue label")


func _spawn_hub() -> Node3D:
	var scene: Node3D = Workshop.instantiate()
	scene.chapter_profile_path = profile_path
	scene.settings_path = settings_path
	scene.save_path = demo_path
	root.add_child(scene)
	current_scene = scene
	scene.hud.safe_insets_override = INSETS
	scene.hud._queue_layout()
	return scene


func _validate_menu(scale: float, fixture: String) -> void:
	var hud = hub.hud
	var expected := Rect2(Vector2(INSETS.x, INSETS.y), root.get_visible_rect().size - Vector2(INSETS.x + INSETS.z, INSETS.y + INSETS.w))
	_check(hub.chapter_profile.save_path == profile_path and hub.settings_path == settings_path and hub.save_path == demo_path, "All isolated storage paths reach scene before readiness")
	_check(hub.text_scale == scale and hub.reduced_motion and hub.music_volume == 0 and hub.effects_volume == 0, "Saved text and quiet settings loaded")
	_check(hud.touch_mode and hud.menu_scroll != null and hud.overlay.visible, "Production touch menu is active")
	_check(hud.text_scale == scale, "Shared HUD receives the saved text scale")
	var heading: Label
	for child in hud.menu_box.get_children():
		if child is Label and child.text == "Matchbox Workshop": heading = child
	_check(heading != null, "Workshop heading exists")
	if heading != null:
		_check(float(heading.get_meta("touch_font_base", -1)) == 30.0, "Heading retains its unscaled30-unit base")
		_check(heading.get_theme_font_size("font_size") == int(30 * scale), "Heading scales exactly once:30 at1.0 and37 at1.25")
	_check(not hud.rotation_guard.visible and not hud.touch_controls.enabled, "Landscape Workshop is a menu without gameplay touch controls")
	_check(hud.safe_rect.is_equal_approx(expected) and expected.encloses(hud.menu_scroll.get_global_rect()), "Menu scroll viewport stays inside asymmetric safe rectangle")
	var panel: Rect2 = hud.menu.get_global_rect()
	var scroll: Rect2 = hud.menu_scroll.get_global_rect()
	_check(panel.position.x >= scroll.position.x - 1 and panel.end.x <= scroll.end.x + 1, "Menu panel width fits scroll viewport without horizontal clipping")
	_check(not hud.top_card.visible and not hud.target_card.visible and not hud.message.visible and not hud.pause_button.visible, "Gameplay cards stay hidden in Workshop")
	var prior_bottom := -INF
	for child in hud.menu_box.get_children():
		if not child is Control: continue
		var rect: Rect2 = child.get_global_rect()
		_check(panel.grow(1).encloses(rect), "Menu child fits content panel: " + child.name)
		_check(rect.position.y >= prior_bottom - 1, "Menu rows do not overlap: " + child.name)
		prior_bottom = rect.end.y
		if child is Button or child is Label:
			_check(child.get_theme_font_size("font_size") >= int(24 * scale), "Text honors scaled minimum24: " + child.name)
		if child is Button:
			_check(child.size.x >= 88 and child.size.y >= 88, "Menu target is at least88 logical units: " + child.name)
			var pixel_size: Vector2 = _pixel_size(child, child.size)
			_check(pixel_size.x >= 44 and pixel_size.y >= 44, "Menu target renders at least44 pixels: " + child.name)
			var style: StyleBox = child.get_theme_stylebox("disabled" if child.disabled else "normal")
			var available: float = child.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
			var ink_width: float = child.get_theme_font("font").get_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, child.get_theme_font_size("font_size")).x
			_check(ink_width <= available + 1, "Full button label fits without truncation: " + child.name)
	_check(hub.stage_button.text.begins_with("Play" if fixture == "fresh" else "Replay"), "Crumb action reflects profile fixture")
	_check(hub.harbor_button.text.begins_with("Milk Harbor · Locked" if fixture == "fresh" else ("Replay" if fixture == "cleared" else "Continue")), "Harbor action reflects profile fixture")
	_check(hub.future_buttons.size() == 2 and hub.future_buttons[0].disabled and hub.future_buttons[1].disabled, "Both unbuilt stages remain unavailable")
	var pip_bounds := _projected_bounds(hub.pip_art)
	var visible_panel: Rect2 = panel.intersection(scroll)
	_check(root.get_visible_rect().encloses(pip_bounds), "Full Pip mesh bounds remain in landscape viewport")
	_check(not pip_bounds.intersects(visible_panel), "Full Pip mesh bounds remain clear of visible menu")


func _audit_portrait() -> void:
	for scale: float in [1.0, 1.25]:
		context = "390x844_text%s_portrait" % str(scale).replace(".", "_")
		_seed_fixture("saved", scale)
		root.size = Vector2i(390, 844)
		hub = _spawn_hub()
		await _settle()
		_check(hub.hud.rotation_guard.visible and not hub.hud.touch_controls.enabled, "Portrait shows rotation guidance and disables gameplay touch controls")
		for node in hub.hud.rotation_guard.find_children("*", "Label", true, false):
			_check(root.get_visible_rect().encloses(node.get_global_rect()), "Portrait guidance label fits logical viewport")
		await _capture(context, Vector2i(390, 844), "saved")
		root.size = Vector2i(844, 390)
		await _settle()
		_check(not hub.hud.rotation_guard.visible and current_scene == hub and hub.hud.overlay.visible, "Rotation back restores same Workshop menu without navigation")
		await _capture(context + "_recovered", Vector2i(844, 390), "saved")
		await _dispose_scene()


func _audit_navigation_guards() -> void:
	# Each probe gets an independent enabled-stage fixture, so a failed navigation
	# cannot invalidate later probes or mistake a locked stage for portrait safety.
	for probe: Dictionary in NAVIGATION_PROBES:
		context = "portrait/recovery navigation: " + probe.label
		_seed_fixture("saved", 1.25)
		root.size = Vector2i(390, 844)
		hub = _spawn_hub()
		await _settle()
		_check(hub.hud.rotation_guard.visible and not hub.stage_button.disabled and not hub.ballast_button.disabled and not hub.harbor_button.disabled, "Portrait probe starts with all three stage destinations unlocked")
		var old_id: int = hub.get_instance_id()
		var before_profile := FileAccess.get_sha256(profile_path)
		await _invoke_navigation_probe(probe)
		await create_timer(0.35).timeout
		var stayed: bool = is_instance_valid(hub) and is_instance_valid(current_scene) and current_scene.get_instance_id() == old_id
		if stayed: stayed = not hub.transitioning and hub.hud.rotation_guard.visible
		_check(stayed, "Portrait rejects " + probe.label + " without starting a transition")
		_check(FileAccess.get_sha256(profile_path) == before_profile and not FileAccess.file_exists(demo_path), "Rejected portrait command preserves chapter and demo progress")
		observations.append({"context": context, "phase": "portrait", "scene": current_scene.scene_file_path if is_instance_valid(current_scene) else "none", "stayed_in_workshop": stayed})
		if not stayed:
			await _dispose_scene()
			continue
		root.size = Vector2i(844, 390)
		await _settle()
		_check(not hub.hud.rotation_guard.visible and current_scene.get_instance_id() == old_id, "Landscape recovery exposes the same Workshop before " + probe.label)
		await _invoke_navigation_probe(probe)
		if probe.key == KEY_ESCAPE:
			await _settle()
			_check(current_scene.get_instance_id() == old_id and hub.hud.menu_mode == "workshop_settings", "Recovered landscape Escape opens settings in the existing Workshop")
			_check(FileAccess.get_sha256(profile_path) == before_profile and not FileAccess.file_exists(demo_path), "Opening pre-play settings preserves both progress profiles")
			await _dispose_scene()
			continue
		var deadline: int = Time.get_ticks_msec() + 3000
		while is_instance_valid(current_scene) and current_scene.get_instance_id() == old_id and Time.get_ticks_msec() < deadline:
			await process_frame
		await process_frame
		var switched: bool = is_instance_valid(current_scene) and current_scene.get_instance_id() != old_id
		_check(switched and current_scene.scene_file_path == probe.destination, "Recovered landscape " + probe.label + " reaches its actual destination")
		if switched:
			_check(current_scene.chapter_profile_path == profile_path and current_scene.settings_path == settings_path and current_scene.save_path == demo_path, "Recovered navigation retains all isolated storage paths")
			_check(current_scene.text_scale == 1.25, "Recovered destination loads the saved max-text preference")
		observations.append({"context": context, "phase": "landscape", "scene": current_scene.scene_file_path if is_instance_valid(current_scene) else "none", "expected_scene": probe.destination, "switched": switched})
		await _dispose_scene()


func _invoke_navigation_probe(probe: Dictionary) -> void:
	if probe.key == 0:
		hub.on_command(probe.action, null)
		return
	var event := InputEventKey.new()
	event.physical_keycode = probe.key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = probe.key
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _execution_metadata() -> Dictionary:
	# Official4.5 APIs: https://docs.godotengine.org/en/4.5/classes/class_os.html
	# Build tags: https://docs.godotengine.org/en/4.5/tutorials/export/feature_tags.html
	var executable := OS.get_executable_path()
	var editor_build := OS.has_feature("editor")
	var template_build := OS.has_feature("template")
	var host := "editor build" if editor_build else ("export-template build" if template_build else "unclassified build")
	var script: Script = get_script()
	return {"executable": executable, "executable_sha256": FileAccess.get_sha256(executable),
		"host_kind": host, "editor_build": editor_build, "export_template_build": template_build,
		"editor_hint": Engine.is_editor_hint(), "process_id": OS.get_process_id(),
		"engine_reported_arguments": OS.get_cmdline_args(), "user_arguments": OS.get_cmdline_user_args(),
		"project_resource_root": ProjectSettings.globalize_path("res://"),
		"harness_path": script.resource_path, "harness_sha256": FileAccess.get_sha256(script.resource_path),
		"declared_audited_pack": pack_path, "declared_pack_sha256": FileAccess.get_sha256(pack_path) if pack_path != "" else "",
		"content_scope": "Caller-declared exported PCK; verify launcher --main-pack and loaded source hashes" if pack_path != "" else "Project source; no exported PCK declared",
		"note": "Executable identity and build tags are runtime observations. Engine-reported arguments are not a shell command or redirection record. --audited-pack is explicit provenance, not proof that the pack was loaded. An editor host is not the distributed application executable."}


func _projected_bounds(node: Node) -> Rect2:
	var points: Array[Vector2] = []
	_collect_points(node, points)
	if points.is_empty(): return Rect2()
	var result := Rect2(points[0], Vector2.ZERO)
	for point in points: result = result.expand(point)
	return result


func _collect_points(node: Node, points: Array[Vector2]) -> void:
	if node is MeshInstance3D and node.visible and node.mesh != null:
		var box: AABB = node.get_aabb()
		for index in 8:
			var corner := box.position + box.size * Vector3(index & 1, (index >> 1) & 1, (index >> 2) & 1)
			points.append(hub.camera.unproject_position(node.global_transform * corner))
	for child in node.get_children(): _collect_points(child, points)


func _capture(name: String, requested: Vector2i, fixture: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var delta := frame.get_size() - requested
	_check(delta.x >= -1 and delta.x <= 0 and delta.y >= -1 and delta.y <= 0, "Native frame matches request within macOS one-pixel rounding")
	var path := output_dir.path_join(name + ".png")
	_check(frame.save_png(path) == OK, "Native frame saved")
	var rows: Array[Dictionary] = []
	for child in hub.hud.menu_box.get_children():
		if child is Button or child is Label:
			rows.append({"name": child.name, "text": child.text, "font_size": child.get_theme_font_size("font_size"), "rect": _rect(child.get_global_rect()), "disabled": child.disabled if child is Button else false})
	captures.append({"path": path, "requested_pixels": [requested.x, requested.y], "pixels": [frame.get_width(), frame.get_height()], "text_scale": hub.text_scale, "hud_text_scale": hub.hud.text_scale,
		"fixture": fixture, "focused": DisplayServer.window_is_focused(), "logical_viewport": _rect(root.get_visible_rect()), "safe_rect": _rect(hub.hud.safe_rect),
		"menu_rect": _rect(hub.hud.menu.get_global_rect()), "scroll_rect": _rect(hub.hud.menu_scroll.get_global_rect()), "scroll_vertical": hub.hud.menu_scroll.scroll_vertical,
		"pip_projected_aabb": _rect(_projected_bounds(hub.pip_art)), "drawer_projected_aabb": _rect(_projected_bounds(hub.get_node("OpenMatchbox/OpenDrawer"))),
		"rotation_guard": hub.hud.rotation_guard.visible, "rows": rows})


func _pixel_size(control: Control, logical: Vector2) -> Vector2:
	var transform: Transform2D = root.get_final_transform() * control.get_global_transform_with_canvas()
	return Vector2(transform.basis_xform(Vector2(logical.x, 0)).length(), transform.basis_xform(Vector2(0, logical.y)).length())


func _rect(value: Rect2) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]


func _settle() -> void:
	await create_timer(0.22).timeout
	await process_frame
	await process_frame


func _dispose_scene() -> void:
	if is_instance_valid(current_scene):
		if current_scene.has_method("stop_audio"): await current_scene.stop_audio()
		current_scene.queue_free()
	await process_frame
	await process_frame


func _cleanup_files() -> void:
	for path: String in [profile_path, settings_path, demo_path]:
		if path == "": continue
		for extension: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + extension): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + extension))


func _check(passed: bool, message: String) -> void:
	checks.append({"passed": passed, "context": context, "message": message})
	if not passed:
		failures += 1
		push_error(context + ": " + message)
