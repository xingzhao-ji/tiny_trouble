extends SceneTree
## W01S01 scene scenarios use model fixtures and injected starting positions.
## Actual scene movement, resize, menu, recovery, and disk profile paths are
## exercised; this is not the separate ordinary-input route playthrough.

const Stage = preload("res://scripts/chapter/crumb_crossing.gd")
const Demo = preload("res://scripts/main.gd")
const State = preload("res://scripts/chapter/crumb_state.gd")
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
const PASSAGE_Z: float = 2.45
const SUGAR_SMALL_SCALE: float = 0.35
var game: Node3D
var checks: int = 0
var failures: int = 0
var profile_path: String
var settings_path: String
var demo_path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	profile_path = "user://crumb_scene_test_%d.json" % OS.get_process_id()
	settings_path = "user://crumb_scene_settings_%d.cfg" % OS.get_process_id()
	demo_path = "user://crumb_scene_demo_%d.json" % OS.get_process_id()
	_cleanup()
	game = _create_scene()
	_expect(game.props.size() == 2 and game.props.has("sugar") and game.props.has("spoon"), "Chapter scene contains exactly its own two playable props")
	_expect(game.chapter_profile.save_path == profile_path and game.settings_path == settings_path, "Scene profile and settings are isolated before ready")
	_test_sugar_corridor()
	_test_growth_clearance()
	_test_handle_and_bridge_guards()
	_test_recovery_paths()
	await _test_paused_resize_title()
	await _test_completion_and_profile()
	_test_completion_write_retry()
	await _test_invalid_stage_snapshot()
	await _test_workshop_roundtrip()
	await _test_demo_navigation_roundtrip()
	await game.stop_audio()
	game.queue_free()
	await process_frame
	_release_movement()
	_cleanup()
	print("%s: %d Crumb Crossing scene checks; physical corridor, primary mesh clearance, occupied bridge, checkpoint recovery, pause, and chapter profile." % ["PASS" if failures == 0 else "FAIL", checks])
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


func _test_sugar_corridor() -> void:
	_setup(0)
	game.pip.position = Vector3(-10.0, 0.08, PASSAGE_Z)
	var reached: bool = _walk_toward_x(-7.0, 210)
	_expect(not reached and game.pip.position.x < -8.5, "Normal cube physically stops an eastbound tray exit")
	_expect(not game.state.sugar_passed and game.state.checkpoint == 0, "A blocked walk cannot award the sugar checkpoint")
	# A jump must not bypass the full-width normal obstruction.
	game.jump_buffer = 0.15
	reached = _walk_toward_x(-7.0, 80)
	_expect(not reached and game.state.checkpoint == 0, "Jumping at the normal sugar cube cannot skip the opening puzzle")
	_setup(0)
	game.target = "sugar"
	game.resize_target(0)
	_expect(int(game.state.sizes["sugar"]) == 0 and game.state.checkpoint == 0, "Scene shrink changes sugar size without claiming a passage")
	game.pip.position = Vector3(-10.0, 0.08, PASSAGE_Z)
	reached = _walk_toward_x(-7.0, 210)
	_expect(reached and game.recovery_time == 0, "Small sugar leaves an actual traversable path out of the tray")
	_expect(game.state.sugar_passed and game.state.checkpoint == 1, "Crossing the tray exit through production movement awards checkpoint one")
	_expect(game.chapter_profile.stage_snapshot(Stage.STAGE_ID).get("checkpoint") == 1, "Physical sugar passage saves the chapter stage checkpoint")
	# Primary vertices, not a copy of the collision-radius formula, establish
	# that Pip's body and feet fit at the narrowest visible part of the path.
	game.pip.position = Vector3(Stage.STAGE_TRAYS["sugar"].x, 0.08, PASSAGE_Z)
	game.pip_art.transform = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3.ZERO)
	for foot: String in ["FootL", "FootR"]:
		game.pip_art.get_node(foot).rotation = Vector3.ZERO
	var sugar: Node3D = game.props["sugar"]
	_expect(not _actor_enters_mesh(sugar.get_node("Body")), "East-facing Pip's primary body and feet clear the small sugar mesh in the passage")
	var tray: Node3D = game.get_node("SugarCorridorTray")
	_expect(not _actor_enters_mesh(tray.get_node("WallFar")), "The same passage keeps Pip's primary body and feet outside the paper wall")


func _test_growth_clearance() -> void:
	_setup(1)
	game.target = "sugar"
	var sugar: Node3D = game.props["sugar"]
	game.pip.position = Stage.STAGE_TRAYS["sugar"] + Vector3(-0.76, 0.02, 0)
	game.pip_art.transform = Transform3D.IDENTITY
	# Demonstrate that the requested normal-sized mesh would actually cover a
	# primary actor vertex, then restore the visible small size before acting.
	sugar.scale = Vector3.ONE
	_expect(_actor_enters_mesh(sugar.get_node("Body")), "Growth fixture puts Pip inside the requested normal sugar mesh")
	sugar.scale = Vector3.ONE * SUGAR_SMALL_SCALE
	_expect(not _actor_enters_mesh(sugar.get_node("Body")), "Growth fixture starts clear of the existing small sugar mesh")
	var before: Dictionary = game.state.to_dict()
	game.resize_target(1)
	_expect(game.state.to_dict() == before and sugar.scale.is_equal_approx(Vector3.ONE * SUGAR_SMALL_SCALE), "Scene refuses sugar growth over Pip without changing rules or visible size")
	_expect(game.hud.message.text.contains("growing space"), "Blocked growth explains how to make room")
	game.pip.position = Vector3(-6.9, 0.06, 3.5)
	game.resize_target(1)
	_expect(int(game.state.sizes["sugar"]) == 1, "Stepping into free space permits normal sugar growth")
	before = game.state.to_dict()
	game.resize_target(2)
	_expect(game.state.to_dict() == before, "Oversized sugar cannot grow through the fixed paper tray")
	game.target = "spoon"
	game.pip.position = Stage.STAGE_TRAYS["spoon"] + Vector3(0, 0, 0.8)
	before = game.state.to_dict()
	game.resize_target(2)
	_expect(game.state.to_dict() == before, "Large spoon requires its roomy bridge socket")
	game.target = "sugar"
	game.pip.position = Stage.EXIT_POS
	before = game.state.to_dict()
	game.resize_target(0)
	_expect(game.state.to_dict() == before, "Resize cannot manipulate a prop across the room")


func _test_handle_and_bridge_guards() -> void:
	_setup(1)
	game.target = "spoon"
	game.pip.position = Stage.STAGE_TRAYS["spoon"] + Vector3(0, 0, -0.8)
	game.resize_target(0)
	game.interact()
	_expect(game.state.carried == "spoon", "Scene picks up the nearby small spoon")
	game.pip.position = Vector3(-5.7, 0.06, 1.2)
	game.interact()
	_expect(game.state.carried == "spoon" and not game.state.handle_passed, "Being near the bridge cannot skip carrying through the handle")
	game.pip.position = Vector3(-6.75, 0.06, 1.2)
	var reached: bool = _walk_toward_x(-5.7, 90)
	_expect(reached and game.state.handle_passed, "Production movement with a carried spoon passes the authored handle")
	game.interact()
	_expect(game.state.sockets["spoon"] == "bridge" and game.state.carried == "", "Scene places the portable spoon at the nearby bridge rest")
	game.target = "spoon"
	game.resize_target(2)
	_expect(game.state.bridge_placed and game.state.checkpoint == 2, "Growing the placed spoon creates the scene's second checkpoint")
	var handle: MeshInstance3D = game.props["spoon"].get_child(0)
	var top: float = (handle.global_transform * handle.mesh.get_aabb().end).y
	game.pip.position = Vector3(-3.7, top, 1.2)
	_expect(is_equal_approx(game.surface_height(game.pip.position), top), "Bridge support matches the top of the actual spoon handle mesh")
	for requested: int in [0, 1]:
		var before: Dictionary = game.state.to_dict()
		game.resize_target(requested)
		_expect(game.state.to_dict() == before and game.state.bridge_placed, "Occupied spoon prevents shrinking to size %d" % requested)
		_expect(game.hud.message.text.contains("Step off"), "Occupied bridge rejection gives a recoverable instruction")
	game.pip.position = Vector3(-5.9, 0.06, 1.2)
	game.resize_target(0)
	_expect(not game.state.bridge_placed and game.state.checkpoint == 2, "Stepping off permits bridge experiments without losing the checkpoint")
	game.recover("Bridge reset scenario")
	_expect(game.state.bridge_placed and int(game.state.sizes["spoon"]) == 2, "Recovery reconstructs a removed checkpoint-two bridge")
	_assert_safe_respawn(game, "Removed bridge recovery")
	_assert_prop_sync(game, "Removed bridge recovery")


func _test_recovery_paths() -> void:
	for checkpoint: int in range(3):
		_setup(checkpoint)
		game.state.discover()
		game.state.resize("spoon", 0)
		game.state.interact("spoon")
		game.sync_props(false)
		_expect(game.state.carried == "spoon", "Recovery fixture carries the spoon at checkpoint %d" % checkpoint)
		game.pip.position = Vector3(-4.2, 0.4, 3.0)
		game.vertical_speed = -3
		game.jump_buffer = 0.1
		_press_direction(Vector3.RIGHT)
		game.move_pip(1.0 / 60.0)
		_release_movement()
		_expect(game.recovery_time > 0 and game.hud.message.text.contains("splash"), "Production milk step triggers recovery at checkpoint %d" % checkpoint)
		_assert_canonical(checkpoint, "Milk recovery")
		_expect(game.state.discovered, "Recovery retains the earned crumb discovery at checkpoint %d" % checkpoint)
		_expect(game.vertical_speed == 0 and game.jump_buffer == 0, "Recovery clears fall and queued jump at checkpoint %d" % checkpoint)
		_assert_safe_respawn(game, "Milk recovery %d" % checkpoint)
		_assert_prop_sync(game, "Milk recovery %d" % checkpoint)
		var saved: Dictionary = game.chapter_profile.stage_snapshot(Stage.STAGE_ID)
		var verifier: State = State.new()
		_expect(verifier.restore(saved) and verifier.checkpoint == checkpoint and verifier.carried == "", "Milk recovery persists a valid stable snapshot at checkpoint %d" % checkpoint)
		game.on_command("pause", null)
		game.pip.position = Vector3(0, 3, 0)
		game.on_command("reset", null)
		_expect(not game.paused and game.paused_tweens.is_empty(), "Paused checkpoint reset releases transition references at %d" % checkpoint)
		_assert_canonical(checkpoint, "Menu reset")
		_assert_safe_respawn(game, "Menu reset %d" % checkpoint)


func _test_paused_resize_title() -> void:
	# Drain the scene-construction frame before timing this real transition.
	await process_frame
	await process_frame
	await create_timer(0.02).timeout
	_setup(0)
	game.reduced_motion = false
	game.target = "sugar"
	game.resize_target(0)
	game.pip.position = Vector3(-10.0, 0.08, PASSAGE_Z)
	var crossed_before_animation: bool = _walk_toward_x(-7.0, 150)
	_expect(not crossed_before_animation and not game.state.sugar_passed, "Movement cannot enter the sugar passage before the visible shrink has opened it")
	await process_frame
	await process_frame
	await create_timer(0.05).timeout
	var sugar: Node3D = game.props["sugar"]
	_expect(int(game.state.sizes["sugar"]) == 0 and not sugar.scale.is_equal_approx(Vector3.ONE * SUGAR_SMALL_SCALE), "Pause scenario starts during an actual sugar resize")
	game.on_command("pause", null)
	var before: Vector3 = sugar.scale
	var before_position: Vector3 = game.pip.position
	var before_camera: Transform3D = game.camera.transform
	var before_clock: float = game.t
	_press_direction(Vector3.RIGHT)
	game._process(0.5)
	_release_movement()
	_expect(game.pip.position == before_position and game.camera.transform == before_camera and game.t == before_clock, "Chapter pause freezes movement, camera, and simulation clock")
	await create_timer(0.08).timeout
	_expect(sugar.scale.is_equal_approx(before) and not game.paused_tweens.is_empty(), "Pause freezes the unfinished chapter prop resize")
	game.on_command("controls", null)
	game.on_command("pause", null)
	game.on_command("title", null)
	_expect(not game.started and not game.paused and game.hud.menu_mode == "title", "Chapter title return clears pause after nested Controls navigation")
	_expect(game.paused_tweens.is_empty(), "Chapter title return releases suspended resize references")
	await create_timer(0.45).timeout
	_expect(sugar.scale.is_equal_approx(Vector3.ONE * SUGAR_SMALL_SCALE), "Sugar resize settles while the chapter title is open")
	game.on_command("start", null)
	_expect(game.started and not game.paused and sugar.scale.is_equal_approx(Vector3.ONE * SUGAR_SMALL_SCALE), "Continue crossing resumes a fully settled prop")
	game.reduced_motion = true


func _test_completion_and_profile() -> void:
	for checkpoint: int in [0, 1]:
		_setup(checkpoint)
		game.pip.position = Stage.EXIT_POS
		game.move_pip(1.0 / 60.0)
		_expect(not game.state.completed and not game.chapter_profile.is_completed(Stage.STAGE_ID), "Flag proximity before checkpoint two cannot award completion at %d" % checkpoint)
	_setup(2)
	game.pip.position = Stage.FRIEND_POS
	game.interact()
	_expect(game.state.discovered and game.chapter_profile.stage_snapshot(Stage.STAGE_ID).get("discovered") == true, "Actual crumb-friend interaction saves the optional discovery")
	game.pip.position = Stage.EXIT_POS + Vector3(0, 0, 1.0)
	game.move_pip(1.0 / 60.0)
	_expect(not game.state.completed, "Completed bridge alone does not finish outside the right-hand flag")
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(game.state.completed and game.ever_completed, "Reaching the right-hand flag after building the bridge completes the stage")
	_expect(game.chapter_profile.is_completed(Stage.STAGE_ID) and game.chapter_profile.is_unlocked("W01S02"), "Actual stage finish records earned chapter history and unlocks stage two")
	game.move_pip(1.3)
	_expect(game.paused and game.hud.menu_mode == "complete", "Flag celebration resolves to the chapter completion menu")
	var reloaded: Node3D = _create_scene()
	_expect(reloaded.has_save and reloaded.state.completed and reloaded.ever_completed, "Fresh scene reads achieved completion from the chapter profile")
	_expect(reloaded.paused and reloaded.hud.menu_mode == "complete", "Completed Continue opens the stage-complete menu")
	_assert_safe_respawn(reloaded, "Completed reload")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame
	game.on_command("explore", null)
	_expect(game.exploring and not game.paused and not game.state.completed, "Keep exploring returns to playable chapter geometry")
	_expect(game.state.discovered and game.state.bridge_placed and game.chapter_profile.is_completed(Stage.STAGE_ID), "Exploration preserves discovery, crossing, and chapter completion history")
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(not game.state.completed, "Keep exploring can revisit the flag without reopening completion")
	game.on_command("title", null)
	reloaded = _create_scene()
	_expect(reloaded.has_save and not reloaded.state.completed and not reloaded.paused, "Exploration save reloads as a playable crossing")
	_expect(reloaded.ever_completed and reloaded.state.discovered and reloaded.chapter_profile.is_unlocked("W01S02"), "Fresh exploration reload retains earned discovery and stage unlock")
	_assert_safe_respawn(reloaded, "Exploration reload")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame
	game.on_command("new", null)
	_expect(game.state.checkpoint == 0 and not game.state.completed and not game.state.discovered, "Play again starts fresh stage rules")
	_expect(game.ever_completed and game.chapter_profile.is_completed(Stage.STAGE_ID) and game.chapter_profile.is_unlocked("W01S02"), "Play again preserves achieved chapter history and unlocks")
	var profile: Progress = Progress.new()
	profile.save_path = profile_path
	_expect(profile.load_profile() and profile.is_completed(Stage.STAGE_ID), "A separate profile reader retains earned completion after replay reset")
	_expect(profile.stage_snapshot(Stage.STAGE_ID).get("checkpoint") == 0, "Replay reset saves a genuine opening-stage snapshot")


func _test_invalid_stage_snapshot() -> void:
	var malformed: Dictionary = game.state.to_dict()
	malformed["schema_version"] = 500
	_expect(game.chapter_profile.save_stage(Stage.STAGE_ID, malformed), "Profile accepts bounded stage data while scene owns its semantic validation")
	var reloaded: Node3D = _create_scene()
	_expect(not reloaded.has_save and reloaded.state.checkpoint == 0, "Scene rejects an unsupported stage snapshot without mutating fresh rules")
	_expect(reloaded.ever_completed and reloaded.chapter_profile.is_completed(Stage.STAGE_ID), "Rejected stage snapshot does not erase validated chapter completion history")
	_expect(reloaded.save_notice.contains("fresh start"), "Scene explains recovery from an unsupported stage snapshot")
	_assert_safe_respawn(reloaded, "Invalid stage snapshot")
	await reloaded.stop_audio()
	reloaded.queue_free()
	await process_frame


func _test_completion_write_retry() -> void:
	var original_profile: Progress = game.chapter_profile
	var isolated: Progress = Progress.new()
	# No directories are created at this unique path. A failed open is a
	# deterministic save error without altering permissions or real user files.
	isolated.save_path = profile_path + ".missing/profile.json"
	game.chapter_profile = isolated
	_setup(2)
	game.pip.position = Stage.EXIT_POS
	game.move_pip(1.0 / 60.0)
	_expect(game.state.completed and not game.last_save_ok, "A failed completion write leaves the achieved in-session finish available for retry")
	_expect(not game.ever_completed and not isolated.is_completed(Stage.STAGE_ID), "Failed completion commit does not claim durable chapter history")
	_expect(isolated.stage_snapshot(Stage.STAGE_ID).is_empty(), "Failed completion commit does not apply only half of the profile transaction")
	_expect(game.hud.message.text.contains("could not be saved"), "Completion explicitly explains an unsuccessful profile write")
	isolated.save_path = profile_path + ".retry"
	game.save_game()
	_expect(game.last_save_ok and game.ever_completed and isolated.is_completed(Stage.STAGE_ID), "Retry commits chapter completion and updates earned history")
	var reader: Progress = Progress.new()
	reader.save_path = isolated.save_path
	var loaded: bool = reader.load_profile()
	var rules: State = State.new()
	_expect(loaded and reader.is_completed(Stage.STAGE_ID) and rules.restore(reader.stage_snapshot(Stage.STAGE_ID)) and rules.completed, "Fresh retry profile contains both the completion prefix and the completed stage snapshot")
	game.chapter_profile = original_profile
	game.ever_completed = original_profile.is_completed(Stage.STAGE_ID)


func _test_workshop_roundtrip() -> void:
	_setup(2)
	game.state.finish()
	game.save_game()
	var saved_bytes: String = FileAccess.get_file_as_string(profile_path)
	var old_stage: Node3D = game
	await game.on_command("workshop", null)
	var hub: Node3D = current_scene
	_expect(is_instance_valid(hub) and hub != old_stage, "Stage workshop command opens an actual new hub scene")
	if not is_instance_valid(hub) or hub == old_stage: return
	hub.set_process(false)
	await process_frame
	_expect(not is_instance_valid(old_stage), "Workshop navigation frees the previous stage after draining its audio")
	_expect(hub.chapter_profile_path == profile_path and hub.chapter_profile.save_path == profile_path and hub.settings_path == settings_path, "Workshop receives isolated chapter and settings paths before loading")
	_expect(hub.chapter_profile.is_completed(Stage.STAGE_ID) and hub.stage_button.text.begins_with("Replay"), "Workshop shows the earned Crumb Crossing clear as replayable")
	_expect(hub.future_buttons.size() == 4, "Workshop identifies all four unfinished chapter stages")
	for button: Button in hub.future_buttons:
		_expect(button.disabled, "An unfinished stage remains disabled even after its progress unlock")
	_expect(FileAccess.get_file_as_string(profile_path) == saved_bytes, "Visiting the workshop does not rewrite or downgrade chapter progress")
	await hub.on_command("crumb", null)
	game = current_scene
	_expect(is_instance_valid(game) and game != hub, "Workshop Crumb Crossing command opens the actual stage scene")
	if not is_instance_valid(game) or game == hub:
		game = hub
		return
	game.set_process(false)
	await process_frame
	_expect(not is_instance_valid(hub), "Returning to the stage frees the old workshop scene")
	_expect(game.chapter_profile_path == profile_path and game.chapter_profile.save_path == profile_path and game.settings_path == settings_path, "Stage return preserves isolated profile and settings paths")
	_expect(game.has_save and game.state.completed and game.ever_completed, "Stage return loads both the completed snapshot and earned chapter history")
	game.on_command("start", null)
	_expect(game.paused and game.hud.menu_mode == "complete", "Continuing the returned completed stage opens its completion menu")
	_assert_safe_respawn(game, "Workshop roundtrip")


func _test_demo_navigation_roundtrip() -> void:
	# Produce a genuine demo checkpoint with the production writer before any
	# demo scene enters the tree. Its nonzero checkpoint proves pre-ready path
	# transfer, rather than merely checking fields after load_save has run.
	var seed: Node3D = Demo.new()
	seed.save_path = demo_path
	seed.settings_path = settings_path
	seed.chapter_profile_path = profile_path
	seed.state.resize("spoon", 0)
	seed.state.interact("spoon")
	seed.state.pass_handle()
	seed.state.place("bridge")
	seed.state.resize("spoon", 2)
	seed.save_game()
	_expect(seed.save_count == 1 and FileAccess.file_exists(demo_path), "Demo navigation fixture creates its own genuine checkpoint-one save")
	seed.free()
	game.on_command("music", 0.19)
	game.on_command("reduced", true)
	game.on_command("title", null)
	var chapter_bytes: String = FileAccess.get_file_as_string(profile_path)
	var stage_button: Button = _single_button(game.hud, "Matchbox Workshop")
	var hub: Node3D = await _activate_navigation(stage_button, game, "Chapter title workshop button")
	game = hub
	if not is_instance_valid(hub) or hub.get_script() == Stage: return
	_assert_navigation_paths(hub, "Stage to workshop")
	_expect(hub.chapter_profile.is_completed(Stage.STAGE_ID), "Workshop reached through the actual title button retains the chapter clear")
	var demo_button: Button = _single_button(hub.hud, "Original Toast Express demo")
	var demo_game: Node3D = await _activate_navigation(demo_button, hub, "Workshop original-demo button")
	game = demo_game
	_expect(is_instance_valid(demo_game) and demo_game.get_script() == Demo, "Original-demo button opens the original VS01 scene")
	if not is_instance_valid(demo_game) or demo_game.get_script() != Demo: return
	_assert_navigation_paths(demo_game, "Workshop to original demo")
	_expect(demo_game.has_save and demo_game.state.checkpoint == 1 and demo_game.state.bridge_placed, "Original demo loads the isolated checkpoint during ready")
	_expect(demo_game.props.size() == 6 and not demo_game.props.has("sugar"), "Original demo restores its own puzzle rather than chapter rules")
	_expect(FileAccess.get_file_as_string(profile_path) == chapter_bytes, "Entering the original demo leaves chapter progress untouched")
	var chapter_button: Button = _single_button(demo_game.hud, "Visit the Matchbox Workshop")
	_assert_visible_button_layout(chapter_button, demo_game.hud, "Original-demo title chapter button")
	var start_button: Button = _single_button(demo_game.hud, "Continue breakfast")
	if start_button == null: return
	start_button.pressed.emit()
	_expect(demo_game.started and not demo_game.paused, "Actual demo Continue button starts its saved breakfast")
	demo_game.target = "blueberry"
	demo_game.pip.position = Vector3(-1.5, 0.06, 0.5)
	demo_game.resize_target(0)
	_expect(int(demo_game.state.sizes["blueberry"]) == 0, "The original demo can independently change and save its blueberry")
	demo_game.on_command("title", null)
	await process_frame
	await process_frame
	_expect(FileAccess.get_file_as_string(profile_path) == chapter_bytes, "Playing and saving the original demo does not modify chapter progress")
	var reader: Node3D = Demo.new()
	reader.save_path = demo_path
	reader.settings_path = settings_path
	reader.chapter_profile_path = profile_path
	reader.load_save()
	_expect(reader.has_save and reader.state.checkpoint == 1 and int(reader.state.sizes["blueberry"]) == 0, "A fresh demo reader reloads the changed blueberry from its distinct JSON file")
	reader.free()
	var demo_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(demo_path))
	var chapter_data: Variant = JSON.parse_string(chapter_bytes)
	_expect(demo_path != profile_path and demo_data is Dictionary and chapter_data is Dictionary and demo_data.get("format") != chapter_data.get("format"), "Demo and chapter progress remain separate validated save formats")
	chapter_button = _single_button(demo_game.hud, "Visit the Matchbox Workshop")
	var demo_bytes: String = FileAccess.get_file_as_string(demo_path)
	hub = await _activate_navigation(chapter_button, demo_game, "Original-demo title workshop button")
	game = hub
	if not is_instance_valid(hub) or hub.get_script() == Demo: return
	_assert_navigation_paths(hub, "Original demo to workshop")
	_expect(hub.chapter_profile.is_completed(Stage.STAGE_ID) and hub.stage_button.text.begins_with("Replay"), "Returning from the demo shows the existing chapter clear")
	_expect(FileAccess.get_file_as_string(profile_path) == chapter_bytes and FileAccess.get_file_as_string(demo_path) == demo_bytes, "Returning to the workshop preserves both independent progress files")
	game = await _activate_navigation(hub.stage_button, hub, "Workshop chapter-replay button")
	_expect(is_instance_valid(game) and game.get_script() == Stage, "Chapter replay button returns to Crumb Crossing")
	if not is_instance_valid(game) or game.get_script() != Stage: return
	_assert_navigation_paths(game, "Workshop back to chapter stage")
	_expect(game.has_save and game.state.completed and game.ever_completed and game.state.checkpoint == 2, "Full stage-workshop-demo-workshop-stage route restores the achieved chapter completion")
	_expect(FileAccess.get_file_as_string(demo_path) == demo_bytes, "Returning to chapter play preserves the demo's changed checkpoint")
	game.on_command("start", null)
	_expect(game.paused and game.hud.menu_mode == "complete", "Completed chapter Continue remains stable after the original-demo detour")
	_assert_safe_respawn(game, "Original-demo roundtrip")


func _single_button(hud: CanvasLayer, label: String) -> Button:
	var matches: Array[Button] = []
	for child: Node in hud.menu_box.get_children():
		if child is Button and child.text == label: matches.append(child)
	_expect(matches.size() == 1, "Menu exposes exactly one actionable '%s' button" % label)
	if matches.size() != 1: return null
	_expect(not matches[0].disabled and matches[0].is_visible_in_tree(), "'%s' button is visible and enabled" % label)
	return matches[0]


func _activate_navigation(button: Button, previous: Node3D, label: String) -> Node3D:
	if button == null: return previous
	var previous_id: int = previous.get_instance_id()
	button.pressed.emit()
	var deadline: int = Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if is_instance_valid(current_scene) and current_scene.get_instance_id() != previous_id:
			var next: Node3D = current_scene
			next.set_process(false)
			await process_frame
			await process_frame
			_expect(not is_instance_valid(previous), label + " frees its old scene after audio shutdown")
			return next
	_expect(false, label + " must finish its scene transition")
	return previous


func _assert_navigation_paths(scene: Node3D, label: String) -> void:
	_expect(scene.chapter_profile_path == profile_path and scene.settings_path == settings_path and scene.save_path == demo_path, label + " preserves all three isolated storage paths")
	_expect(is_equal_approx(scene.music_volume, 0.19) and scene.reduced_motion, label + " loads the isolated shared settings during ready")
	if scene.get_script() != Demo:
		_expect(scene.chapter_profile.save_path == profile_path, label + " loads its chapter backend from the isolated profile")


func _assert_visible_button_layout(button: Button, hud: CanvasLayer, label: String) -> void:
	if button == null: return
	var bounds: Rect2 = button.get_global_rect()
	_expect(bounds.size.x > 0 and bounds.size.y > 0, label + " has a nonempty usable hit area")
	_expect(hud.menu.get_global_rect().encloses(bounds), label + " fits inside the title panel")
	_expect(root.get_visible_rect().encloses(bounds), label + " fits inside the current viewport")
	for child: Node in hud.menu_box.get_children():
		if child is Button and child != button:
			_expect(not bounds.intersects(child.get_global_rect()), label + " does not overlap another title action")


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
	game.reduced_motion = true
	game.pip_art.transform = Transform3D.IDENTITY
	game.sync_props(false)
	game.respawn()


func _fixture(checkpoint: int) -> State:
	var rules: State = State.new()
	if checkpoint >= 1:
		rules.resize("sugar", 0)
		rules.pass_sugar()
	if checkpoint == 2:
		rules.resize("spoon", 0)
		rules.interact("spoon")
		rules.pass_handle()
		rules.place("bridge")
		rules.resize("spoon", 2)
	return rules


func _assert_canonical(checkpoint: int, label: String) -> void:
	_expect(game.state.checkpoint == checkpoint and game.state.carried == "", "%s restores checkpoint %d with no dangling carried prop" % [label, checkpoint])
	_expect(int(game.state.sizes["sugar"]) == (0 if checkpoint >= 1 else 1), "%s restores safe sugar size at checkpoint %d" % [label, checkpoint])
	_expect(int(game.state.sizes["spoon"]) == (2 if checkpoint == 2 else 1), "%s restores canonical spoon size at checkpoint %d" % [label, checkpoint])
	_expect(game.state.sockets["spoon"] == ("bridge" if checkpoint == 2 else "tray"), "%s restores canonical spoon socket at checkpoint %d" % [label, checkpoint])


func _assert_safe_respawn(scene: Node3D, label: String) -> void:
	var floor_y: float = scene.surface_height(scene.pip.position)
	_expect(floor_y >= 0, label + " places Pip on a valid authored surface")
	_expect(not scene.obstructed(scene.pip.position), label + " places Pip outside solid obstructions")
	_expect(is_equal_approx(scene.pip.position.y, floor_y), label + " settles Pip's feet immediately on the support")


func _assert_prop_sync(scene: Node3D, label: String) -> void:
	for kind: String in ["sugar", "spoon"]:
		var prop: Node3D = scene.props[kind]
		_expect(prop.position.is_equal_approx(scene.prop_position(kind)), label + " restores visible " + kind + " position")
		var expected_scale: float = SUGAR_SMALL_SCALE if kind == "sugar" and int(scene.state.sizes[kind]) == 0 else Stage.SCALE_VALUES[int(scene.state.sizes[kind])]
		_expect(prop.scale.is_equal_approx(Vector3.ONE * expected_scale), label + " restores visible " + kind + " size")


func _walk_toward_x(destination_x: float, steps: int) -> bool:
	_press_direction(Vector3.RIGHT if destination_x > game.pip.position.x else Vector3.LEFT)
	var eastbound: bool = destination_x > game.pip.position.x
	var reached: bool = false
	for step: int in range(steps):
		game.move_pip(1.0 / 60.0)
		if (eastbound and game.pip.position.x >= destination_x) or (not eastbound and game.pip.position.x <= destination_x):
			reached = true
			break
	_release_movement()
	return reached


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
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)


func _actor_enters_mesh(solid: MeshInstance3D) -> bool:
	var bounds: AABB = solid.mesh.get_aabb()
	for part: String in ["Body", "FootL", "FootR"]:
		var actor: MeshInstance3D = game.pip_art.get_node(part)
		var actor_to_solid: Transform3D = solid.global_transform.affine_inverse() * actor.global_transform
		for vertex: Vector3 in actor.mesh.get_faces():
			if bounds.has_point(actor_to_solid * vertex): return true
	return false


func _cleanup() -> void:
	for base: String in [profile_path, profile_path + ".retry", demo_path]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(base + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(base + suffix))
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
