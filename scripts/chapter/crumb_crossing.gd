extends "res://scripts/main.gd"
## W01S01 owns its world/rules. The demo supplies proven input, settings, audio,
## toy primitives and Pip animation; its puzzle and save methods are overridden.
const StageRules = preload("res://scripts/chapter/crumb_state.gd")
const StageArt = preload("res://scripts/chapter/chapter_art.gd")
const ChapterProgress = preload("res://scripts/chapter/chapter_progress.gd")
const STAGE_ID = "W01S01"
const STAGE_TRAYS = {"sugar": Vector3(-8.5, 0.06, 3.2), "spoon": Vector3(-6.45, 0.06, 3.45)}
const BRIDGE_SOCKET = Vector3(-4.2, 0.11, 1.2)
const EXIT_POS = Vector3(1.8, 0.06, 1.2)
const FRIEND_POS = Vector3(-1.2, 0.06, -1.6)
var chapter_profile = ChapterProgress.new()
var friends: Node3D
var pinwheel: Node3D
var exit_flag: Node3D
var last_save_ok := true
var changing_scene := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	state = StageRules.new()
	if chapter_profile_path != "": chapter_profile.save_path = chapter_profile_path
	if capture_dir == "":
		capture_dir = ProjectSettings.globalize_path("res://evidence/crumb_crossing" if OS.has_feature("editor") else "user://captures/crumb_crossing")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): capture_dir = arg.trim_prefix("--evidence-dir=")
	configure_inputs()
	load_settings()
	load_save()
	build_world()
	build_audio()
	hud = HUD.new()
	add_child(hud)
	hud.command.connect(on_command)
	hud.set_bindings(binding_names())
	apply_text_size()
	sync_props(false)
	respawn()
	show_stage_title()

func build_world() -> void:
	add_child(Art.table())
	var world_environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d8c8ae")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dddde0")
	env.ambient_light_energy = 0.22
	world_environment.environment = env
	add_child(world_environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58, -28, 0)
	light.light_color = Color("fff5e8")
	light.light_energy = 0.58
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_max_distance = 55
	light.shadow_blur = 2.5
	add_child(light)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 130, 0)
	fill.light_color = Color("b4d3d4")
	fill.light_energy = 0.12
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.position = Vector3(-4.5, 0, 1.5) + Vector3(10, 16, 22)
	add_child(camera)
	camera.look_at(Vector3(-4.5, 0, 1.5))
	camera.current = true
	add_child(StageArt.paper_tray())
	props["sugar"] = StageArt.sugar_cube()
	props["spoon"] = Art.prop("spoon")
	for kind in props:
		props[kind].name = kind.capitalize()
		add_child(props[kind])
	var milk = cube(Vector3(2.0, 0.055, 11.3), Color("e5eff0"), Vector3(-4.2, 0.025, 0))
	milk.material_override.roughness = 0.24
	add_child(milk)
	for z in [-5.35, 5.35]:
		add_child(sphere(Vector3(2.0, 0.06, 1.5), Color("e5eff0"), Vector3(-4.2, 0.03, z)))
	for pos in [Vector3(-5.95, 0.015, 1.2), Vector3(-2.25, 0.015, 1.2)]:
		add_child(cylinder(1.28, 0.08, Color("f5e6cc"), pos))
		add_child(ring(1.10, 0.035, Color("4a9290"), pos + Vector3(0, 0.045, 0)))
	for x in [-5.28, -2.75]:
		add_child(sphere(Vector3(0.32, 0.39, 0.68), Color("4a9290"), Vector3(x, 0.22, 1.2)))
	build_teacup()
	var marker = Node3D.new()
	marker.position = BRIDGE_SOCKET
	marker.add_child(ring(0.56, 0.033, Color("4a9290"), Vector3(0, 0.015, 0)))
	add_child(marker)
	markers["bridge"] = marker
	friends = StageArt.crumb_friends()
	friends.position = FRIEND_POS
	add_child(friends)
	pinwheel = StageArt.paper_pinwheel()
	pinwheel.position = Vector3(-6.1, 0.06, -2.3)
	add_child(pinwheel)
	exit_flag = Node3D.new()
	exit_flag.position = EXIT_POS
	exit_flag.add_child(cylinder(0.7, 0.12, Color("f5e6cc"), Vector3.ZERO))
	exit_flag.add_child(cube(Vector3(0.05, 1.9, 0.05), Color("384657"), Vector3(0, 0.95, 0)))
	exit_flag.add_child(cube(Vector3(0.85, 0.45, 0.045), Color("4a9290"), Vector3(0.42, 1.68, 0)))
	add_child(exit_flag)
	pip = Node3D.new()
	pip.name = "Pip"
	pip_art = Art.pip()
	pip.add_child(pip_art)
	add_child(pip)
	shadow = cylinder(0.31, 0.003, Color(0.2, 0.24, 0.25, 0.22), Vector3.ZERO)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_child(shadow)
	target_ring = ring(0.55, 0.033, Color("fff3b6"), Vector3.ZERO)
	add_child(target_ring)

func _process(delta: float) -> void:
	var now = Time.get_ticks_usec()
	if previous_frame_usec > 0 and started and not paused and intro_time > 2 and frame_samples.size() < 60000:
		frame_samples.append((now - previous_frame_usec) / 1000.0)
		peak_draw_calls = maxi(peak_draw_calls, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
		peak_objects = maxi(peak_objects, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)))
	previous_frame_usec = now
	if paused: return
	t += delta
	recovery_time = maxf(0, recovery_time - delta)
	resize_pose = maxf(0, resize_pose - delta)
	landing_squash = maxf(0, landing_squash - delta * 3)
	if started:
		intro_time += delta
		move_pip(delta)
		update_target()
		update_objective()
	animate_pip(delta)
	if state.carried == "spoon":
		props["spoon"].position = pip.position + Vector3(0, 0.94, 0) + pip_art.basis.z * 0.35
		props["spoon"].rotation.y = pip_art.rotation.y
	if target != "":
		target_ring.position = props[target].position + Vector3(0, 0.035, 0)
		target_ring.scale = Vector3.ONE * (0.65 + SCALE_VALUES[int(state.sizes[target])] * 0.4)
		target_ring.visible = started and in_range(target, 4.7)
	shadow.position = Vector3(pip.position.x, surface_height(pip.position) + 0.015, pip.position.z)
	shadow.scale = Vector3.ONE * clampf(1.0 - pip.position.y * 0.12, 0.4, 1.0)
	var center = Vector3(-4.5 + clampf((pip.position.x + 4.5) * 0.13, -0.65, 0.65), 0, 1.5)
	camera.position = camera.position.lerp(center + Vector3(10, 16, 22), minf(delta * 1.8, 1))
	camera.look_at(camera.position - Vector3(10, 16, 22))
	if not reduced_motion:
		var close = pip.position.distance_to(FRIEND_POS) < 2.5
		for child in friends.get_children():
			if child is Node3D:
				child.rotation.z = sin(t * (5.0 if close else 1.8) + child.get_index()) * (0.17 if close else 0.035)
		var rotor = pinwheel.get_node_or_null("Rotor")
		if rotor: rotor.rotation.z += delta * (3.2 if pip.position.distance_to(pinwheel.position) < 2.5 else 0.22)
		if decoration_react:
			decoration_react.rotation.z = sin(t * 4.0) * 0.12

func move_pip(delta: float) -> void:
	if state.completed:
		walking = false
		celebration_time += delta
		pip.position.y = surface_height(pip.position) + (0.0 if reduced_motion else absf(sin(celebration_time * 7)) * 0.16)
		if celebration_time >= 1.2:
			paused = true
			show_stage_complete()
		return
	jump_buffer = maxf(0, jump_buffer - delta)
	var axis = movement_input()
	var right = camera.global_basis.x
	right.y = 0
	var back = camera.global_basis.z
	back.y = 0
	var direction = right.normalized() * axis.x + back.normalized() * axis.y
	walking = direction.length() > 0.05 and recovery_time <= 0
	if walking:
		var displacement = direction * (2.7 if state.carried == "" else 2.3) * delta
		var steps = maxi(1, int(ceil(displacement.length() / 0.10)))
		for step in steps:
			var previous = pip.position
			var next = previous + displacement / steps
			next.x = clampf(next.x, -10.51, 3.8)
			next.z = clampf(next.z, -5.1, 5.1)
			if not obstructed(next):
				pip.position.x = next.x
				pip.position.z = next.z
			else:
				var nx = Vector3(next.x, pip.position.y, pip.position.z)
				var nz = Vector3(pip.position.x, pip.position.y, next.z)
				if not obstructed(nx): pip.position.x = next.x
				elif not obstructed(nz): pip.position.z = next.z
			if surface_height(pip.position) < -1:
				recover("A tiny splash. Pip and the spoon are safe at the checkpoint.")
				return
			if not state.sugar_passed and previous.x <= -7.65 and pip.position.x > -7.65:
				var old_cp = state.checkpoint
				apply_result(state.pass_sugar(), "checkpoint")
				checkpoint_feedback(old_cp)
			if state.carried == "spoon" and not state.handle_passed and absf(pip.position.x + 6.3) < 0.27 and absf(pip.position.z - 1.2) < 0.55:
				apply_result(state.pass_handle(), "place")
				burst(pip.position + Vector3(0, 0.6, 0), Color("e5a54b"))
		pip_art.rotation.y = lerp_angle(pip_art.rotation.y, atan2(direction.x, direction.z), minf(delta * 14, 1))
	var floor_y = surface_height(pip.position)
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
	if not exploring and state.checkpoint == 2 and Vector2(pip.position.x - EXIT_POS.x, pip.position.z - EXIT_POS.z).length() < 0.75:
		var result = state.finish()
		if result.ok:
			celebration_time = 0
			landing_squash = 0.5
			save_game()
			sfx("complete")
			burst(pip.position + Vector3(0, 0.7, 0), Color("e5a54b"), 28)
			hud.toast("One small spoon. One very big step." if last_save_ok else "Crossing complete. Chapter progress could not be saved yet.", 5)

func obstructed(pos: Vector3) -> bool:
	if Vector2(pos.x + 8.4, pos.z + 0.5).length() < 1.38: return true
	if pos.x >= -11.26 and pos.x <= -6.94:
		if absf(pos.z - 1.8) < 0.46 or absf(pos.z - 4.6) < 0.46: return true
	if absf(pos.x + 10.8) < 0.46 and pos.z > 1.34 and pos.z < 5.06: return true
	var sugar = STAGE_TRAYS["sugar"]
	# A shrinking cube remains solid until its visible body has cleared the route.
	var ratio = maxf(size_ratio("sugar", int(state.sizes["sugar"])), props["sugar"].scale.x)
	var half = 0.675 * ratio + 0.40
	return absf(pos.x - sugar.x) < half and absf(pos.z - sugar.z) < half

func surface_height(pos: Vector3) -> float:
	if state.bridge_placed and absf(pos.z - 1.2) < 0.38 and pos.x > -5.65 and pos.x < -1.4:
		return 0.52
	if absf(pos.x + 4.2) < 1.05:
		return 0.52 if state.bridge_placed and absf(pos.z - 1.2) < 0.59 else -2.0
	return 0.08 if pos.x < -7.4 and pos.z > 1.8 and pos.z < 4.6 else 0.06

func size_ratio(kind: String, size_index: int) -> float:
	# The small sugar cube leaves room for Pip's full silhouette inside the tray.
	return 0.35 if kind == "sugar" and size_index == 0 else SCALE_VALUES[size_index]

func prop_position(kind: String) -> Vector3:
	if state.carried == kind: return pip.position + Vector3(0, 0.94, 0)
	return BRIDGE_SOCKET if kind == "spoon" and state.sockets[kind] == "bridge" else STAGE_TRAYS[kind]

func sync_props(animate: bool = true) -> void:
	for kind in props:
		var node: Node3D = props[kind]
		if prop_tweens.has(kind) and prop_tweens[kind].is_valid(): prop_tweens[kind].kill()
		node.rotation = Vector3(0, PI / 2 if kind == "spoon" and state.sockets[kind] == "tray" else 0, 0)
		var ratio = size_ratio(kind, int(state.sizes[kind]))
		if animate and not reduced_motion:
			var tw = create_tween().set_parallel(true)
			tw.tween_property(node, "scale", Vector3.ONE * ratio, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(node, "position", prop_position(kind), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			prop_tweens[kind] = tw
		else:
			node.scale = Vector3.ONE * ratio
			node.position = prop_position(kind)
	markers["bridge"].visible = state.sockets["spoon"] != "bridge"

func resize_target(new_size: int) -> void:
	if new_size < 0 or new_size > 2: return reject("Choose small, normal, or large.")
	if not props.has(target) or not in_range(target, 4.0): return reject("Move a little closer to the prop.")
	var old_size = int(state.sizes[target])
	if target == "sugar" and new_size == 2: return reject("Small or normal fits inside this paper tray.")
	if target == "sugar" and new_size > old_size:
		var half = 0.675 * size_ratio("sugar", new_size) + 0.40
		var sugar = STAGE_TRAYS["sugar"]
		if absf(pip.position.x - sugar.x) < half and absf(pip.position.z - sugar.z) < half:
			return reject("Step out of the sugar cube's growing space first.")
	if target == "spoon":
		if state.bridge_placed and new_size < 2 and surface_height(pip.position) > 0.4:
			return reject("Step off the spoon before changing your bridge.")
		if new_size == 2 and state.sockets["spoon"] == "tray":
			return reject("The saucers have room for a big bridge. Carry the small spoon there first.")
	var before = state.checkpoint
	var result = state.resize(target, new_size)
	apply_result(result, "resize_up" if new_size > old_size else "resize_down")
	if result.ok:
		resize_pose = 0.5
		sync_props()
		if new_size != old_size: burst(props[target].position + Vector3(0, 0.4, 0), Color("e5a54b"))
		checkpoint_feedback(before)

func interact() -> void:
	if state.carried == "spoon":
		var socket = "bridge" if pip.position.distance_to(BRIDGE_SOCKET) < 1.65 else "tray"
		apply_result(state.place(socket), "place")
		sync_props()
	elif pip.position.distance_to(FRIEND_POS) < 1.35:
		apply_result(state.discover(), "discovery")
		burst(FRIEND_POS + Vector3(0, 0.4, 0), Color("e5a54b"))
	elif props.has(target) and in_range(target, 2.1):
		apply_result(state.interact(target), "pickup")
		sync_props()
	else:
		reject("Step closer to pick up the small spoon.")

func cycle_target() -> void:
	var candidates: Array[String] = []
	for kind in props:
		if in_range(kind, 4.4): candidates.append(kind)
	if candidates.is_empty(): return
	target = candidates[(candidates.find(target) + 1) % candidates.size()]
	sfx("place")

func update_target() -> void:
	if state.completed:
		hud.update_target("Crossing complete", "Your first bridge is ready for another visit.", -1)
		return
	if not in_range(target, 4.7):
		for kind in props:
			if in_range(kind, 4.4): target = kind
	var help_text = "1 / Q  Make a little room beside the cube."
	if target == "spoon":
		help_text = "1 / Q  Shrink it, then E to carry."
		if state.carried == "spoon": help_text = "E  Place near the saucers, or return to its tray."
		elif state.sockets["spoon"] == "bridge":
			help_text = "3 / F  Grow a bridge across the milk." if not state.bridge_placed else "A bridge made from a spoon. Walk across!"
	if state.carried == "" and pip.position.distance_to(FRIEND_POS) < 1.35:
		hud.update_target("Crumb friends", "E  Say hello to the little breakfast club.", -1)
	else:
		hud.update_target("Sugar cube" if target == "sugar" else "Teaspoon", help_text, int(state.sizes[target]))

func current_goal() -> String:
	if not state.sugar_passed: return "Shrink the sugar cube. Slip around it and out of the paper tray."
	if not state.handle_passed: return "Carry a small teaspoon through the cup handle."
	if not state.bridge_placed: return "Set the spoon between the saucers, then make it big."
	return "Cross your spoon bridge and find the teal flag."

func update_objective() -> void:
	hud.objective.text = "Crumb Crossing"
	hud.progress.text = "BREAKFAST TABLE  /  1 OF 5"
	hud.subgoal.text = current_goal() if not state.completed else "The first little crossing is complete."

func show_hint() -> void:
	var hints: Array[String]
	if not state.sugar_passed:
		hints = ["The cube leaves very little room.", "A smaller cube means a wider path.", "Select the sugar cube, press 1, then walk around its upper or lower edge."]
	elif not state.handle_passed:
		hints = ["That teaspoon could reach the far saucer.", "A portable spoon can fit through the cup handle.", "Walk to the teaspoon beside the tray. Press 1, then E. Carry it through the round handle."]
	elif not state.bridge_placed:
		hints = ["The saucers make a good resting place.", "A small spoon is easy to carry; a big one is easy to cross.", "Near the glowing saucer marker, press E to place the spoon. Step back, then press 3."]
	else:
		hints = ["Your route is open.", "Follow the spoon handle toward the teal flag.", "Cross at the center of the spoon, then walk to the flag on the far side."]
	hud.toast(hints[mini(hint_step, hints.size() - 1)], 7)
	hint_step += 1

func checkpoint_feedback(previous: int) -> void:
	if state.checkpoint <= previous: return
	hint_step = 0
	hud.toast("Past the sugar. Checkpoint saved." if state.checkpoint == 1 else "Your spoon bridge is ready. Checkpoint saved.", 5)
	sfx("checkpoint")
	burst(pip.position + Vector3(0, 0.65, 0), Color("4a9290"))
	save_game()

func respawn() -> void:
	pip.position = [Vector3(-10, 0.08, 3.2), Vector3(-6.8, 0.06, 3.5), Vector3(-5.8, 0.06, 1.2)][state.checkpoint]
	if state.completed: pip.position = EXIT_POS + Vector3(0.35, 0, 0)
	pip.position.y = surface_height(pip.position)
	pip_art.rotation.y = 0.4
	vertical_speed = 0
	jump_buffer = 0
	target = "sugar" if state.checkpoint == 0 else "spoon"

func save_game() -> void:
	last_save_ok = chapter_profile.complete_stage_with_snapshot(STAGE_ID, state.to_dict()) if state.completed else chapter_profile.save_stage(STAGE_ID, state.to_dict())
	ever_completed = chapter_profile.is_completed(STAGE_ID)
	if not last_save_ok and is_instance_valid(hud):
		hud.toast("Your crossing is safe for this visit, but it could not be saved.", 6)

func load_save() -> void:
	chapter_profile.load_profile()
	var snapshot = chapter_profile.stage_snapshot(STAGE_ID)
	has_save = not snapshot.is_empty() and state.restore(snapshot)
	ever_completed = chapter_profile.is_completed(STAGE_ID)
	if not snapshot.is_empty() and not has_save:
		save_notice = "That stage save needs a fresh start. Your earned chapter progress is safe."

func show_stage_title() -> void:
	hud.clear_menu("title")
	hud.menu_label("BREAKFAST TABLE · FIRST STEPS", 12, HUD.TEAL)
	hud.menu_label("Crumb Crossing", 38)
	hud.menu_label("A sugar cube in the way.\nA spoon full of possibilities.", 18)
	hud.menu_box.add_child(hud.button("Continue crossing" if has_save else "Take a little step   →", func(): on_command("start", null)))
	if has_save: hud.menu_box.add_child(hud.button("Start this stage again", func(): on_command("new", null)))
	hud.menu_box.add_child(hud.button("Matchbox Workshop", func(): on_command("workshop", null)))
	update_objective()
	update_target()

func show_stage_complete() -> void:
	hud.clear_menu("complete")
	hud.menu_label("ONE SMALL SPOON. ONE BIG STEP.", 12, HUD.TEAL)
	hud.menu_label("Crumb Crossing\ncomplete!", 34)
	hud.menu_label("The little breakfast club waves you on." if state.discovered else "Your very first bridge is ready for another visit.", 18)
	hud.menu_box.add_child(hud.button("Back to the workshop", func(): on_command("workshop", null)))
	hud.menu_box.add_child(hud.button("Keep exploring", func(): on_command("explore", null)))
	hud.menu_box.add_child(hud.button("Play this stage again", func(): on_command("new", null)))

func on_command(action: String, value: Variant) -> void:
	match action:
		"start":
			if hud.rotation_guard.visible: return
			started = true
			paused = false
			hud.hide_menu()
			if state.completed:
				show_stage_complete()
				paused = true
			else:
				hud.toast(save_notice if save_notice != "" else "Good morning, Pip. Let's make a little room.", 5)
		"new":
			state = StageRules.new()
			chapter_profile.reset_stage_snapshot(STAGE_ID)
			exploring = false
			hint_step = 0
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
			navigation.switch_scene(self, "res://scenes/chapter/workshop.tscn", chapter_profile.save_path, settings_path)
		"explore":
			exploring = true
			state.reset_checkpoint()
			sync_props(false)
			respawn()
			super.on_command("resume", null)
		_:
			if action == "reset": hint_step = 0
			super.on_command(action, value)
