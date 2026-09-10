extends SceneTree
## W01S03 ordinary-input route. Only its two predecessors are seeded;
## this stage begins fresh, with no teleports or puzzle-state writes.
var game: Node
var controls: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/chapter/milk_harbor.tscn").instantiate()
	game.chapter_profile_path = "user://harbor_route_%d.json" % OS.get_process_id()
	game.settings_path = "user://harbor_route_settings_%d.cfg" % OS.get_process_id()
	var profile = load("res://scripts/chapter/chapter_progress.gd").new()
	profile.save_path = game.chapter_profile_path
	if not profile.complete_stage("W01S01") or not profile.complete_stage("W01S02"):
		push_error("Could not create the completed predecessor fixture.")
		quit(1)
		return
	root.add_child(game)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--route-text-scale="):
			game.on_command("text", clampf(float(arg.trim_prefix("--route-text-scale=")), 1.0, 1.25))
	if DirAccess.make_dir_recursive_absolute(game.capture_dir) != OK:
		push_error("Could not create route evidence directory.")
		quit(1)
		return
	var harness_path = get_script().resource_path.get_base_dir().get_base_dir().path_join("replay_route.gd")
	if "--touch-route" in OS.get_cmdline_user_args():
		harness_path = get_script().resource_path.get_base_dir().get_base_dir().path_join("platform/touch_route_driver.gd")
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
	await controls.go(Vector2(-6.2, 1.2))
	await controls.key(KEY_E)
	controls.check(game.state.discovered, "The little cereal crew greets Pip")
	await controls.capture("cereal_crew")
	await controls.go(Vector2(-5.55, 0))
	await controls.select("cereal")
	await controls.key(KEY_3)
	await create_timer(0.55).timeout
	controls.check(int(game.state.sizes["cereal"]) == 2 and game.state.checkpoint == 1, "The cereal loop grows into a boardable raft")
	await controls.capture("raft_ready")
	await controls.key(KEY_E)
	await create_timer(0.75).timeout
	controls.check(game.state.aboard and not game.changing_rider, "Pip hops safely onto the raft beside the parcel")
	await controls.capture("aboard")
	await controls.key(KEY_E)
	await create_timer(2.6).timeout
	controls.check(game.state.phase == "shoal" and game.state.checkpoint == 2, "The raft reaches its safe stop at the shallow ridge")
	var loaded_deck: float = game.deck_height()
	await controls.key(KEY_E)
	controls.check(game.state.phase == "shoal", "Normal cargo keeps the raft grounded at the shallows")
	await controls.capture("grounded")
	await controls.select("cargo")
	await controls.key(KEY_1)
	await create_timer(0.55).timeout
	controls.check(game.state.cargo_clear() and game.deck_height() > loaded_deck + 0.09, "Small cargo visibly raises the raft clear of the ridge")
	await controls.capture("lightened")
	await controls.key(KEY_E)
	await create_timer(3.4).timeout
	controls.check(game.state.phase == "far" and game.state.dock_open and game.state.checkpoint == 3, "The light raft arrives and unfolds the spoon dock")
	controls.check(absf(game.dock_leaf.rotation.z - game.deployed_dock_angle()) < 0.005, "The actual spoon dock settles into its landing pose")
	await controls.capture("dock_open")
	await controls.key(KEY_E)
	await create_timer(1.1).timeout
	controls.check(not game.state.aboard and not game.changing_rider and game.pip.position.x > 5.2, "Pip steps around the parcel and onto the far bank")
	await controls.capture("ashore")
	var deadline: float = game.t + 4.0
	while not game.state.completed and game.t < deadline:
		var direction = Vector2(game.EXIT_POS.x - game.pip.position.x, game.EXIT_POS.z - game.pip.position.z).normalized()
		var right = Vector2(game.camera.global_basis.x.x, game.camera.global_basis.x.z).normalized()
		var back = Vector2(game.camera.global_basis.z.x, game.camera.global_basis.z.z).normalized()
		var axis = Vector2(direction.dot(right), direction.dot(back))
		controls.drive(axis)
		await process_frame
	controls.release_movement()
	controls.check(game.state.completed, "The teal flag completes Milk Harbor")
	controls.check(game.chapter_profile.is_completed("W01S03") and game.chapter_profile.is_unlocked("W01S04"), "Harbor completion durably unlocks the next Breakfast stage slot")
	await create_timer(1.4).timeout
	await controls.capture("complete")
	var visibility: Dictionary = {}
	if "--touch-route" in OS.get_cmdline_user_args(): visibility = controls.finish_visibility_checks()
	var frames = game.frame_samples.duplicate()
	frames.sort()
	var report = {"result": "FAIL" if controls.failed else "PASS", "checks": controls.checks, "steps": controls.steps,
		"stage": "W01S03", "fixture": "Only W01S01 and W01S02 completion is seeded before stage readiness",
		"input": "InputEventKey plus InputMap movement; no stage teleports or puzzle-state writes",
		"window_pixels": str(DisplayServer.window_get_size()), "renderer": RenderingServer.get_video_adapter_name(),
		"engine": Engine.get_version_info().string, "display_driver": DisplayServer.get_name(),
		"movie_mode": not Engine.get_write_movie_path().is_empty(), "snapshot": game.state.to_dict(),
		"text_scale": game.text_scale,
		"chapter_completed_ids": game.chapter_profile.completed_ids()}
	if "--touch-route" in OS.get_cmdline_user_args():
		report["input"] = "Injected ScreenTouch/ScreenDrag through actual touch controls; title button via injected mouse; no stage teleports or puzzle-state writes. Native macOS viewport simulation, not physical touch or iOS Simulator."
		report["toast_visibility"] = visibility
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
		push_error("Could not write Milk Harbor route report.")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("HARBOR ROUTE: ", report.result, " — ", controls.checks, " checks")
	await game.stop_audio()
	quit(1 if controls.failed else 0)
