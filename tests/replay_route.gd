extends Node
## End-to-end route through the same Input events and world-space movement as a player.
## Never writes puzzle state or teleports Pip. Dedicated replay save is selected by main.
var game: Node
var checks := 0
var steps: Array[String] = []
var failed := false

func run(scene: Node) -> void:
	game = scene
	await wait_frames(20)
	await key(KEY_ENTER)
	await wait_frames(30)
	await game.capture("opening")
	await go(Vector2(-8.0, 3.0))
	await select("spoon")
	await key(KEY_1)
	await key(KEY_E)
	check(game.state.carried == "spoon", "Small spoon can be carried")
	await go(Vector2(-7.0, 1.2))
	await go(Vector2(-6.3, 1.2))
	check(game.state.handle_passed, "Small spoon passes through cup handle")
	await go(Vector2(-5.65, 1.2))
	await key(KEY_E)
	await go(Vector2(-6.2, 1.2))
	await select("spoon")
	await key(KEY_3)
	check(game.state.checkpoint == 1, "Spoon bridge creates first checkpoint")
	await go(Vector2(-4.1, 1.2))
	await game.capture("puzzle_one")
	await go(Vector2(-1.8, 1.2))
	check(game.pip.position.x > -2.2, "Pip crosses the spoon bridge")
	# Optional discovery before the final flight preparation.
	await go(Vector2(1.9, -1.4))
	await select("cereal")
	await key(KEY_1)
	await go(Vector2(2.20, -1.0))
	await key(KEY_E)
	check(game.state.discovered, "Cereal panel reveals optional picnic")
	await game.capture("optional_discovery")
	await key(KEY_2)
	await go(Vector2(-1.1, 1.3))
	await select("blueberry")
	await key(KEY_1)
	await key(KEY_E)
	check(game.state.carried == "blueberry", "Small blueberry can be carried")
	await go(Vector2(1.45, -0.2))
	await key(KEY_E)
	await go(Vector2(0.7, -0.2))
	await select("blueberry")
	await key(KEY_3)
	check(game.state.ramp_raised(), "Ballast physically raises cereal flap")
	await go(Vector2(-1.0, 2.0))
	await select("butter")
	await key(KEY_1)
	await key(KEY_E)
	await go(Vector2(1.5, 1.65))
	await key(KEY_E)
	await select("butter")
	await key(KEY_2)
	check(game.state.ramp_latched and game.state.checkpoint == 2, "Butter permanently latches ramp")
	await game.capture("puzzle_two")
	await go(Vector2(0.1, 3.7))
	await select("napkin")
	await key(KEY_1)
	await key(KEY_E)
	await go(Vector2(2.3, 1.2))
	await go(Vector2(5.5, 1.2))
	check(game.pip.position.x > 5.1, "Pip crosses the latched cereal ramp")
	await go(Vector2(8.0, 2.8))
	await key(KEY_E)
	await go(Vector2(7.0, 2.8))
	await select("napkin")
	await key(KEY_3)
	check(game.state.napkin_ready, "Large napkin prepares soft landing")
	await game.capture("puzzle_three")
	await go(Vector2(5.5, 1.2))
	await go(Vector2(2.35, 1.2))
	await go(Vector2(1.1, -0.2))
	await select("blueberry")
	await key(KEY_1)
	await key(KEY_E)
	check(game.state.carried == "blueberry" and game.state.ramp_latched, "Blueberry is reused without losing return route")
	await go(Vector2(2.0, -2.4))
	await key(KEY_E)
	await select("blueberry")
	await key(KEY_3)
	check(game.state.can_launch() and game.state.checkpoint == 3, "Prepared lever lowers toast and saves launch checkpoint")
	await select("toaster")
	await key(KEY_E)
	check(game.boarded, "Pip boards lowered toast through interaction")
	await wait_frames(20)
	await game.capture("before_launch")
	await key(KEY_1)
	check(game.flying, "Onboard remote shrink releases toaster")
	await wait_frames(52)
	await game.capture("flight_window")
	while not game.state.completed and game.flight_time < 5:
		await get_tree().process_frame
	await wait_frames(20)
	await game.capture("finale_scene")
	await wait_frames(70)
	check(game.state.completed, "Toast lands on prepared napkin and completes demo")
	await game.capture("finale")
	var sorted: Array = game.frame_samples.duplicate()
	sorted.sort()
	var report = {"result":"PASS" if not failed else "FAIL", "checks": checks, "steps":steps,
		"input":"InputEventKey plus InputMap movement; no state mutation or teleports", "logical_viewport":str(game.get_viewport().get_visible_rect().size), "window_pixels":str(DisplayServer.window_get_size()), "movie_mode":OS.has_feature("movie"),
		"renderer":RenderingServer.get_video_adapter_name(), "engine":Engine.get_version_info().string,
		"samples":sorted.size(), "peak_draw_calls":game.peak_draw_calls, "peak_rendered_objects":game.peak_objects, "frame_ms_p50":sorted[int(sorted.size() * .50)] if sorted.size() else 0,
		"frame_ms_p95":sorted[int(sorted.size() * .95)] if sorted.size() else 0,
		"frame_ms_p99":sorted[int(sorted.size() * .99)] if sorted.size() else 0,
		"measurement_note":"Raw wall-clock between _process frames after 2-second warmup, includes screenshot stalls. Automated native route; fixed-fps/movie mode if supplied is not a real-time gameplay benchmark."}
	var file = FileAccess.open(game.capture_dir.path_join("replay_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ROUTE: ", report.result, " — ", checks, " checks")
	await game.stop_audio()
	get_tree().quit(1 if failed else 0)

func check(condition: bool, text: String) -> void:
	checks += 1
	steps.append(("PASS " if condition else "FAIL ") + text)
	print(steps[-1])
	if not condition:
		failed = true
		push_error("Route blocked: " + text)
		get_tree().quit(1)

func key(code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await wait_frames(28)

func select(kind: String) -> void:
	for i in 8:
		if game.target == kind: return
		await key(KEY_TAB)
	check(game.target == kind, "Target " + kind + " is reachable")

func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func go(destination: Vector2) -> void:
	for i in 1200:
		var current = Vector2(game.pip.position.x, game.pip.position.z)
		if current.distance_to(destination) < 0.075:
			release_movement()
			await wait_frames(4)
			return
		var direction = (destination - current).normalized()
		var right = Vector2(game.camera.global_basis.x.x, game.camera.global_basis.x.z).normalized()
		var back = Vector2(game.camera.global_basis.z.x, game.camera.global_basis.z.z).normalized()
		var axis = Vector2(direction.dot(right), direction.dot(back))
		release_movement()
		Input.action_press("move_right" if axis.x > 0 else "move_left", absf(axis.x))
		Input.action_press("move_down" if axis.y > 0 else "move_up", absf(axis.y))
		await get_tree().process_frame
	release_movement()
	check(false, "Movement reaches " + str(destination) + " (stopped at " + str(game.pip.position) + ")")

func release_movement() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
