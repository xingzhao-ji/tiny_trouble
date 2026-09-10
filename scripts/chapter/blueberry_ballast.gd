extends "res://scripts/chapter/chapter_stage.gd"
## W01S02: authored rolling tracks and a visible counterweight mechanism.
## Changing either loaded berry changes the actual ramp angle and landing height.
const StageRules = preload("res://scripts/chapter/ballast_state.gd")
const StageArt = preload("res://scripts/chapter/ballast_art.gd")
const STAGE_ID = "W01S02"
const TRAY_POINTS = {"berry_a": Vector3(-7.5, 0.06, -3.92), "berry_b": Vector3(-7.5, 0.06, -1.68)}
const PAN_CENTER = Vector3(-4.0, 0, -2.8)
const RAMP_START = Vector3(-2.8, 0.12, 1.3)
const LEDGE_CENTER = Vector3(5.25, 0, 1.3)
const EXIT_POS = Vector3(5.55, 1.8, 1.3)
const TOWER_POS = Vector3(-0.75, 0.06, -3.0)
var pan: Node3D
var tower: Node3D
var indicator: MeshInstance3D
var rolling_tracks: Dictionary = {}
var berry_pivots: Dictionary = {}
var cords: Array[MeshInstance3D] = []
var mechanism_tween: Tween
var displayed_weight := 0.0
var rolling := ""
var roll_tween: Tween
var exit_flag: Node3D
var slope_pose: Node3D
var foot_rest_positions: Dictionary = {}
var foot_contact_vertices: Dictionary = {}

func stage_definition() -> Dictionary:
	return {"id": STAGE_ID, "slug": "blueberry_ballast", "title": "Blueberry Ballast",
		"interaction_label": "Roll / Inspect",
		"kicker": "BREAKFAST TABLE · A LITTLE BALANCE", "description": "Two round berries. Five tiny counterweights.\nA cardboard path waiting to rise.",
		"opening": "Those big berries look ready for a gentle roll.",
		"complete_kicker": "A LITTLE LESS MAKES JUST ENOUGH.",
		"complete_text": "The cardboard path settles into a perfect little landing."}

func create_stage_rules() -> RefCounted:
	return StageRules.new()

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
	camera.position = Vector3(-1.4, 0, -0.2) + Vector3(10, 16, 22)
	add_child(camera)
	camera.look_at(Vector3(-1.4, 0, -0.2))
	camera.current = true
	pan = StageArt.balance_pan()
	pan.position = PAN_CENTER
	add_child(pan)
	tower = StageArt.counterweight_tower()
	tower.position = TOWER_POS
	add_child(tower)
	ramp = StageArt.ramp()
	ramp.position = RAMP_START
	add_child(ramp)
	var ledge = StageArt.ledge()
	ledge.position = LEDGE_CENTER
	add_child(ledge)
	# The fold-out lip receives the balanced ramp. The lower ramp can swing
	# beneath it without its endpoint entering the solid cereal-box wall.
	var landing_lip = cube(Vector3(0.40, 0.10, 1.65), Color("eed8b1"), Vector3(3.13, 1.75, 1.3))
	landing_lip.name = "FoldoutLandingLip"
	add_child(landing_lip)
	for kind in TRAY_POINTS:
		var prop = Node3D.new()
		prop.name = "BlueberryFar" if kind == "berry_a" else "BlueberryNear"
		var pivot = Node3D.new()
		pivot.name = "RollingBody"
		pivot.position.y = 0.29
		var berry = Art.prop("blueberry")
		berry.position.y = -0.29
		pivot.add_child(berry)
		prop.add_child(pivot)
		props[kind] = prop
		berry_pivots[kind] = pivot
		add_child(prop)
		var track = StageArt.ramp(3.5, 1.65)
		track.name = "RollingTrackFar" if kind == "berry_a" else "RollingTrackNear"
		track.position = TRAY_POINTS[kind]
		add_child(track)
		rolling_tracks[kind] = track
		var mat = cylinder(0.83, 0.018, Color("4a9290") if kind == "berry_a" else Color("d77865"), TRAY_POINTS[kind] - Vector3(0, 0.02, 0))
		add_child(mat)
	# Three visible strands connect the moving cereal flap, fixed pulley,
	# exposed stack, and the far end of the rising walkway.
	for i in range(3):
		var thread = cylinder(0.026, 1.0, Color("705e4b"), Vector3.ZERO)
		add_child(thread)
		cords.append(thread)
	indicator = sphere(Vector3(0.20, 0.20, 0.20), Color("e5a54b"), Vector3(2.93, 1.91, 2.03))
	add_child(indicator)
	# A short teal stripe makes the intended landing height visible throughout.
	add_child(cube(Vector3(0.045, 0.1, 1.55), Color("4a9290"), Vector3(2.935, 1.74, 1.3)))
	exit_flag = Node3D.new()
	exit_flag.position = EXIT_POS
	exit_flag.add_child(cylinder(0.5, 0.08, Color("f5e6cc"), Vector3(0, 0.04, 0)))
	exit_flag.add_child(cube(Vector3(0.05, 1.7, 0.05), Color("384657"), Vector3(0, 0.85, 0)))
	exit_flag.add_child(cube(Vector3(0.72, 0.42, 0.045), Color("4a9290"), Vector3(0.36, 1.46, 0)))
	add_child(exit_flag)
	pip = Node3D.new()
	pip.name = "Pip"
	slope_pose = Node3D.new()
	slope_pose.name = "SlopePose"
	pip.add_child(slope_pose)
	pip_art = Art.pip()
	slope_pose.add_child(pip_art)
	for foot_name in ["FootL", "FootR"]:
		var foot: MeshInstance3D = pip_art.get_node(foot_name)
		foot_rest_positions[foot_name] = foot.position
		var unique: Dictionary = {}
		for vertex in foot.mesh.get_faces(): unique[vertex] = true
		foot_contact_vertices[foot_name] = unique.keys()
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
	if props.has(target):
		target_ring.position = props[target].position + Vector3(0, 0.035, 0)
		target_ring.scale = Vector3.ONE * (0.45 + SCALE_VALUES[int(state.sizes[target])] * 0.24)
		target_ring.visible = started and not state.completed and in_range(target, 4.7)
	shadow.position = Vector3(pip.position.x, surface_height(pip.position) + 0.015, pip.position.z)
	shadow.scale = Vector3.ONE * clampf(1.0 - (pip.position.y - surface_height(pip.position)) * 0.2, 0.4, 1.0)
	var center = Vector3(-1.4 + clampf((pip.position.x + 1.4) * 0.16, -0.9, 0.9), 0, -0.2)
	camera.position = camera.position.lerp(center + Vector3(10, 16, 22), minf(delta * 1.8, 1))
	camera.look_at(camera.position - Vector3(10, 16, 22))

func set_mechanism_weight(value: float) -> void:
	displayed_weight = value
	pan.position.y = 0.85 - value * 0.09
	var end_height = 0.20 + value * 0.32
	ramp.rotation.z = asin((end_height - RAMP_START.y) / 6.0)
	tower.get_node("WeightStack").position.y = 0.35 + value * 0.06
	for kind in props:
		if state.sockets[kind] == "flap" and rolling != kind:
			props[kind].position = prop_position(kind)
		var track: Node3D = rolling_tracks[kind]
		# Keep the track's endpoint joined to the moving flap, with exact X reach.
		track.rotation.z = atan2(pan.position.y - 0.06, 3.5)
		track.scale.x = Vector2(3.5, pan.position.y - 0.06).length() / 3.5
	set_cord(cords[0], pan.position + Vector3(1.25, 0.1, 0), tower.get_node("PulleyLeft").global_position)
	set_cord(cords[1], tower.get_node("PulleyRight").global_position, tower.get_node("WeightStack/ThreadAnchor").global_position)
	set_cord(cords[2], tower.get_node("PulleyRight").global_position, ramp.get_node("FarAnchor").global_position + Vector3(0, 0.04, -0.7))
	indicator.material_override.albedo_color = Color("4a9290") if absf(value - 5.0) < 0.03 else Color("e5a54b")

func animate_pip(delta: float) -> void:
	for foot_name in foot_rest_positions:
		pip_art.get_node(foot_name).position = foot_rest_positions[foot_name]
	super.animate_pip(delta)
	# Keep the handmade feet parallel to the sloped cardboard under their yaw.
	# The separate parent avoids mixing world slope with PipArt's local gait.
	var on_ramp = pip.position.x >= RAMP_START.x and pip.position.x < 2.93 and absf(pip.position.z - RAMP_START.z) <= 0.62
	slope_pose.rotation.z = ramp.rotation.z if on_ramp and pip.position.y <= surface_height(pip.position) + 0.06 else 0.0
	if pip.position.y > surface_height(pip.position) + 0.06: return
	# At a join, a forward foot reaches the next surface before Pip's center.
	# Lift each rounded foot only enough to meet the nearby walking surface.
	# Cached unique mesh vertices keep contact independent of an AABB proxy.
	for foot_name in foot_rest_positions:
		var foot: MeshInstance3D = pip_art.get_node(foot_name)
		var lift := 0.0
		for vertex: Vector3 in foot_contact_vertices[foot_name]:
			var point = foot.to_global(vertex)
			var height = surface_height(point)
			if height <= pip.position.y + 0.35:
				lift = maxf(lift, height - point.y)
		if lift > 0:
			foot.position.y += (lift + 0.002) / pip_art.global_basis.y.y

func set_cord(node: Node3D, a: Vector3, b: Vector3) -> void:
	node.position = (a + b) * 0.5
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	node.scale = Vector3(1, a.distance_to(b), 1)

func prop_position(kind: String) -> Vector3:
	if state.sockets[kind] == "tray": return TRAY_POINTS[kind]
	return Vector3(PAN_CENTER.x, pan.position.y, TRAY_POINTS[kind].z)

func sync_props(animate: bool = true) -> void:
	if is_instance_valid(roll_tween) and roll_tween.is_valid(): roll_tween.kill()
	rolling = ""
	if is_instance_valid(mechanism_tween) and mechanism_tween.is_valid(): mechanism_tween.kill()
	for kind in props:
		if prop_tweens.has(kind) and prop_tweens[kind].is_valid(): prop_tweens[kind].kill()
		var ratio: float = SCALE_VALUES[int(state.sizes[kind])]
		props[kind].position = prop_position(kind)
		if animate and not reduced_motion:
			var tw = create_tween()
			tw.tween_property(props[kind], "scale", Vector3.ONE * ratio, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			prop_tweens[kind] = tw
		else: props[kind].scale = Vector3.ONE * ratio
	if animate and not reduced_motion and absf(displayed_weight - float(state.total_weight())) > 0.001:
		mechanism_tween = create_tween()
		mechanism_tween.tween_method(set_mechanism_weight, displayed_weight, float(state.total_weight()), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else: set_mechanism_weight(float(state.total_weight()))

func mechanism_busy() -> bool:
	return rolling != "" or (is_instance_valid(mechanism_tween) and mechanism_tween.is_valid() and mechanism_tween.is_running())

func ramp_occupied() -> bool:
	return pip.position.x > RAMP_START.x - 0.35 and pip.position.x < 3.35 and absf(pip.position.z - RAMP_START.z) < 1.15

func resize_target(new_size: int) -> void:
	if new_size < 0 or new_size > 2: return reject("Choose small, normal, or large.")
	if not props.has(target) or not in_range(target, 4.0): return reject("Move a little closer to the blueberry.")
	if mechanism_busy(): return reject("Let the berries and cardboard settle first.")
	if ramp_occupied(): return reject("Step off the cardboard path before changing its balance.")
	var old_size = int(state.sizes[target])
	if new_size > old_size:
		var distance = Vector2(pip.position.x - props[target].position.x, pip.position.z - props[target].position.z).length()
		if distance < 0.31 * SCALE_VALUES[new_size] + 0.42:
			return reject("Give the growing berry a little room.")
	var before = state.checkpoint
	var result = state.resize(target, new_size)
	apply_result(result, "resize_up" if new_size > old_size else "resize_down")
	if result.ok:
		resize_pose = 0.5
		sync_props()
		if new_size != old_size: burst(props[target].position + Vector3(0, 0.4, 0), Color("e5a54b"))
		checkpoint_feedback(before)

func interact() -> void:
	if Vector2(pip.position.x - TOWER_POS.x, pip.position.z - TOWER_POS.z).length() < 1.55:
		apply_result(state.discover(), "discovery")
		return
	if not props.has(target) or not in_range(target, 2.1): return reject("Step close to a berry for a gentle roll.")
	if mechanism_busy(): return reject("Let this little roll finish first.")
	if ramp_occupied(): return reject("Step off the cardboard path before changing its balance.")
	var start: Vector3 = props[target].position
	var end: Vector3 = TRAY_POINTS[target] if state.sockets[target] == "flap" else Vector3(PAN_CENTER.x, pan.position.y, TRAY_POINTS[target].z)
	var margin: float = 0.31 * SCALE_VALUES[int(state.sizes[target])] + 0.42
	if pip.position.x > minf(start.x, end.x) - margin and pip.position.x < maxf(start.x, end.x) + margin and absf(pip.position.z - start.z) < margin:
		return reject("Stand beside the track or behind the berry to roll it safely.")
	var before = state.checkpoint
	var kind = target
	var result = state.interact(kind)
	apply_result(result, "place")
	if not result.ok: return
	sync_props()
	rolling = kind
	props[kind].position = start
	var begin_rotation: float = berry_pivots[kind].rotation.z
	if reduced_motion:
		rolling = ""
		set_mechanism_weight(float(state.total_weight()))
		props[kind].position = prop_position(kind)
	else:
		roll_tween = create_tween()
		roll_tween.tween_method(func(u: float):
			var destination = prop_position(kind)
			props[kind].position = start.lerp(destination, u)
			# A returning berry follows the track as the emptied flap rises.
			# Interpolating from its old pan height would sink it into that track.
			var track_fraction: float = (props[kind].position.x - TRAY_POINTS[kind].x) / (PAN_CENTER.x - TRAY_POINTS[kind].x)
			props[kind].position.y = lerpf(TRAY_POINTS[kind].y, pan.position.y, clampf(track_fraction, 0, 1))
			berry_pivots[kind].rotation.z = begin_rotation - (destination.x - start.x) * u / (0.29 * SCALE_VALUES[int(state.sizes[kind])]), 0.0, 1.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		roll_tween.tween_callback(func():
			rolling = ""
			props[kind].position = prop_position(kind)
			sfx("land"))
	checkpoint_feedback(before)

func surface_height(pos: Vector3) -> float:
	if pos.x >= 3.25 and pos.x <= 7.25 and absf(pos.z - 1.3) <= 1.6: return 1.8
	if pos.x >= 2.93 and pos.x <= 3.33 and absf(pos.z - 1.3) <= 0.825: return 1.8
	var dx: float = pos.x - RAMP_START.x
	var reach: float = 6.0 * cos(ramp.rotation.z)
	if dx >= -0.12 and dx <= reach and absf(pos.z - 1.3) <= 0.62:
		return RAMP_START.y + maxf(0, dx) * tan(ramp.rotation.z)
	return 0.06

func obstructed(pos: Vector3) -> bool:
	# Tracks and flap are prop space; Pip walks around their visibly raised edges.
	if pos.x > -7.30 and pos.x < -2.25 and pos.z > -5.40 and pos.z < -0.20: return true
	if absf(pos.x - TOWER_POS.x) < 1.28 and absf(pos.z - TOWER_POS.z) < 1.15: return true
	for kind in props:
		var berry: Node3D = props[kind]
		var radius: float = 0.31 * maxf(berry.scale.x, SCALE_VALUES[int(state.sizes[kind])]) + 0.40
		if Vector2(pos.x - berry.position.x, pos.z - berry.position.z).length() < radius: return true
	var next_height = surface_height(pos)
	if next_height > pip.position.y + 0.23: return true
	# Solid cereal sides extend to the edge of Pip's footprint.
	if pos.x > 2.88 and pos.x < 7.62 and absf(pos.z - 1.3) < 1.96:
		if pip.position.y < 1.57 and not (absf(pos.z - 1.3) < 0.62 and pos.x < 3.26 and state.is_balanced()): return true
	# A raised or low ramp cannot silently snap onto the landing.
	if pos.x >= 2.91 and absf(pos.z - 1.3) < 0.9 and pip.position.x < 2.95:
		if not state.is_balanced() or mechanism_busy(): return true
	return false

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
			next.x = clampf(next.x, -9.3, 7.7)
			next.z = clampf(next.z, -5.95, 4.9)
			if not obstructed(next):
				pip.position.x = next.x
				pip.position.z = next.z
			else:
				var nx = Vector3(next.x, pip.position.y, pip.position.z)
				var nz = Vector3(pip.position.x, pip.position.y, next.z)
				if not obstructed(nx): pip.position.x = next.x
				elif not obstructed(nz): pip.position.z = next.z
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
	if not exploring and pip.position.distance_to(EXIT_POS) < 0.7:
		var result = state.finish()
		if result.ok:
			celebration_time = 0
			save_game()
			sfx("complete")
			burst(pip.position + Vector3(0, 0.7, 0), Color("e5a54b"), 28)
			hud.toast("A little less makes just enough." if last_save_ok else "Balance complete. Chapter progress could not be saved yet.", 5)

func cycle_target() -> void:
	var candidates: Array[String] = []
	for kind in props:
		if in_range(kind, 4.4): candidates.append(kind)
	if candidates.is_empty(): return
	target = candidates[(candidates.find(target) + 1) % candidates.size()]
	sfx("place")

func update_target() -> void:
	if state.completed:
		hud.update_target("Perfect little balance", "The cardboard path is ready for another visit.", -1)
		return
	if not in_range(target, 4.7):
		for kind in props:
			if in_range(kind, 4.4): target = kind
	if Vector2(pip.position.x - TOWER_POS.x, pip.position.z - TOWER_POS.z).length() < 1.55:
		hud.update_target("Cereal counterweights", "E  Peek at what makes the path rise.", -1)
		return
	var help_text = "3 / F  Grow a rolling berry. E gives it a gentle push."
	if state.sockets[target] == "flap":
		help_text = "1 / Q  Try a little less weight. Watch the cardboard path."
		if state.is_balanced(): help_text = "Just enough! Walk up the path to the teal flag."
	if mechanism_busy(): help_text = "A little roll. A big change in balance."
	if not in_range(target, 4.7):
		hud.update_target("Cardboard path", "Walk along the center toward the teal flag." if state.is_balanced() else "The berry flap changes the height of this path.", -1)
	else:
		hud.update_target("Blueberry · far track" if target == "berry_a" else "Blueberry · near track", help_text, int(state.sizes[target]))

func current_goal() -> String:
	if state.sockets["berry_a"] != "flap" or state.sockets["berry_b"] != "flap": return "Make both berries large. Roll them onto the cereal flap."
	if not state.is_balanced():
		return "The path is too high. Make one loaded berry small to balance it." if state.total_weight() > 5 else "A little more weight will lift the path. Try one large berry and one small."
	return "The path meets the box! Walk up to the teal flag."

func update_objective() -> void:
	hud.objective.text = "Blueberry Ballast"
	hud.progress.text = "BREAKFAST TABLE  /  2 OF 5"
	hud.subgoal.text = current_goal() if not state.completed else "A perfect little balance."

func show_hint() -> void:
	var hints: Array[String]
	if state.sockets["berry_a"] != "flap" or state.sockets["berry_b"] != "flap":
		hints = ["The tracks lead to a cereal-box flap.", "Large berries have enough heft to roll into the pockets.", "Stand behind each berry. Press 3 to grow it, then E to roll it along its track."]
	elif not state.is_balanced():
		hints = ["The berries change how high the path rises.", "The exposed cereal weights cannot change. Your berries can.", "Stand beside the flap. Make one loaded berry small and the other large."]
	else:
		hints = ["The teal edges now meet.", "The cardboard path is steady while Pip stands on it.", "Walk to the low end of the path, then follow its center to the flag."]
	hud.toast(hints[mini(hint_step, hints.size() - 1)], 7)
	hint_step += 1

func checkpoint_feedback(previous: int) -> void:
	if state.checkpoint <= previous: return
	hint_step = 0
	hud.toast("Both berries are aboard. Checkpoint saved." if state.checkpoint == 1 else "A perfect little balance. Checkpoint saved.", 5)
	sfx("checkpoint")
	burst(pip.position + Vector3(0, 0.65, 0), Color("4a9290"))
	save_game()

func respawn() -> void:
	pip.position = Vector3(-8.85, 0.06, -1.68) if state.checkpoint == 0 else Vector3(-4.0, 0.06, 0.3)
	if state.completed: pip.position = EXIT_POS + Vector3(0.3, 0, 0)
	pip.position.y = surface_height(pip.position)
	pip_art.rotation.y = 0.6
	vertical_speed = 0
	jump_buffer = 0
	target = "berry_b"
