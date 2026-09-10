extends SceneTree
## Full-scene headless checks. Scene setup uses model actions; assertions invoke
## the production resize/input/pause paths and inspect the authored prop meshes.

const Main = preload("res://scripts/main.gd")
const State = preload("res://scripts/puzzle_state.gd")
var game: Node3D
var checks: int = 0
var failures: int = 0
var test_path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	test_path = "user://scene_safety_test_%d.json" % OS.get_process_id()
	_cleanup()
	game = Main.new()
	game.save_path = test_path
	root.add_child(game)
	game.set_process(false)
	game.reduced_motion = true
	game.on_command("start", true)
	_test_rotated_solid_growth()
	_test_occupied_bridge()
	_test_occupied_ramp()
	_test_optional_discovery_and_boarding_safety()
	_test_pause_motion_and_flight()
	await _test_pause_tweens()
	await _test_title_roundtrip_resumes_resize()
	await game.stop_audio()
	game.queue_free()
	await process_frame
	_cleanup()
	print("%s: %d scene safety checks; mesh clearance, occupied supports, and pause/resume." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_rotated_solid_growth() -> void:
	# These corner positions were missed by the old circular growth clearance.
	# The overlap check below uses Pip mesh vertices against prospective prop
	# mesh bounds, independently of solid_footprint_contains().
	for kind: String in ["cereal", "toaster"]:
		game.state = State.new()
		game.state.resize(kind, 0)
		game.sync_props(false)
		game.target = kind
		var art: Node3D = game.props[kind]
		var local_corner: Vector3 = Vector3(1.35, 0.04, 0.79) if kind == "cereal" else Vector3(1.21, 0.04, 0.85)
		game.pip.position = art.position + Basis(Vector3.UP, art.rotation.y) * local_corner
		game.pip_art.rotation = Vector3(0, art.rotation.y, 0)
		game.pip_art.scale = Vector3.ONE
		game.pip_art.position = Vector3.ZERO
		_expect(not game.obstructed(game.pip.position), kind + " corner is accessible while small")
		var small_scale: Vector3 = art.scale
		art.scale = Vector3.ONE
		_expect(_actor_enters_prop_bounds(art), kind + " normal geometry reaches the actor at the regression corner")
		art.scale = small_scale
		var before: Dictionary = game.state.to_dict()
		var position_before: Vector3 = game.pip.position
		var saves_before: int = game.save_count
		game.resize_target(1)
		_expect(game.state.to_dict() == before, kind + " growth rejects the occupied corner atomically")
		_expect(game.pip.position == position_before, kind + " rejected growth does not displace Pip")
		_expect(game.save_count == saves_before, kind + " rejected growth does not persist an invalid transition")
		_expect(game.hud.message.text.contains("growing space"), kind + " rejection explains how to make room")
		# A nearby clear location must still permit the same transition.
		game.pip.position = art.position + Vector3(-2.0, 0.04, 1.9)
		game.resize_target(1)
		_expect(int(game.state.sizes[kind]) == 1, kind + " grows after the player steps clear")


func _test_occupied_bridge() -> void:
	game.state = _prepared_state(true)
	game.sync_props(false)
	game.target = "spoon"
	game.pip.position = Vector3(-3.4, 0.52, 1.2)
	# The first authored spoon mesh is the handle. Compare its executed world
	# bounds with the actual foot surface, so an art height change fails the test.
	var handle: MeshInstance3D = game.props["spoon"].get_child(0)
	var handle_bounds: AABB = handle.global_transform * handle.mesh.get_aabb()
	var floor_height: float = game.surface_height(game.pip.position)
	_expect(is_equal_approx(floor_height, handle_bounds.end.y), "Spoon foot surface meets the visible handle top")
	_expect(is_equal_approx(floor_height, 0.52), "Current authored spoon handle supports feet at 0.52")
	var before: Dictionary = game.state.to_dict()
	game.resize_target(0)
	_expect(game.state.to_dict() == before, "An occupied spoon cannot shrink even after the return latch opens")
	_expect(game.hud.message.text.contains("Step off the spoon"), "Occupied spoon explains safe recovery")
	game.pip.position = Vector3(-3.4, 0.06, 2.15)
	game.resize_target(0)
	_expect(not game.state.bridge_placed and int(game.state.sizes["spoon"]) == 0, "The unoccupied spoon remains reusable after latching")
	_expect(game.surface_height(Vector3(-4.2, 0, -2.2)) > 0, "Permanent return bridge remains traversable after spoon removal")


func _test_occupied_ramp() -> void:
	game.state = _prepared_state(false)
	game.sync_props(false)
	game.target = "blueberry"
	game.pip.position = Vector3(3.45, 0.17, 1.2)
	_expect(game.state.ramp_raised() and not game.state.ramp_latched, "Ramp test starts raised by removable ballast")
	var before: Dictionary = game.state.to_dict()
	game.resize_target(0)
	_expect(game.state.to_dict() == before, "Occupied ramp cannot lose its ballast support")
	_expect(game.hud.message.text.contains("Step off the ramp"), "Occupied ramp explains safe recovery")
	game.pip.position = Vector3(1.2, 0.06, 1.2)
	game.resize_target(0)
	_expect(not game.state.ramp_raised(), "Unoccupied unlatched ramp can lower for experimentation")
	game.state = _prepared_state(true)
	game.sync_props(false)
	game.pip.position = Vector3(3.45, 0.17, 1.2)
	game.resize_target(0)
	_expect(int(game.state.sizes["blueberry"]) == 0 and game.state.ramp_raised(), "Latched ramp safely releases ballast even while occupied")


func _test_optional_discovery_and_boarding_safety() -> void:
	game.state = _launch_ready()
	game.sync_props(false)
	game.flying = false
	game.boarded = false
	game.paused = false
	game.recovery_time = 0
	game.target = "cereal"
	game.pip.position = Vector3(2.2, 0.06, -1.0)
	_expect(game.state.napkin_ready and not game.state.discovered, "Discovery scenario starts with a prepared landing and unexplored panel")
	_expect(not game.obstructed(game.pip.position) and game.surface_height(game.pip.position) >= 0, "On-foot cereal interaction uses an accessible dry approach")
	game.resize_target(0)
	_expect(int(game.state.sizes["cereal"]) == 0 and game.state.napkin_ready, "Prepared napkin does not prevent optional cereal shrinking on foot")
	game.interact()
	_expect(game.state.discovered, "Optional picnic remains discoverable after all launch preparation")
	_expect(game.props["cereal"].get_node("Picnic").visible, "Post-preparation discovery opens the actual picnic art")
	game.pip.position = Vector3(0.4, 0.06, -2.5)
	game.target = "toaster"
	_expect(not game.obstructed(game.pip.position), "Boarding scenario approaches from outside the toaster")
	game.interact()
	_expect(not game.boarded and game.hud.message.text.contains("cereal"), "Small cereal window prevents boarding until restored")
	game.target = "cereal"
	game.resize_target(1)
	_expect(int(game.state.sizes["cereal"]) == 1, "Player can restore the normal cereal window from the boarding approach")
	game.target = "toaster"
	game.interact()
	_expect(game.boarded and not game.flying, "Normal cereal and toaster allow actual boarding")
	game.move_pip(0.5)
	_expect(game.boarding_time >= 0.5, "Authored boarding hop reaches its settled state")
	for kind: String in ["cereal", "toaster"]:
		game.target = kind
		var before: Dictionary = game.state.to_dict()
		game.resize_target(0)
		_expect(game.state.to_dict() == before and game.boarded and not game.flying, "Boarded Pip prevents resizing the " + kind)
		_expect(game.hud.message.text.contains("Step off the toast"), "Occupied launcher restriction explains safe recovery for " + kind)
		game.resize_target(1)
		_expect(game.state.to_dict() == before, "Selecting the existing " + kind + " size aboard remains an idempotent action")
		_expect(game.hud.message.text == "Already that size.", "Selecting the existing " + kind + " size aboard is accepted")
	game.target = "blueberry"
	game.resize_target(0)
	_expect(game.flying and not game.boarded and int(game.state.sizes["blueberry"]) == 0, "Protecting launcher geometry still allows the intended blueberry release")


func _test_pause_motion_and_flight() -> void:
	game.state = State.new()
	game.sync_props(false)
	game.pip.position = Vector3(0.0, 0.06, 2.5)
	game.target = "napkin"
	game.started = true
	game.paused = false
	game.flying = false
	game.boarded = false
	game.recovery_time = 0
	game.vertical_speed = 0
	Input.action_press("move_right")
	var beginning: Vector3 = game.pip.position
	game._process(0.1)
	_expect(game.pip.position.distance_to(beginning) > 0.1, "Production movement advances while unpaused")
	game.on_command("pause", null)
	var paused_position: Vector3 = game.pip.position
	var paused_camera: Transform3D = game.camera.transform
	var paused_clock: float = game.t
	var samples: int = game.frame_samples.size()
	game._process(0.6)
	_expect(game.pip.position == paused_position, "Pause freezes held movement input")
	_expect(game.camera.transform == paused_camera, "Pause freezes camera motion")
	_expect(game.t == paused_clock and game.frame_samples.size() == samples, "Pause freezes simulation clock and excludes pause from frame samples")
	Input.action_release("move_right")
	game.on_command("resume", null)
	game.state = _launch_ready()
	game.sync_props(false)
	game.state.release_launch()
	game.begin_flight()
	game._process(0.2)
	_expect(game.flight_time > 0 and game.flying, "Production flight advances before pause")
	game.on_command("pause", null)
	var flight_position: Vector3 = game.pip.position
	var toast_position: Vector3 = game.toast.position
	var elapsed: float = game.flight_time
	game._process(1.0)
	_expect(game.flight_time == elapsed and game.pip.position == flight_position, "Pause freezes flight elapsed time and rider")
	_expect(game.toast.position == toast_position and not game.state.completed, "Pause freezes toast and cannot complete flight in the background")
	game.on_command("resume", null)
	game._process(0.1)
	_expect(game.flight_time > elapsed and game.pip.position != flight_position, "Flight resumes from its paused position")
	game.flying = false


func _test_pause_tweens() -> void:
	var probe: Node3D = Node3D.new()
	game.add_child(probe)
	var tween: Tween = game.create_tween()
	tween.tween_property(probe, "position:x", 3.0, 1.0)
	# Allow initial scene construction to finish before measuring a tween. Its
	# first processing frame initializes it and may include expensive mesh setup.
	await process_frame
	await process_frame
	await create_timer(0.08).timeout
	_expect(probe.position.x > 0, "Authored tween advances before pause")
	game.on_command("pause", null)
	var position_before: Vector3 = probe.position
	await create_timer(0.12).timeout
	_expect(probe.position == position_before, "Pause freezes active prop and effect tweens")
	game.on_command("controls", null)
	game.on_command("pause", null)
	await create_timer(0.08).timeout
	_expect(probe.position == position_before, "Controls and Back navigation keep the transition paused")
	game.on_command("resume", null)
	await create_timer(0.08).timeout
	_expect(probe.position.x > position_before.x, "Paused tweens resume after Controls, Back, and closing the menu")
	tween.kill()
	probe.queue_free()


func _test_title_roundtrip_resumes_resize() -> void:
	game.state = State.new()
	game.flying = false
	game.boarded = false
	game.started = true
	game.paused = false
	game.reduced_motion = false
	game.sync_props(false)
	game.target = "blueberry"
	game.pip.position = Vector3(0.5, 0.06, 1.3)
	game.resize_target(2)
	await process_frame
	await process_frame
	await create_timer(0.06).timeout
	var berry: Node3D = game.props["blueberry"]
	_expect(int(game.state.sizes["blueberry"]) == 2 and not berry.scale.is_equal_approx(Vector3.ONE * 2), "Title regression starts inside an actual blueberry resize animation")
	game.on_command("pause", null)
	var paused_scale: Vector3 = berry.scale
	await create_timer(0.08).timeout
	_expect(berry.scale.is_equal_approx(paused_scale) and not game.paused_tweens.is_empty(), "Pause suspends the actual partially resized prop")
	game.on_command("title", null)
	_expect(not game.started and not game.paused and game.hud.menu_mode == "title", "Save and return to title opens the expected menu")
	_expect(game.paused_tweens.is_empty(), "Returning to title releases suspended resize references")
	await create_timer(0.45).timeout
	_expect(berry.scale.is_equal_approx(Vector3.ONE * 2), "Saved blueberry finishes its authored resize on the title screen")
	game.on_command("start", true)
	_expect(game.started and not game.paused and berry.scale.is_equal_approx(Vector3.ONE * 2), "Continue breakfast restores a fully settled playable prop")
	game.reduced_motion = true


func _actor_enters_prop_bounds(prop: Node3D) -> bool:
	for part: String in ["Body", "FootL", "FootR"]:
		var actor_mesh: MeshInstance3D = game.pip_art.get_node(part)
		var vertices: PackedVector3Array = actor_mesh.mesh.get_faces()
		for child: Node in prop.get_children():
			if not child is MeshInstance3D:
				continue
			var solid: MeshInstance3D = child
			var actor_to_solid: Transform3D = solid.global_transform.affine_inverse() * actor_mesh.global_transform
			var bounds: AABB = solid.mesh.get_aabb()
			for vertex: Vector3 in vertices:
				if bounds.has_point(actor_to_solid * vertex):
					return true
	return false


func _prepared_state(latched: bool) -> PuzzleState:
	var state: PuzzleState = State.new()
	state.resize("spoon", 0)
	state.interact("spoon")
	state.pass_handle()
	state.place("bridge")
	state.resize("spoon", 2)
	state.resize("blueberry", 0)
	state.interact("blueberry")
	state.place("ballast")
	state.resize("blueberry", 2)
	if latched:
		state.resize("butter", 0)
		state.interact("butter")
		state.place("wedge")
		state.resize("butter", 1)
	return state


func _launch_ready() -> PuzzleState:
	var state: PuzzleState = _prepared_state(true)
	state.resize("napkin", 0)
	state.interact("napkin")
	state.place("landing")
	state.resize("napkin", 2)
	state.resize("blueberry", 0)
	state.interact("blueberry")
	state.place("lever")
	state.resize("blueberry", 2)
	return state


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		var path: String = test_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
