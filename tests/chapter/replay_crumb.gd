extends SceneTree
## W01S01 ordinary-input solution. No teleports or puzzle-state writes.
var game: Node
var controls: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/chapter/crumb_crossing.tscn").instantiate()
	game.chapter_profile_path = "user://crumb_route_%d.json" % OS.get_process_id()
	game.settings_path = "user://crumb_route_settings_%d.cfg" % OS.get_process_id()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute(game.capture_dir)
	var harness_path = get_script().resource_path.get_base_dir().get_base_dir().path_join("replay_route.gd")
	controls = load(harness_path).new()
	root.add_child(controls)
	controls.game = game
	controls.route_started_usec = Time.get_ticks_usec()
	await create_timer(0.4).timeout
	await game.capture("title")
	await controls.key(KEY_ENTER)
	await game.capture("opening")
	await controls.key(KEY_1)
	controls.check(int(game.state.sizes["sugar"]) == 0, "Sugar cube shrinks to open the paper tray")
	await controls.go(Vector2(-9.8, 2.45))
	await controls.go(Vector2(-6.8, 2.45))
	controls.check(game.state.sugar_passed and game.state.checkpoint == 1, "Pip physically passes the small sugar cube")
	await game.capture("sugar_passage")
	await controls.go(Vector2(-6.45, 2.65))
	await controls.select("spoon")
	await controls.key(KEY_1)
	await controls.key(KEY_E)
	controls.check(game.state.carried == "spoon", "Small teaspoon can be carried")
	await controls.go(Vector2(-6.65, 1.2))
	await controls.go(Vector2(-6.95, 1.2))
	await controls.go(Vector2(-5.65, 1.2))
	controls.check(game.state.handle_passed, "Carried teaspoon fits through the actual cup handle")
	await game.capture("cup_handle")
	await controls.key(KEY_E)
	controls.check(game.state.sockets["spoon"] == "bridge", "Teaspoon rests between the saucers")
	await controls.go(Vector2(-5.65, 2.7))
	await controls.select("spoon")
	await controls.key(KEY_3)
	controls.check(game.state.bridge_placed and game.state.checkpoint == 2, "The enlarged teaspoon completes the crossing")
	await game.capture("bridge_ready")
	await controls.go(Vector2(-5.5, 1.2))
	await controls.go(Vector2(-4.1, 1.2))
	await game.capture("bridge_crossing")
	await controls.go(Vector2(-1.65, 1.2))
	controls.check(game.pip.position.x > -2.2, "Pip walks safely across the spoon bridge")
	await controls.go(Vector2(-1.2, -0.55))
	await controls.key(KEY_E)
	controls.check(game.state.discovered, "Optional crumb friends respond to Pip")
	await game.capture("crumb_friends")
	await controls.go(Vector2(0.6, 1.2))
	var deadline = Time.get_ticks_msec() + 4000
	while not game.state.completed and Time.get_ticks_msec() < deadline:
		var direction = Vector2(1.8 - game.pip.position.x, 1.2 - game.pip.position.z).normalized()
		var right = Vector2(game.camera.global_basis.x.x, game.camera.global_basis.x.z).normalized()
		var back = Vector2(game.camera.global_basis.z.x, game.camera.global_basis.z.z).normalized()
		var axis = Vector2(direction.dot(right), direction.dot(back))
		controls.release_movement()
		Input.action_press("move_right" if axis.x > 0 else "move_left", absf(axis.x))
		Input.action_press("move_down" if axis.y > 0 else "move_up", absf(axis.y))
		await process_frame
	controls.release_movement()
	controls.check(game.state.completed, "The teal flag completes Crumb Crossing")
	controls.check(game.chapter_profile.is_completed("W01S01") and game.chapter_profile.is_unlocked("W01S02"), "Stage completion durably unlocks the next chapter slot")
	await create_timer(1.4).timeout
	await game.capture("complete")
	var report = {"result": "FAIL" if controls.failed else "PASS", "checks": controls.checks, "steps": controls.steps,
		"stage": "W01S01", "input": "InputEventKey plus InputMap movement; no teleports or puzzle-state writes",
		"window_pixels": str(DisplayServer.window_get_size()), "renderer": RenderingServer.get_video_adapter_name(),
		"engine": Engine.get_version_info().string, "display_driver": DisplayServer.get_name(),
		"movie_mode": not Engine.get_write_movie_path().is_empty(), "snapshot": game.state.to_dict(),
		"chapter_completed_ids": game.chapter_profile.completed_ids()}
	var file = FileAccess.open(game.capture_dir.path_join("replay_report.json"), FileAccess.WRITE)
	if not file:
		push_error("Could not write Crumb Crossing route report.")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CRUMB ROUTE: ", report.result, " — ", controls.checks, " checks")
	await game.stop_audio()
	quit(1 if controls.failed else 0)
