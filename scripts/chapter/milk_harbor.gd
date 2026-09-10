extends "res://scripts/chapter/chapter_stage.gd"
## W01S03: a cereal raft, a shallow milk ridge, and a cargo-size decision.
## Controlled travel follows visible stops; interrupted trips restore a safe stop.
const StageRules = preload("res://scripts/chapter/harbor_state.gd")
const StageArt = preload("res://scripts/chapter/harbor_art.gd")
const STAGE_ID = "W01S03"
const WATER_Y := 0.42
const NEAR_X := -3.10
const FAR_X := 3.10
const NEAR_BANK = Vector3(-5.55, 0.06, 0)
const FAR_BANK = Vector3(5.6, 0.06, 1.30)
const DOCK_HINGE = Vector3(4.9, 0.90, 1.30)
const EXIT_POS = Vector3(6.45, 0.06, 1.30)
const FRIEND_POS = Vector3(-6.2, 0.06, 2.05)
var boat_x := NEAR_X
var voyage_tween: Tween
var rider_tween: Tween
var dock_tween: Tween
var changing_rider := false
var spoon_dock: Node3D
var dock_leaf: Node3D
var friends: Node3D
var far_friends: Node3D
var exit_flag: Node3D
var ripples: Node3D

func stage_definition() -> Dictionary:
	return {"id": STAGE_ID, "slug": "milk_harbor", "title": "Milk Harbor",
		"interaction_label": "Board / Sail", "kicker": "BREAKFAST TABLE · A GENTLE VOYAGE",
		"description": "A cereal loop. A precious little parcel.\nA whole puddle of possibility.",
		"opening": "That cereal loop could carry a tiny captain.",
		"complete_kicker": "LESS CARGO. MORE ADVENTURE.",
		"complete_text": "The cereal crew welcomes its newest captain ashore."}

func create_stage_rules() -> RefCounted:
	return StageRules.new()

func load_save() -> void:
	super.load_save()
	if has_save and state.recovered_motion:
		save_notice = "Your voyage paused between stops. Pip and the parcel are safe at the last mooring."

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
	camera.size = 14.0
	camera.position = Vector3(-0.2, 0, 0.4) + Vector3(10, 16, 22)
	add_child(camera)
	camera.look_at(Vector3(-0.2, 0, 0.4))
	camera.current = true
	# A shallow ceramic serving dish contains the milk, above the tabletop.
	add_child(cube(Vector3(9.7, 0.08, 11.4), Color("e0e9e2"), Vector3(0, 0.03, 0)))
	for x in [-4.87, 4.87]:
		add_child(cube(Vector3(0.16, 0.49, 11.4), Color("f5e6cc"), Vector3(x, 0.26, 0)))
	for z in [-5.7, 5.7]:
		add_child(cube(Vector3(9.8, 0.49, 0.16), Color("f5e6cc"), Vector3(0, 0.26, z)))
	var milk = cube(Vector3(9.6, 0.035, 11.3), Color("c4d9db"), Vector3(0, WATER_Y - 0.0175, 0))
	milk.name = "MilkSurface"
	milk.material_override.albedo_color.a = 0.78
	milk.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	milk.material_override.roughness = 0.28
	add_child(milk)
	# Submerged warm crumbs trace the real shallow stop without a debug label.
	var shoal = Node3D.new()
	shoal.name = "ShallowRidge"
	add_child(shoal)
	for index in range(18):
		var z: float = -5.25 + index * 0.62
		shoal.add_child(sphere(Vector3(0.62, 0.32, 0.66), Color("b99152"), Vector3(0.07 * sin(index * 2.1), 0.04, z)))
	for x in [-0.34, 0.34]:
		add_child(cube(Vector3(0.045, 0.012, 10.6), Color("dbd2ad"), Vector3(x, WATER_Y + 0.002, 0)))
	ripples = Node3D.new()
	ripples.name = "MilkRipples"
	add_child(ripples)
	for side in [-1.0, 1.0]:
		for scale_factor in [1.0, 1.18]:
			var a = Vector3(-0.65, 0, side * 1.63 * scale_factor)
			var b = Vector3(0, 0, side * 1.73 * scale_factor)
			var c = Vector3(0.65, 0, side * 1.63 * scale_factor)
			for segment in [[a, b], [b, c]]:
				var line = Art._line(ripples, segment[0], segment[1], 0.015, Color("94b8bd"))
				line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props["cereal"] = StageArt.cereal_raft()
	props["cargo"] = StageArt.cargo_parcel()
	for kind in props: add_child(props[kind])
	spoon_dock = StageArt.folded_spoon_dock()
	spoon_dock.position = DOCK_HINGE
	# The fixed pin rises from the ceramic rim to the spoon hinge.
	var pin_height: float = DOCK_HINGE.y - 0.50
	add_child(cylinder(0.075, pin_height, Color("4a9290"), DOCK_HINGE - Vector3(0, pin_height * 0.5, 0)))
	add_child(spoon_dock)
	dock_leaf = spoon_dock.get_node("HingedDock")
	friends = StageArt.cereal_friends()
	friends.position = FRIEND_POS
	add_child(friends)
	far_friends = StageArt.cereal_friends()
	far_friends.position = Vector3(6.35, 0.06, -1.7)
	add_child(far_friends)
	for bank in [NEAR_BANK, FAR_BANK]:
		add_child(cylinder(0.55, 0.02, Color("4a9290"), bank - Vector3(0, 0.02, 0)))
	exit_flag = Node3D.new()
	exit_flag.position = EXIT_POS
	exit_flag.add_child(cylinder(0.44, 0.08, Color("f5e6cc"), Vector3(0, 0.04, 0)))
	exit_flag.add_child(cube(Vector3(0.05, 1.65, 0.05), Color("384657"), Vector3(0, 0.825, 0)))
	exit_flag.add_child(cube(Vector3(0.7, 0.4, 0.04), Color("4a9290"), Vector3(0.35, 1.4, 0)))
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
	refresh_boat()
	if started:
		intro_time += delta
		move_pip(delta)
		update_target()
		update_objective()
	animate_pip(delta)
	if props.has(target):
		target_ring.position = props[target].position + Vector3(0, 0.025, 0)
		target_ring.scale = Vector3.ONE * (0.45 if target == "cargo" else 1.45)
		target_ring.visible = started and not state.completed and not in_transit() and in_range(target, 4.8)
	shadow.position = Vector3(pip.position.x, maxf(0.06, surface_height(pip.position)) + 0.01, pip.position.z)
	shadow.scale = Vector3.ONE * clampf(1.0 - (pip.position.y - maxf(0.06, surface_height(pip.position))) * 0.2, 0.4, 1)
	var center = Vector3(clampf(pip.position.x * 0.14, -0.8, 0.8), 0, 0.4)
	camera.position = camera.position.lerp(center + Vector3(10, 16, 22), minf(delta * 1.8, 1))
	camera.look_at(camera.position - Vector3(10, 16, 22))
	if not reduced_motion:
		for crew in [friends, far_friends]:
			for friend in crew.get_children():
				if friend is Node3D:
					var arm = friend.get_node_or_null("WaveArm")
					if arm: arm.rotation.z = sin(t * (6.0 if state.phase == "far" else 2.0) + friend.get_index()) * 0.26

func in_transit() -> bool:
	return state.phase in ["to_shoal", "to_far"]

func busy() -> bool:
	if in_transit() or changing_rider: return true
	if is_instance_valid(dock_tween) and dock_tween.is_valid() and dock_tween.is_running(): return true
	for tw in prop_tweens.values():
		if tw.is_valid() and tw.is_running(): return true
	return false

func deck_height() -> float:
	return props["cereal"].position.y + 0.30 * props["cereal"].scale.x

func aboard_position() -> Vector3:
	return Vector3(boat_x - 0.7, deck_height(), 0)

func refresh_boat() -> void:
	var cargo_scale: float = props["cargo"].scale.x
	var draft: float = lerpf(0.10, 0.30, clampf((cargo_scale - 0.5) * 2, 0, 1)) if cargo_scale <= 1 else lerpf(0.30, 0.40, clampf(cargo_scale - 1, 0, 1))
	# The hull cannot sink through the ceramic floor. Heavy loads rise gently
	# onto the actual crumb ridge before stopping at its shallow mooring.
	var y: float = maxf(WATER_Y - draft, 0.075)
	if cargo_scale > 0.55:
		var shoal_proximity = 1.0 - smoothstep(1.6, 2.0, absf(boat_x))
		y = maxf(y, lerpf(y, 0.20, shoal_proximity))
	if int(state.sizes["cereal"]) != 2: y = 0.15
	props["cereal"].position = Vector3(boat_x, y, 0)
	ripples.position = Vector3(boat_x, WATER_Y + 0.007, 0)
	ripples.visible = int(state.sizes["cereal"]) == 2
	props["cargo"].position = Vector3(boat_x + 0.18 * props["cereal"].scale.x, deck_height(), 0)
	if state.aboard and not changing_rider:
		pip.position = aboard_position()
		vertical_speed = 0
		walking = false

func sync_props(animate: bool = true) -> void:
	for tw in [voyage_tween, rider_tween, dock_tween]:
		if is_instance_valid(tw) and tw.is_valid(): tw.kill()
	changing_rider = false
	flying = false
	boat_x = FAR_X if state.phase == "far" else (0.0 if state.phase == "shoal" else NEAR_X)
	for kind in props:
		if prop_tweens.has(kind) and prop_tweens[kind].is_valid(): prop_tweens[kind].kill()
		var ratio: float = SCALE_VALUES[int(state.sizes[kind])]
		if animate and not reduced_motion:
			var tw = create_tween()
			tw.tween_property(props[kind], "scale", Vector3.ONE * ratio, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			prop_tweens[kind] = tw
		else: props[kind].scale = Vector3.ONE * ratio
	dock_leaf.rotation.z = deployed_dock_angle() if state.dock_open else -PI / 2
	refresh_boat()

func deployed_dock_angle() -> float:
	# The bowl underside clears the cereal ring; its top becomes the hop's
	# small landing, with the handle descending toward the dish rim.
	return -asin((1.10 - DOCK_HINGE.y) / 2.2)

func resize_target(new_size: int) -> void:
	if new_size < 0 or new_size > 2: return reject("Choose small, normal, or large.")
	if not props.has(target) or not in_range(target, 4.5): return reject("Move a little closer to the raft or parcel.")
	if busy(): return reject("Let Pip and the raft settle at the next stop first.")
	var old_size = int(state.sizes[target])
	if target == "cargo" and new_size > old_size:
		var parcel: Vector3 = props["cargo"].position
		var half: float = 0.29 * SCALE_VALUES[new_size] + 0.40
		if absf(pip.position.x - parcel.x) < half and absf(pip.position.z - parcel.z) < half:
			return reject("Give the growing parcel a little room.")
	var before = state.checkpoint
	var result = state.resize(target, new_size)
	apply_result(result, "resize_up" if new_size > old_size else "resize_down")
	if result.ok:
		resize_pose = 0.5
		sync_props()
		if new_size != old_size: burst(props[target].position + Vector3(0, 0.3, 0), Color("e5a54b"))
		checkpoint_feedback(before)

func interact() -> void:
	if busy(): return reject("A gentle voyage. Wait until the raft settles.")
	if state.aboard:
		if state.phase == "far":
			var result = state.disembark()
			apply_result(result, "place")
			if result.ok: move_rider(false)
		else:
			var result = state.depart()
			apply_result(result, "place")
			if result.ok: begin_voyage()
		return
	for pos in [FRIEND_POS, far_friends.position]:
		if pip.position.distance_to(pos) < 1.4:
			apply_result(state.discover(), "discovery")
			burst(pos + Vector3(0, 0.4, 0), Color("e5a54b"))
			return
	var bank: Vector3 = FAR_BANK if state.phase == "far" else NEAR_BANK
	if pip.position.distance_to(bank) < 1.25:
		var result = state.board()
		apply_result(result, "pickup")
		if result.ok:
			target = "cargo"
			move_rider(true)
	else: reject("Stand at the teal mooring beside the raft, then press E.")

func move_rider(onto_boat: bool) -> void:
	changing_rider = true
	flying = true
	walking = false
	var start = pip.position
	var finish = aboard_position() if onto_boat else FAR_BANK
	var far_side: bool = state.phase == "far"
	var corner = Vector3(2.78, 1.18, 1.30)
	var rim = Vector3(4.91, 1.05, 1.30)
	var route = [start, rim, corner, finish] if onto_boat else [start, corner, rim, finish]
	pip_art.rotation.y = -PI / 2 if onto_boat and far_side else PI / 2
	rider_tween = create_tween()
	rider_tween.tween_method(func(u: float):
		if far_side:
			var segment: int = mini(2, int(u * 3.0))
			var progress: float = clampf(u * 3.0 - segment, 0, 1)
			pip.position = route[segment].lerp(route[segment + 1], progress)
			pip.position.y += sin(progress * PI) * 0.20
		else:
			pip.position = start.lerp(finish, u)
			pip.position.y += sin(u * PI) * 0.6, 0.0, 1.0, 1.25 if far_side else 0.7)
	rider_tween.tween_callback(func():
		changing_rider = false
		flying = false
		pip.position = aboard_position() if state.aboard else finish
		landing_squash = 0.35
		sfx("land")
		save_game())

func begin_voyage() -> void:
	var destination: float = 0.0 if state.phase == "to_shoal" else FAR_X
	voyage_tween = create_tween()
	voyage_tween.tween_property(self, "boat_x", destination, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	voyage_tween.tween_callback(func():
		var before = state.checkpoint
		apply_result(state.arrive(), "checkpoint")
		refresh_boat()
		checkpoint_feedback(before)
		if state.dock_open:
			dock_tween = create_tween()
			dock_tween.tween_property(dock_leaf, "rotation:z", deployed_dock_angle(), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			sfx("place"))

func _unhandled_input(event: InputEvent) -> void:
	if started and not paused and state.aboard and event.is_action_pressed("jump"):
		reject("Stay steady, little captain. E sails or steps ashore at the dock.")
		return
	super._unhandled_input(event)

func surface_height(pos: Vector3) -> float:
	if absf(pos.x - boat_x) <= 1.15 and absf(pos.z) <= 0.70 and int(state.sizes["cereal"]) == 2: return deck_height()
	if state.dock_open and absf(cos(dock_leaf.rotation.z)) > 0.2:
		var height = DOCK_HINGE.y + (pos.x - DOCK_HINGE.x) * tan(dock_leaf.rotation.z)
		var local = dock_leaf.to_local(Vector3(pos.x, height, pos.z))
		if local.x >= -2.2 and local.x <= 0 and absf(local.z) < 0.55:
			return height
	return -2.0 if absf(pos.x) < 4.98 else 0.06

func obstructed(pos: Vector3) -> bool:
	if surface_height(pos) > pip.position.y + 0.23: return true
	# Free walking meets the ceramic wall before Pip's feet or body enter it.
	# The authored boarding hop clears its top; a jump into milk still recovers.
	if absf(pos.x) >= 4.39 and absf(pos.x) <= 5.35 and pos.y < 0.51: return true
	for crew in [friends, far_friends]:
		if Vector2(pos.x - crew.position.x, pos.z - crew.position.z).length() < 0.75: return true
	if not state.dock_open and absf(pos.x - DOCK_HINGE.x) < 0.42 and absf(pos.z - DOCK_HINGE.z) < 0.9: return true
	return false

func move_pip(delta: float) -> void:
	if changing_rider or state.aboard: return
	if state.completed:
		walking = false
		celebration_time += delta
		pip.position.y = surface_height(pip.position) + (0.0 if reduced_motion else absf(sin(celebration_time * 7)) * 0.16)
		if celebration_time >= 1.2:
			paused = true
			show_stage_complete()
		return
	jump_buffer = maxf(0, jump_buffer - delta)
	var axis = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.get_connected_joypads().size() > 0:
		var joy = Input.get_connected_joypads()[0]
		var stick = Vector2(Input.get_joy_axis(joy, JOY_AXIS_LEFT_X), Input.get_joy_axis(joy, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2: axis = stick.limit_length()
	var right = camera.global_basis.x
	right.y = 0
	var back = camera.global_basis.z
	back.y = 0
	var direction = right.normalized() * axis.x + back.normalized() * axis.y
	walking = direction.length() > 0.05 and recovery_time <= 0
	if walking:
		var displacement = direction * 2.7 * delta
		var steps = maxi(1, int(ceil(displacement.length() / 0.10)))
		for step in steps:
			var next = pip.position + displacement / steps
			next.x = clampf(next.x, -8.2, 8.2)
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
				recover("A tiny splash. Pip, the raft and the parcel are safe at the last mooring.")
				return
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
	else: pip.position.y = floor_y
	if not exploring and pip.position.distance_to(EXIT_POS) < 0.65:
		var result = state.finish()
		if result.ok:
			celebration_time = 0
			save_game()
			sfx("complete")
			burst(pip.position + Vector3(0, 0.7, 0), Color("e5a54b"), 28)
			hud.toast("Welcome ashore, little captain." if last_save_ok else "Voyage complete. Chapter progress could not be saved yet.", 5)

func cycle_target() -> void:
	target = "cargo" if target == "cereal" else "cereal"
	sfx("place")

func update_target() -> void:
	if state.completed:
		hud.update_target("Safe in Milk Harbor", "The cereal crew is ready for another visit.", -1)
		return
	if in_transit() or changing_rider:
		hud.update_target("A gentle voyage", "Pip and the parcel ride together. R returns to the last mooring.", -1)
		return
	for crew in [friends, far_friends]:
		if not state.aboard and pip.position.distance_to(crew.position) < 1.4:
			hud.update_target("Cereal crew", "E  Say hello to the little harbor helpers.", -1)
			return
	if state.aboard:
		var prompt = "E  Push off toward the shallow ridge."
		if state.phase == "shoal": prompt = "E  Continue through the shallows." if state.cargo_clear() else "1 / Q  A smaller parcel lets the raft float higher."
		elif state.phase == "far": prompt = "E  Hop ashore along the spoon dock."
		if target == "cereal" and state.phase == "shoal" and not state.cargo_clear():
			prompt = "Tab  Select the parcel to lighten the raft."
		hud.update_target("Cargo parcel" if target == "cargo" else "Cereal raft", prompt, int(state.sizes[target]))
	else:
		hud.update_target("Cereal raft" if target == "cereal" else "Cargo parcel", "3 / F  Grow a raft, then E at the teal mooring to board." if target == "cereal" else "1 / Q  A lighter parcel means a shallower draft.", int(state.sizes[target]))

func current_goal() -> String:
	if int(state.sizes["cereal"]) != 2: return "Grow the cereal loop into a raft for Pip and the parcel."
	if state.phase == "near": return "Push off toward the shallow ridge." if state.aboard else "Board at the teal mooring, then push off toward the shallows."
	if state.phase == "to_shoal": return "A gentle ride toward the shallow ridge."
	if state.phase == "shoal": return "The raft floats higher. Sail through the shallows!" if state.cargo_clear() else "Make the cargo small so the raft can clear the shallow ridge."
	if state.phase == "to_far": return "The lighter raft glides toward the spoon dock."
	return "Step ashore and greet the teal flag."

func update_objective() -> void:
	hud.objective.text = "Milk Harbor"
	hud.progress.text = "BREAKFAST TABLE  /  3 OF 5"
	hud.subgoal.text = current_goal() if not state.completed else "Pip and the parcel reached the far harbor."

func show_hint() -> void:
	var hints: Array[String]
	if state.phase == "near": hints = ["A cereal loop is almost a boat already.", "Make it large enough for Pip to board.", "Press 3 to grow the cereal loop. At the teal mooring, E boards; E again pushes off."]
	elif state.phase == "shoal": hints = ["The raft's belly is touching the shallow ridge.", "A smaller parcel weighs less and lets the raft rise.", "Select the cargo and press 1. Once it settles, press E to continue."]
	else: hints = ["The harbor crew is waiting.", "A spoon makes a fine little dock.", "At the far stop, E steps ashore. Walk to the teal flag."]
	hud.toast(hints[mini(hint_step, hints.size() - 1)], 7)
	hint_step += 1

func checkpoint_feedback(previous: int) -> void:
	if state.checkpoint <= previous: return
	hint_step = 0
	hud.toast(["", "A raft for two. Mooring saved.", "Safe at the shallow ridge. Mooring saved.", "The spoon dock unfolds. Far harbor saved."][state.checkpoint], 5)
	sfx("checkpoint")
	burst(pip.position + Vector3(0, 0.6, 0), Color("4a9290"))
	save_game()

func respawn() -> void:
	pip.position = aboard_position() if state.aboard else (FAR_BANK if state.phase == "far" else Vector3(-6.0, 0.06, 0.3))
	pip_art.rotation.y = PI / 2
	vertical_speed = 0
	jump_buffer = 0
	target = "cargo" if state.aboard else "cereal"
