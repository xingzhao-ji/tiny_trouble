extends SceneTree
## W01S02 ordinary-input route. Only predecessor W01S01 is a seeded fixture;
## this stage begins fresh, with no teleports or puzzle-state writes.
var game: Node
var controls: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/chapter/blueberry_ballast.tscn").instantiate()
	game.chapter_profile_path = "user://ballast_route_%d.json" % OS.get_process_id()
	game.settings_path = "user://ballast_route_settings_%d.cfg" % OS.get_process_id()
	var profile = load("res://scripts/chapter/chapter_progress.gd").new()
	profile.save_path = game.chapter_profile_path
	if not profile.complete_stage("W01S01"):
		push_error("Could not create the completed predecessor fixture.")
		quit(1)
		return
	root.add_child(game)
	if DirAccess.make_dir_recursive_absolute(game.capture_dir) != OK:
		push_error("Could not create route evidence directory.")
		quit(1)
		return
	var harness_path = get_script().resource_path.get_base_dir().get_base_dir().path_join("replay_route.gd")
	controls = load(harness_path).new()
	root.add_child(controls)
	controls.game = game
	controls.route_started_usec = Time.get_ticks_usec()
	controls.captures_enabled = not ("--no-captures" in OS.get_cmdline_user_args()) and DisplayServer.get_name() != "headless"
	controls.initial_display_config = controls.display_config()
	await create_timer(0.5).timeout
	await controls.capture("title")
	await controls.key(KEY_ENTER)
	await controls.capture("opening")
	await controls.select("berry_b")
	await controls.key(KEY_3)
	await create_timer(0.45).timeout
	controls.check(int(game.state.sizes["berry_b"]) == 2, "The near blueberry grows into a rolling weight")
	await controls.key(KEY_E)
	await create_timer(1.25).timeout
	controls.check(game.state.sockets["berry_b"] == "flap", "The large near berry rolls into its cereal-flap pocket")
	await controls.capture("first_berry")
	await controls.go(Vector2(-8.85, -3.92))
	await controls.select("berry_a")
	await controls.key(KEY_3)
	await create_timer(0.45).timeout
	await controls.key(KEY_E)
	await create_timer(1.25).timeout
	controls.check(game.state.checkpoint == 1 and game.state.total_weight() == 8, "Both berries load the flap and raise the path above its landing")
	await controls.capture("overbalanced")
	var alternate = "--alternate" in OS.get_cmdline_user_args()
	if alternate:
		await controls.go(Vector2(-8.85, -5.65))
		await controls.go(Vector2(-4.0, -5.65))
		await controls.select("berry_a")
	else:
		await controls.go(Vector2(-8.85, 0.3))
		await controls.go(Vector2(-4.0, 0.3))
		await controls.select("berry_b")
	await controls.key(KEY_1)
	await create_timer(0.85).timeout
	controls.check(game.state.is_balanced() and game.state.checkpoint == 2, "Shrinking one loaded berry aligns the cardboard path")
	controls.check(absf(game.ramp.get_node("FarAnchor").global_position.y - 1.8) < 0.005, "The actual ramp endpoint reaches the visible box top")
	await controls.capture("balanced")
	if alternate:
		await controls.go(Vector2(-2.4, -5.65))
		await controls.go(Vector2(0.8, -5.65))
		await controls.go(Vector2(0.8, -3.0))
		await controls.go(Vector2(0.6, -3.0))
	else:
		await controls.go(Vector2(-1.9, 0.3))
		await controls.go(Vector2(-0.75, -1.55))
	await controls.key(KEY_E)
	controls.check(game.state.discovered, "Pip inspects the exposed cereal counterweights")
	await controls.capture("counterweights")
	if alternate:
		await controls.go(Vector2(0.8, -1.3))
		await controls.go(Vector2(-1.9, 0.3))
	else: await controls.go(Vector2(-1.9, 0.3))
	await controls.go(Vector2(-3.35, 1.3))
	# Preserve an actual moving step before Pip's center reaches the incline.
	# This is where a foot used to intersect the cardboard at the entrance.
	var entry_right = Vector2(game.camera.global_basis.x.x, game.camera.global_basis.x.z).normalized()
	var entry_back = Vector2(game.camera.global_basis.z.x, game.camera.global_basis.z.z).normalized()
	Input.action_press("move_right", entry_right.x)
	Input.action_press("move_down", entry_back.x)
	var entry_deadline: float = game.t + 2.0
	while game.pip.position.x < -2.99 and game.t < entry_deadline: await process_frame
	await controls.capture("ramp_entry")
	controls.release_movement()
	await controls.go(Vector2(0.3, 1.3))
	controls.check(game.pip.position.y > 0.9, "Pip climbs the physical rising cardboard surface")
	await controls.capture("ramp_crossing")
	await controls.go(Vector2(3.55, 1.3))
	controls.check(absf(game.pip.position.y - 1.8) < 0.05, "Pip steps safely onto the cereal-box landing")
	await controls.go(Vector2(4.3, 1.3))
	var deadline: float = game.t + 4.0
	while not game.state.completed and game.t < deadline:
		var direction = Vector2(game.EXIT_POS.x - game.pip.position.x, game.EXIT_POS.z - game.pip.position.z).normalized()
		var right = Vector2(game.camera.global_basis.x.x, game.camera.global_basis.x.z).normalized()
		var back = Vector2(game.camera.global_basis.z.x, game.camera.global_basis.z.z).normalized()
		var axis = Vector2(direction.dot(right), direction.dot(back))
		controls.release_movement()
		Input.action_press("move_right" if axis.x > 0 else "move_left", absf(axis.x))
		Input.action_press("move_down" if axis.y > 0 else "move_up", absf(axis.y))
		await process_frame
	controls.release_movement()
	controls.check(game.state.completed, "The teal flag completes Blueberry Ballast")
	controls.check(game.chapter_profile.is_completed("W01S02") and game.chapter_profile.is_unlocked("W01S03"), "Completion durably unlocks the next Breakfast stage slot")
	await create_timer(1.4).timeout
	await controls.capture("complete")
	var frames = game.frame_samples.duplicate()
	frames.sort()
	var report = {"result": "FAIL" if controls.failed else "PASS", "checks": controls.checks, "steps": controls.steps,
		"stage": "W01S02", "solution": "small far berry" if alternate else "small near berry", "fixture": "Only predecessor W01S01 completion is seeded before stage readiness",
		"input": "InputEventKey plus InputMap movement; no stage teleports or puzzle-state writes",
		"window_pixels": str(DisplayServer.window_get_size()), "renderer": RenderingServer.get_video_adapter_name(),
		"engine": Engine.get_version_info().string, "display_driver": DisplayServer.get_name(),
		"movie_mode": not Engine.get_write_movie_path().is_empty(), "snapshot": game.state.to_dict(),
		"chapter_completed_ids": game.chapter_profile.completed_ids()}
	report["performance"] = {"samples": frames.size(), "frame_ms_p50": frames[int(frames.size() * 0.5)] if frames.size() else null,
		"frame_ms_p95": frames[int(frames.size() * 0.95)] if frames.size() else null,
		"frame_ms_p99": frames[int(frames.size() * 0.99)] if frames.size() else null,
		"peak_draw_calls": game.peak_draw_calls, "peak_rendered_objects": game.peak_objects,
		"capture_enabled": controls.captures_enabled, "capture_requests": controls.capture_requests,
		"frame_pacing_start": controls.initial_display_config, "frame_pacing_end": controls.display_config(),
		"focus": controls.focus_summary(), "fps_monitor": controls.monitor_summary("rendered_fps"),
		"host_processor": OS.get_processor_name(), "host_os": OS.get_version(),
		"measurement_note": "Wall-clock intervals between active process frames after2s warmup. Captures, saves and report I/O can stall. Movie/fixed FPS is not a real-time benchmark. Window focus is explicitly recorded."}
	var file = FileAccess.open(game.capture_dir.path_join("replay_report.json"), FileAccess.WRITE)
	if not file:
		push_error("Could not write Blueberry Ballast route report.")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("BALLAST ROUTE: ", report.result, " — ", controls.checks, " checks")
	await game.stop_audio()
	quit(1 if controls.failed else 0)
