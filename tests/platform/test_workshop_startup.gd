extends SceneTree
## Shipped first-visit and pre-play settings, with disposable progress paths.
var output := ""
var folder := ""
var checks: Array[Dictionary] = []
var failures := 0
var hub: Node
var touch := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks.append({"ok": ok, "description": description})
	if not ok:
		failures += 1
		push_error(description)

func settle() -> void:
	await create_timer(0.25).timeout

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	hub._unhandled_input(event)
	await settle()

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "Saved native view: " + name)

func bounds() -> void:
	var panel: Rect2 = hub.hud.menu.get_global_rect()
	var viewport: Rect2 = root.get_visible_rect()
	print("MENU ", hub.hud.menu_mode, " panel ", panel, " panel_min ", hub.hud.menu.get_combined_minimum_size(), " box ", hub.hud.menu_box.get_rect(), " box_min ", hub.hud.menu_box.get_combined_minimum_size())
	if touch:
		check(viewport.encloses(hub.hud.menu_scroll.get_global_rect()), "Touch settings scroll fits viewport")
		check(panel.size.x <= hub.hud.menu_scroll.size.x, "Touch settings have no horizontal clipping")
	else:
		check(viewport.encloses(panel), "Desktop menu fits at " + hub.hud.menu_mode)
	for child in hub.hud.menu_box.find_children("*", "Control", true, false):
		check(panel.grow(1).encloses(child.get_global_rect()), "Contained menu control: " + child.name)

func spawn_hub() -> void:
	hub = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	hub.chapter_profile_path = folder.path_join("chapter.json")
	hub.settings_path = folder.path_join("settings.cfg")
	hub.save_path = folder.path_join("demo.json")
	root.add_child(hub)
	current_scene = hub
	await settle()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output = arg.trim_prefix("--evidence-dir=")
	touch = "--touch-ui" in OS.get_cmdline_user_args()
	if output == "" or FileAccess.file_exists(output.path_join("startup-report.json")):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	folder = OS.get_cache_dir().path_join("tiny-startup-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(844, 390) if touch else Vector2i(1280, 720)
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/chapter/workshop.tscn", "Actual application opens the Workshop")
	await spawn_hub()
	check(hub.stage_button.has_focus() and hub.next_stage_action() == "crumb", "Fresh start focuses Crumb Crossing")
	bounds()
	await capture("fresh")
	hub.hud.menu_box.get_node("WorkshopSettingsButton").pressed.emit()
	await settle()
	check(hub.hud.menu_mode == "workshop_settings" and not hub.started, "Settings open before any gameplay")
	var toggle: CheckButton = hub.hud.menu_box.find_children("*", "CheckButton", true, false)[0]
	toggle.button_pressed = true
	var sliders: Array[Node] = hub.hud.menu_box.find_children("*", "HSlider", true, false)
	sliders[0].value = 0.0
	sliders[1].value = 0.25
	sliders[2].value = 1.25
	await settle()
	check(hub.reduced_motion and hub.music_volume == 0.0 and hub.effects_volume == 0.25 and hub.text_scale == 1.25, "Actual settings widgets update all four preferences")
	var config := ConfigFile.new()
	check(config.load(hub.settings_path) == OK and config.get_value("comfort", "text_scale") == 1.25 and config.get_value("sound", "music") == 0.0, "Pre-play preferences persist to the isolated ConfigFile")
	bounds()
	await capture("settings-large")
	hub.on_command("controls", null)
	await settle()
	hub.on_command("rebind", "jump")
	check(hub.hud.controls_notice.text.contains("Press a key"), "Remapping prompt is visible inside its menu")
	await key(KEY_1)
	check(hub.pending_rebind == "jump" and hub.hud.controls_notice.text.contains("quick size keys"), "Reserved key refusal is visible and preserves remapping")
	await key(KEY_J)
	check(hub.pending_rebind == "" and hub.binding_names().jump == "J", "An unused key is saved through the actual input handler")
	bounds()
	await capture("controls")
	await key(KEY_ESCAPE)
	check(hub.hud.menu_mode == "workshop_settings", "Escape from controls returns to settings")
	await key(KEY_ESCAPE)
	check(hub.hud.menu_mode == "workshop", "Escape from settings returns to Workshop")
	bounds()
	await capture("workshop-large")
	check(not FileAccess.file_exists(hub.chapter_profile_path) and not FileAccess.file_exists(hub.save_path), "Browsing and preferences create no chapter or demo progress")
	var profile = hub.chapter_profile
	check(profile.complete_stage("W01S01"), "Fixture earns first-stage prerequisite")
	hub.show_workshop_menu()
	await settle()
	check(hub.ballast_button.has_focus() and hub.next_stage_action() == "ballast", "First completion focuses the next unfinished stage")
	check(profile.complete_stage("W01S02"), "Fixture earns second-stage prerequisite")
	var Harbor = load("res://scripts/chapter/harbor_state.gd")
	check(profile.save_stage("W01S03", Harbor.new().to_dict()), "Fixture retains a real canonical Harbor snapshot")
	var saved := FileAccess.get_file_as_string(hub.chapter_profile_path)
	await hub.stop_audio()
	hub.queue_free()
	await process_frame
	await spawn_hub()
	check(hub.harbor_button.has_focus() and hub.harbor_button.text.begins_with("Continue"), "Relaunch focuses Continue for saved Harbor")
	check(hub.binding_names().jump == "J" and hub.reduced_motion and hub.text_scale == 1.25, "Relaunch restores settings and key remap before readiness")
	check(saved == FileAccess.get_file_as_string(hub.chapter_profile_path), "Workshop relaunch leaves chapter progress byte-identical")
	bounds()
	await capture("saved-harbor")
	if touch:
		root.size = Vector2i(390, 844)
		await settle()
		hub.on_command("settings", null)
		check(hub.hud.rotation_guard.visible and hub.hud.menu_mode == "workshop", "Portrait prevents hidden settings/navigation actions")
		root.size = Vector2i(844, 390)
		await settle()
	await key(KEY_ENTER)
	check(current_scene != hub and current_scene.scene_file_path.ends_with("milk_harbor.tscn"), "Unconsumed Enter continues the next unfinished Harbor stage")
	var stage = current_scene
	check(stage.chapter_profile_path == folder.path_join("chapter.json") and stage.settings_path == folder.path_join("settings.cfg") and stage.save_path == folder.path_join("demo.json"), "Scene switch preserves all isolated storage paths")
	check(stage.binding_names().jump == "J" and stage.text_scale == 1.25, "The destination applies the pre-play preferences")
	await stage.stop_audio()
	stage.queue_free()
	await process_frame
	for name in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	var report := {"result": "PASS" if failures == 0 else "FAIL", "checks": checks, "failures": failures, "touch": touch, "version": ProjectSettings.get_setting("application/config/version"), "executable": OS.get_executable_path(), "scope": "Native Mac viewport and generated controls; isolated fresh, saved and transition fixtures. No human or physical mobile input claim."}
	var file := FileAccess.open(output.path_join("startup-report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("STARTUP: %s / %d checks / %d failures" % [report.result, checks.size(), failures])
	quit(0 if failures == 0 else 1)
