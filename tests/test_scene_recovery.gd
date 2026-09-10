extends SceneTree
## Scenario regression tests using model fixtures and real scene recovery,
## movement, menu, save, and fresh-scene load paths. This is not a fresh-player
## input playthrough. Test saves are isolated and removed when the suite exits.

const Main = preload("res://scripts/main.gd")
const State = preload("res://scripts/puzzle_state.gd")
var game: Node3D
var checks: int = 0
var failures: int = 0
var test_path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	test_path = "user://scene_recovery_test_%d.json" % OS.get_process_id()
	_cleanup()
	game = Main.new()
	game.save_path = test_path
	root.add_child(game)
	game.set_process(false)
	game.reduced_motion = true
	game.on_command("start", true)
	_test_recovery_at_every_checkpoint()
	_test_milk_recovery()
	_test_permanent_crossings()
	_test_paused_flight_reset()
	await _test_fresh_scene_interrupted_flight()
	await _test_completion_exploration_history()
	await game.stop_audio()
	game.queue_free()
	await process_frame
	_cleanup()
	print("%s: %d scene recovery checks; checkpoint surfaces, prop recovery, return crossings, flight reset, and fresh reloads." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_recovery_at_every_checkpoint() -> void:
	for checkpoint: int in range(4):
		_setup(checkpoint)
		var carried_prop: String = "spoon" if checkpoint in [0, 3] else "napkin"
		game.state.resize(carried_prop, 0)
		game.state.interact(carried_prop)
		game.sync_props(false)
		_expect(game.state.carried == carried_prop, "Checkpoint %d fixture carries a movable prop" % checkpoint)
		game.pip.position = Vector3(-4.2, -1.0, 4.0)
		game.vertical_speed = -6
		game.jump_buffer = 0.1
		game.flying = true
		game.boarded = true
		var saves_before: int = game.save_count
		game.recover("Recovery scenario")
		_expect(game.state.checkpoint == checkpoint, "Recovery preserves checkpoint %d" % checkpoint)
		_expect(not game.flying and not game.boarded and game.vertical_speed == 0 and game.jump_buffer == 0, "Recovery clears transient flight and fall state at %d" % checkpoint)
		_expect(game.state.carried.is_empty() and game.state.sockets[carried_prop] == "tray", "Recovery returns previously carried prop to its stable tray at %d" % checkpoint)
		_expect(game.save_count == saves_before + 1, "Recovery saves restored checkpoint %d" % checkpoint)
		_assert_safe_respawn(game, "Recovery %d" % checkpoint)
		_assert_prop_sync("Recovery %d" % checkpoint)
		# Exercise the actual menu reset as a separate entry point while paused.
		game.on_command("pause", null)
		game.pip.position = Vector3(0, 3, 0)
		game.on_command("reset", null)
		_expect(not game.paused and not game.flying and not game.boarded, "Menu reset resumes controllable play at %d" % checkpoint)
		_assert_safe_respawn(game, "Menu reset %d" % checkpoint)


func _test_milk_recovery() -> void:
	for checkpoint: int in range(4):
		_setup(checkpoint)
		var saves_before: int = game.save_count
		game.pip.position = Vector3(-4.2, 0.8, 4.0)
		game.vertical_speed = -3.0
		_expect(game.surface_height(game.pip.position) < -1, "Milk scenario starts away from every crossing")
		game.move_pip(1.0 / 60.0)
		_expect(game.state.checkpoint == checkpoint and game.recovery_time > 0, "Missed milk landing recovers checkpoint %d" % checkpoint)
		_expect(game.save_count == saves_before + 1 and game.hud.message.text.contains("splash"), "Milk landing saves recovery and explains it at %d" % checkpoint)
		_assert_safe_respawn(game, "Milk recovery %d" % checkpoint)


func _test_permanent_crossings() -> void:
	_setup(2)
	game.state.resize("spoon", 0)
	game.state.interact("spoon")
	game.sync_props(false)
	_expect(not game.state.bridge_placed and game.state.carried == "spoon", "Return route test removes and carries the spoon")
	_cross(Vector3(-5.8, 0.06, -2.2), -2.75, "Permanent return bridge eastbound with spoon")
	_cross(Vector3(-2.75, 0.06, -2.2), -5.8, "Permanent return bridge westbound with spoon")
	game.state.place("tray")
	game.state.resize("blueberry", 0)
	game.state.interact("blueberry")
	game.sync_props(false)
	_expect(game.state.ramp_raised() and game.state.carried == "blueberry", "Latched cereal ramp stays raised while carrying its old ballast")
	_cross(Vector3(2.25, 0.06, 1.2), 5.6, "Latched cereal ramp eastbound without ballast")
	_cross(Vector3(5.6, 0.06, 1.2), 2.25, "Latched cereal ramp westbound without ballast")


func _test_paused_flight_reset() -> void:
	_setup(3)
	game.state.release_launch()
	game.begin_flight()
	game.update_flight(0.6)
	game.on_command("pause", null)
	_expect(game.flying and game.paused, "Flight reset scenario is paused in midair")
	game.on_command("reset", null)
	_expect(not game.flying and not game.boarded and not game.paused, "Reset from paused flight clears launch and pause modes")
	_expect(game.state.checkpoint == 3 and game.state.can_launch(), "Reset from flight preserves fully prepared launch")
	_expect(game.paused_tweens.is_empty(), "Reset does not retain stale paused transition references")
	_assert_safe_respawn(game, "Paused-flight reset")
	_assert_prop_sync("Paused-flight reset")
	# Frame stepping after the menu action catches stale flight state restarting.
	game._process(1.0 / 60.0)
	_expect(not game.flying and game.state.can_launch(), "Following frame remains safely at the launcher")


func _test_fresh_scene_interrupted_flight() -> void:
	_setup(3)
	game.state.release_launch()
	game.begin_flight()
	game.update_flight(0.7)
	var reloaded: Node3D = Main.new()
	reloaded.save_path = test_path
	root.add_child(reloaded)
	reloaded.set_process(false)
	_expect(reloaded.has_save and reloaded.state.checkpoint == 3, "Fresh scene loads the interrupted-flight save")
	_expect(reloaded.state.can_launch() and not reloaded.flying and not reloaded.boarded, "Fresh scene restores a prepared launcher rather than continuing midair")
	_expect(not reloaded.state.completed and not reloaded.ever_completed, "Interrupted flight does not award a stage clear")
	_assert_safe_respawn(reloaded, "Fresh interrupted-flight load")
	_expect(reloaded.pip.position.distance_to(reloaded.props["toaster"].position) < 2.25, "Reloaded launcher respawn can reach the toaster interaction")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame


func _test_completion_exploration_history() -> void:
	_setup(3)
	game.state.release_launch()
	game.begin_flight()
	game.update_flight(3.1)
	_expect(game.state.completed and game.ever_completed, "Actual scene landing records completed puzzle and earned profile clear")
	game.on_command("explore", null)
	_expect(game.exploring and not game.state.completed and not game.paused, "Completion Explore resumes ordinary play")
	_expect(game.ever_completed and game.state.can_launch(), "Explore retains earned clear and a replayable launch")
	_assert_safe_respawn(game, "Postcompletion exploration")
	game.on_command("title", null)
	var reloaded: Node3D = Main.new()
	reloaded.save_path = test_path
	root.add_child(reloaded)
	reloaded.set_process(false)
	_expect(reloaded.has_save and reloaded.ever_completed, "Leaving exploration and reloading retains profile clear")
	_expect(not reloaded.state.completed and reloaded.state.can_launch(), "Reloaded exploration remains playable rather than locking the completion menu")
	reloaded.on_command("start", true)
	_expect(reloaded.started and not reloaded.paused, "Continue after exploration opens playable scene")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame


func _cross(start: Vector3, destination_x: float, label: String) -> void:
	game.pip.position = start
	game.vertical_speed = 0
	game.recovery_time = 0
	var desired: Vector3 = Vector3.RIGHT if destination_x > start.x else Vector3.LEFT
	var right: Vector3 = game.camera.global_basis.x
	var back: Vector3 = game.camera.global_basis.z
	right.y = 0
	back.y = 0
	right = right.normalized()
	back = back.normalized()
	var horizontal: float = desired.dot(right)
	var vertical: float = desired.dot(back)
	Input.action_press("move_right" if horizontal > 0 else "move_left", absf(horizontal))
	Input.action_press("move_down" if vertical > 0 else "move_up", absf(vertical))
	var reached: bool = false
	var saves_before: int = game.save_count
	for step: int in range(240):
		game.move_pip(1.0 / 60.0)
		if (desired.x > 0 and game.pip.position.x >= destination_x) or (desired.x < 0 and game.pip.position.x <= destination_x):
			reached = true
			break
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	_expect(reached, label + " reaches its opposite dry island")
	_expect(game.save_count == saves_before and game.recovery_time == 0, label + " crosses without a hidden recovery")
	_expect(absf(game.pip.position.z - start.z) < 0.05, label + " follows the authored crossing corridor")


func _assert_safe_respawn(scene: Node3D, label: String) -> void:
	var floor_height: float = scene.surface_height(scene.pip.position)
	_expect(floor_height >= 0, label + " returns to a valid support surface")
	_expect(not scene.obstructed(scene.pip.position), label + " returns outside solid prop colliders")
	_expect(absf(scene.pip.position.y - floor_height) <= 0.025, label + " places feet on the visible support immediately")


func _assert_prop_sync(label: String) -> void:
	for kind: String in State.PROP_KINDS:
		var prop: Node3D = game.props[kind]
		_expect(prop.position.is_equal_approx(game.prop_position(kind)), label + " restores visible " + kind + " placement")
		_expect(prop.scale.is_equal_approx(Vector3.ONE * Main.SCALE_VALUES[int(game.state.sizes[kind])]), label + " restores visible " + kind + " size")


func _setup(checkpoint: int) -> void:
	if game.paused:
		game.on_command("resume", null)
	game.state = _fixture(checkpoint)
	game.flying = false
	game.boarded = false
	game.started = true
	game.exploring = false
	game.recovery_time = 0
	game.sync_props(false)
	game.respawn()


func _fixture(checkpoint: int) -> PuzzleState:
	var state: PuzzleState = State.new()
	if checkpoint == 0:
		return state
	state.resize("spoon", 0)
	state.interact("spoon")
	state.pass_handle()
	state.place("bridge")
	state.resize("spoon", 2)
	if checkpoint == 1:
		return state
	state.resize("blueberry", 0)
	state.interact("blueberry")
	state.place("ballast")
	state.resize("blueberry", 2)
	state.resize("butter", 0)
	state.interact("butter")
	state.place("wedge")
	state.resize("butter", 1)
	if checkpoint == 2:
		return state
	# Establish the launch checkpoint with the spoon safely returned to its
	# tray. This also verifies that the permanent return route replaces it.
	state.resize("spoon", 0)
	state.interact("spoon")
	state.place("tray")
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
