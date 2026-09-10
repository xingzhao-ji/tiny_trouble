extends SceneTree
## Manual play only. No route input, outcome score, enjoyment inference or
## recording. Disposable study profiles remain separate through navigation.
var session_id := ""
var scene_key := "demo"
var camera_variant := "default"
var camera_applied := 0
var smoke := false
const SCENES := {"demo": "res://scenes/main.tscn", "workshop": "res://scenes/chapter/workshop.tscn", "crumb": "res://scenes/chapter/crumb_crossing.tscn", "harbor": "res://scenes/chapter/milk_harbor.tscn"}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	session_id = "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	for arg in OS.get_cmdline_user_args():
		if not (arg.begins_with("--playtest-scene=") or arg.begins_with("--camera-variant=") or arg in ["--playtest-smoke", "--touch-ui"]):
			push_error("Unsupported manual-study option: " + arg)
			quit(1)
			return
		if arg.begins_with("--playtest-scene="): scene_key = arg.trim_prefix("--playtest-scene=")
		if arg.begins_with("--camera-variant="): camera_variant = arg.trim_prefix("--camera-variant=")
		smoke = smoke or arg == "--playtest-smoke"
	if not SCENES.has(scene_key) or camera_variant not in ["default", "closer"]:
		push_error("Use demo/workshop/crumb/harbor and camera variant default/closer.")
		quit(1)
		return
	if camera_variant == "closer" and scene_key != "harbor":
		push_error("The closer camera is a Harbor-only study alternative.")
		quit(1)
		return
	var prefix := "user://manual_study_" + session_id
	var chapter_path := prefix + "_chapter.json"
	if scene_key == "harbor":
		var profile = load("res://scripts/chapter/chapter_progress.gd").new()
		profile.save_path = chapter_path
		if not profile.complete_stage("W01S01") or not profile.complete_stage("W01S02"):
			push_error("Could not create the isolated Harbor prerequisite fixture.")
			quit(1)
			return
	var scene = load(SCENES[scene_key]).instantiate()
	scene.save_path = prefix + "_demo.json"
	scene.settings_path = prefix + "_settings.cfg"
	scene.chapter_profile_path = chapter_path
	root.add_child(scene)
	current_scene = scene
	print("MANUAL PLAYTEST READY: session=%s scene=%s camera=%s; no human result has been recorded." % [session_id, scene_key, camera_variant])
	print("Runtime: %s | project %s | Godot %s" % [OS.get_executable_path(), ProjectSettings.get_setting("application/config/version", "unversioned legacy package"), Engine.get_version_info().string])
	print("Profiles remain isolated under: " + ProjectSettings.globalize_path(prefix))
	print("Harbor starts fresh with only its two prerequisite completion flags seeded." if scene_key == "harbor" else "Fresh study profile; normal stage progression applies.")
	await process_frame
	await process_frame
	if smoke:
		# A two-frame cold launch can still have Ogg playback initialization in
		# flight. Give the smoke's music node a bounded startup grace before
		# the normal stop/drain/free sequence; manual play is unaffected.
		await create_timer(0.25).timeout
		var ok: bool = scene.save_path == prefix + "_demo.json" and scene.settings_path == prefix + "_settings.cfg" and scene.chapter_profile_path == chapter_path
		ok = ok and (camera_variant != "closer" or camera_applied == scene.get_instance_id())
		if scene_key == "harbor": ok = ok and not scene.state.completed and scene.state.checkpoint == 0
		await scene.stop_audio()
		scene.queue_free()
		current_scene = null
		await process_frame
		await process_frame
		for suffix in ["_demo.json", "_chapter.json", "_settings.cfg"]:
			for tail in ["", ".bak", ".tmp"]:
				if FileAccess.file_exists(prefix + suffix + tail): DirAccess.remove_absolute(prefix + suffix + tail)
		print("MANUAL LAUNCHER SMOKE: %s; startup/isolation only, no player validation." % ("PASS" if ok else "FAIL"))
		quit(0 if ok else 1)

func _process(_delta: float) -> bool:
	if camera_variant == "closer" and is_instance_valid(current_scene) and current_scene.get_script().resource_path == "res://scripts/chapter/milk_harbor.gd" and camera_applied != current_scene.get_instance_id():
		if is_instance_valid(current_scene.camera):
			current_scene.camera.size *= 0.8
			camera_applied = current_scene.get_instance_id()
	return false
