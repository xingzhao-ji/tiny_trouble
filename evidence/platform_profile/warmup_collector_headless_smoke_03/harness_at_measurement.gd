extends SceneTree
## Native profiling fixture, not a player-completion replay. The stable exported
## runtime handles movement, resizing, boarding, flight, audio, saves and rendering.
## Preparation/teleports are explicit and retained in the measured frame stream.
var game: Node3D
var output_dir := ""
var duration_seconds := 60.0
var warmup_seconds := 2.0
var warmup_started_usec := 0
var warmup_start_unix := 0.0
var warmup_end_unix := 0.0
var warmup_wall_seconds := 0.0
var warmup_frames := 0
var warmup_walking_frames := 0
var warmup_flight_frames := 0
var warmup_completed_flights := 0
var warmup_fixture_cycles := 0
var workload_running := false
var active_start_unix := 0.0
var started_usec := 0
var last_frame_usec := 0
var measured := false
# Two Float64 columns plus one bit-mask byte per frame: exact packed payload
# 17 bytes/slot, allocated before warmup. No per-frame Array/Variant allocation.
var frame_times := PackedFloat64Array()
var frame_intervals := PackedFloat64Array()
var frame_flags := PackedByteArray()
var frame_count := 0
var frame_capacity := 0
var monitor_rows: Array[Dictionary] = []
var load_rows: Array[Dictionary] = []
var events: Array[Dictionary] = []
var latency_rows: Array[Dictionary] = []
var pending_latency: Array[Dictionary] = []
var render_post_draw_count := 0
var next_monitor_usec := 0
var fixture_until_frame := 0
var failures: Array[String] = []
var scene_paths: Array[String] = []
var profile_path := ""
var settings_path := ""
var demo_path := ""
var initial_display: Dictionary = {}
var peak_draws := 0
var peak_objects := 0
var walking_frames := 0
var flight_frames := 0
var boarding_frames := 0
var completed_flights := 0
var fixture_cycles := 0
var smoke := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--profile-output="): output_dir = arg.trim_prefix("--profile-output=")
		if arg.begins_with("--profile-duration="): duration_seconds = float(arg.trim_prefix("--profile-duration="))
		if arg.begins_with("--profile-warmup="): warmup_seconds = float(arg.trim_prefix("--profile-warmup="))
		smoke = smoke or arg == "--profile-smoke"
	if not is_finite(duration_seconds) or not is_finite(warmup_seconds) or duration_seconds < 2 or duration_seconds > 1200 or warmup_seconds < 2 or warmup_seconds > 120:
		push_error("Profile duration must be 2–1200 seconds and active warmup 2–120 seconds.")
		quit(1)
		return
	if output_dir.is_empty():
		push_error("--profile-output is required.")
		quit(1)
		return
	if DisplayServer.get_name() == "headless" and not smoke:
		push_error("Headless rendering is not a native performance measurement. Use --profile-smoke only for harness validation.")
		quit(1)
		return
	if not Engine.get_write_movie_path().is_empty():
		push_error("Movie Maker cannot supply this real-time profile.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		push_error("Profile output directory could not be created.")
		quit(1)
		return
	var suffix := str(OS.get_process_id())
	profile_path = "user://platform_profile_chapter_" + suffix + ".json"
	settings_path = "user://platform_profile_settings_" + suffix + ".cfg"
	demo_path = "user://platform_profile_demo_" + suffix + ".json"
	_cleanup_files()
	RenderingServer.frame_post_draw.connect(_after_draw)
	game = await _load_scene("res://scenes/main.tscn", "VS01")
	if game == null: return
	game.on_command("start", null)
	game.reduced_motion = false
	await create_timer(0.4).timeout
	if DisplayServer.get_name() != "headless": DisplayServer.window_move_to_foreground()
	# Allocate the entire bounded frame store before warmup. A capped 60 FPS,
	# 1200-second run reserves 72,120 slots = 1,226,040 packed payload bytes.
	# An uncapped run reserves at most 360,000 slots; overflow fails explicitly.
	var retention_fps: int = Engine.max_fps if Engine.max_fps > 0 else 300
	frame_capacity = mini(360000, int(ceil(duration_seconds * retention_fps)) + 120)
	frame_times.resize(frame_capacity)
	frame_intervals.resize(frame_capacity)
	frame_flags.resize(frame_capacity)
	_prepare_fixture()
	warmup_started_usec = Time.get_ticks_usec()
	warmup_start_unix = Time.get_unix_time_from_system()
	workload_running = true
	print("PROFILE WARMUP: %.1f seconds of the same active route fixture; excluded from primary statistics" % warmup_seconds)
	await _run_fixture()
	workload_running = false
	measured = false
	_release_movement()
	var active_wall_seconds: float = float(Time.get_ticks_usec() - started_usec) / 1000000.0
	var active_end_unix: float = Time.get_unix_time_from_system()
	while not pending_latency.is_empty(): _finish_pending(0, false, "active_interval_ended")
	var ending_display: Dictionary = _display_config()
	if frame_count < 30: failures.append("Too few process frames were sampled.")
	if not smoke and (walking_frames < 300 or flight_frames < 100 or completed_flights < 1):
		failures.append("Workload did not include sufficient actual walking and complete toast flight.")
	await _unload_scene()
	# Load/readiness probes are separate from the continuous active sample. These
	# are first loads in this process after VS01, with shared resources/OS caches warm.
	for item: Array in [["res://scenes/chapter/crumb_crossing.tscn", "W01S01"], ["res://scenes/chapter/blueberry_ballast.tscn", "W01S02"], ["res://scenes/chapter/milk_harbor.tscn", "W01S03"]]:
		game = await _load_scene(item[0], item[1])
		if game == null: break
		await create_timer(0.25).timeout
		await _unload_scene()
	var report: Dictionary = {
		"schema_version": 2, "result": "PASS" if failures.is_empty() else "FAIL", "failures": failures,
		"measurement_kind": "native_active_fixture_baseline" if not smoke else "harness_smoke_not_a_performance_result",
		"duration_requested_seconds": duration_seconds, "active_wall_seconds": active_wall_seconds,
		"warmup": {"requested_seconds": warmup_seconds, "wall_seconds": warmup_wall_seconds,
			"start_unix_seconds": warmup_start_unix, "end_unix_seconds": warmup_end_unix,
			"process_frames": warmup_frames, "walking_frames": warmup_walking_frames,
			"flight_frames": warmup_flight_frames, "completed_flights": warmup_completed_flights,
			"fixture_cycles_started": warmup_fixture_cycles, "workload": "Same continuous active fixture; no idle-only warmup. Measurement begins without resetting the current motion.",
			"excluded_from_primary_frame_statistics": true},
		"active_start_unix_seconds": active_start_unix, "active_end_unix_seconds": active_end_unix,
		"engine": Engine.get_version_info(), "executable": OS.get_executable_path(), "process_id": OS.get_process_id(),
		"host": {"os": OS.get_name(), "os_version": OS.get_version(), "model": OS.get_model_name(), "processor": OS.get_processor_name(), "logical_processors": OS.get_processor_count(), "debug_build": OS.is_debug_build(), "renderer": RenderingServer.get_video_adapter_name()},
		"conditions": {"start": initial_display, "end": ending_display, "capture_enabled": false, "capture_count": 0, "movie_mode": false, "fixed_fps_mode": false, "fixed_fps_source": "Launcher explicitly runs normal real-time mode without --fixed-fps; absence is not inferred from consumed engine args.", "reduced_motion": false, "audio": "Normal runtime audio enabled; unique settings file, default volumes.", "warmup_seconds": warmup_seconds},
		"workload": {"scene": "VS01", "fixture_cycles": fixture_cycles, "completed_flights": completed_flights, "walking_frames": walking_frames, "flight_frames": flight_frames, "boarding_frames": boarding_frames,
			"description": "Prepared launch state and starting position are injected using model APIs. Subsequent ramp/ground walking, resize, boarding, and toast launch use production input/animation. Completion resets are explicit fixture events. This is not an ordinary-input completion test or a whole-campaign performance claim."},
		"process_frame_ms": _summary(_column(1)), "collector_memory": _collector_memory(), "ten_second_buckets": _buckets(),
		"peak_draw_calls": peak_draws, "peak_render_objects": peak_objects,
		"monitor_samples": monitor_rows, "input_response_samples": latency_rows, "fixture_events": events, "scene_loads": load_rows,
		"engine_monitor_note": "TIME_PROCESS / TIME_PHYSICS_PROCESS are interval maxima updated about once per second, not per-frame CPU costs; zero static allocation counters are unavailable in the release build.",
		"limitations": [
			"Frame intervals are wall time between SceneTree process callbacks, including cap/VSync waits, fixture reset work and ordinary game save I/O. They are not CPU-only or GPU timings.",
			"Input probes start at injected in-engine events scheduled near process-frame callbacks and end at the first frame_post_draw with a changed target transform. No pixel readback is performed. Physical device, OS event delivery, compositor and panel latency are excluded; input phase is not randomized.",
			"Static allocator monitors are unavailable in release exports. Zero/unknown values are reported unavailable. Render memory is an engine estimate, not process RSS or total unified-memory use.",
			"External RSS and CPU sampling plus this harness add overhead. Frame packed buffers are allocated before warmup; monitor/event/probe records accumulate during measurement. Exact packed bytes and serialized diagnostic sizes are reported, not falsely treated as complete allocator or process overhead. Normal game saves remain enabled.",
			"Load times are in-process resource load, instantiation, ready callback and first rendered viewport timing. They exclude process startup and do not establish cold disk/cache or cold shader behavior.",
			"This run describes only the recorded host, resolution, focus, cap and power conditions. Other hardware, physical controllers, touch hardware, battery life and thermal sustainability are unverified."],
		"sources": ["https://docs.godotengine.org/en/4.5/classes/class_performance.html", "https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html#class-renderingserver-signal-frame-post-draw", "https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-get-memory-info"]}
	_write_frames()
	report["result"] = "PASS" if failures.is_empty() else "FAIL"
	_write_json("runtime_profile.json", report)
	_cleanup_files()
	print("PROFILE: %s — %d frames, p50 %.3f / p95 %.3f / p99 %.3f ms, %d complete flights" % [report.result, frame_count, report.process_frame_ms.p50, report.process_frame_ms.p95, report.process_frame_ms.p99, completed_flights])
	quit(0 if failures.is_empty() else 1)


func _run_fixture() -> void:
	while _active():
		await _go(Vector2(6.0, 1.2))
		await _tap_action("jump", "jump", game.pip, "position")
		await _go(Vector2(7.0, 3.0))
		await _go(Vector2(6.0, 1.2))
		await _go(Vector2(0.7, 1.2))
		await _go(Vector2(0.7, -2.5))
		if not _active(): break
		game.target = "cereal"
		await _tap_key(KEY_1, "cereal_shrink", game.props.cereal, "scale")
		await _wait_active(0.5)
		await _tap_key(KEY_2, "cereal_normal", game.props.cereal, "scale")
		await _wait_active(0.5)
		if not _active(): break
		game.target = "toaster"
		await _tap_action("interact", "boarding", game.pip, "position")
		await _wait_active(0.65)
		if not _active(): break
		if not game.boarded:
			failures.append("Fixture did not board the prepared toast through the production input handler.")
			break
		await _tap_key(KEY_1, "toast_release", game.pip, "position")
		while _active() and game.flying: await process_frame
		if game.state.completed:
			if measured: completed_flights += 1
			else: warmup_completed_flights += 1
		await _wait_active(0.25)
		if _active(): _prepare_fixture()


func _begin_active(now: int) -> void:
	warmup_wall_seconds = float(now - warmup_started_usec) / 1000000.0
	warmup_end_unix = Time.get_unix_time_from_system()
	warmup_fixture_cycles = fixture_cycles
	fixture_cycles = 0
	initial_display = _display_config()
	started_usec = now
	active_start_unix = warmup_end_unix
	next_monitor_usec = now
	last_frame_usec = 0
	measured = true
	print("PROFILE ACTIVE: continuous %.1f seconds after %.2f-second active warmup; captures disabled" % [duration_seconds, warmup_wall_seconds])


func _collector_memory() -> Dictionary:
	return {"frame_storage": "Preallocated PackedFloat64Array time + interval columns and PackedByteArray flags",
		"frame_capacity": frame_capacity, "retained_frames": frame_count,
		"bytes_per_frame_slot": 17, "exact_packed_payload_bytes": frame_capacity * 17,
		"used_packed_payload_bytes": frame_count * 17, "allocation_phase": "before warmup",
		"hard_capacity_limit_frames": 360000, "hard_packed_payload_limit_bytes": 6120000,
		"monitor_records": monitor_rows.size(), "event_records": events.size(), "latency_records": latency_rows.size(),
		"diagnostic_serialized_bytes_after_active": var_to_bytes([monitor_rows, events, latency_rows]).size(),
		"container_allocator_overhead_bytes": null,
		"note": "Packed payload size is exact; container headers, allocator alignment, dictionaries and runtime bookkeeping are not included. Serialized diagnostic size is a reproducible content-size measure, not actual allocated RAM. Percentile/CSV/JSON construction occurs after active sampling and may raise later whole-process RSS. No claim that RSS growth equals game-only allocations."}


func _process(_delta: float) -> bool:
	if not workload_running or not is_instance_valid(game): return false
	var now: int = Time.get_ticks_usec()
	if not measured:
		warmup_frames += 1
		warmup_walking_frames += 1 if game.walking else 0
		warmup_flight_frames += 1 if game.flying else 0
		if now - warmup_started_usec < int(warmup_seconds * 1000000): return false
		_begin_active(now)
	var focused: bool = DisplayServer.get_name() != "headless" and DisplayServer.window_is_focused()
	if last_frame_usec > 0:
		if frame_count >= frame_capacity:
			failures.append("Bounded frame storage exhausted; no frame samples were silently dropped.")
			return false
		frame_times[frame_count] = float(now - started_usec) / 1000000.0
		frame_intervals[frame_count] = float(now - last_frame_usec) / 1000.0
		frame_flags[frame_count] = (1 if focused else 0) | (2 if Engine.get_process_frames() <= fixture_until_frame else 0) | (4 if game.walking else 0) | (8 if game.flying else 0) | (16 if game.boarded else 0)
		frame_count += 1
	last_frame_usec = now
	walking_frames += 1 if game.walking else 0
	flight_frames += 1 if game.flying else 0
	boarding_frames += 1 if game.boarded else 0
	peak_draws = maxi(peak_draws, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	peak_objects = maxi(peak_objects, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
	if now >= next_monitor_usec:
		next_monitor_usec = now + 1000000
		monitor_rows.append({"engine_ticks_usec": now, "active_seconds": float(now - started_usec) / 1000000.0, "window_focused": focused,
			"fps_monitor": Performance.get_monitor(Performance.TIME_FPS),
			"process_interval_peak_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000,
			"physics_interval_peak_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000,
			"static_allocator_bytes": _positive(Performance.get_monitor(Performance.MEMORY_STATIC)),
			"static_allocator_peak_bytes": _positive(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)),
			"render_video_bytes": _positive(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
			"render_texture_bytes": _positive(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
			"render_buffer_bytes": _positive(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
			"system_memory": OS.get_memory_info()})
	return false


func _after_draw() -> void:
	render_post_draw_count += 1
	if pending_latency.is_empty() or not is_instance_valid(game): return
	for index: int in range(pending_latency.size() - 1, -1, -1):
		var probe: Dictionary = pending_latency[index]
		var target: Node3D = probe.target
		if not is_instance_valid(target):
			_finish_pending(index, false, "target_freed")
			continue
		var current: Vector3 = target.get(probe.property)
		var difference: Vector3 = current - Vector3(probe.before)
		var distance: float = difference.length()
		if probe.label == "movement": distance = Vector2(difference.x, difference.z).length()
		elif probe.label == "jump": distance = absf(difference.y)
		if distance > 0.001: _finish_pending(index, true, "changed_transform_after_viewport_update")
		elif Time.get_ticks_usec() - int(probe.started_usec) > 1000000: _finish_pending(index, false, "observation_timeout")


func _begin_latency(label: String, target: Node3D, property: String) -> void:
	if not measured: return
	pending_latency.append({"label": label, "target": target, "property": property, "before": target.get(property), "started_usec": Time.get_ticks_usec(), "frame": Engine.get_process_frames(), "render_count": render_post_draw_count})


func _finish_pending(index: int, changed: bool, status: String) -> void:
	var probe: Dictionary = pending_latency[index]
	var node: Node3D = probe.target
	var point: Vector3 = node.global_position + Vector3(0, 0.3, 0) if is_instance_valid(node) else Vector3.ZERO
	latency_rows.append({"label": probe.label, "active_seconds": float(int(probe.started_usec) - started_usec) / 1000000.0,
		"observation_status": status, "input_source": "InputMap action-state injection" if probe.label == "movement" else "Input.parse_input_event",
		"changed_render_state_observed": changed, "elapsed_ms": float(Time.get_ticks_usec() - int(probe.started_usec)) / 1000.0 if changed else null,
		"process_frame_difference": Engine.get_process_frames() - int(probe.frame) if changed else null,
		"render_post_draws_until_change": render_post_draw_count - int(probe.render_count) if changed else null,
		"target_in_viewport": is_instance_valid(game) and not game.camera.is_position_behind(point) and game.get_viewport().get_visible_rect().has_point(game.camera.unproject_position(point)),
		"window_focused": DisplayServer.get_name() != "headless" and DisplayServer.window_is_focused()})
	pending_latency.remove_at(index)


func _load_scene(path: String, label: String) -> Node3D:
	var start: int = Time.get_ticks_usec()
	var packed: PackedScene = load(path)
	var loaded: int = Time.get_ticks_usec()
	if packed == null:
		failures.append("Scene could not load: " + path)
		return null
	var scene: Node3D = packed.instantiate()
	var instantiated: int = Time.get_ticks_usec()
	scene.save_path = demo_path
	scene.settings_path = settings_path
	scene.chapter_profile_path = profile_path
	root.add_child(scene)
	var ready_usec: int = Time.get_ticks_usec()
	await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	load_rows.append({"scene": label, "resource_path": path, "resource_load_ms": float(loaded - start) / 1000.0,
		"instantiate_ms": float(instantiated - loaded) / 1000.0, "add_child_to_ready_ms": float(ready_usec - instantiated) / 1000.0,
		"load_to_ready_ms": float(ready_usec - start) / 1000.0, "load_to_first_render_post_draw_ms": float(Time.get_ticks_usec() - start) / 1000.0,
		"first_render_unix_seconds": Time.get_unix_time_from_system(),
		"outside_active_sampling": true})
	return scene


func _unload_scene() -> void:
	if not is_instance_valid(game): return
	await game.stop_audio()
	game.queue_free()
	await process_frame
	game = null


func _prepare_fixture() -> void:
	_release_movement()
	if game.paused: game.on_command("resume", null)
	var rules: RefCounted = game.state.get_script().new()
	rules.resize("spoon", 0)
	rules.interact("spoon")
	rules.pass_handle()
	rules.place("bridge")
	rules.resize("spoon", 2)
	rules.resize("blueberry", 0)
	rules.interact("blueberry")
	rules.place("ballast")
	rules.resize("blueberry", 2)
	rules.resize("butter", 0)
	rules.interact("butter")
	rules.place("wedge")
	rules.resize("butter", 1)
	rules.resize("napkin", 0)
	rules.interact("napkin")
	rules.place("landing")
	rules.resize("napkin", 2)
	rules.resize("blueberry", 0)
	rules.interact("blueberry")
	rules.place("lever")
	rules.resize("blueberry", 2)
	game.state = rules
	game.flying = false
	game.boarded = false
	game.started = true
	game.exploring = true
	game.recovery_time = 0
	game.vertical_speed = 0
	game.jump_buffer = 0
	game.celebration_time = 0
	game.sync_props(false)
	game.pip.position = Vector3(-1.2, 0.06, 1.2)
	game.target = "cereal"
	fixture_cycles += 1
	fixture_until_frame = Engine.get_process_frames() + 2
	if measured: events.append({"active_seconds": float(Time.get_ticks_usec() - started_usec) / 1000000.0, "event": "fixture_reset", "included_in_primary_frame_statistics": true})


func _go(destination: Vector2) -> void:
	if not _active(): return
	_begin_latency("movement", game.pip, "position")
	var timeout: int = Time.get_ticks_usec() + 6500000
	while _active() and Time.get_ticks_usec() < timeout:
		var offset: Vector2 = destination - Vector2(game.pip.position.x, game.pip.position.z)
		if offset.length() < 0.12: break
		_direction(Vector3(offset.x, 0, offset.y).normalized())
		await process_frame
	_release_movement()
	if _active() and Vector2(game.pip.position.x, game.pip.position.z).distance_to(destination) > 0.25:
		failures.append("Movement fixture failed to reach " + str(destination))
		workload_running = false


func _direction(desired: Vector3) -> void:
	var right: Vector3 = game.camera.global_basis.x
	var back: Vector3 = game.camera.global_basis.z
	right.y = 0
	back.y = 0
	var horizontal: float = desired.dot(right.normalized())
	var vertical: float = desired.dot(back.normalized())
	Input.action_press("move_right", maxf(horizontal, 0))
	Input.action_press("move_left", maxf(-horizontal, 0))
	Input.action_press("move_down", maxf(vertical, 0))
	Input.action_press("move_up", maxf(-vertical, 0))


func _tap_key(key: Key, label: String, target: Node3D, property: String) -> void:
	if not _active(): return
	_begin_latency(label, target, property)
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)


func _tap_action(action: String, label: String, target: Node3D, property: String) -> void:
	if not _active(): return
	_begin_latency(label, target, property)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)


func _wait_active(seconds: float) -> void:
	var end: int = Time.get_ticks_usec() + int(seconds * 1000000)
	while _active() and Time.get_ticks_usec() < end: await process_frame


func _active() -> bool:
	if not workload_running or not failures.is_empty(): return false
	return not measured or Time.get_ticks_usec() - started_usec < int(duration_seconds * 1000000)


func _release_movement() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down"]: Input.action_release(action)


func _display_config() -> Dictionary:
	var native: bool = DisplayServer.get_name() != "headless"
	return {"display_driver": DisplayServer.get_name(), "window_pixels": str(DisplayServer.window_get_size()) if native else null,
		"logical_viewport": str(root.get_visible_rect().size), "focused": DisplayServer.window_is_focused() if native else null,
		"display_refresh_hz": DisplayServer.screen_get_refresh_rate() if native else null,
		"screen_scale": DisplayServer.screen_get_scale() if native else null,
		"vsync_mode": DisplayServer.window_get_vsync_mode() if native else null,
		"runtime_max_fps": Engine.max_fps, "configured_max_fps": ProjectSettings.get_setting("application/run/max_fps", 0),
		"physics_ticks_per_second": Engine.physics_ticks_per_second, "low_processor_mode": OS.low_processor_usage_mode}


func _positive(value: float) -> Variant:
	return value if value > 0 else null


func _column(index: int) -> Array[float]:
	var values: Array[float] = []
	for i: int in frame_count: values.append(frame_intervals[i] if index == 1 else frame_times[i])
	return values


func _summary(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {"samples": 0, "p50": 0, "p95": 0, "p99": 0, "max": 0}
	values = values.duplicate()
	values.sort()
	return {"samples": values.size(), "p50": values[mini(values.size() - 1, int(values.size() * 0.50))], "p95": values[mini(values.size() - 1, int(values.size() * 0.95))], "p99": values[mini(values.size() - 1, int(values.size() * 0.99))], "max": values[-1]}


func _buckets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for start: int in range(0, int(ceil(duration_seconds)), 10):
		var all: Array[float] = []
		var focused: Array[float] = []
		var unfocused: Array[float] = []
		var excluding_fixture: Array[float] = []
		for i: int in frame_count:
			if frame_times[i] >= start and frame_times[i] < start + 10:
				all.append(frame_intervals[i])
				if frame_flags[i] & 1: focused.append(frame_intervals[i])
				else: unfocused.append(frame_intervals[i])
				if not frame_flags[i] & 2: excluding_fixture.append(frame_intervals[i])
		result.append({"start_seconds": start, "end_seconds": minf(start + 10, duration_seconds), "all_process_frame_ms": _summary(all), "focused_frame_ms": _summary(focused), "unfocused_frame_ms": _summary(unfocused), "excluding_two_frames_after_fixture_reset_ms": _summary(excluding_fixture)})
	return result


func _write_json(filename: String, data: Dictionary) -> void:
	var file := FileAccess.open(output_dir.path_join(filename), FileAccess.WRITE)
	if file == null:
		failures.append("Cannot write " + filename)
		push_error(failures[-1])
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()


func _write_frames() -> void:
	var file := FileAccess.open(output_dir.path_join("process_frames.csv"), FileAccess.WRITE)
	if file == null:
		failures.append("Cannot write process_frames.csv")
		push_error(failures[-1])
		return
	file.store_csv_line(["active_seconds", "process_frame_ms", "window_focused", "fixture_transition", "walking", "flying", "boarded"])
	for i: int in frame_count:
		file.store_csv_line([str(frame_times[i]), str(frame_intervals[i]), str(bool(frame_flags[i] & 1)), str(bool(frame_flags[i] & 2)), str(bool(frame_flags[i] & 4)), str(bool(frame_flags[i] & 8)), str(bool(frame_flags[i] & 16))])
	file.close()


func _cleanup_files() -> void:
	for base: String in [profile_path, demo_path, settings_path]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(base + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(base + suffix))
