extends "res://scripts/main.gd"
## Shared chapter lifecycle for authored stages. Physical rules/worlds remain
## stage-owned; profiles and menu transitions use the established chapter API.
const ChapterProgress = preload("res://scripts/chapter/chapter_progress.gd")
var chapter_profile = ChapterProgress.new()
var stage_info: Dictionary
var last_save_ok := true
var changing_scene := false

func stage_definition() -> Dictionary:
	return {}

func create_stage_rules() -> RefCounted:
	return null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	stage_info = stage_definition()
	state = create_stage_rules()
	if chapter_profile_path != "": chapter_profile.save_path = chapter_profile_path
	if capture_dir == "":
		capture_dir = ProjectSettings.globalize_path("res://evidence/" + stage_info.slug if OS.has_feature("editor") else "user://captures/" + stage_info.slug)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): capture_dir = arg.trim_prefix("--evidence-dir=")
	configure_inputs()
	load_settings()
	load_save()
	build_world()
	build_audio()
	hud = HUD.new()
	hud.interaction_label = stage_info.get("interaction_label", "Carry / Place")
	add_child(hud)
	hud.command.connect(on_command)
	hud.set_bindings(binding_names())
	apply_text_size()
	sync_props(false)
	respawn()
	show_stage_title()

func save_game() -> void:
	last_save_ok = chapter_profile.complete_stage_with_snapshot(stage_info.id, state.to_dict()) if state.completed else chapter_profile.save_stage(stage_info.id, state.to_dict())
	ever_completed = chapter_profile.is_completed(stage_info.id)
	if not last_save_ok and is_instance_valid(hud):
		hud.toast("Your puzzle is safe for this visit, but it could not be saved.", 6)

func load_save() -> void:
	chapter_profile.load_profile()
	var snapshot = chapter_profile.stage_snapshot(stage_info.id)
	has_save = not snapshot.is_empty() and state.restore(snapshot)
	ever_completed = chapter_profile.is_completed(stage_info.id)
	if not snapshot.is_empty() and not has_save:
		save_notice = "That stage save needs a fresh start. Your earned chapter progress is safe."

func show_stage_title() -> void:
	hud.clear_menu("title")
	hud.menu_label(stage_info.kicker, 12, HUD.TEAL)
	hud.menu_label(stage_info.title, 38)
	hud.menu_label(stage_info.description, 18)
	hud.menu_box.add_child(hud.button("Continue adventure" if has_save else "Take a little step   →", func(): on_command("start", null)))
	if has_save: hud.menu_box.add_child(hud.button("Start this stage again", func(): on_command("new", null)))
	hud.menu_box.add_child(hud.button("Matchbox Workshop", func(): on_command("workshop", null)))
	update_objective()
	update_target()

func show_stage_complete() -> void:
	hud.clear_menu("complete")
	hud.menu_label(stage_info.complete_kicker, 12, HUD.TEAL)
	hud.menu_label(stage_info.title + "\ncomplete!", 34)
	hud.menu_label(stage_info.complete_text, 18)
	if not last_save_ok: hud.menu_label("Progress could not be saved yet. Returning to the workshop retries.", 15)
	hud.menu_box.add_child(hud.button("Back to the workshop", func(): on_command("workshop", null)))
	hud.menu_box.add_child(hud.button("Keep exploring", func(): on_command("explore", null)))
	hud.menu_box.add_child(hud.button("Play this stage again", func(): on_command("new", null)))

func on_command(action: String, value: Variant) -> void:
	match action:
		"start":
			started = true
			paused = false
			hud.hide_menu()
			if state.completed:
				show_stage_complete()
				paused = true
			else:
				hud.toast(save_notice if save_notice != "" else stage_info.opening, 5)
		"new":
			state = create_stage_rules()
			exploring = false
			hint_step = 0
			celebration_time = 0
			sync_props(false)
			respawn()
			save_game()
			on_command("start", null)
		"title":
			save_game()
			super.on_command("resume", null)
			started = false
			has_save = true
			show_stage_title()
		"workshop":
			if changing_scene: return
			changing_scene = true
			save_game()
			await stop_audio()
			var navigation = load("res://scripts/chapter/chapter_navigation.gd")
			if navigation.switch_scene(self, "res://scenes/chapter/workshop.tscn", chapter_profile.save_path, settings_path) == null:
				changing_scene = false
				build_audio()
				hud.toast("The workshop could not open. Your current puzzle is still here.", 5)
		"explore":
			exploring = true
			state.reset_checkpoint()
			sync_props(false)
			respawn()
			super.on_command("resume", null)
		_:
			if action == "reset": hint_step = 0
			super.on_command(action, value)
