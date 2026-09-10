extends Node
## End-to-end route through the same Input events and world-space movement as a player.
## Never writes puzzle state or teleports Pip. Dedicated replay save is selected by main.
var game: Node
var checks := 0
var steps: Array[String] = []
var failed := false
var route_started_usec: int = 0
var next_monitor_sample_usec: int = 0
var monitor_samples: Array[Dictionary] = []
var initial_display_config: Dictionary = {}
var captures_enabled: bool = true
var capture_requests: int = 0
var foreground_requested: bool = false

func run(scene: Node) -> void:
	game = scene
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(game.capture_dir)
	if directory_error != OK:
		failed = true
		push_error("Replay evidence directory could not be created: " + error_string(directory_error))
		await game.stop_audio()
		get_tree().quit(1)
		return
	var declared_mode: Variant = user_argument("--evidence-mode")
	if declared_mode == "movie" and Engine.get_write_movie_path().is_empty():
		failed = true
		push_error("Recording harness declared movie mode, but Godot Movie Maker is not active.")
		await game.stop_audio()
		get_tree().quit(1)
		return
	route_started_usec = Time.get_ticks_usec()
	captures_enabled = not ("--no-captures" in OS.get_cmdline_user_args()) and DisplayServer.get_name() != "headless"
	await wait_seconds(0.35)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_move_to_foreground()
		foreground_requested = true
		await wait_seconds(0.25)
	initial_display_config = display_config()
	await key(KEY_ENTER)
	await wait_seconds(0.5)
	await capture("opening")
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
	await capture("puzzle_one")
	await go(Vector2(-1.8, 1.2))
	check(game.pip.position.x > -2.2, "Pip crosses the spoon bridge")
	# Walk around the solid berry instead of grazing its collision circle.
	await go(Vector2(0.5, 1.2))
	# Optional discovery before the final flight preparation.
	await go(Vector2(1.9, -1.4))
	await select("cereal")
	await key(KEY_1)
	await go(Vector2(2.20, -1.0))
	await key(KEY_E)
	check(game.state.discovered, "Cereal panel reveals optional picnic")
	await capture("optional_discovery")
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
	await capture("puzzle_two")
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
	await capture("puzzle_three")
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
	# Render rate is not an animation clock: wait for the actual boarding pose.
	while game.boarded and game.boarding_time < 0.5:
		await get_tree().process_frame
	await capture("before_launch")
	await key(KEY_1)
	check(game.flying, "Onboard remote shrink releases toaster")
	while game.flying and game.flight_time < 1.32:
		await get_tree().process_frame
	await capture("flight_window")
	while not game.state.completed and game.flight_time < 5:
		await get_tree().process_frame
	await wait_seconds(0.3)
	await capture("finale_scene")
	await wait_seconds(1.2)
	check(game.state.completed, "Toast lands on prepared napkin and completes demo")
	await capture("finale")
	var sorted: Array = game.frame_samples.duplicate()
	sorted.sort()
	var capture_note: String = "Includes synchronous PNG capture stalls." if captures_enabled else "PNG captures disabled; ordinary save and progress-report I/O remain."
	var mode_info: Dictionary = evidence_mode()
	var report = {"result":"PASS" if not failed else "FAIL", "checks": checks, "steps":steps,
		"input":"InputEventKey plus InputMap movement; no state mutation or teleports", "logical_viewport":str(game.get_viewport().get_visible_rect().size), "window_pixels":str(DisplayServer.window_get_size()), "movie_mode":mode_info["movie_mode"], "fixed_fps_mode":mode_info["fixed_fps_mode"], "display_driver":DisplayServer.get_name(),
		"renderer":RenderingServer.get_video_adapter_name(), "engine":Engine.get_version_info().string,
		"samples":sorted.size(), "peak_draw_calls":game.peak_draw_calls, "peak_rendered_objects":game.peak_objects, "frame_ms_p50":sorted[int(sorted.size() * .50)] if sorted.size() else 0,
		"frame_ms_p95":sorted[int(sorted.size() * .95)] if sorted.size() else 0,
		"frame_ms_p99":sorted[int(sorted.size() * .99)] if sorted.size() else 0,
		"capture_enabled": captures_enabled, "capture_requests": capture_requests,
		"measurement_note":"Raw wall-clock between _process frames after 2-second warmup. " + capture_note + " Automated native route; fixed-fps/movie mode if supplied is not a real-time gameplay benchmark."}
	report["evidence_mode"] = mode_info
	report["frame_pacing"] = {"start": initial_display_config, "end": display_config(),
		"foreground_requested": foreground_requested, "focus_samples": focus_summary(),
		"max_fps_argument": engine_argument("--max-fps"),
		"disable_vsync_argument": "--disable-vsync" in OS.get_cmdline_args(),
		"fixed_fps_argument": engine_argument("--fixed-fps"),
		"declared_fixed_fps": mode_info["declared_fixed_fps"],
		"route_wall_seconds": float(Time.get_ticks_usec() - route_started_usec) / 1000000.0}
	report["host"] = {"os": OS.get_name(), "os_version": OS.get_version(),
		"processor": OS.get_processor_name(), "logical_processors": OS.get_processor_count(),
		"debug_build": OS.is_debug_build()}
	report["engine_timing"] = {"sample_count": monitor_samples.size(),
		"process_interval_peak_ms": monitor_summary("process_ms"),
		"physics_interval_peak_ms": monitor_summary("physics_ms"),
		"rendered_fps_monitor": monitor_summary("rendered_fps"),
		"samples": monitor_samples,
		"note": "Godot 4.5 TIME_PROCESS and TIME_PHYSICS_PROCESS expose interval maxima updated about once per second. Sampled once per wall-clock second during active play after warmup. Process includes main-loop/draw work and potential waits; these are not per-frame CPU costs, OS CPU utilization, GPU time, or power measurements.",
		"os_cpu_utilization_percent": null,
		"source": "https://github.com/godotengine/godot/blob/4.5-stable/main/main.cpp#L4484-L4519"}
	var report_error: Error = write_json(game.capture_dir.path_join("replay_report.json"), report)
	if report_error != OK:
		failed = true
		push_error("Replay report could not be written: " + error_string(report_error))
		await game.stop_audio()
		get_tree().quit(1)
		return
	print("ROUTE: ", report.result, " — ", checks, " checks")
	await game.stop_audio()
	get_tree().quit(1 if failed else 0)

func _process(_delta: float) -> void:
	if not is_instance_valid(game) or not game.started or game.paused or game.intro_time < 2.0:
		return
	var now: int = Time.get_ticks_usec()
	if now < next_monitor_sample_usec:
		return
	next_monitor_sample_usec = now + 1000000
	monitor_samples.append({"route_wall_seconds": float(now - route_started_usec) / 1000000.0,
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"rendered_fps": Performance.get_monitor(Performance.TIME_FPS),
		"window_focused": null if DisplayServer.get_name() == "headless" else DisplayServer.window_is_focused()})

func capture(name: String) -> void:
	if captures_enabled:
		capture_requests += 1
		await game.capture(name)

func focus_summary() -> Dictionary:
	var focused: int = 0
	var unfocused: int = 0
	for sample: Dictionary in monitor_samples:
		if sample["window_focused"] == true:
			focused += 1
		elif sample["window_focused"] == false:
			unfocused += 1
	return {"focused": focused, "unfocused": unfocused,
		"all_sampled_focused": null if focused + unfocused == 0 else unfocused == 0,
		"note": "Window focus sampled once per second during active play after warmup; start/end focus is recorded separately."}

func display_config() -> Dictionary:
	var headless: bool = DisplayServer.get_name() == "headless"
	var vsync: int = -1 if headless else DisplayServer.window_get_vsync_mode()
	var names: Array[String] = ["disabled", "enabled", "adaptive", "mailbox"]
	var refresh_rate: float = -1.0 if headless else DisplayServer.screen_get_refresh_rate()
	return {"display_refresh_hz": refresh_rate if refresh_rate > 0 else null,
		"screen": null if headless else DisplayServer.window_get_current_screen(),
		"screen_scale": null if headless else DisplayServer.screen_get_scale(),
		"window_focused": null if headless else DisplayServer.window_is_focused(),
		"vsync_mode": vsync,
		"vsync_name": names[vsync] if vsync >= 0 and vsync < names.size() else "unavailable",
		"configured_vsync_mode": ProjectSettings.get_setting("display/window/vsync/vsync_mode", 1),
		"configured_max_fps": ProjectSettings.get_setting("application/run/max_fps", 0),
		"runtime_max_fps": Engine.max_fps,
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"low_processor_mode": OS.low_processor_usage_mode}

func monitor_summary(key: String) -> Dictionary:
	var values: Array[float] = []
	for sample: Dictionary in monitor_samples:
		values.append(float(sample[key]))
	values.sort()
	if values.is_empty() or values[-1] <= 0:
		return {"available": false, "p50": null, "p95": null, "max": null}
	return {"available": true, "p50": values[int(values.size() * 0.50)],
		"p95": values[mini(int(values.size() * 0.95), values.size() - 1)], "max": values[-1]}

func engine_argument(flag: String) -> Variant:
	return argument_value(OS.get_cmdline_args(), flag)

func user_argument(flag: String) -> Variant:
	return argument_value(OS.get_cmdline_user_args(), flag)

func argument_value(args: PackedStringArray, flag: String) -> Variant:
	for i: int in range(args.size()):
		if args[i] == flag and i + 1 < args.size():
			return args[i + 1]
		if args[i].begins_with(flag + "="):
			return args[i].substr(flag.length() + 1)
	return null

func evidence_mode() -> Dictionary:
	var movie_path: String = Engine.get_write_movie_path()
	var movie_active: bool = not movie_path.is_empty()
	var declared_mode: Variant = user_argument("--evidence-mode")
	var declared_fps_text: Variant = user_argument("--evidence-fixed-fps")
	var declared_fps: Variant = null
	if declared_fps_text != null and String(declared_fps_text).is_valid_int() and int(declared_fps_text) > 0:
		declared_fps = int(declared_fps_text)
	var fixed_argument: Variant = engine_argument("--fixed-fps")
	var fixed_mode: Variant = null
	var fixed_source: String = "Unknown; consumed engine arguments cannot establish absence of fixed stepping."
	if movie_active:
		fixed_mode = true
		fixed_source = "Godot Movie Maker is active and uses fixed stepping; FPS is separately declared by the recording harness."
	elif declared_fps != null or fixed_argument != null:
		fixed_mode = true
		fixed_source = "Explicit harness --evidence-fixed-fps declaration." if declared_fps != null else "Visible --fixed-fps engine argument."
	elif declared_mode == "native":
		fixed_mode = false
		fixed_source = "Explicit harness --evidence-mode=native declaration; not inferred from missing engine arguments."
	return {"movie_mode": movie_active, "movie_mode_source": "Engine.get_write_movie_path()",
		"movie_output_file": movie_path.get_file(), "fixed_fps_mode": fixed_mode,
		"fixed_fps_mode_source": fixed_source, "declared_evidence_mode": declared_mode,
		"declared_fixed_fps": declared_fps, "visible_fixed_fps_argument": fixed_argument,
		"note": "Arguments used by the engine may not remain visible to scripts. Movie activity comes from the engine API; harness declarations are identified separately.",
		"source": "https://docs.godotengine.org/en/4.5/classes/class_engine.html#class-engine-method-get-write-movie-path"}

func check(condition: bool, text: String) -> void:
	checks += 1
	steps.append(("PASS " if condition else "FAIL ") + text)
	print(steps[-1])
	var progress_error: Error = write_json(game.capture_dir.path_join("route_progress.json"),
		{"steps":steps,"position":str(game.pip.position),"target":game.target,"passed_so_far":not failed and condition})
	if progress_error != OK:
		failed = true
		push_error("Replay progress could not be written: " + error_string(progress_error))
		get_tree().quit(1)
		return
	if not condition:
		failed = true
		push_error("Route blocked: " + text)
		get_tree().quit(1)

func write_json(path: String, data: Dictionary) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	return write_error

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
	await wait_seconds(0.25)

func select(kind: String) -> void:
	for i in 8:
		if game.target == kind: return
		await key(KEY_TAB)
	check(game.target == kind, "Target " + kind + " is reachable")

func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func go(destination: Vector2) -> void:
	var deadline = game.t + 12.0
	while game.t < deadline:
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
