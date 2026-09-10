extends SceneTree
## Tests scene persistence without adding the scene to the tree or running UI.
## All files use a process-specific test prefix; real player saves are untouched.

const Main = preload("res://scripts/main.gd")
const State = preload("res://scripts/puzzle_state.gd")
var checks: int = 0
var failures: int = 0
var test_path: String


func _initialize() -> void:
	test_path = "user://persistence_test_%d.json" % OS.get_process_id()
	_cleanup()
	_test_write_and_backup_recovery()
	_cleanup()
	_test_completion_survives_exploration_and_new_run()
	_cleanup()
	_test_corrupt_and_future_data()
	_cleanup()
	_test_interrupted_launch()
	_cleanup()
	print("%s: %d scene persistence checks; profile progress, atomic saves, backup recovery, and compatibility." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_write_and_backup_recovery() -> void:
	var scene = Main.new()
	scene.save_path = test_path
	scene.load_save()
	_expect(not scene.has_save, "Missing primary and backup start fresh")
	scene.save_game()
	_expect(scene.has_save and scene.save_count == 1, "First save succeeds")
	_expect(FileAccess.file_exists(test_path), "Primary exists after save")
	_expect(not FileAccess.file_exists(test_path + ".tmp"), "Successful rename consumes temporary file")
	var first: String = FileAccess.get_file_as_string(test_path)
	scene.state.resize("cereal", 0)
	scene.state.interact("cereal")
	scene.save_game()
	_expect(scene.save_count == 2, "Second save succeeds")
	_expect(FileAccess.get_file_as_string(test_path + ".bak") == first, "Backup contains previous validated save")
	var loaded = Main.new()
	loaded.save_path = test_path
	loaded.load_save()
	_expect(loaded.has_save and loaded.state.discovered, "Primary restores latest discovery")
	_write(test_path, "{ broken primary")
	loaded = _replace_scene(loaded)
	loaded.load_save()
	_expect(loaded.has_save and not loaded.state.discovered, "Corrupt primary recovers previous valid backup")
	_expect(loaded.save_notice.contains("backup"), "Recovery is disclosed to player")
	loaded.save_game()
	_expect(loaded.save_count == 1, "Recovered session writes a healthy primary")
	_expect(FileAccess.get_file_as_string(test_path + ".bak") == first, "Corrupt primary never replaces known-good backup")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	loaded = _replace_scene(loaded)
	loaded.load_save()
	_expect(loaded.has_save, "A backup loads even when primary is absent")
	_expect(loaded.save_notice.contains("backup"), "Backup-only recovery is disclosed")
	loaded.save_game()
	_expect(FileAccess.file_exists(test_path), "Backup-only recovery recreates primary")
	_expect(FileAccess.get_file_as_string(test_path + ".bak") == first, "Recreating missing primary preserves backup")
	var valid_primary: String = FileAccess.get_file_as_string(test_path)
	loaded.state.sizes["blueberry"] = 99
	loaded.save_game()
	_expect(FileAccess.get_file_as_string(test_path) == valid_primary, "Invalid in-memory state cannot overwrite valid save")
	_expect(loaded.save_notice.contains("last good"), "Invalid state save failure explains retained checkpoint")
	scene.free()
	loaded.free()


func _test_completion_survives_exploration_and_new_run() -> void:
	var scene = Main.new()
	scene.save_path = test_path
	scene.state = _launch_ready()
	scene.state.release_launch()
	scene.state.completed = true
	# Backward compatibility: the original build saved a bare puzzle dictionary.
	_write(test_path, JSON.stringify(scene.state.to_dict()))
	scene.state = State.new()
	scene.load_save()
	_expect(scene.state.completed and scene.ever_completed, "Legacy completed save preserves earned stage clear")
	scene.save_game()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(test_path))
	_expect(envelope.get("format") == "tiny_trouble.profile", "Legacy save migrates to versioned profile envelope")
	_expect(bool(envelope.get("ever_completed", false)), "Profile stores earned completion")
	# These are exactly the puzzle changes used by explore/reset; the profile
	# should survive them without keeping the live puzzle locked as completed.
	scene.state.completed = false
	scene.state.reset_checkpoint()
	scene.save_game()
	var loaded = Main.new()
	loaded.save_path = test_path
	loaded.load_save()
	_expect(loaded.ever_completed and not loaded.state.completed, "Exploration reload preserves clear while allowing play")
	_expect(loaded.state.can_launch(), "Exploration reload keeps a replayable launcher")
	loaded.state = State.new()
	loaded.save_game()
	scene.load_save()
	_expect(scene.ever_completed and scene.state.checkpoint == 0, "Starting fresh preserves profile completion")
	_expect(not scene.state.completed, "New run is playable despite prior clear")
	# Even if an older valid primary lacks the profile, a valid backup must not
	# lose its earned completion when loading a previous generation.
	_write(test_path, JSON.stringify(State.new().to_dict()))
	loaded = _replace_scene(loaded)
	loaded.load_save()
	_expect(loaded.ever_completed, "Earned completion is retained across valid backup history")
	scene.free()
	loaded.free()


func _test_corrupt_and_future_data() -> void:
	var scene = Main.new()
	scene.save_path = test_path
	scene.save_game()
	var healthy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(test_path))
	var invalid: Dictionary = healthy.duplicate(true)
	invalid["version"] = 2
	_expect(scene._decode_save(invalid).is_empty(), "Future profile version is rejected")
	invalid = healthy.duplicate(true)
	invalid["ever_completed"] = "true"
	_expect(scene._decode_save(invalid).is_empty(), "Malformed completion metadata is rejected")
	invalid = healthy.duplicate(true)
	invalid["puzzle"]["checkpoint_state"]["sizes"]["spoon"] = 3
	_expect(scene._decode_save(invalid).is_empty(), "Corrupt nested recovery state is rejected")
	invalid = healthy.duplicate(true)
	invalid["puzzle"] = []
	_expect(scene._decode_save(invalid).is_empty(), "Wrong puzzle payload type is rejected")
	invalid = healthy.duplicate(true)
	invalid["unexpected"] = true
	_expect(scene._decode_save(invalid).is_empty(), "Unexpected envelope structure is rejected")
	var completed: PuzzleState = _launch_ready()
	completed.release_launch()
	completed.completed = true
	invalid = healthy.duplicate(true)
	invalid["puzzle"] = completed.to_dict()
	_expect(scene._decode_save(invalid).is_empty(), "Completed puzzle cannot deny its earned profile clear")
	_write(test_path, "[]")
	_write(test_path + ".bak", "{ invalid backup")
	var before: Dictionary = scene.state.to_dict()
	scene.load_save()
	_expect(scene.state.to_dict() == before, "Two corrupt files leave the working puzzle untouched")
	_expect(scene.save_notice.contains("could not be read"), "Corrupt save fallback is disclosed")
	var fresh = Main.new()
	fresh.save_path = test_path
	fresh.load_save()
	_expect(not fresh.has_save and fresh.state.checkpoint == 0, "Two corrupt saves safely start a fresh puzzle")
	fresh.save_path = "user://missing_test_directory_%d/no_save.json" % OS.get_process_id()
	fresh.save_game()
	_expect(not fresh.has_save and fresh.save_count == 0, "Write failure never reports successful save")
	_expect(fresh.save_notice.contains("Could not write"), "Write failure remains visible and recoverable")
	scene.free()
	fresh.free()


func _test_interrupted_launch() -> void:
	var scene = Main.new()
	scene.save_path = test_path
	scene.state = _launch_ready()
	scene.save_game()
	scene.state.release_launch()
	scene.save_game()
	var loaded = Main.new()
	loaded.save_path = test_path
	loaded.load_save()
	_expect(loaded.has_save and loaded.state.can_launch(), "Mid-flight scene save reloads at prepared checkpoint")
	_expect(not loaded.state.completed and not loaded.ever_completed, "Interrupted flight does not award false completion")
	scene.free()
	loaded.free()


func _launch_ready() -> PuzzleState:
	var state: PuzzleState = State.new()
	state.resize("spoon", 0)
	state.interact("spoon")
	state.pass_handle()
	state.place("bridge")
	state.resize("spoon", 2)
	state.resize("blueberry", 0)
	state.interact("blueberry")
	state.place("ballast")
	state.resize("blueberry", 2)
	state.resize("butter", 0)
	state.interact("butter")
	state.place("wedge")
	state.resize("butter", 1)
	state.resize("napkin", 0)
	state.interact("napkin")
	state.place("landing")
	state.resize("napkin", 2)
	state.resize("blueberry", 0)
	state.interact("blueberry")
	state.place("lever")
	state.resize("blueberry", 2)
	return state


func _replace_scene(previous: Node3D) -> Node3D:
	previous.free()
	var replacement = Main.new()
	replacement.save_path = test_path
	return replacement


func _write(path: String, contents: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()


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
