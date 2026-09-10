extends SceneTree
## Scene scenarios use rule/position fixtures; production interactions, tweens,
## movement, menus, and persistence remain real. This is not an input replay.
const Stage = preload("res://scripts/chapter/milk_harbor.gd")
const State = preload("res://scripts/chapter/harbor_state.gd")
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
var game: Node3D
var profile_path: String
var settings_path: String
var demo_path: String
var checks := 0
var failures := 0
var vertices: Dictionary = {}
var faces: Dictionary = {}
var rims: Array[MeshInstance3D] = []
var floor_mesh: MeshInstance3D
var contact_evidence: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	profile_path = "user://harbor_scene_test_%d.json" % OS.get_process_id()
	settings_path = "user://harbor_scene_settings_%d.cfg" % OS.get_process_id()
	demo_path = "user://harbor_scene_demo_%d.json" % OS.get_process_id()
	_cleanup()
	var seed = Progress.new()
	seed.save_path = profile_path
	_expect(seed.complete_stage("W01S01") and seed.complete_stage("W01S02") and seed.completed_ids() == ["W01S01", "W01S02"], "Fixture seeds only the two prerequisite clears")
	game = _create_scene()
	_expect(game.chapter_profile.save_path == profile_path and game.settings_path == settings_path and game.save_path == demo_path, "All three storage paths are isolated before ready")
	_expect(game.props.keys().size() == 2 and game.props.has("cereal") and game.props.has("cargo") and not game.has_save, "Harbor starts with its own raft and parcel, without a fabricated stage save")
	_expect(game.hud.controls.text.contains("Board / Sail"), "Harbor footer describes its actual boarding and sailing control")
	for child in game.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var size: Vector3 = child.mesh.size
			if size.y > 0.45 and minf(size.x, size.z) < 0.2: rims.append(child)
			elif size.x > 9 and size.z > 11 and is_equal_approx(size.y, 0.08): floor_mesh = child
	_expect(rims.size() == 4 and floor_mesh != null, "Independent probe locates all four rendered ceramic walls and the actual dish floor")
	await process_frame
	await process_frame
	print("Harbor geometry: " + JSON.stringify({"near_x": Stage.NEAR_X, "far_x": Stage.FAR_X, "dock_hinge": Stage.DOCK_HINGE, "water_y": Stage.WATER_Y}))
	_test_static_contacts()
	if not "--contacts-only" in OS.get_cmdline_user_args():
		await _test_resize_guards()
		_test_shore_rims()
		await _test_rider_paths()
		await _test_voyage_and_shoal()
		_test_recovery()
		await _test_pause_and_title()
		await _test_interrupted_voyages()
		await _test_completion()
		_test_failed_completion_retry()
	await game.stop_audio()
	game.queue_free()
	await process_frame
	_release_movement()
	_cleanup()
	print("Contact probe evidence: " + JSON.stringify(contact_evidence))
	print("%s: %d Milk Harbor scene checks; actual mesh contacts, boarding, cargo lift, voyages, recovery, interrupted saves, menus, and durable completion." % ["PASS" if failures == 0 else "FAIL", checks])
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


func _test_static_contacts() -> void:
	var floor_top: float = _extreme_y(floor_mesh, true)
	for raft: int in [0, 1]:
		for cargo: int in range(3):
			_setup(0)
			game.state.resize("cereal", raft)
			game.state.resize("cargo", cargo)
			game.sync_props(false)
			var deck: MeshInstance3D = game.props.cereal.get_node("Deck")
			var parcel: MeshInstance3D = game.props.cargo.get_node("WrappedSugar")
			var parcel_bottom: Vector3 = parcel.to_global(Vector3(0, parcel.mesh.get_aabb().position.y, 0))
			var local: Vector3 = deck.to_local(parcel_bottom)
			var support: AABB = deck.mesh.get_aabb()
			_expect(absf(parcel_bottom.y - _extreme_y(deck, true)) < 0.002 and local.x > support.position.x and local.x < support.end.x and local.z > support.position.z and local.z < support.end.z, "Parcel center remains physically supported during raft %d/cargo %d experiments" % [raft, cargo])
	for checkpoint: int in [1, 2, 3]:
		for cargo: int in range(3):
			_setup(checkpoint)
			game.state.resize("cargo", cargo)
			game.sync_props(false)
			game.respawn()
			var deck: MeshInstance3D = game.props.cereal.get_node("Deck")
			var parcel: MeshInstance3D = game.props.cargo.get_node("WrappedSugar")
			var ring: MeshInstance3D = game.props.cereal.get_node("CerealRing")
			_expect(is_equal_approx(_extreme_y(deck, true), game.deck_height()) and absf(_extreme_y(parcel, false) - _extreme_y(deck, true)) < 0.002, "Actual parcel floor and rendered deck agree at stop %d, cargo %d" % [checkpoint, cargo])
			_expect(_extreme_y(ring, false) >= floor_top - 0.002, "Actual cereal hull clears the ceramic floor at stop %d, cargo %d" % [checkpoint, cargo])
			var hull_wall: Dictionary = _mesh_contact(ring, rims)
			_expect(hull_wall.is_empty(), "Actual cereal ring clears every ceramic side wall at stop %d, cargo %d" % [checkpoint, cargo])
			if not hull_wall.is_empty(): contact_evidence.append(hull_wall)
			if checkpoint == 2:
				_expect(_hull_shoal_contact().is_empty() and _actor_contact().is_empty(), "Grounded or light raft and its rider clear the actual shoal/parcel meshes with cargo %d" % cargo)
			if checkpoint == 3:
				var dock: MeshInstance3D = game.dock_leaf.get_node("SpoonSurface")
				var dock_ring: Dictionary = _mesh_contact(dock, [ring])
				if dock_ring.is_empty(): dock_ring = _mesh_contact(ring, [dock])
				_expect(dock_ring.is_empty(), "Actual spoon shell and cereal ring do not intersect at the far mooring with cargo %d" % cargo)
				if not dock_ring.is_empty(): contact_evidence.append(dock_ring)
				var dock_deck: Dictionary = _mesh_contact(dock, [deck])
				if dock_deck.is_empty(): dock_deck = _mesh_contact(deck, [dock])
				_expect(dock_deck.is_empty(), "Actual spoon shell and wafer deck do not intersect with cargo %d" % cargo)
				if not dock_deck.is_empty(): contact_evidence.append(dock_deck)
	_setup(3)
	var spoon: MeshInstance3D = game.dock_leaf.get_node("SpoonSurface")
	var clear := true
	for point: Vector3 in _vertices(spoon.mesh):
		for rim: MeshInstance3D in rims:
			if _inside(rim, spoon.to_global(point), 0.002): clear = false
	_expect(clear, "Every rendered open spoon vertex clears the full ceramic rim")
	_expect(game.dock_leaf.get_node("OuterAnchor").global_position.y > _extreme_y(floor_mesh, true) + 0.5, "Deployed spoon endpoint is visibly raised above the dish floor")


func _test_resize_guards() -> void:
	_setup(0)
	game.pip.position = Stage.NEAR_BANK
	game.target = "cereal"
	var before: Dictionary = game.state.to_dict()
	game.interact()
	_expect(game.state.to_dict() == before and not game.changing_rider, "Normal loop cannot start a boarding animation")
	game.reduced_motion = false
	game.resize_target(2)
	_expect(game.state.checkpoint == 1 and game.busy() and int(game.state.sizes.cargo) == 1, "Growing the raft starts a real transition and leaves the parcel independently normal")
	before = game.state.to_dict()
	game.interact()
	game.target = "cargo"
	game.resize_target(0)
	_expect(game.state.to_dict() == before and not game.state.aboard, "Busy raft resize rejects boarding and another resize")
	await _settle()
	_expect(game.props.cereal.scale.is_equal_approx(Vector3.ONE * 2) and game.props.cargo.scale.is_equal_approx(Vector3.ONE), "Raft and parcel settle at their independent authored sizes")
	_setup(1)
	game.target = "cargo"
	game.pip.position = game.props.cargo.position + Vector3(-0.77, 0, 0)
	var parcel: MeshInstance3D = game.props.cargo.get_node("WrappedSugar")
	_expect(_actor_contact([parcel]).is_empty(), "Growth fixture starts clear of the normal parcel's actual rounded mesh")
	game.props.cargo.scale = Vector3.ONE * 2
	_expect(not _actor_contact([parcel]).is_empty(), "Requested large parcel would cover an actual Pip body or foot vertex")
	game.props.cargo.scale = Vector3.ONE
	before = game.state.to_dict()
	game.resize_target(2)
	_expect(game.state.to_dict() == before and game.props.cargo.scale == Vector3.ONE, "Production parcel growth guard refuses the independently demonstrated overlap")
	_setup(2)
	game.target = "cereal"
	before = game.state.to_dict()
	game.resize_target(0)
	var jump := InputEventAction.new()
	jump.action = "jump"
	jump.pressed = true
	game._unhandled_input(jump)
	_expect(game.state.to_dict() == before and game.jump_buffer == 0, "Aboard raft cannot shrink or launch a jump off its support")
	var position: Vector3 = game.pip.position
	_press_direction(Vector3.RIGHT)
	for frame: int in range(30): game.move_pip(1.0 / 60.0)
	_release_movement()
	_expect(game.pip.position == position, "Ordinary walking cannot leave the raft while aboard")


func _test_shore_rims() -> void:
	for checkpoint: int in [1, 3]:
		_setup(checkpoint)
		var direction: Vector3 = Vector3.RIGHT if checkpoint == 1 else Vector3.LEFT
		game.pip.position = Vector3(-5.1 if checkpoint == 1 else 5.1, 0.06, 3.5)
		game.pip_art.rotation.y = PI / 2 if checkpoint == 1 else -PI / 2
		_expect(not _actor_contact(rims).is_empty(), "Unsafe shore-edge fixture demonstrates actual body/rim overlap on side %d" % checkpoint)
		game.pip.position.x = -5.75 if checkpoint == 1 else 5.75
		_press_direction(direction)
		var clear := true
		for frame: int in range(60):
			game._process(1.0 / 60.0)
			clear = clear and _actor_contact(rims).is_empty()
		_release_movement()
		_expect(clear and game.recovery_time == 0 and is_equal_approx(game.pip.position.y, 0.06), "Ordinary walking stops clear of the actual ceramic wall on shore %d" % checkpoint)


func _test_rider_paths() -> void:
	_setup(1)
	game.pip.position = Stage.NEAR_BANK
	game.reduced_motion = false
	game.interact()
	_expect(game.changing_rider and game.state.aboard and game.flying, "Near mooring interaction starts the actual boarding hop")
	var before: Dictionary = game.state.to_dict()
	game.interact()
	game.target = "cargo"
	game.resize_target(0)
	_expect(game.state.to_dict() == before, "Boarding blocks duplicate interactions and parcel edits")
	var sample: Dictionary = await _settle(true)
	_expect(sample.samples > 10 and sample.contact.is_empty(), "Animated near boarding clears the actual ceramic rim and parcel")
	_expect(game.state.aboard and not game.changing_rider and not game.flying and game.pip.position.is_equal_approx(game.aboard_position()), "Near boarding settles Pip on the rendered deck")
	for cargo: int in [0, 2]:
		_setup(3)
		game.state.resize("cargo", cargo)
		game.state.board()
		game.sync_props(false)
		game.respawn()
		game.reduced_motion = false
		game.interact()
		_expect(not game.state.aboard and game.changing_rider, "Far mooring starts disembarking with cargo %d" % cargo)
		sample = await _settle(true)
		_expect(sample.samples > 20 and sample.contact.is_empty(), "Far disembark path clears the actual parcel, spoon, and rim with cargo %d" % cargo)
		_expect(game.pip.position.is_equal_approx(Stage.FAR_BANK) and _safe_respawn(), "Far disembark reaches dry authored support with cargo %d" % cargo)
		game.interact()
		_expect(game.state.aboard and game.changing_rider, "Far bank permits a fresh boarding hop with cargo %d" % cargo)
		sample = await _settle(true)
		_expect(sample.samples > 20 and sample.contact.is_empty(), "Reverse boarding clears the same actual solid geometry with cargo %d" % cargo)
		_expect(game.pip.position.is_equal_approx(game.aboard_position()) and not game.changing_rider, "Reverse boarding settles on the changed-draft deck with cargo %d" % cargo)


func _test_voyage_and_shoal() -> void:
	_setup(1)
	game.state.resize("cargo", 2)
	game.state.board()
	game.sync_props(false)
	game.respawn()
	game.interact()
	_expect(game.in_transit() and game.state.phase == "to_shoal", "Heavy cargo may begin the first actual voyage")
	var before: Dictionary = game.state.to_dict()
	game.target = "cargo"
	game.resize_target(0)
	game.interact()
	_expect(game.state.to_dict() == before, "Transit rejects resizing and a second departure")
	var sample: Dictionary = await _settle(true, true)
	_expect(sample.samples > 50 and sample.hull_contact.is_empty() and sample.contact.is_empty(), "Moving heavy raft and rider clear the actual shoal, parcel, and ceramic meshes")
	_expect(game.state.phase == "shoal" and game.state.checkpoint == 2 and game.state.aboard, "Actual voyage reaches the safe shoal checkpoint aboard")
	for cargo: int in [2, 1]:
		game.resize_target(cargo)
		before = game.state.to_dict()
		game.interact()
		_expect(game.state.to_dict() == before and not game.in_transit(), "Visible shallow ridge refuses onward travel with cargo %d" % cargo)
	var ring: MeshInstance3D = game.props.cereal.get_node("CerealRing")
	var grounded_bottom: float = _extreme_y(ring, false)
	game.resize_target(0)
	_expect(game.state.cargo_clear() and _extreme_y(ring, false) > grounded_bottom + 0.08, "Shrinking the parcel visibly raises the actual hull clear of its grounded draft")
	_expect(absf(_extreme_y(game.props.cargo.get_node("WrappedSugar"), false) - _extreme_y(game.props.cereal.get_node("Deck"), true)) < 0.002, "Lift keeps the independently scaled parcel resting on the deck")
	game.interact()
	_expect(game.state.phase == "to_far", "Light cargo can begin the second voyage")
	sample = await _settle(true, true)
	_expect(sample.hull_contact.is_empty() and sample.contact.is_empty(), "Light second voyage clears the actual shoal and keeps the rider clear of cargo")
	_expect(game.state.phase == "far" and game.state.checkpoint == 3 and game.state.dock_open and not game.busy(), "Far arrival opens and fully settles the latched spoon dock")
	var saved = State.new()
	_expect(saved.restore(game.chapter_profile.stage_snapshot(Stage.STAGE_ID)) and saved.phase == "far" and saved.aboard and saved.dock_open, "Arrival durably saves the valid aboard far-mooring state")


func _test_recovery() -> void:
	for checkpoint: int in range(4):
		_setup(checkpoint)
		game.state.discover()
		game.state.resize("cargo", 2)
		game.sync_props(false)
		game.pip.position = Vector3(0, -3, 3)
		game.vertical_speed = -5
		game.jump_buffer = 0.1
		game.recover("Harbor recovery scenario")
		_expect(game.state.checkpoint == checkpoint and game.state.to_dict().sizes == _fixture(checkpoint).to_dict().sizes, "Recovery reconstructs canonical raft and parcel at checkpoint %d" % checkpoint)
		_expect(game.state.discovered and _safe_respawn() and game.vertical_speed == 0 and game.jump_buffer == 0, "Recovery retains discovery and clears falling on valid support at checkpoint %d" % checkpoint)
		var copy = State.new()
		_expect(copy.restore(game.chapter_profile.stage_snapshot(Stage.STAGE_ID)) and copy.checkpoint == checkpoint, "Recovery persists a valid mooring snapshot at checkpoint %d" % checkpoint)
		game.on_command("pause", null)
		game.on_command("reset", null)
		_expect(not game.paused and not game.busy() and _safe_respawn(), "Paused reset resumes safely at checkpoint %d" % checkpoint)
		if checkpoint != 2:
			game.recovery_time = 0
			game.pip.position = Vector3(-5.6 if checkpoint < 3 else 5.6, 0.06, 3.5)
			var jump := InputEventAction.new()
			jump.action = "jump"
			jump.pressed = true
			game._unhandled_input(jump)
			_press_direction(Vector3.RIGHT if checkpoint < 3 else Vector3.LEFT)
			var max_y: float = game.pip.position.y
			var clear := true
			for step: int in range(75):
				game._process(1.0 / 60.0)
				max_y = maxf(max_y, game.pip.position.y)
				clear = clear and _actor_contact(rims).is_empty()
				if game.recovery_time > 0: break
			_release_movement()
			_expect(max_y > _extreme_y(rims[0], true) and clear, "Actual jump clears the full ceramic wall before a splash at checkpoint %d" % checkpoint)
			_expect(game.recovery_time > 0 and game.state.checkpoint == checkpoint and _safe_respawn(), "Actual jump into milk restores the authored mooring at checkpoint %d" % checkpoint)


func _test_pause_and_title() -> void:
	_setup(0)
	game.pip.position = Stage.NEAR_BANK
	game.reduced_motion = false
	game.target = "cereal"
	game.resize_target(2)
	await create_timer(0.07).timeout
	game.on_command("pause", null)
	var partial: Vector3 = game.props.cereal.scale
	await create_timer(0.08).timeout
	_expect(partial.x > 1 and partial.x < 2 and game.props.cereal.scale == partial, "Pause freezes an actual partial raft resize")
	game.on_command("controls", null)
	game.on_command("pause", null)
	game.on_command("title", null)
	await _settle()
	_expect(not game.started and not game.paused and game.paused_tweens.is_empty() and game.props.cereal.scale.is_equal_approx(Vector3.ONE * 2), "Nested menu and title return release suspended raft resize")
	game.on_command("start", null)
	_expect(game.started and _safe_respawn(), "Continue remains supported after a paused resize")
	for reset: bool in [false, true]:
		_setup(1)
		game.pip.position = Stage.NEAR_BANK
		game.interact()
		await create_timer(0.12).timeout
		game.on_command("pause", null)
		var position: Vector3 = game.pip.position
		var clock_before: float = game.t
		game._process(0.3)
		await create_timer(0.08).timeout
		_expect(game.pip.position == position and game.t == clock_before and game.changing_rider, "Pause freezes an in-progress boarding hop")
		game.on_command("reset" if reset else "title", null)
		await _settle()
		await create_timer(0.8).timeout
		if not reset: game.on_command("start", null)
		_expect(not game.paused and not game.changing_rider and not game.flying and _safe_respawn() and game.state.aboard == (not reset), "Boarding %s releases transient animation and stale callbacks safely" % ("reset" if reset else "title/continue"))


func _test_interrupted_voyages() -> void:
	for checkpoint: int in [1, 2]:
		_setup(checkpoint)
		if checkpoint == 1: game.state.board()
		else: game.state.resize("cargo", 0)
		game.sync_props(false)
		game.respawn()
		game.interact()
		await create_timer(0.18).timeout
		game.refresh_boat()
		game.on_command("pause", null)
		var boat_position: Vector3 = game.props.cereal.position
		var rider_position: Vector3 = game.pip.position
		var phase: String = game.state.phase
		game._process(0.4)
		await create_timer(0.08).timeout
		_expect(game.props.cereal.position == boat_position and game.pip.position == rider_position and game.state.phase == phase, "Pause freezes boat and rider during voyage from checkpoint %d" % checkpoint)
		var reloaded: Node3D = _create_scene()
		_expect(reloaded.has_save and reloaded.state.recovered_motion and reloaded.state.checkpoint == checkpoint and reloaded.state.phase == ("near" if checkpoint == 1 else "shoal"), "Fresh disk restore recovers interrupted voyage %d at its canonical mooring" % checkpoint)
		_expect(reloaded.state.aboard == (checkpoint == 2) and int(reloaded.state.sizes.cargo) == 1 and reloaded.pip.position.y > 0, "Interrupted voyage restores the canonical cargo and rider placement")
		_expect(reloaded.save_notice.contains("last mooring") and reloaded.hud.message.text.contains("last mooring"), "Interrupted reload explains recovery in the actual start notice")
		await reloaded.stop_audio()
		reloaded.queue_free()
		await process_frame
		game.on_command("title", null)
		await _settle()
		game.on_command("start", null)
		_expect(game.state.phase == ("shoal" if checkpoint == 1 else "far") and game.state.aboard and not game.busy() and _safe_respawn(), "Title and continue allow suspended voyage %d to settle safely" % checkpoint)
		_setup(checkpoint)
		if checkpoint == 1: game.state.board()
		else: game.state.resize("cargo", 0)
		game.sync_props(false)
		game.respawn()
		game.interact()
		await create_timer(0.1).timeout
		game.on_command("pause", null)
		game.on_command("reset", null)
		await create_timer(2.75).timeout
		_expect(not game.busy() and not game.flying and game.paused_tweens.is_empty() and game.state.checkpoint == checkpoint and _safe_respawn(), "Paused voyage %d reset cancels all later callbacks and restores safe support" % checkpoint)


func _test_completion() -> void:
	_setup(0)
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(not game.state.completed, "Injected far flag location cannot bypass the harbor progression rules")
	_setup(3)
	game.pip.position = game.far_friends.position + Vector3(0, 0, 1.1)
	game.interact()
	_expect(game.state.discovered, "Actual far crew interaction records the optional discovery")
	game.pip.position = Stage.FAR_BANK
	_press_direction(Vector3.RIGHT)
	for step: int in range(30):
		game.move_pip(1.0 / 60.0)
		if game.state.completed: break
	_release_movement()
	_expect(game.state.completed and game.last_save_ok and game.ever_completed, "Ordinary movement from far mooring reaches the flag and saves completion")
	_expect(game.chapter_profile.completed_ids() == ["W01S01", "W01S02", "W01S03"] and game.chapter_profile.is_unlocked("W01S04"), "Harbor completion atomically extends the genuine chapter prefix")
	game.move_pip(1.3)
	_expect(game.paused and game.hud.menu_mode == "complete", "Arrival celebration reaches the real completion menu")
	var reloaded: Node3D = _create_scene()
	_expect(reloaded.has_save and reloaded.state.completed and reloaded.ever_completed and reloaded.paused, "Fresh scene restores completed harbor and durable history")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame
	game.on_command("explore", null)
	_expect(game.exploring and not game.paused and not game.state.completed and game.state.discovered and _safe_respawn(), "Keep exploring restores a safe far mooring while retaining discovery")
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(not game.state.completed, "Exploration may revisit the flag without retriggering completion")
	game.on_command("title", null)
	reloaded = _create_scene()
	_expect(reloaded.has_save and not reloaded.state.completed and reloaded.ever_completed and reloaded.state.dock_open, "Exploration reload remains playable while retaining chapter completion")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame
	game.on_command("new", null)
	_expect(game.state.checkpoint == 0 and game.state.phase == "near" and game.state.sizes == {"cereal": 1, "cargo": 1} and _safe_respawn(), "Replay restores the opening raft, parcel, and dry starting position")
	_expect(game.ever_completed and game.chapter_profile.completed_ids() == ["W01S01", "W01S02", "W01S03"], "Replay preserves all earned chapter history")


func _test_failed_completion_retry() -> void:
	var previous: Progress = game.chapter_profile
	var isolated = Progress.new()
	isolated.save_path = profile_path + ".retry"
	_expect(isolated.complete_stage("W01S01") and isolated.complete_stage("W01S02"), "Failed-write fixture seeds only harbor prerequisites")
	isolated.save_path = profile_path + ".missing/profile.json"
	game.chapter_profile = isolated
	_setup(3)
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(game.state.completed and not game.last_save_ok and not game.ever_completed, "Failed finish write retains session achievement without claiming a durable clear")
	_expect(isolated.completed_ids() == ["W01S01", "W01S02"] and isolated.stage_snapshot(Stage.STAGE_ID).is_empty(), "Failed completion commit applies neither stage snapshot nor chapter clear")
	_expect(game.hud.message.text.contains("could not be saved"), "Completion feedback honestly reports the failed write")
	isolated.save_path = profile_path + ".retry"
	game.save_game()
	var reader = Progress.new()
	reader.save_path = isolated.save_path
	var loaded: bool = reader.load_profile()
	var copy = State.new()
	_expect(game.last_save_ok and loaded and reader.is_completed(Stage.STAGE_ID) and copy.restore(reader.stage_snapshot(Stage.STAGE_ID)) and copy.completed, "Retry commits completed snapshot and history together for a new reader")
	game.chapter_profile = previous
	game.ever_completed = previous.is_completed(Stage.STAGE_ID)


func _fixture(checkpoint: int) -> State:
	var state = State.new()
	if checkpoint > 0: state.resize("cereal", 2)
	if checkpoint > 1:
		state.board()
		state.depart()
		state.arrive()
	if checkpoint > 2:
		state.resize("cargo", 0)
		state.depart()
		state.arrive()
		state.disembark()
	return state


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
	game.resize_pose = 0
	game.reduced_motion = true
	game.pip_art.transform = Transform3D.IDENTITY
	game.sync_props(false)
	game.respawn()


func _safe_respawn() -> bool:
	return game.surface_height(game.pip.position) >= 0 and not game.obstructed(game.pip.position) and is_equal_approx(game.pip.position.y, game.surface_height(game.pip.position))


func _settle(contact: bool = false, hull: bool = false) -> Dictionary:
	var result: Dictionary = {"samples": 0, "contact": {}, "hull_contact": {}}
	var deadline: int = Time.get_ticks_msec() + 6000
	while game.busy() and Time.get_ticks_msec() < deadline:
		await process_frame
		game._process(1.0 / 60.0)
		result.samples += 1
		if contact and result.contact.is_empty(): result.contact = _actor_contact()
		if hull and result.hull_contact.is_empty(): result.hull_contact = _hull_shoal_contact()
	if not result.contact.is_empty(): contact_evidence.append(result.contact)
	if not result.hull_contact.is_empty(): contact_evidence.append(result.hull_contact)
	return result


func _vertices(mesh: Mesh) -> Array:
	var id: int = mesh.get_instance_id()
	if not vertices.has(id):
		var unique: Dictionary = {}
		for vertex: Vector3 in mesh.get_faces(): unique[vertex] = true
		vertices[id] = unique.keys()
	return vertices[id]


func _extreme_y(mesh: MeshInstance3D, maximum: bool) -> float:
	var result: float = -INF if maximum else INF
	for vertex: Vector3 in _vertices(mesh.mesh):
		var y: float = mesh.to_global(vertex).y
		result = maxf(result, y) if maximum else minf(result, y)
	return result


func _inside(mesh: MeshInstance3D, point: Vector3, margin: float = 0.01) -> bool:
	var local: Vector3 = mesh.to_local(point)
	var scale_min: float = minf(mesh.global_basis.x.length(), minf(mesh.global_basis.y.length(), mesh.global_basis.z.length()))
	if not mesh.mesh.get_aabb().grow(-margin / scale_min).has_point(local): return false
	if mesh.mesh is BoxMesh: return true
	if mesh.mesh is SphereMesh:
		var radius: float = mesh.mesh.radius
		return Vector3(local.x / radius, local.y / (mesh.mesh.height * 0.5), local.z / radius).length_squared() < 1.0
	if mesh.mesh is TorusMesh:
		var major: float = (mesh.mesh.outer_radius + mesh.mesh.inner_radius) * 0.5
		var minor: float = (mesh.mesh.outer_radius - mesh.mesh.inner_radius) * 0.5
		return Vector2(Vector2(local.x, local.z).length() - major, local.y).length_squared() < minor * minor
	var id: int = mesh.mesh.get_instance_id()
	if not faces.has(id): faces[id] = mesh.mesh.get_faces()
	var triangles: PackedVector3Array = faces[id]
	var ray := Vector3(0.937, 0.233, 0.261).normalized()
	var distances: Array[float] = []
	for index: int in range(0, triangles.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(local, ray, triangles[index], triangles[index + 1], triangles[index + 2])
		if hit != null:
			var distance: float = local.distance_to(hit)
			var duplicate := false
			for existing: float in distances:
				if absf(existing - distance) < 0.00001: duplicate = true
			if not duplicate: distances.append(distance)
	return distances.size() % 2 == 1


func _actor_contact(override_solids: Array = []) -> Dictionary:
	var solids: Array = override_solids
	if solids.is_empty():
		solids = rims.duplicate()
		solids.append(game.props.cargo.get_node("WrappedSugar"))
		solids.append(game.dock_leaf.get_node("SpoonSurface"))
		solids.append(game.props.cereal.get_node("CerealRing"))
	for part: String in ["Body", "FootL", "FootR"]:
		var actor: MeshInstance3D = game.pip_art.get_node(part)
		for solid: MeshInstance3D in solids:
			for vertex: Vector3 in _vertices(actor.mesh):
				var point: Vector3 = actor.to_global(vertex)
				if _inside(solid, point): return {"actor": part, "solid": str(solid.get_path()), "vertex": point, "pip": game.pip.position, "phase": game.state.phase, "cargo": game.state.sizes.cargo}
	return {}


func _mesh_contact(source: MeshInstance3D, solids: Array) -> Dictionary:
	for solid: MeshInstance3D in solids:
		for vertex: Vector3 in _vertices(source.mesh):
			var point: Vector3 = source.to_global(vertex)
			if _inside(solid, point, 0.002): return {"source": str(source.get_path()), "solid": str(solid.get_path()), "vertex": point, "phase": game.state.phase, "cargo": game.state.sizes.cargo}
	return {}


func _hull_shoal_contact() -> Dictionary:
	var hull: MeshInstance3D = game.props.cereal.get_node("CerealRing")
	for vertex: Vector3 in _vertices(hull.mesh):
		var point: Vector3 = hull.to_global(vertex)
		for crumb: MeshInstance3D in game.get_node("ShallowRidge").get_children():
			if _inside(crumb, point, 0.002): return {"solid": "ShallowRidge", "hull_vertex": point, "boat": game.props.cereal.position, "cargo": game.state.sizes.cargo}
	return {}


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
