extends Node3D
## VS01 scene owner: physical route, ordinary controls, presentation and durable saves.
const Art = preload("res://scripts/art.gd")
const Rules = preload("res://scripts/puzzle_state.gd")
const HUD = preload("res://scripts/hud.gd")
const SCALE_VALUES = [0.5, 1.0, 2.0]
const TRAYS = {
	"spoon": Vector3(-8.2, 0.06, 2.1), "blueberry": Vector3(-1.1, 0.06, 0.2),
	"butter": Vector3(-1.0, 0.06, 3.0), "napkin": Vector3(0.7, 0.06, 3.6),
	"cereal": Vector3(4.0, 0.02, -1.0), "toaster": Vector3(1.35, 0.02, -3.8)}
const SOCKETS = {"bridge": Vector3(-4.2, 0.11, 1.2), "ballast": Vector3(2.1, 0.12, -0.2),
	"wedge": Vector3(2.4, 0.04, 1.55), "landing": Vector3(8.5, 0.06, 2.8), "lever": Vector3(2.75, 0.83, -3.8)}
const SOCKET_LABELS = {"bridge": "SPOON REST", "ballast": "BERRY BALLAST", "wedge": "BUTTER WEDGE", "landing": "SOFT LANDING", "lever": "TOASTER LEVER"}
const DEFAULT_KEYS = {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
	"jump": KEY_SPACE, "interact": KEY_E, "shrink": KEY_Q, "grow": KEY_F, "target": KEY_TAB, "hint": KEY_H, "reset": KEY_R}
var state = Rules.new()
var props: Dictionary = {}
var markers: Dictionary = {}
var prop_tweens: Dictionary = {}
var camera: Camera3D
var pip: Node3D
var pip_art: Node3D
var toast: Node3D
var ramp: Node3D
var return_bridge: Node3D
var weight_flap: Node3D
var target_ring: Node3D
var hud: TinyHUD
var target := "spoon"
var started := false
var paused := false
var flying := false
var boarded := false
var boarding_time := 0.0
var boarding_start := Vector3.ZERO
var celebration_time := 0.0
var exploring := false
var t := 0.0
var vertical_speed := 0.0
var walking := false
var jump_buffer := 0.0
var landing_squash := 0.0
var resize_pose := 0.0
var recovery_time := 0.0
var flight_time := 0.0
var hint_step := 0
var last_goal := ""
var reduced_motion := false
var music_volume := 0.55
var effects_volume := 0.8
var text_scale := 1.0
var music_player: AudioStreamPlayer
var sounds: Dictionary = {}
var pending_rebind := ""
var save_path := "user://toast_express_v1.json"
var capture_dir := ""
var settings_path := "user://settings.cfg"
var has_save := false
var save_notice := ""
var replay_mode := false
var frame_samples: Array[float] = []
var previous_frame_usec := 0
var peak_draw_calls := 0
var peak_objects := 0
var intro_time := 0.0
var motion_clock := 0.0
var decoration_react: Node3D
var shadow: MeshInstance3D
var save_count := 0
var paused_tweens: Array[Tween] = []
var camera_aspect_multiplier := 1.0
var ever_completed := false
var chapter_profile_path := ""
var scene_transition_pending := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	replay_mode = "--replay" in OS.get_cmdline_user_args()
	if replay_mode:
		save_path = "user://replay_test_v1.json"
	if capture_dir == "":
		capture_dir = ProjectSettings.globalize_path("res://evidence" if OS.has_feature("editor") else "user://captures")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):
			capture_dir = arg.trim_prefix("--evidence-dir=")
	configure_inputs()
	load_settings()
	build_world()
	build_audio()
	hud = HUD.new()
	add_child(hud)
	hud.command.connect(on_command)
	hud.set_bindings(binding_names())
	apply_text_size()
	if not replay_mode:
		load_save()
	sync_props(false)
	respawn()
	hud.show_title(has_save)
	if replay_mode:
		var runner = load("res://tests/replay_route.gd").new()
		add_child(runner)
		runner.call_deferred("run", self)

func configure_inputs() -> void:
	if is_inside_tree() and not get_viewport().size_changed.is_connected(_update_camera_aspect):
		get_viewport().size_changed.connect(_update_camera_aspect)
	if is_inside_tree(): call_deferred("_update_camera_aspect")
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		var ev = InputEventKey.new()
		ev.physical_keycode = DEFAULT_KEYS[action]
		InputMap.action_add_event(action, ev)
	for entry in [["move_up", KEY_UP], ["move_down", KEY_DOWN], ["move_left", KEY_LEFT], ["move_right", KEY_RIGHT]]:
		var e = InputEventKey.new()
		e.physical_keycode = entry[1]
		InputMap.action_add_event(entry[0], e)
	for entry in [["jump", JOY_BUTTON_A], ["interact", JOY_BUTTON_X], ["target", JOY_BUTTON_Y], ["shrink", JOY_BUTTON_LEFT_SHOULDER], ["grow", JOY_BUTTON_RIGHT_SHOULDER], ["hint", JOY_BUTTON_BACK]]:
		var ev = InputEventJoypadButton.new()
		ev.button_index = entry[1]
		InputMap.action_add_event(entry[0], ev)

func _update_camera_aspect() -> void:
	if not is_instance_valid(camera): return
	var extent: Vector2 = get_viewport().get_visible_rect().size
	if extent.y <= 0 or extent.x <= 0: return
	# Preserve the authored horizontal route on narrower tablet/window aspects.
	# Wider phones retain vertical scale and reveal more of the same diorama.
	var next: float = maxf(1.0, (16.0 / 9.0) / (extent.x / extent.y))
	camera.size *= next / camera_aspect_multiplier
	camera_aspect_multiplier = next

func build_world() -> void:
	add_child(Art.table())
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d8c8ae")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dddde0")
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-58, -28, 0)
	key.light_color = Color("fff5e8")
	key.light_energy = 0.58
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 55
	key.shadow_blur = 2.5
	add_child(key)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 130, 0)
	fill.light_color = Color("b4d3d4")
	fill.light_energy = 0.12
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.7
	camera.position = Vector3(10, 16, 22)
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true
	# Two shallow milk spills divide three dry breakfast islands.
	for x in [-4.2, 3.9]:
		var milk = cube(Vector3(2.0, 0.055, 11.3), Color("e5eff0"), Vector3(x, 0.025, 0))
		milk.material_override.roughness = 0.24
		add_child(milk)
		for z in [-5.35, 5.35]:
			add_child(sphere(Vector3(2.0, 0.06, 1.5), Color("e5eff0"), Vector3(x, 0.03, z)))
	# Glazed saucers make the bridge endpoints readable.
	for pos in [Vector3(-5.95, 0.015, 1.2), Vector3(-2.25, 0.015, 1.2)]:
		add_child(cylinder(1.28, 0.08, Color("f5e6cc"), pos))
		add_child(ring(1.10, 0.035, Color("4a9290"), pos + Vector3(0, 0.045, 0)))
	for x in [-5.28, -2.75]:
		add_child(sphere(Vector3(0.32, 0.39, 0.68), Color("4a9290"), Vector3(x, 0.22, 1.2)))
	build_teacup()
	for kind in Rules.PROP_KINDS:
		var node: Node3D = Art.prop(kind)
		node.name = kind.capitalize()
		add_child(node)
		props[kind] = node
	for socket in SOCKETS:
		var marker = Node3D.new()
		marker.position = SOCKETS[socket]
		marker.add_child(ring(0.56 if socket != "landing" else 1.2, 0.033, Color("4a9290"), Vector3(0, 0.015, 0)))
		var marker_label = Label3D.new()
		marker_label.text = SOCKET_LABELS[socket]
		marker_label.font = load("res://assets/fonts/Nunito.ttf")
		marker_label.font_size = 34
		marker_label.pixel_size = 0.008
		marker_label.modulate = Color("384657")
		marker_label.outline_modulate = Color("f5e6cc")
		marker_label.outline_size = 5
		marker_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker_label.position = Vector3(0, 0.21, 0.48)
		marker.add_child(marker_label)
		add_child(marker)
		markers[socket] = marker
	# The cereal flap rises about its visible hinge; the wedge makes it permanent.
	ramp = Node3D.new()
	ramp.position = Vector3(2.8, 0.06, 1.2)
	ramp.add_child(cube(Vector3(2.8, 0.10, 1.2), Color("e5a54b"), Vector3(1.4, 0.02, 0)))
	for i in 9:
		ramp.add_child(cube(Vector3(0.035, 0.014, 1.05), Color("bb7e3a"), Vector3(0.2 + i * 0.29, 0.08, 0)))
	add_child(ramp)
	weight_flap = Node3D.new()
	weight_flap.position = Vector3(2.1, 0.075, -0.2)
	weight_flap.add_child(cube(Vector3(1.3, 0.075, 1.15), Color("c95c54"), Vector3.ZERO))
	add_child(weight_flap)
	# A visible linkage connects the ballast pedal and ramp.
	add_child(cube(Vector3(0.08, 0.065, 1.5), Color("384657"), Vector3(2.75, 0.06, 0.40)))
	add_child(cylinder(0.18, 0.1, Color("e5a54b"), Vector3(2.77, 0.07, 1.15)))
	return_bridge = Node3D.new()
	return_bridge.position = Vector3(-4.2, 0.09, -2.2)
	return_bridge.add_child(cube(Vector3(2.5, 0.12, 1.15), Color("e5a54b"), Vector3.ZERO))
	for i in 8:
		return_bridge.add_child(cube(Vector3(0.18, 0.025, 1.03), Color("f5e6cc"), Vector3(-1.03+i*0.3, 0.077, 0)))
	add_child(return_bridge)
	toast = Art.prop("toast")
	add_child(toast)
	build_flag()
	pip = Node3D.new()
	pip.name = "Pip"
	pip_art = Art.pip()
	pip.add_child(pip_art)
	add_child(pip)
	shadow = cylinder(0.31, 0.003, Color(0.20, 0.24, 0.25, 0.22), Vector3.ZERO)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_child(shadow)
	target_ring = ring(0.55, 0.033, Color("fff3b6"), Vector3.ZERO)
	add_child(target_ring)

func build_teacup() -> void:
	var cup = Node3D.new()
	cup.position = Vector3(-8.4, 0.05, -0.5)
	cup.add_child(cylinder(1.15, 1.75, Color("f5e6cc"), Vector3(0, 0.89, 0)))
	cup.add_child(cylinder(1.01, 0.04, Color("855035"), Vector3(0, 1.785, 0)))
	cup.add_child(ring(1.08, 0.10, Color("fff2dc"), Vector3(0, 1.81, 0)))
	cup.add_child(ring(1.08, 0.055, Color("4a9290"), Vector3(0, 0.3, 0)))
	cup.add_child(cylinder(1.63, 0.10, Color("fff2dc"), Vector3(0, 0.02, 0)))
	# Oversized handmade handle forms the traversable tunnel on the route.
	var handle = ring(0.82, 0.14, Color("f5e6cc"), Vector3(2.1, 0.85, 1.7))
	handle.rotation.z = PI / 2
	cup.add_child(handle)
	cup.add_child(cube(Vector3(1.25, 0.15, 0.17), Color("f5e6cc"), Vector3(1.52, 1.58, 1.7)))
	cup.add_child(cube(Vector3(1.25, 0.15, 0.17), Color("f5e6cc"), Vector3(1.52, 0.12, 1.7)))
	add_child(cup)
	decoration_react = Node3D.new()
	decoration_react.position = Vector3(-9.25, 0.06, 3.85)
	decoration_react.add_child(cylinder(0.30, 0.16, Color("e5a54b"), Vector3.ZERO))
	for x in [-0.10, 0.10]:
		decoration_react.add_child(sphere(Vector3(0.075, 0.1, 0.06), Color("384657"), Vector3(x, 0.14, 0.20)))
	add_child(decoration_react)

func build_flag() -> void:
	var home = Node3D.new()
	home.position = Vector3(9.6, 0.05, 0.8)
	home.add_child(cube(Vector3(1.7, 0.55, 1.1), Color("c95c54"), Vector3(0, 0.27, 0)))
	home.add_child(cube(Vector3(1.4, 0.42, 1.16), Color("f5e6cc"), Vector3(0, 0.27, 0)))
	home.add_child(cube(Vector3(0.04, 2.6, 0.04), Color("384657"), Vector3(0.0, 1.6, 0)))
	home.add_child(cube(Vector3(0.92, 0.5, 0.045), Color("4a9290"), Vector3(0.44, 2.5, 0)))
	var l = Label3D.new()
	l.text = "HOME"
	l.font_size = 40
	l.pixel_size = 0.006
	l.position = Vector3(0.44, 2.5, 0.032)
	l.modulate = Color("fff6e5")
	home.add_child(l)
	add_child(home)

func material(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.78
	return m

func cube(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	return n

func sphere(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.radial_segments = 24
	mesh.rings = 12
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.scale = size
	n.material_override = material(color)
	n.position = pos
	return n

func cylinder(radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	return n

func ring(radius: float, width: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh = TorusMesh.new()
	mesh.inner_radius = radius - width
	mesh.outer_radius = radius + width
	mesh.rings = 40
	mesh.ring_segments = 8
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	return n

const EFFECT_VOICE_LIMIT := 8
# Short guards prevent same-frame/repeated-input chatter. After the guard, a
# same-cue retrigger replaces its previous tail instead of stacking identical
# samples (current effects last 0.56–2.62s). These are technical policies, not
# a claim of auditioned balance. Important progress cues can replace lower ones.
const EFFECT_RETRIGGER_USEC := {"reject": 150000, "jump": 90000, "land": 100000, "checkpoint": 150000, "discovery": 200000, "complete": 250000, "launch": 150000}
const EFFECT_PRIORITY := {"reject": 0, "jump": 0, "land": 0, "pickup": 1, "place": 1, "resize_up": 1, "resize_down": 1, "launch": 2, "checkpoint": 2, "discovery": 2, "complete": 3}
var effect_players: Array[AudioStreamPlayer] = []
var effect_last_play_usec: Dictionary = {}

func build_audio() -> void:
	AudioServer.set_bus_layout(load("res://assets/default_bus_layout.tres"))
	for sound in ["resize_up", "resize_down", "pickup", "place", "reject", "checkpoint", "jump", "land", "launch", "complete", "discovery"]:
		sounds[sound] = load("res://assets/audio/" + sound + ".wav")
	var retained: Array[AudioStreamPlayer] = []
	for player in effect_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			retained.append(player)
	effect_players = retained
	effect_last_play_usec.clear()
	while effect_players.size() < EFFECT_VOICE_LIMIT:
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		player.max_polyphony = 1
		add_child(player)
		effect_players.append(player)
	if not is_instance_valid(music_player):
		music_player = AudioStreamPlayer.new()
		music_player.bus = "Music"
		add_child(music_player)
	var music: AudioStreamOggVorbis = load("res://assets/audio/music.ogg")
	music.loop = true
	music_player.stop()
	music_player.stream = music
	music_player.stream_paused = false
	apply_volumes()
	music_player.play()

func sfx(sound: String) -> void:
	if not sounds.has(sound):
		return
	var now := Time.get_ticks_usec()
	if effect_last_play_usec.has(sound) and now - int(effect_last_play_usec[sound]) < int(EFFECT_RETRIGGER_USEC.get(sound, 80000)):
		return
	var priority: int = EFFECT_PRIORITY.get(sound, 1)
	var selected: AudioStreamPlayer
	# There is at most one active voice for a given cue, even after its guard.
	for player in effect_players:
		if is_instance_valid(player) and player.playing and player.stream == sounds[sound]:
			selected = player
			break
	if selected == null:
		for player in effect_players:
			if is_instance_valid(player) and not player.playing:
				selected = player
				break
	if selected == null:
		for player in effect_players:
			if not is_instance_valid(player): continue
			var previous_priority: int = player.get_meta("effect_priority", 0)
			if previous_priority > priority: continue
			if selected == null or previous_priority < int(selected.get_meta("effect_priority", 0)) or (previous_priority == int(selected.get_meta("effect_priority", 0)) and int(player.get_meta("effect_started_usec", 0)) < int(selected.get_meta("effect_started_usec", 0))):
				selected = player
	if selected == null: return
	selected.stop()
	selected.stream = sounds[sound]
	selected.stream_paused = false
	selected.set_meta("effect_priority", priority)
	selected.set_meta("effect_started_usec", now)
	effect_last_play_usec[sound] = now
	selected.play()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(hud) and hud.rotation_guard.visible: return
	if pending_rebind != "" and event is InputEventKey and event.pressed:
		if event.physical_keycode != KEY_ESCAPE:
			if event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
				hud.toast("1, 2 and 3 are quick size keys. Choose another key.", 5)
				return
			for action in DEFAULT_KEYS:
				if action == pending_rebind: continue
				for binding in InputMap.action_get_events(action):
					if binding is InputEventKey and binding.physical_keycode == event.physical_keycode:
						hud.toast("That key is already used for " + action.replace("_", " ") + ". Try another.", 5)
						return
			var replacement = InputEventKey.new()
			replacement.physical_keycode = event.physical_keycode
			for old in InputMap.action_get_events(pending_rebind):
				if old is InputEventKey:
					InputMap.action_erase_event(pending_rebind, old)
			InputMap.action_add_event(pending_rebind, replacement)
		pending_rebind = ""
		save_settings()
		hud.set_bindings(binding_names())
		hud.show_controls(binding_names())
		return
	if (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		if started:
			on_command("resume" if paused else "pause", null)
		return
	if not started:
		if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_ENTER, KEY_SPACE]:
			on_command("start", true)
		return
	if paused:
		return
	if event.is_action_pressed("reset"):
		on_command("reset", null)
	elif event.is_action_pressed("hint"):
		show_hint()
	elif not flying:
		if event.is_action_pressed("target"):
			cycle_target()
		elif event.is_action_pressed("interact"):
			interact()
		elif event.is_action_pressed("shrink"):
			resize_target(maxi(0, int(state.sizes[target]) - 1))
		elif event.is_action_pressed("grow"):
			resize_target(mini(2, int(state.sizes[target]) + 1))
		elif event.is_action_pressed("jump"):
			jump_buffer = 0.15
		elif event is InputEventKey and event.pressed:
			if event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
				resize_target(event.physical_keycode - KEY_1)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			select_at_mouse(event.position)

func on_command(action: String, value: Variant) -> void:
	match action:
		"orientation":
			if started and not paused: on_command("pause", null)
		"touch":
			if not started or paused: return
			var touch_action = str(value)
			if touch_action == "pause":
				on_command("pause", null)
			elif touch_action.begins_with("size_"):
				on_command("size", ["size_small", "size_normal", "size_large"].find(touch_action))
			else:
				var event = InputEventAction.new()
				event.action = touch_action
				event.pressed = true
				_unhandled_input(event)
		"start":
			if hud.rotation_guard.visible: return
			started = true
			paused = false
			hud.hide_menu()
			if state.completed:
				hud.show_complete(state.discovered)
				paused = true
			elif save_notice != "":
				hud.toast(save_notice, 5)
			else:
				hud.toast("Good morning, Pip. That spoon looks full of possibility.", 5)
		"new":
			state = Rules.new()
			flying = false
			boarded = false
			exploring = false
			hint_step = 0
			sync_props(false)
			respawn()
			save_game()
			on_command("start", true)
		"pause":
			if not started:
				return
			if not paused:
				paused_tweens.clear()
				for tw in get_tree().get_processed_tweens():
					if tw.is_running():
						paused_tweens.append(tw)
						tw.pause()
			paused = true
			hud.show_pause(reduced_motion, music_volume, effects_volume, text_scale)
		"resume":
			if hud.rotation_guard.visible: return
			for tw in paused_tweens:
				if tw.is_valid(): tw.play()
			paused_tweens.clear()
			paused = false
			hud.hide_menu()
		"reset":
			state.reset_checkpoint()
			flying = false
			boarded = false
			exploring = false
			sync_props(false)
			respawn()
			save_game()
			sfx("checkpoint")
			hud.toast("Everything is back at your last safe checkpoint.")
			on_command("resume", null)
		"size":
			if started and not paused and not flying:
				resize_target(int(value))
		"reduced":
			reduced_motion = bool(value)
			save_settings()
		"music", "effects":
			if action == "music": music_volume = float(value)
			else: effects_volume = float(value)
			apply_volumes()
			save_settings()
		"text":
			text_scale = float(value)
			apply_text_size()
			save_settings()
		"controls": hud.show_controls(binding_names())
		"rebind":
			pending_rebind = str(value)
			hud.toast("Press a key for " + pending_rebind.replace("_", " ") + ". Escape cancels.", 10)
		"title":
			save_game()
			# Reuse resume so paused prop transitions cannot remain suspended
			# when the title screen is left through Continue breakfast.
			on_command("resume", null)
			started = false
			hud.show_title(true)
		"chapter":
			if scene_transition_pending: return
			scene_transition_pending = true
			save_game()
			await stop_audio()
			var navigation = load("res://scripts/chapter/chapter_navigation.gd")
			var chapter_path = chapter_profile_path if chapter_profile_path != "" else "user://breakfast_chapter_v1.json"
			var next = navigation.switch_scene(self, "res://scenes/chapter/workshop.tscn", chapter_path, settings_path)
			if next == null:
				scene_transition_pending = false
				build_audio()
				hud.toast("The workshop could not open. Your breakfast progress is saved.", 6)
		"explore":
			exploring = true
			state.completed = false
			state.reset_checkpoint()
			flying = false
			boarded = false
			sync_props(false)
			pip.position = Vector3(7.7, 0.04, 3)
			on_command("resume", null)

func binding_names() -> Dictionary:
	var names: Dictionary = {}
	for action in DEFAULT_KEYS:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				names[action] = OS.get_keycode_string(ev.physical_keycode)
				break
	return names

func _process(delta: float) -> void:
	var now_usec = Time.get_ticks_usec()
	if previous_frame_usec > 0 and started and not paused and intro_time > 2.0 and frame_samples.size() < 60000:
		frame_samples.append((now_usec - previous_frame_usec) / 1000.0)
		peak_draw_calls = maxi(peak_draw_calls, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
		peak_objects = maxi(peak_objects, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)))
	previous_frame_usec = now_usec
	if paused:
		return
	t += delta
	recovery_time = maxf(0, recovery_time - delta)
	resize_pose = maxf(0, resize_pose - delta)
	landing_squash = maxf(0, landing_squash - delta * 3)
	if not started:
		animate_pip(delta)
		return
	intro_time += delta
	if flying:
		update_flight(delta)
		hud.update_target("Next stop: home", "Your napkin is ready. Enjoy the ride.", -1)
	else:
		move_pip(delta)
		update_target()
	animate_pip(delta)
	for kind in props:
		if state.carried == kind:
			props[kind].position = pip.position + Vector3(0, 0.94, 0) + pip_art.basis.z * 0.35
			props[kind].rotation.y = pip_art.rotation.y
	if target != "":
		target_ring.position = props[target].position + Vector3(0, 0.035, 0)
		target_ring.scale = Vector3.ONE * (0.65 + SCALE_VALUES[int(state.sizes[target])] * 0.4)
		target_ring.visible = not flying
	var desired_center = Vector3(clampf(pip.position.x * 0.32, -2.6, 2.6), 0, 0)
	var desired_camera = desired_center + Vector3(10, 16, 22)
	camera.position = camera.position.lerp(desired_camera, delta * 1.6)
	camera.size = lerpf(camera.size, (14.2 if not flying else 17.0) * camera_aspect_multiplier, delta * 1.6)
	camera.look_at(camera.position - Vector3(10, 16, 22))
	shadow.position = Vector3(pip.position.x, 0.095, pip.position.z)
	shadow.scale = Vector3.ONE * clampf(1.0 - pip.position.y * 0.12, 0.4, 1.0)
	shadow.visible = not flying
	if decoration_react and not reduced_motion:
		var near = pip.position.distance_to(decoration_react.position) < 2.5
		decoration_react.rotation.z = sin(t * 5) * (0.2 if near else 0.04)
		decoration_react.position.y = 0.10 + absf(sin(t * 4)) * (0.15 if near else 0.02)
	update_objective()

func movement_input() -> Vector2:
	var axis = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.get_connected_joypads().size() > 0:
		var joy = Input.get_connected_joypads()[0]
		var stick = Vector2(Input.get_joy_axis(joy, JOY_AXIS_LEFT_X), Input.get_joy_axis(joy, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2: axis = stick.limit_length()
	if is_instance_valid(hud) and is_instance_valid(hud.touch_controls) and hud.touch_controls.enabled:
		axis = (axis + hud.touch_controls.pad_vector).limit_length()
	return axis

func move_pip(delta: float) -> void:
	if state.completed:
		walking = false
		celebration_time += delta
		if celebration_time >= 1.2:
			paused = true
			hud.show_complete(state.discovered)
		pip.position.y = 0.38 + absf(sin(celebration_time * 7)) * (0.0 if reduced_motion else 0.19)
		return
	jump_buffer = maxf(0, jump_buffer - delta)
	if boarded:
		walking = false
		boarding_time = minf(boarding_time + delta, 0.5)
		var u = boarding_time / 0.5
		pip.position = boarding_start.lerp(toast.position + Vector3(0, 0.19, 0), u) + Vector3(0, sin(u * PI) * 0.7, 0)
		return
	var input = movement_input()
	var right = camera.global_basis.x
	right.y = 0
	right = right.normalized()
	var back = camera.global_basis.z
	back.y = 0
	back = back.normalized()
	var direction = right * input.x + back * input.y
	walking = direction.length() > 0.05 and recovery_time <= 0
	if walking:
		var next = pip.position + direction * (2.7 if state.carried == "" else 2.3) * delta
		next.x = clampf(next.x, -10.9, 10.9)
		next.z = clampf(next.z, -5.25, 5.1)
		if not obstructed(next):
			pip.position.x = next.x
			pip.position.z = next.z
		else:
			var next_x = Vector3(next.x, pip.position.y, pip.position.z)
			var next_z = Vector3(pip.position.x, pip.position.y, next.z)
			if not obstructed(next_x): pip.position.x = next.x
			elif not obstructed(next_z): pip.position.z = next.z
		pip_art.rotation.y = lerp_angle(pip_art.rotation.y, atan2(direction.x, direction.z), minf(delta * 14, 1))
	if state.carried == "spoon" and not state.handle_passed and absf(pip.position.x + 6.3) < 0.30 and absf(pip.position.z - 1.2) < 0.61:
		apply_result(state.pass_handle(), "place")
		burst(pip.position + Vector3(0, 0.6, 0), Color("e5a54b"))
	var floor_y = surface_height(pip.position)
	if floor_y < -1 and recovery_time <= 0:
		recover("A splash! Pip and the props are safe at the checkpoint.")
		return
	var grounded = pip.position.y <= floor_y + 0.02
	if grounded and jump_buffer > 0:
		vertical_speed = 4.5
		jump_buffer = 0
		sfx("jump")
	if not grounded or vertical_speed > 0:
		vertical_speed -= 13.5 * delta
		pip.position.y += vertical_speed * delta
		if pip.position.y <= floor_y:
			pip.position.y = floor_y
			vertical_speed = 0
			landing_squash = 0.38
			sfx("land")
	else:
		pip.position.y = floor_y

func obstructed(pos: Vector3) -> bool:
	# Authored simple footprints match the major solid forms, independent of decoration.
	if Vector2(pos.x + 8.4, pos.z + 0.5).length() < 1.38:
		return true
	if solid_footprint_contains("cereal", int(state.sizes["cereal"]), pos):
		return true
	if solid_footprint_contains("toaster", int(state.sizes["toaster"]), pos):
		return true
	if state.carried != "blueberry" and state.sockets["blueberry"] != "lever":
		var p: Vector3 = prop_position("blueberry")
		if Vector2(pos.x - p.x, pos.z - p.z).length() < 0.3 * SCALE_VALUES[int(state.sizes["blueberry"])] + 0.22:
			return true
	return false

func solid_footprint_contains(kind: String, size: int, pos: Vector3) -> bool:
	var local: Vector3 = (pos - TRAYS[kind]).rotated(Vector3.UP, -0.79 if kind == "cereal" else 0.0)
	var dims = Vector2(1.15, 0.60) if kind == "cereal" else Vector2(1.0, 0.7)
	return absf(local.x) < dims.x * SCALE_VALUES[size] + 0.23 and absf(local.z) < dims.y * SCALE_VALUES[size] + 0.23

func surface_height(pos: Vector3) -> float:
	if state.bridge_placed and absf(pos.z - 1.2) < 0.38 and pos.x > -5.65 and pos.x < -1.40:
		return 0.52
	if absf(pos.x + 4.2) < 1.05:
		if state.bridge_placed and absf(pos.z - 1.2) < 0.59:
			return 0.52
		if state.ramp_latched and absf(pos.z + 2.2) < 0.54:
			return 0.20
		return -2
	if pos.x > 2.85 and pos.x < 5.05:
		if state.ramp_raised() and absf(pos.z - 1.2) < 0.55:
			return 0.17
		return -2
	return 0.06

func animate_pip(delta: float) -> void:
	motion_clock += delta * (10.5 if walking else 2.2)
	var bob = absf(sin(motion_clock)) * 0.048 if walking else sin(motion_clock) * 0.018
	if reduced_motion:
		bob *= 0.35
	pip_art.position.y = bob
	var stretch = 1.0 - landing_squash * 0.35
	if vertical_speed > 1: stretch = 1.12
	if flying: stretch = 1.04
	pip_art.scale = Vector3(1.0 / sqrt(stretch), stretch, 1.0 / sqrt(stretch))
	for named in ["FootL", "FootR"]:
		var foot = pip_art.get_node_or_null(named)
		if foot:
			foot.rotation.x = sin(motion_clock + (PI if named == "FootR" else 0.0)) * (0.40 if walking else 0.0)
	var tool = pip_art.get_node_or_null("Tool")
	if tool:
		tool.rotation.z = -0.4 * minf(resize_pose * 4, 1)
	var tail = pip_art.get_node_or_null("Tail")
	if tail:
		tail.rotation.y = sin(t * 3.4) * 0.15
	var blink = 0.12 if fmod(t, 4.3) < 0.12 else 1.0
	for eye_name in ["EyeL", "EyeR"]:
		var eye = pip_art.get_node_or_null(eye_name)
		if eye:
			eye.scale.y = 0.155 * blink
	if recovery_time > 0 and not reduced_motion:
		pip_art.rotation.z = sin(t * 18) * 0.08 * recovery_time
	else:
		pip_art.rotation.z = 0

func prop_position(kind: String) -> Vector3:
	if state.sockets[kind] == "carried":
		return pip.position + Vector3(0, 0.94, 0)
	if SOCKETS.has(state.sockets[kind]):
		return SOCKETS[state.sockets[kind]]
	return TRAYS[kind]

func sync_props(animate: bool = true) -> void:
	for kind in props:
		var node: Node3D = props[kind]
		var scale_value: float = SCALE_VALUES[int(state.sizes[kind])]
		if prop_tweens.has(kind) and prop_tweens[kind].is_valid():
			prop_tweens[kind].kill()
		node.rotation = Vector3(0, 0.79 if kind == "cereal" else 0.0, 0)
		if animate and not reduced_motion:
			var tw = create_tween().set_parallel(true)
			tw.tween_property(node, "scale", Vector3.ONE * scale_value, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(node, "position", prop_position(kind), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			prop_tweens[kind] = tw
		else:
			node.scale = Vector3.ONE * scale_value
			node.position = prop_position(kind)
	var target_ramp_angle = 0.0 if state.ramp_raised() else -1.30
	if animate:
		create_tween().tween_property(ramp, "rotation:z", target_ramp_angle, 0.45).set_trans(Tween.TRANS_CUBIC)
	else:
		ramp.rotation.z = target_ramp_angle
	weight_flap.rotation.z = -0.13 if state.ramp_raised() else 0.10
	return_bridge.visible = state.ramp_latched
	toast.position = Vector3(1.35, 1.47 if state.toast_lowered else 1.78, -3.8)
	var lever = props["toaster"].get_node_or_null("Lever")
	if lever:
		lever.position.y = 0.73 if state.toast_lowered else 1.04
	var picnic = props["cereal"].get_node_or_null("Picnic")
	var panel = props["cereal"].get_node_or_null("SecretPanel")
	if picnic: picnic.visible = state.discovered
	if panel: panel.visible = not state.discovered
	for socket in markers:
		var occupied = socket in state.sockets.values()
		markers[socket].visible = not occupied

func resize_target(new_size: int) -> void:
	if target == "" or flying:
		return
	if not in_range(target, 6.4 if boarded else 4.0):
		reject("Move a little closer to reach the " + target + ".")
		return
	var old_size = int(state.sizes[target])
	if boarded and target in ["cereal", "toaster"] and new_size != old_size:
		reject("Step off the toast before adjusting the launcher or its window.")
		return
	if target in ["cereal", "toaster"] and new_size > old_size and solid_footprint_contains(target, new_size, pip.position):
		reject("Step out of its growing space, then try again.")
		return
	if target == "spoon" and new_size < 2 and state.bridge_placed and absf(pip.position.z - 1.2) < 0.65 and pip.position.x > -6.8 and pip.position.x < -1.3:
		reject("Step off the spoon before shrinking your bridge.")
		return
	if target == "blueberry" and new_size < 2 and state.sockets["blueberry"] == "ballast" and not state.ramp_latched and pip.position.x > 2.85 and pip.position.x < 5.05:
		reject("Step off the ramp before removing its weight.")
		return
	if boarded and boarding_time < 0.5:
		reject("Almost aboard. Let Pip find their footing.")
		return
	if boarded and target == "blueberry" and new_size < 2:
		var result = state.release_launch()
		if result.ok:
			begin_flight()
		else: reject(result.message)
		return
	if new_size > old_size and state.carried != target:
		var footprint: float = {"spoon": 0.5, "blueberry": 0.38, "cereal": 1.25, "napkin": 0.55, "butter": 0.4, "toaster": 1.1}[target] * SCALE_VALUES[new_size]
		var p: Vector3 = props[target].position
		if Vector2(pip.position.x - p.x, pip.position.z - p.z).length() < footprint + 0.28:
			reject("Give it a little room before growing it.")
			return
	if target in ["cereal", "toaster"] and new_size == 2:
		reject("The breakfast tray is too snug for that. Small or normal fits here.")
		return
	var cp_before = state.checkpoint
	var result = state.resize(target, new_size)
	apply_result(result, "resize_up" if new_size > old_size else "resize_down")
	if result.ok:
		resize_pose = 0.5
		if old_size != new_size:
			burst(props[target].position + Vector3(0, 0.35, 0), Color("e5a54b") if new_size > old_size else Color("8bc6c0"))
		sync_props()
		checkpoint_feedback(cp_before)

func interact() -> void:
	if boarded:
		boarded = false
		pip.position = Vector3(0.7, 0.06, -2.5)
		hud.toast("Back on the table. Your launch is still ready.")
		return
	if state.carried != "":
		var socket = nearest_socket(state.carried)
		var cp = state.checkpoint
		apply_result(state.place(socket), "place")
		sync_props()
		checkpoint_feedback(cp)
		return
	if target == "":
		reject("Look for a prop with a little glowing ring.")
		return
	if not in_range(target, 2.25):
		reject("Step closer to pick up or use the " + target + ".")
		return
	if target == "toaster" and state.can_launch():
		if int(state.sizes["cereal"]) != 1:
			reject("Return the cereal box to normal so the toast fits its window.")
			return
		if int(state.sizes["toaster"]) != 1:
			reject("Return the toaster to normal before boarding.")
			return
		boarded = true
		boarding_time = 0
		boarding_start = pip.position
		target = "blueberry"
		sfx("jump")
		hud.toast("All aboard! Shrink the blueberry to release the toast.", 6)
		return
	var was_discovered = state.discovered
	var result = state.interact(target)
	apply_result(result, "pickup")
	sync_props()
	if state.discovered and not was_discovered:
		sfx("discovery")
		burst(props["cereal"].position + Vector3(0, 0.5, 0), Color("e5a54b"))
		landing_squash = 0.4

func nearest_socket(kind: String) -> String:
	var best := "tray"
	var distance := 1.85
	for socket in Rules.PROP_SOCKETS[kind]:
		if not SOCKETS.has(socket):
			continue
		var p: Vector3 = SOCKETS[socket]
		var d = Vector2(pip.position.x - p.x, pip.position.z - p.z).length()
		if d < distance:
			best = socket
			distance = d
	return best

func in_range(kind: String, distance: float) -> bool:
	return state.carried == kind or pip.position.distance_to(props[kind].position) < distance

func cycle_target() -> void:
	var candidates: Array[String] = []
	for kind: String in Rules.PROP_KINDS:
		if in_range(kind, 6.4 if boarded else 4.4):
			candidates.append(kind)
	if candidates.is_empty():
		reject("Walk toward one of the breakfast props.")
		return
	var idx = candidates.find(target)
	target = candidates[(idx + 1) % candidates.size()]
	sfx("place")

func select_at_mouse(screen_pos: Vector2) -> void:
	var closest := 80.0
	for kind in props:
		var screen = camera.unproject_position(props[kind].position + Vector3(0, 0.35, 0))
		var d = screen.distance_to(screen_pos)
		if d < closest and in_range(kind, 6.4 if boarded else 4.4):
			target = kind
			closest = d

func update_target() -> void:
	if state.completed:
		hud.update_target("Home, sweet matchbox", "Delivery complete. A little celebration is in order.", -1)
		return
	if not in_range(target, 4.7) and state.carried == "" and not boarded:
		var distance = INF
		for kind in props:
			var d = pip.position.distance_to(props[kind].position)
			if d < distance:
				distance = d
				target = kind
	var help_text := ""
	if boarded:
		help_text = "1 / Q  Shrink the berry to launch!   E  Step off"
	elif state.carried != "":
		var socket = nearest_socket(state.carried)
		help_text = "E  Place at " + SOCKET_LABELS[socket].to_lower() if socket != "tray" else "E  Return to tray • Find the matching ring"
	elif not in_range(target, 4.0):
		help_text = "Walk closer to reach this prop."
	elif target == "toaster":
		help_text = "E  Board the toast" if state.can_launch() else "A big berry can press the toy lever."
	elif target == "cereal":
		help_text = "E  Peek inside the small side panel" if int(state.sizes[target]) == 0 else "A little panel hides a breakfast secret."
	else:
		help_text = "E  Pick up • Tab  Change target" if int(state.sizes[target]) == 0 else "1 / Q  Shrink to carry • 3 / F  Grow"
	var shown = state.carried if state.carried != "" else target
	hud.update_target(shown.capitalize() + ("  ·  carrying" if state.carried != "" else ""), help_text, int(state.sizes[shown]))

func update_objective() -> void:
	var goal = current_goal()
	if goal != last_goal:
		hint_step = 0
		last_goal = goal
	hud.subgoal.text = goal
	hud.progress.text = ["01  /  THE SPOON BRIDGE", "02  /  BLUEBERRY BALLAST", "03  /  READY, SET, TOAST", "03  /  ALL ABOARD"][state.checkpoint]

func current_goal() -> String:
	if state.completed: return "Special delivery! Pip made it home."
	if flying: return "Next stop: the matchbox flag!"
	if boarded: return "Shrink the blueberry. Hold on to your crumbs."
	if state.checkpoint == 0:
		if not state.handle_passed: return "Carry a tiny spoon through the cup handle."
		return "Rest the spoon across the milk. Make it mighty."
	if state.checkpoint == 1:
		if not state.ramp_raised(): return "Give the cereal flap a heavy blueberry."
		return "Wedge the ramp with butter to keep it open."
	if not state.napkin_ready: return "Spread a giant napkin by the home flag."
	if not state.toast_lowered: return "Move the blueberry onto the toaster lever."
	return "Board the toast. Your ride home is ready."

func show_hint() -> void:
	var hints: Array[String] = []
	if state.checkpoint == 0 and not state.handle_passed:
		hints = ["The spoon is too bulky for that cup handle.", "Small things fit through small spaces.", "Select the spoon, press 1 then E. Carry it through the handle beside the spoon rest."]
	elif state.checkpoint == 0:
		hints = ["The two saucers need something between them.", "The teal ring is a resting place for the spoon.", "Carry the spoon to the SPOON REST, press E, step back, then press 3."]
	elif state.checkpoint == 1 and not state.ramp_raised():
		hints = ["The cereal flap and ramp are connected.", "A heavy blueberry can press the coral pedal.", "Shrink and carry the blueberry to BERRY BALLAST. Place it, step back, then grow it large."]
	elif state.checkpoint == 1:
		hints = ["The ramp needs something to keep it steady.", "Butter makes a surprisingly good wedge.", "Carry small butter to BUTTER WEDGE. Place it and grow it to normal. The berry is free to reuse."]
	elif not state.napkin_ready:
		hints = ["Before a big leap, plan a soft landing.", "The napkin belongs by the matchbox flag.", "Carry the small napkin across the cereal ramp to SOFT LANDING. Place it and grow it large."]
	elif not state.toast_lowered:
		hints = ["Your old blueberry has one more job.", "The toaster has a little toy lever.", "Shrink the ballast berry, carry it to TOASTER LEVER, place it, step away, and grow it large."]
	else:
		hints = ["The toast is your ticket home.", "Release its weight once you are aboard.", "Approach the toaster, select it with Tab and press E. Then shrink the blueberry."]
	hud.toast(hints[mini(hint_step, 2)], 7)
	hint_step += 1

func apply_result(result: Dictionary, sound: String) -> void:
	if result.ok:
		hud.toast(result.message)
		sfx(sound)
		save_game()
	else:
		reject(result.message)

func reject(reason: String) -> void:
	hud.toast(reason)
	sfx("reject")
	if target != "" and not reduced_motion:
		var n: Node3D = props[target]
		var tw = create_tween()
		tw.tween_property(n, "rotation:z", 0.08, 0.07)
		tw.tween_property(n, "rotation:z", -0.06, 0.1)
		tw.tween_property(n, "rotation:z", 0.0, 0.1)

func checkpoint_feedback(previous: int) -> void:
	if state.checkpoint > previous:
		sfx("checkpoint")
		hud.toast(["", "Spoon bridge complete. Checkpoint saved.", "Ramp latched! A permanent return path is open.", "Landing ready. Launch checkpoint saved."][state.checkpoint], 5)
		burst(pip.position + Vector3(0, 0.65, 0), Color("4a9290"))
		save_game()

func respawn() -> void:
	pip.position = [Vector3(-8.1, 0.06, 3.5), Vector3(-1.6, 0.06, 1.3), Vector3(0.5, 0.06, 2.2), Vector3(0.3, 0.06, -2.4)][state.checkpoint]
	if state.completed: pip.position = Vector3(8.5, 0.38, 2.8)
	else: pip.position.y = surface_height(pip.position)
	pip_art.rotation.y = 0.1
	vertical_speed = 0
	jump_buffer = 0
	target = ["spoon", "blueberry", "napkin", "toaster"][state.checkpoint]

func recover(reason: String) -> void:
	state.reset_checkpoint()
	boarded = false
	flying = false
	sync_props(false)
	respawn()
	recovery_time = 0.8
	landing_squash = 0.4
	hud.toast(reason, 4)
	sfx("land")
	burst(pip.position + Vector3(0, 0.5, 0), Color("f5e6cc"))
	save_game()

func begin_flight() -> void:
	flying = true
	boarded = false
	flight_time = 0
	sync_props()
	hud.toast("Toast Express, away!", 4)
	sfx("launch")
	save_game()

func update_flight(delta: float) -> void:
	flight_time += delta
	var u = clampf(flight_time / 3.1, 0, 1)
	# Aligned middle segment keeps toast and Pip entirely inside the carton window.
	var route = [Vector3(1.35, 1.47, -3.8), Vector3(2.35, 1.49, -2.65), Vector3(5.65, 1.49, 0.65), Vector3(8.5, 0.18, 2.8)]
	var p: Vector3
	if u < 0.20:
		var v = u / 0.20
		p = route[0].lerp(route[1], v)
		p.y += sin(v * PI) * 0.2
	elif u < 0.65:
		p = route[1].lerp(route[2], (u - 0.20) / 0.45)
	else:
		var v = (u - 0.65) / 0.35
		p = route[2].lerp(route[3], v)
		p.y += sin(v * PI) * 0.6
	toast.position = p
	toast.rotation.y = 0.79
	toast.rotation.z = sin(u * TAU) * (0.0 if reduced_motion or (u > 0.2 and u < 0.65) else 0.07)
	pip.position = p + Vector3(0, 0.19, 0)
	pip_art.rotation.y = 0.7
	if u >= 1:
		flying = false
		state.completed = true
		toast.rotation = Vector3.ZERO
		pip.position = Vector3(8.5, 0.38, 2.8)
		celebration_time = 0.0
		landing_squash = 0.65
		hud.toast("Special delivery! One very happy little Pip.", 3)
		sfx("complete")
		burst(pip.position + Vector3(0, 0.7, 0), Color("e5a54b"), 32)
		save_game()

func burst(pos: Vector3, color: Color, count: int = 12) -> void:
	if reduced_motion:
		count = 4
	for i in count:
		var n = sphere(Vector3.ONE * (0.045 + (i % 3) * 0.02), color, pos)
		add_child(n)
		var angle = i * TAU / count
		var dest = pos + Vector3(cos(angle), 0.3 + (i % 4) * 0.12, sin(angle)) * 0.65
		var tw = create_tween().set_parallel(true)
		tw.tween_property(n, "position", dest, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(n, "scale", Vector3.ZERO, 0.6)
		tw.chain().tween_callback(n.queue_free)

func save_game() -> void:
	# The earned stage clear is profile progress; replay and local reset only
	# change the active puzzle. Keep the two durable records separate.
	ever_completed = ever_completed or state.completed
	var data: Dictionary = {"format": "tiny_trouble.profile", "version": 1,
		"ever_completed": ever_completed, "puzzle": state.to_dict()}
	if _decode_save(data).is_empty():
		save_notice = "Could not save this puzzle state. Your last good checkpoint is still safe."
		return
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_notice = "Could not write the checkpoint. Your current session is still playable."
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK or _read_save(save_path + ".tmp").is_empty():
		save_notice = "Checkpoint write failed. Your last good checkpoint is still safe."
		return
	var absolute: String = ProjectSettings.globalize_path(save_path)
	# Never copy a corrupt primary over the valid backup used to recover it.
	# Stage the backup separately so a failed backup copy is also recoverable.
	if not _read_save(save_path).is_empty():
		var backup_error: Error = DirAccess.copy_absolute(absolute, absolute + ".bak.tmp")
		if backup_error == OK:
			if _read_save(save_path + ".bak.tmp").is_empty():
				backup_error = ERR_FILE_CORRUPT
			else:
				backup_error = DirAccess.rename_absolute(absolute + ".bak.tmp", absolute + ".bak")
		if backup_error != OK:
			save_notice = "Could not preserve the checkpoint backup. Your last good save is still safe."
			return
	var err: Error = DirAccess.rename_absolute(absolute + ".tmp", absolute)
	if err == OK:
		has_save = true
		save_count += 1
		if save_notice.begins_with("Could not") or save_notice.begins_with("Checkpoint write failed"):
			save_notice = ""
	else:
		save_notice = "Checkpoint write failed. You can keep playing and retry from pause."

func load_save() -> void:
	var primary: Dictionary = _read_save(save_path)
	var backup: Dictionary = _read_save(save_path + ".bak")
	# Check the backup even if the primary is missing. Also preserve a recorded
	# stage clear across either valid generation of the save.
	for record: Dictionary in [primary, backup]:
		if not record.is_empty():
			ever_completed = ever_completed or bool(record["ever_completed"])
	var selected: Dictionary = primary if not primary.is_empty() else backup
	if not selected.is_empty():
		state = selected["state"]
		has_save = true
		save_notice = "Recovered your last good checkpoint from the backup." if primary.is_empty() else ""
	elif FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak"):
		save_notice = "The saved breakfast could not be read. A fresh, safe adventure is ready."

func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 131072:
		return {}
	var contents: String = file.get_as_text()
	file.close()
	var parser: JSON = JSON.new()
	if parser.parse(contents) != OK:
		return {}
	return _decode_save(parser.data)

func _decode_save(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return {}
	var candidate: PuzzleState = Rules.new()
	# The first prototype wrote the puzzle directly. Accept those v1 saves and
	# migrate them into the profile envelope on the next successful write.
	if data.has("schema_version"):
		if candidate.restore(data):
			return {"state": candidate, "ever_completed": candidate.completed}
		return {}
	if data.size() != 4 or data.get("format") != "tiny_trouble.profile":
		return {}
	var version: Variant = data.get("version")
	if (typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT) or float(version) != 1.0:
		return {}
	if typeof(data.get("ever_completed")) != TYPE_BOOL or typeof(data.get("puzzle")) != TYPE_DICTIONARY:
		return {}
	if not candidate.restore(data["puzzle"]):
		return {}
	if candidate.completed and not bool(data["ever_completed"]):
		return {}
	return {"state": candidate, "ever_completed": bool(data["ever_completed"])}

func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume * 0.5))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(effects_volume))

func apply_text_size() -> void:
	if not is_instance_valid(hud): return
	hud.apply_text_scale(text_scale)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("comfort", "reduced_motion", reduced_motion)
	config.set_value("comfort", "text_scale", text_scale)
	config.set_value("sound", "music", music_volume)
	config.set_value("sound", "effects", effects_volume)
	for action in DEFAULT_KEYS:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				config.set_value("keys", action, ev.physical_keycode)
				break
	config.save(settings_path)

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(settings_path) != OK: return
	reduced_motion = bool(config.get_value("comfort", "reduced_motion", false))
	text_scale = finite_setting(config.get_value("comfort", "text_scale", 1.0), 1.0, 1.0, 1.25)
	music_volume = finite_setting(config.get_value("sound", "music", 0.55), 0.55, 0.0, 1.0)
	effects_volume = finite_setting(config.get_value("sound", "effects", 0.8), 0.8, 0.0, 1.0)
	for action in DEFAULT_KEYS:
		if config.has_section_key("keys", action):
			var code: Variant = config.get_value("keys", action)
			if typeof(code) != TYPE_INT or int(code) <= 0 or int(code) > 0x7FFFFF:
				continue
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey: InputMap.action_erase_event(action, ev)
			var ev = InputEventKey.new()
			ev.physical_keycode = int(config.get_value("keys", action))
			InputMap.action_add_event(action, ev)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var error = get_viewport().get_texture().get_image().save_png(capture_dir.path_join(name + ".png"))
	if error != OK: push_error("Could not save review capture: " + name)

func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null

func stop_audio() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await get_tree().create_timer(0.12).timeout

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		if not is_node_ready(): return
		if is_instance_valid(hud): hud.touch_controls.release_all()
		for action in DEFAULT_KEYS:
			if InputMap.has_action(action): Input.action_release(action)
		jump_buffer = 0
		if started:
			if not paused: on_command("pause", null)
			# Save synchronously before a mobile OS can suspend this process.
			# Each stage's existing serializer preserves its recovery policy.
			save_game()
		for child in get_children():
			if child is AudioStreamPlayer: child.stream_paused = true
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		if not is_node_ready(): return
		for child in get_children():
			if child is AudioStreamPlayer: child.stream_paused = false
		# Gameplay resumes only through the visible pause menu.
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		await stop_audio()
		get_tree().quit()

func finite_setting(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return fallback
	var numeric = float(value)
	return clampf(numeric, minimum, maximum) if is_finite(numeric) else fallback
