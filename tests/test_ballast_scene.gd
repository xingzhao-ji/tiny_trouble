extends SceneTree
## Full W01S02 scene scenarios. Model setup and injected starting positions are
## fixtures; production movement, resize, roll, menus, and disk saves are tested.
## This is separate from the ordinary-input native route.
const Stage = preload("res://scripts/chapter/blueberry_ballast.gd")
const State = preload("res://scripts/chapter/ballast_state.gd")
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
var game: Node3D
var profile_path: String
var settings_path: String
var demo_path: String
var checks: int = 0
var failures: int = 0
var worst_foot_depth: float = 0.0
var worst_foot_probe: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	profile_path = "user://ballast_scene_test_%d.json" % OS.get_process_id()
	settings_path = "user://ballast_scene_settings_%d.cfg" % OS.get_process_id()
	demo_path = "user://ballast_scene_demo_%d.json" % OS.get_process_id()
	_cleanup()
	var seed = Progress.new()
	seed.save_path = profile_path
	_expect(seed.complete_stage("W01S01") and seed.completed_ids() == ["W01S01"], "Fixture seeds only the prerequisite chapter clear")
	game = _create_scene()
	_expect(game.chapter_profile.save_path == profile_path and game.settings_path == settings_path and game.save_path == demo_path, "All storage paths are isolated before scene ready")
	_expect(game.props.size() == 2 and game.props.has("berry_a") and game.props.has("berry_b") and not game.has_save, "Stage starts with its own two berries and no fabricated stage-two save")
	_expect(game.hud.controls.text.contains("Roll / Inspect") and not game.hud.controls.text.contains("Carry / Place"), "Stage footer describes its actual rolling and inspection controls")
	await process_frame
	await process_frame
	_test_growth_and_tracks()
	await _test_busy_roll_and_reset()
	await _test_return_roll_contact()
	_test_ramp_geometry_and_gates()
	_test_both_walkable_solutions()
	_test_occupied_ramp()
	_test_canonical_recovery()
	await _test_paused_resize_title()
	await _test_completion_lifecycle()
	_test_failed_completion_retry()
	await game.stop_audio()
	game.queue_free()
	await process_frame
	_release_movement()
	_cleanup()
	print("%s: %d Blueberry Ballast scene checks; solid growth, rolling, ramp geometry, both crossings, recovery, pause, and durable completion. Maximum primary-foot depth on rendered support: %.4f m." % ["PASS" if failures == 0 else "FAIL", checks, worst_foot_depth])
	print("Primary-foot probe: " + JSON.stringify(worst_foot_probe))
	quit(0 if failures == 0 else 1)


func _create_scene() -> Node3D:
	var scene: Node3D = Stage.new()
	scene.chapter_profile_path = profile_path
	scene.settings_path = settings_path
	scene.save_path = demo_path
	root.add_child(scene)
	scene.set_process(false)
	scene.reduced_motion = true
	scene.on_command("start", null)
	return scene


func _test_growth_and_tracks() -> void:
	_setup(0)
	game.target = "berry_b"
	game.pip.position = Stage.TRAY_POINTS["berry_b"] + Vector3(-0.82, 0, 0)
	game.pip_art.transform = Transform3D.IDENTITY
	var berry: Node3D = game.props["berry_b"]
	var body: MeshInstance3D = berry.get_node("RollingBody").get_child(0).get_child(0)
	_expect(not _actor_enters_mesh(body), "Growth fixture starts clear of the visible normal berry")
	berry.scale = Vector3.ONE * 2.0
	_expect(_actor_enters_mesh(body), "Requested large berry would actually cover Pip's primary mesh")
	berry.scale = Vector3.ONE
	var before: Dictionary = game.state.to_dict()
	game.resize_target(2)
	_expect(game.state.to_dict() == before and berry.scale.is_equal_approx(Vector3.ONE), "Production growth guard prevents the requested overlap")
	game.pip.position = Stage.TRAY_POINTS["berry_b"] + Vector3(-1.35, 0, 0)
	game.resize_target(2)
	_expect(int(game.state.sizes["berry_b"]) == 2, "Growing from behind the berry succeeds with visible clearance")
	for point: Vector3 in [Vector3(-6.0, 0.06, -1.68), Vector3(-4.0, 0.06, -2.8)]:
		_expect(game.obstructed(point), "Raised rolling-track and pan surfaces are protected prop space")
	game.pip.position = Stage.TRAY_POINTS["berry_b"] + Vector3(0.8, 0, 0)
	before = game.state.to_dict()
	game.interact()
	_expect(game.state.to_dict() == before and game.hud.message.text.contains("track"), "Standing in the rolling corridor cannot push a berry through Pip")
	game.pip.position = Vector3(6, 0.06, 4.0)
	game.resize_target(0)
	_expect(game.state.to_dict() == before, "A remote berry cannot resize across the room")


func _test_busy_roll_and_reset() -> void:
	_setup(0)
	game.target = "berry_b"
	game.pip.position = Stage.TRAY_POINTS["berry_b"] + Vector3(-1.35, 0, 0)
	var before: Dictionary = game.state.to_dict()
	game.interact()
	_expect(game.state.to_dict() == before, "Normal berry cannot roll into the pocket")
	game.resize_target(2)
	game.reduced_motion = false
	game.interact()
	_expect(game.rolling == "berry_b" and game.mechanism_busy() and game.state.sockets["berry_b"] == "flap", "Actual large-berry interaction begins an animated roll")
	before = game.state.to_dict()
	game.resize_target(0)
	game.interact()
	_expect(game.state.to_dict() == before and game.rolling == "berry_b", "Busy roll rejects resizing and a second roll without changing state")
	var beginning: Vector3 = game.props["berry_b"].position
	await create_timer(0.18).timeout
	_expect(game.props["berry_b"].position.x > beginning.x and game.berry_pivots["berry_b"].rotation.z != 0, "Authored roll moves and rotates the actual berry")
	game.on_command("pause", null)
	var berry_position: Vector3 = game.props["berry_b"].position
	var ramp_pose: Transform3D = game.ramp.transform
	var clock_before: float = game.t
	_press_direction(Vector3.RIGHT)
	game._process(0.3)
	_release_movement()
	await create_timer(0.1).timeout
	_expect(game.props["berry_b"].position == berry_position and game.ramp.transform == ramp_pose and game.t == clock_before, "Pause freezes rolling, mechanism motion, and the scene clock")
	game.on_command("reset", null)
	_expect(not game.paused and game.rolling == "" and not game.mechanism_busy() and game.paused_tweens.is_empty(), "Reset during a paused roll cancels transient motion and releases pause references")
	_expect(game.state.checkpoint == 0 and game.state.sizes == {"berry_a": 1, "berry_b": 1} and _props_match_rules(), "Interrupted opening roll returns both visible normal berries to their trays")
	await create_timer(1.25).timeout
	_expect(game.rolling == "" and game.displayed_weight == 0 and _props_match_rules(), "Cancelled roll callbacks cannot move a berry again after reset")
	game.reduced_motion = true


func _test_return_roll_contact() -> void:
	_setup(1)
	game.target = "berry_b"
	game.pip.position = Vector3(-4.0, 0.06, 0.3)
	game.reduced_motion = false
	var initial_pan_y: float = game.pan.position.y
	game.interact()
	_expect(game.rolling == "berry_b" and game.state.sockets["berry_b"] == "tray", "Returning a loaded berry starts an actual rolling animation")
	var max_gap: float = 0.0
	var samples: int = 0
	var deadline: int = Time.get_ticks_msec() + 2500
	var track: MeshInstance3D = game.rolling_tracks["berry_b"].get_node("Surface")
	while game.mechanism_busy() and Time.get_ticks_msec() < deadline:
		await process_frame
		var berry_position: Vector3 = game.props["berry_b"].position
		max_gap = maxf(max_gap, absf(berry_position.y - _plane_height(track, berry_position)))
		samples += 1
	_expect(samples > 10 and game.pan.position.y > initial_pan_y, "Return contact probe observes the track rising during the roll")
	_expect(max_gap < 0.015, "Returning berry remains on the actual moving track instead of sinking through it")
	_expect(not game.mechanism_busy() and game.rolling == "" and _props_match_rules() and game.state.checkpoint == 1, "Return roll settles on the tray while preserving its loading checkpoint")
	game.reduced_motion = true


func _test_ramp_geometry_and_gates() -> void:
	for checkpoint: int in range(3):
		_setup(checkpoint)
		var surface: MeshInstance3D = game.ramp.get_node("Surface")
		var bounds: AABB = surface.mesh.get_aabb()
		var agrees: bool = true
		for local_x: float in [-1.5, 1.5]:
			var top_point: Vector3 = surface.to_global(Vector3(local_x, bounds.end.y, 0))
			agrees = agrees and is_equal_approx(game.surface_height(top_point), top_point.y)
		_expect(agrees, "Support height matches the actual rendered ramp plane at checkpoint %d" % checkpoint)
		if checkpoint == 2:
			var anchor: Vector3 = game.ramp.get_node("FarAnchor").global_position
			var lip: MeshInstance3D = game.get_node("FoldoutLandingLip")
			var local_anchor: Vector3 = lip.to_local(anchor)
			var lip_bounds: AABB = lip.mesh.get_aabb()
			_expect(is_equal_approx(anchor.y, _plane_height(lip, anchor)) and local_anchor.x >= lip_bounds.position.x and local_anchor.x <= lip_bounds.end.x, "Balanced ramp endpoint meets the actual fold-out landing lip")
		else:
			game.pip.position = Stage.RAMP_START + Vector3(-0.25, -0.06, 0)
			var walk: Dictionary = _walk_to_x(3.35, 220)
			_expect(not walk.reached and game.pip.position.x < 2.95, "Low or overheight ramp cannot enter the ledge at checkpoint %d" % checkpoint)
			_expect(walk.max_up <= 0.23 and not game.state.completed, "Mismatched ramp does not teleport Pip upward or award completion")
	_setup(0)
	game.pip.position = Vector3(4.7, 0.06, 3.7)
	_press_direction(Vector3.FORWARD)
	for step: int in range(90): game.move_pip(1.0 / 60.0)
	_release_movement()
	_expect(game.pip.position.z > 2.9 and game.pip.position.y < 0.3, "Ground-level side approach cannot snap Pip onto the tall cereal box")


func _test_both_walkable_solutions() -> void:
	for small: String in State.PROP_KINDS:
		_setup(0)
		for kind: String in State.PROP_KINDS:
			game.target = kind
			game.pip.position = Stage.TRAY_POINTS[kind] + Vector3(-1.35, 0, 0)
			game.resize_target(2)
			game.interact()
		_expect(game.state.checkpoint == 1 and game.state.total_weight() == 8 and _props_match_rules(), "Actual scene resize/roll actions establish both large pocket berries")
		game.target = small
		game.pip.position = Vector3(-4.0, 0.06, -5.75 if small == "berry_a" else 0.3)
		game.resize_target(0)
		_expect(game.state.is_balanced() and game.state.checkpoint == 2 and game.displayed_weight == 5, "Scene accepts the solution with small " + small)
		game.pip.position = Stage.RAMP_START + Vector3(-0.25, -0.06, 0)
		var walk: Dictionary = _walk_to_x(4.6, 260, true)
		_expect(walk.reached and is_equal_approx(game.pip.position.y, 1.8) and not game.state.completed, "InputMap movement climbs the whole balanced ramp and reaches the ledge with " + small)
		_expect(walk.max_up <= 0.23, "Balanced crossing uses continuous support instead of an upward floor snap")
		_expect(walk.foot_depth < 0.02, "Pip's primary feet remain within two centimeters of the actual rendered support during the slope crossing")
		worst_foot_depth = maxf(worst_foot_depth, walk.foot_depth)


func _test_occupied_ramp() -> void:
	_setup(2)
	game.pip.position = Stage.RAMP_START + Vector3(0.05, 0, 0)
	game.pip.position.y = game.surface_height(game.pip.position)
	game.target = "berry_b"
	_expect(game.ramp_occupied(), "Occupancy fixture stands on the authored cardboard path")
	var before: Dictionary = game.state.to_dict()
	var pose: Transform3D = game.ramp.transform
	game.resize_target(2)
	game.interact()
	_expect(game.state.to_dict() == before and game.ramp.transform == pose, "Occupied ramp cannot resize or roll its supporting berries")
	game.pip.position = Vector3(-4.0, 0.06, 0.3)
	game.resize_target(2)
	_expect(not game.state.is_balanced() and game.state.checkpoint == 2, "Stepping off permits reversible overweight experiments while retaining checkpoint two")
	game.on_command("reset", null)
	_expect(game.state.is_balanced() and game.displayed_weight == 5, "Reset restores the balanced occupied-path solution after an experiment")


func _test_canonical_recovery() -> void:
	for checkpoint: int in range(3):
		_setup(checkpoint)
		game.state.discover()
		for kind: String in State.PROP_KINDS:
			if game.state.sockets[kind] == "flap": game.state.interact(kind)
			game.state.resize(kind, 0)
		game.sync_props(false)
		game.pip.position = Vector3(2, 4, 4)
		game.vertical_speed = -5
		game.jump_buffer = 0.1
		game.recover("Ballast recovery scenario")
		_expect(game.state.checkpoint == checkpoint and game.displayed_weight == [0, 8, 5][checkpoint], "Recovery restores the canonical mechanism at checkpoint %d" % checkpoint)
		_expect(game.state.discovered and game.state.carried == "" and _props_match_rules(), "Recovery restores visible berries while preserving discovery at checkpoint %d" % checkpoint)
		_expect(_safe_respawn() and game.vertical_speed == 0 and game.jump_buffer == 0, "Recovery settles Pip on valid dry support and clears falling at checkpoint %d" % checkpoint)
		var copy = State.new()
		_expect(copy.restore(game.chapter_profile.stage_snapshot(Stage.STAGE_ID)) and copy.checkpoint == checkpoint, "Recovery persists a valid stage checkpoint %d" % checkpoint)
		game.on_command("pause", null)
		game.on_command("reset", null)
		_expect(not game.paused and _safe_respawn() and game.state.checkpoint == checkpoint, "Paused menu reset resumes safely at checkpoint %d" % checkpoint)


func _test_paused_resize_title() -> void:
	_setup(0)
	game.reduced_motion = false
	game.target = "berry_b"
	game.resize_target(2)
	await create_timer(0.07).timeout
	var berry: Node3D = game.props["berry_b"]
	_expect(int(game.state.sizes["berry_b"]) == 2 and not berry.scale.is_equal_approx(Vector3.ONE * 2), "Title scenario begins during a real berry resize")
	game.on_command("pause", null)
	var before: Vector3 = berry.scale
	await create_timer(0.08).timeout
	_expect(berry.scale.is_equal_approx(before), "Pause freezes the partial berry resize")
	game.on_command("controls", null)
	game.on_command("pause", null)
	game.on_command("title", null)
	_expect(not game.started and not game.paused and game.paused_tweens.is_empty(), "Title return releases nested paused resize and mechanism transitions")
	await create_timer(0.9).timeout
	_expect(berry.scale.is_equal_approx(Vector3.ONE * 2) and not game.mechanism_busy(), "Berry and mechanism finish settling on the title screen")
	game.on_command("start", null)
	_expect(game.started and not game.paused and _safe_respawn(), "Continue after paused resize resumes safely")
	game.reduced_motion = true


func _test_completion_lifecycle() -> void:
	_setup(2)
	game.pip.position = Stage.TOWER_POS + Vector3(0, 0, 1.35)
	game.interact()
	_expect(game.state.discovered, "Actual counterweight inspection records discovery")
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(game.state.completed and game.last_save_ok and game.ever_completed, "Actual balanced exit completes and durably saves the stage")
	_expect(game.chapter_profile.completed_ids() == ["W01S01", "W01S02"] and game.chapter_profile.is_unlocked("W01S03"), "Stage-two completion preserves its prerequisite and unlocks stage three")
	game.move_pip(1.3)
	_expect(game.paused and game.hud.menu_mode == "complete", "Completed ballast celebration reaches its completion menu")
	var reloaded: Node3D = _create_scene()
	_expect(reloaded.has_save and reloaded.state.completed and reloaded.ever_completed and reloaded.paused, "Fresh actual scene loads completed ballast and its chapter history")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame
	game.on_command("explore", null)
	_expect(game.exploring and not game.paused and not game.state.completed and game.state.is_balanced() and game.state.discovered, "Keep exploring restores a playable balanced crossing and discovery")
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(not game.state.completed, "Exploration can revisit the exit without repeating completion")
	game.on_command("title", null)
	reloaded = _create_scene()
	_expect(reloaded.has_save and not reloaded.state.completed and reloaded.ever_completed and reloaded.state.is_balanced(), "Exploration save reloads playable while retaining earned chapter history")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame
	game.on_command("new", null)
	_expect(game.state.checkpoint == 0 and game.state.total_weight() == 0 and _props_match_rules(), "Replay resets stage-two rules and physical mechanism to the opening")
	_expect(game.ever_completed and game.chapter_profile.completed_ids() == ["W01S01", "W01S02"], "Replay does not erase earned chapter completions")


func _test_failed_completion_retry() -> void:
	var previous_profile: Progress = game.chapter_profile
	var isolated = Progress.new()
	isolated.save_path = profile_path + ".retry"
	_expect(isolated.complete_stage("W01S01"), "Failed-write fixture has only its genuine prerequisite")
	isolated.save_path = profile_path + ".missing/profile.json"
	game.chapter_profile = isolated
	_setup(2)
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(game.state.completed and not game.last_save_ok and not game.ever_completed, "Failed finish write retains the achieved session state without claiming a durable clear")
	_expect(isolated.completed_ids() == ["W01S01"] and isolated.stage_snapshot(Stage.STAGE_ID).is_empty(), "Failed atomic save applies neither completion nor a partial stage snapshot")
	_expect(game.hud.message.text.contains("could not be saved"), "Immediate completion feedback explains a failed write")
	isolated.save_path = profile_path + ".retry"
	game.save_game()
	var reader = Progress.new()
	reader.save_path = isolated.save_path
	var loaded: bool = reader.load_profile()
	var copy = State.new()
	_expect(game.last_save_ok and loaded and reader.is_completed(Stage.STAGE_ID) and copy.restore(reader.stage_snapshot(Stage.STAGE_ID)) and copy.completed, "Retry saves the completed snapshot and chapter clear together for a fresh reader")
	game.chapter_profile = previous_profile
	game.ever_completed = previous_profile.is_completed(Stage.STAGE_ID)


func _setup(checkpoint: int) -> void:
	_release_movement()
	if game.paused: game.on_command("resume", null)
	game.state = _fixture(checkpoint)
	game.started = true
	game.exploring = false
	game.recovery_time = 0
	game.celebration_time = 0
	game.vertical_speed = 0
	game.jump_buffer = 0
	game.landing_squash = 0
	game.reduced_motion = true
	game.pip_art.transform = Transform3D.IDENTITY
	game.sync_props(false)
	game.respawn()


func _fixture(checkpoint: int) -> State:
	var rules = State.new()
	if checkpoint > 0:
		for kind: String in State.PROP_KINDS:
			rules.resize(kind, 2)
			rules.interact(kind)
	if checkpoint == 2: rules.resize("berry_b", 0)
	return rules


func _props_match_rules() -> bool:
	for kind: String in State.PROP_KINDS:
		var prop: Node3D = game.props[kind]
		if not prop.position.is_equal_approx(game.prop_position(kind)) or not prop.scale.is_equal_approx(Vector3.ONE * Stage.SCALE_VALUES[int(game.state.sizes[kind])]): return false
	return true


func _safe_respawn() -> bool:
	return game.surface_height(game.pip.position) >= 0 and not game.obstructed(game.pip.position) and is_equal_approx(game.pip.position.y, game.surface_height(game.pip.position))


func _walk_to_x(destination: float, frames: int, check_feet: bool = false) -> Dictionary:
	_press_direction(Vector3.RIGHT)
	var result: Dictionary = {"reached": false, "max_up": 0.0, "foot_depth": 0.0}
	for step: int in range(frames):
		var previous_y: float = game.pip.position.y
		if check_feet: game._process(1.0 / 60.0)
		else: game.move_pip(1.0 / 60.0)
		result.max_up = maxf(result.max_up, game.pip.position.y - previous_y)
		if check_feet: result.foot_depth = maxf(result.foot_depth, _foot_depth())
		if game.pip.position.x >= destination:
			result.reached = true
			break
	_release_movement()
	return result


func _press_direction(desired: Vector3) -> void:
	_release_movement()
	var right: Vector3 = game.camera.global_basis.x
	var back: Vector3 = game.camera.global_basis.z
	right.y = 0
	back.y = 0
	var horizontal: float = desired.dot(right.normalized())
	var vertical: float = desired.dot(back.normalized())
	Input.action_press("move_right" if horizontal > 0 else "move_left", absf(horizontal))
	Input.action_press("move_down" if vertical > 0 else "move_up", absf(vertical))


func _release_movement() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down"]: Input.action_release(action)


func _actor_enters_mesh(solid: MeshInstance3D) -> bool:
	var bounds: AABB = solid.mesh.get_aabb()
	for part: String in ["Body", "FootL", "FootR"]:
		var actor: MeshInstance3D = game.pip_art.get_node(part)
		var transform: Transform3D = solid.global_transform.affine_inverse() * actor.global_transform
		for vertex: Vector3 in actor.mesh.get_faces():
			if bounds.has_point(transform * vertex): return true
	return false


func _plane_height(surface: MeshInstance3D, point: Vector3) -> float:
	var origin: Vector3 = surface.to_global(Vector3(0, surface.mesh.get_aabb().end.y, 0))
	var normal: Vector3 = surface.global_basis.y.normalized()
	return origin.y - (normal.x * (point.x - origin.x) + normal.z * (point.z - origin.z)) / normal.y


func _foot_depth() -> float:
	var result: float = 0.0
	for part: String in ["FootL", "FootR"]:
		var foot: MeshInstance3D = game.pip_art.get_node(part)
		for vertex: Vector3 in foot.mesh.get_faces():
			var point: Vector3 = foot.to_global(vertex)
			for surface: MeshInstance3D in [game.ramp.get_node("Surface"), game.get_node("FoldoutLandingLip"), game.get_node("CerealBoxLedge/LandingTop")]:
				var top: float = _plane_height(surface, point)
				var local: Vector3 = surface.to_local(Vector3(point.x, top, point.z))
				var bounds: AABB = surface.mesh.get_aabb()
				if local.x >= bounds.position.x and local.x <= bounds.end.x and local.z >= bounds.position.z and local.z <= bounds.end.z:
					result = maxf(result, top - point.y)
					if top - point.y > worst_foot_depth:
						worst_foot_depth = top - point.y
						worst_foot_probe = {"pip": game.pip.position, "foot": part, "vertex": point, "surface": surface.name, "surface_y": top, "foot_rotation": foot.rotation, "art_y": game.pip_art.position.y, "squash": game.landing_squash}
	return result


func _cleanup() -> void:
	for base: String in [profile_path, profile_path + ".retry", demo_path]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(base + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(base + suffix))
	if FileAccess.file_exists(settings_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
