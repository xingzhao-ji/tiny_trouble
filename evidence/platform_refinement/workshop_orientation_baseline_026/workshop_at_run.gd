extends "res://scripts/main.gd"
## A small chapter menu in Pip's open matchbox. The demo only supplies shared
## settings, input, audio, and toy-art helpers; no demo puzzle runs in this hub.

const Progress = preload("res://scripts/chapter/chapter_progress.gd")
const Navigation = preload("res://scripts/chapter/chapter_navigation.gd")
const CRUMB_SCENE := "res://scenes/chapter/crumb_crossing.tscn"
const BALLAST_SCENE := "res://scenes/chapter/blueberry_ballast.tscn"
const HARBOR_SCENE := "res://scenes/chapter/milk_harbor.tscn"
const DEMO_SCENE := "res://scenes/main.tscn"
const FUTURE_STAGES = ["The Jam Detour", "Toast Express"]
var chapter_profile = Progress.new()
var stage_button: Button
var ballast_button: Button
var harbor_button: Button
var future_buttons: Array[Button] = []
var profile_status: Label
var transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	configure_inputs()
	load_settings()
	if chapter_profile_path != "": chapter_profile.save_path = chapter_profile_path
	chapter_profile.load_profile()
	build_world()
	build_audio()
	hud = HUD.new()
	add_child(hud)
	hud.command.connect(on_command)
	hud.set_bindings(binding_names())
	apply_text_size()
	for child in hud.root.get_children():
		if child is CanvasItem and child != hud.overlay: child.hide()
	# Keep the open drawer visible on the left of this single, bounded menu.
	var center := hud.menu.get_parent() as CenterContainer
	center.anchor_left = 0.5
	center.offset_left = -12
	center.offset_right = -12
	hud.overlay.color = Color(0.13, 0.19, 0.20, 0.12)
	show_workshop_menu()


func build_world() -> void:
	add_child(Art.table())
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("d8c8ae")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("dddde0")
	environment.ambient_light_energy = 0.25
	world_environment.environment = environment
	add_child(world_environment)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-58, -28, 0)
	sunlight.light_color = Color("fff5e8")
	sunlight.light_energy = 0.62
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sunlight.directional_shadow_max_distance = 45
	sunlight.shadow_blur = 2.5
	add_child(sunlight)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 130, 0)
	fill.light_color = Color("b4d3d4")
	fill.light_energy = 0.13
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.5
	camera.position = Vector3(10, 14, 20)
	add_child(camera)
	camera.look_at(Vector3(0, 0.4, 0))
	camera.h_offset = 4.0
	camera.current = true
	build_matchbox()
	pip = Node3D.new()
	pip.name = "Pip"
	pip.position = Vector3(-1.35, 0.48, 2.15)
	pip.rotation.y = 0.38
	pip_art = Art.pip()
	pip.add_child(pip_art)
	add_child(pip)


func build_matchbox() -> void:
	var matchbox := Node3D.new()
	matchbox.name = "OpenMatchbox"
	add_child(matchbox)
	# The sleeve is a raised cardboard shell, with its opening facing the drawer.
	var sleeve := Node3D.new()
	sleeve.name = "Sleeve"
	matchbox.add_child(sleeve)
	Art._box(sleeve, Vector3(0, 0.17, -1.3), Vector3(6.9, 0.22, 3.6), Color("a75043"), 0.09)
	Art._box(sleeve, Vector3(0, 1.42, -1.3), Vector3(6.9, 0.22, 3.6), Art.CORAL, 0.09)
	for x in [-3.33, 3.33]:
		Art._box(sleeve, Vector3(x, 0.8, -1.3), Vector3(0.24, 1.24, 3.6), Color("b85b4a"), 0.075)
		Art._box(sleeve, Vector3(x + signf(x) * 0.125, 0.8, -1.3), Vector3(0.025, 0.64, 2.9), Color("795e51"), 0.008)
		for z in range(12):
			Art._box(sleeve, Vector3(x + signf(x) * 0.145, 0.8, -2.57 + z * 0.23), Vector3(0.022, 0.53, 0.022), Color("b68a68"), 0.005)
	# Label and inset border lie on the sleeve roof, not in screen space.
	Art._box(sleeve, Vector3(0, 1.543, -1.3), Vector3(4.85, 0.027, 2.42), Art.CREAM, 0.16)
	Art._box(sleeve, Vector3(0, 1.562, -1.3), Vector3(4.5, 0.014, 2.07), Art.TEAL, 0.13)
	Art._box(sleeve, Vector3(0, 1.574, -1.3), Vector3(4.37, 0.013, 1.94), Art.CREAM, 0.11)
	var sign_label := Label3D.new()
	sign_label.name = "WorkshopLabel"
	sign_label.text = "PIP'S\nWORKSHOP"
	sign_label.font = load("res://assets/fonts/Nunito.ttf")
	sign_label.font_size = 62
	sign_label.pixel_size = 0.009
	sign_label.modulate = Art.SLATE
	sign_label.outline_size = 0
	sign_label.position = Vector3(0, 1.59, -1.3)
	sign_label.rotation_degrees.x = -90
	sign_label.no_depth_test = false
	sleeve.add_child(sign_label)
	# The pulled-out tray has a floor and four thick rims; Pip stands inside it.
	var drawer := Node3D.new()
	drawer.name = "OpenDrawer"
	matchbox.add_child(drawer)
	Art._box(drawer, Vector3(0, 0.32, 1.13), Vector3(6.33, 0.31, 4.48), Color("cbb18b"), 0.1)
	Art._box(drawer, Vector3(0, 0.48, 1.13), Vector3(5.88, 0.035, 4.04), Color("ecddbd"), 0.02)
	for x in [-3.05, 3.05]:
		Art._box(drawer, Vector3(x, 0.68, 1.13), Vector3(0.22, 0.64, 4.48), Color("dcc5a0"), 0.06)
	for z in [-1.0, 3.26]:
		Art._box(drawer, Vector3(0, 0.68, z), Vector3(6.28, 0.64, 0.22), Color("dcc5a0"), 0.06)
	Art._box(drawer, Vector3(0, 0.68, 3.39), Vector3(1.35, 0.32, 0.12), Art.TEAL, 0.06)
	Art._torus(drawer, Vector3(0, 0.68, 3.55), 0.12, 0.19, Color("dca450")).rotation.x = PI / 2
	# A tiny cork workbench, a spool, and a rolled-paper route are authored props.
	var bench := Node3D.new()
	bench.name = "CorkWorkbench"
	bench.position = Vector3(1.5, 0.5, 1.3)
	drawer.add_child(bench)
	Art._box(bench, Vector3(0, 0.5, 0), Vector3(1.75, 0.19, 1.05), Color("b89164"), 0.085)
	for x in [-0.63, 0.63]:
		for z in [-0.33, 0.33]:
			Art._cyl(bench, Vector3(x, 0.23, z), 0.09, 0.45, Color("967452"))
	Art._cyl(bench, Vector3(0.47, 0.81, 0), 0.2, 0.4, Art.TEAL)
	for y in [0.62, 1.01]:
		Art._cyl(bench, Vector3(0.47, y, 0), 0.27, 0.055, Art.CREAM)
	var route := Art._box(bench, Vector3(-0.29, 0.612, 0.03), Vector3(0.69, 0.035, 0.65), Art.CREAM, 0.018)
	route.rotation.y = -0.23
	for z in [-0.15, 0.03, 0.21]:
		Art._line(bench, Vector3(-0.5, 0.64, z), Vector3(-0.13, 0.64, z - 0.06), 0.009, Art.CORAL)
	# A few hand-cut crumbs establish the scale without pretending to be stages.
	for entry in [Vector3(-2.3, 0.53, 1.25), Vector3(0.1, 0.53, 2.35), Vector3(2.35, 0.53, 2.4)]:
		Art._ball(drawer, entry, Vector3(0.2, 0.12, 0.16), Art.AMBER)


func show_workshop_menu() -> void:
	hud.clear_menu("workshop")
	hud.menu.add_theme_stylebox_override("panel", hud.box(HUD.CREAM, 25, 24))
	hud.menu_box.add_theme_constant_override("separation", 8)
	menu_text("Breakfast Chapter · Preview", 14, HUD.TEAL)
	menu_text("Matchbox Workshop", 30)
	menu_text("A little home between big adventures.", 15)
	var cleared: bool = chapter_profile.is_completed("W01S01")
	var saved: bool = not chapter_profile.stage_snapshot("W01S01").is_empty()
	var verb := "Replay" if cleared else ("Continue" if saved else "Play")
	stage_button = hud.button(verb + " Crumb Crossing   →", func(): on_command("crumb", null))
	stage_button.name = "CrumbCrossingButton"
	stage_button.custom_minimum_size.y = 45
	stage_button.add_theme_font_size_override("font_size", int(18 * text_scale))
	hud.menu_box.add_child(stage_button)
	var status := "Cleared · Ready for another visit" if cleared else ("Saved run available" if saved else "Stage 1 of 5 · Ready to play")
	if chapter_profile.recovered_from_backup: status += "\nProgress recovered from backup."
	elif chapter_profile.last_error != "": status = "Saved progress could not be read. Your files are preserved."
	profile_status = menu_text(status, 13, Color("705e4b"))
	var ballast_unlocked: bool = chapter_profile.is_completed("W01S01")
	var ballast_cleared: bool = chapter_profile.is_completed("W01S02")
	var ballast_saved: bool = not chapter_profile.stage_snapshot("W01S02").is_empty()
	var ballast_verb := "Replay" if ballast_cleared else ("Continue" if ballast_saved else "Play")
	ballast_button = hud.button(ballast_verb + " Blueberry Ballast   →" if ballast_unlocked else "Blueberry Ballast · Locked", func(): on_command("ballast", null))
	ballast_button.name = "BlueberryBallastButton"
	ballast_button.custom_minimum_size.y = 43
	ballast_button.add_theme_font_size_override("font_size", int(17 * text_scale))
	ballast_button.add_theme_color_override("font_disabled_color", Color("756e60"))
	ballast_button.add_theme_stylebox_override("disabled", hud.box(Color("eee5d3"), 12, 12))
	ballast_button.disabled = not ballast_unlocked
	hud.menu_box.add_child(ballast_button)
	var ballast_status := "Clear Crumb Crossing to unlock."
	if ballast_unlocked:
		ballast_status = "Cleared · Ready for another visit" if ballast_cleared else ("Saved run available" if ballast_saved else "Stage 2 of 5 · Ready to play")
	menu_text(ballast_status, 12, Color("705e4b"))
	var harbor_unlocked: bool = chapter_profile.is_completed("W01S02")
	var harbor_cleared: bool = chapter_profile.is_completed("W01S03")
	var harbor_saved: bool = not chapter_profile.stage_snapshot("W01S03").is_empty()
	var harbor_verb := "Replay" if harbor_cleared else ("Continue" if harbor_saved else "Play")
	harbor_button = hud.button(harbor_verb + " Milk Harbor   →" if harbor_unlocked else "Milk Harbor · Locked", func(): on_command("harbor", null))
	harbor_button.name = "MilkHarborButton"
	harbor_button.custom_minimum_size.y = 43
	harbor_button.add_theme_font_size_override("font_size", int(17 * text_scale))
	harbor_button.add_theme_color_override("font_disabled_color", Color("756e60"))
	harbor_button.add_theme_stylebox_override("disabled", hud.box(Color("eee5d3"), 12, 12))
	harbor_button.disabled = not harbor_unlocked
	hud.menu_box.add_child(harbor_button)
	var harbor_status := "Clear Blueberry Ballast to unlock."
	if harbor_unlocked:
		harbor_status = "Cleared · Ready for another visit" if harbor_cleared else ("Saved run available" if harbor_saved else "Stage 3 of 5 · Ready to play")
	menu_text(harbor_status, 12, Color("705e4b"))
	menu_text("STILL BEING BUILT", 12, HUD.TEAL)
	future_buttons.clear()
	for index in FUTURE_STAGES.size():
		var unavailable := Button.new()
		unavailable.name = "UnavailableStage%d" % (index + 4)
		unavailable.text = "%02d  %s · Unavailable" % [index + 4, FUTURE_STAGES[index]]
		unavailable.disabled = true
		unavailable.focus_mode = Control.FOCUS_NONE
		unavailable.custom_minimum_size.y = 33
		unavailable.add_theme_font_size_override("font_size", int(14 * text_scale))
		unavailable.add_theme_color_override("font_disabled_color", Color("756e60"))
		unavailable.add_theme_stylebox_override("disabled", hud.box(Color("eee5d3"), 9, 7))
		hud.menu_box.add_child(unavailable)
		future_buttons.append(unavailable)
	var demo_button := hud.button("Original Toast Express demo", func(): on_command("demo", null))
	demo_button.name = "OriginalDemoButton"
	demo_button.custom_minimum_size.y = 41
	demo_button.add_theme_font_size_override("font_size", int(15 * text_scale))
	hud.menu_box.add_child(demo_button)
	menu_text("The original demo keeps its own progress.", 12, Color("705e4b"))


func menu_text(value: String, font_size: int, color: Color = HUD.INK) -> Label:
	var text := hud.label(value, int(font_size * text_scale), color)
	# Touch layout applies the saved scale once, from the authored font size.
	text.set_meta("touch_font_base", maxi(HUD.Design.TYPE_TOUCH_BODY_MIN, font_size))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 400
	hud.menu_box.add_child(text)
	return text


func _process(delta: float) -> void:
	if transitioning or reduced_motion: return
	t += delta
	animate_pip(delta)


func _unhandled_input(event: InputEvent) -> void:
	if transitioning or hud.rotation_guard.visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			on_command("demo", null)
		elif event.physical_keycode in [KEY_ENTER, KEY_SPACE]:
			on_command("crumb", null)


func on_command(action: String, _value: Variant) -> void:
	if transitioning or action not in ["crumb", "ballast", "harbor", "demo"]: return
	if hud.rotation_guard.visible: return
	if action == "ballast" and not chapter_profile.is_completed("W01S01"): return
	if action == "harbor" and not chapter_profile.is_completed("W01S02"): return
	transitioning = true
	stage_button.disabled = true
	ballast_button.disabled = true
	harbor_button.disabled = true
	await stop_audio()
	var destination: String = {"crumb": CRUMB_SCENE, "ballast": BALLAST_SCENE, "harbor": HARBOR_SCENE, "demo": DEMO_SCENE}[action]
	var next: Node = Navigation.switch_scene(self, destination, chapter_profile_path, settings_path)
	if next == null:
		transitioning = false
		stage_button.disabled = false
		ballast_button.disabled = not chapter_profile.is_completed("W01S01")
		harbor_button.disabled = not chapter_profile.is_completed("W01S02")
		profile_status.text = "That scene could not open. Please try again."
		if is_instance_valid(music_player):
			music_player.stream = load("res://assets/audio/music.ogg")
			music_player.play()


func save_game() -> void:
	# Browsing the hub cannot create, reset, downgrade, or award chapter progress.
	pass
