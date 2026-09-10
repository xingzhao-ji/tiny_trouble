extends SceneTree
## Uses unique disposable paths; never reads or writes a player's chapter profile.

const Progress = preload("res://scripts/chapter/chapter_progress.gd")
var checks := 0
var failures := 0
var test_path: String


func _initialize() -> void:
	test_path = "user://chapter_test_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	_test_initial_and_sequential_progress()
	_cleanup()
	_test_snapshot_roundtrip_and_copy_isolation()
	_cleanup()
	_test_backup_recovery()
	_cleanup()
	_test_invalid_profiles()
	_cleanup()
	_test_snapshot_boundaries()
	_cleanup()
	_test_future_version_and_write_failure()
	_cleanup()
	_test_atomic_completed_snapshot()
	_cleanup()
	print("%s: %d chapter progress checks; sequential unlocks, durable snapshots, atomic writes, backup recovery, and bounded JSON." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _profile() -> RefCounted:
	var profile = Progress.new()
	profile.save_path = test_path
	return profile

func _test_atomic_completed_snapshot() -> void:
	var profile = _profile()
	var before: Dictionary = {"checkpoint": 1, "completed": false}
	_expect(profile.save_stage("W01S01", before), "Atomic completion starts with a persisted incomplete snapshot")
	var after: Dictionary = {"checkpoint": 2, "completed": true}
	_expect(profile.complete_stage_with_snapshot("W01S01", after), "Completion and final snapshot persist in one transaction")
	var loaded = _profile()
	_expect(loaded.load_profile() and loaded.is_completed("W01S01"), "Atomic completion reloads earned history")
	var restored: Dictionary = loaded.stage_snapshot("W01S01")
	_expect(restored.get("completed") == true and int(restored.get("checkpoint", -1)) == 2, "Atomic completion reloads the matching final scene")
	var saved_path: String = profile.save_path
	profile.save_path = saved_path + "/missing/profile.json"
	_expect(not profile.complete_stage_with_snapshot("W01S02", after), "Unwritable transaction refuses the next completion")
	_expect(not profile.is_completed("W01S02") and profile.stage_snapshot("W01S02").is_empty(), "Failed completion changes neither snapshot nor history")
	profile.save_path = saved_path
	_expect(not profile.complete_stage_with_snapshot("W01S02", {"bad": NAN}), "Invalid final snapshot cannot award a completion")
	_expect(not profile.is_completed("W01S02"), "Invalid transaction preserves the earned prefix")


func _test_initial_and_sequential_progress() -> void:
	var profile = _profile()
	_expect(not profile.load_profile(), "No profile starts fresh")
	_expect(profile.last_error.is_empty(), "A fresh profile is not corruption")
	_expect(profile.completed_ids().is_empty(), "Fresh profile has no earned completions")
	_expect(not profile.recovered_from_backup, "Fresh profile reports no recovery")
	for index in Progress.STAGE_IDS.size():
		var stage_id: String = Progress.STAGE_IDS[index]
		_expect(profile.is_unlocked(stage_id) == (index == 0), "Only first stage initially unlocked: " + stage_id)
		_expect(not profile.is_completed(stage_id), "Stage starts incomplete: " + stage_id)
		_expect(profile.stage_snapshot(stage_id).is_empty(), "Stage starts without snapshot: " + stage_id)
	for unknown: String in ["", "VS01", "W01S00", "W01S06", "W02S01", "../W01S01", "w01s01"]:
		_expect(not profile.is_unlocked(unknown), "Unknown ID remains locked: " + unknown)
		_expect(not profile.is_completed(unknown), "Unknown ID cannot report complete: " + unknown)
		_expect(not profile.complete_stage(unknown), "Unknown ID cannot complete: " + unknown)
		_expect(not profile.save_stage(unknown, {"x": 1}), "Unknown ID cannot save: " + unknown)
		_expect(not profile.reset_stage_snapshot(unknown), "Unknown ID cannot reset: " + unknown)
		_expect(profile.stage_snapshot(unknown).is_empty(), "Unknown ID snapshot stays empty: " + unknown)
	_expect(not FileAccess.file_exists(test_path), "Rejected IDs do not create a profile")
	_expect(not profile.complete_stage("W01S03"), "Cannot skip preceding chapter stages")
	_expect(not profile.save_stage("W01S02", {"x": 1}), "Cannot save a locked stage")
	_expect(profile.save_profile(), "Fresh valid profile can be persisted")
	for index in Progress.STAGE_IDS.size():
		var stage_id: String = Progress.STAGE_IDS[index]
		_expect(profile.is_unlocked(stage_id), "Previous clear unlocks next stage: " + stage_id)
		_expect(profile.complete_stage(stage_id), "Unlocked stage completion saves: " + stage_id)
		_expect(profile.complete_stage(stage_id), "Repeated completion is idempotent: " + stage_id)
		_expect(profile.completed_ids().size() == index + 1, "Completion list is unique: " + stage_id)
		var loaded = _profile()
		_expect(loaded.load_profile(), "Each completion reloads from disk: " + stage_id)
		_expect(loaded.is_completed(stage_id), "Earned completion survives reload: " + stage_id)
		_expect(loaded.completed_ids() == Progress.STAGE_IDS.slice(0, index + 1), "Completion IDs stay in stage order")
	var returned: Array[String] = profile.completed_ids()
	returned.clear()
	_expect(profile.completed_ids().size() == 5, "Returned completion list cannot mutate profile")
	_expect(not profile.is_unlocked("W01S06"), "Five clears never unlock content outside this chapter")
	_expect(not FileAccess.file_exists(test_path + ".tmp"), "Successful primary rename consumes temporary file")
	_expect(not FileAccess.file_exists(test_path + ".bak.tmp"), "Successful backup rename consumes backup temporary file")


func _test_snapshot_roundtrip_and_copy_isolation() -> void:
	var profile = _profile()
	var snapshot: Dictionary = {"checkpoint": 2, "position": [1.5, -3.25, 0, 1.2345678901234567], "carried": null,
		"switches": {"crumb": true, "gate": false}, "note": "Breakfast ☀", "bounds": [-Progress.MAX_EXACT_INTEGER, Progress.MAX_EXACT_INTEGER]}
	_expect(profile.save_stage("W01S01", snapshot), "Nested JSON-compatible stage state saves")
	snapshot["switches"]["crumb"] = false
	_expect(profile.stage_snapshot("W01S01")["switches"]["crumb"], "Save snapshots are deeply copied from callers")
	var returned: Dictionary = profile.stage_snapshot("W01S01")
	returned["position"][0] = 1000
	_expect(profile.stage_snapshot("W01S01")["position"][0] == 1.5, "Snapshot getter deeply copies nested arrays")
	var loaded = _profile()
	_expect(loaded.load_profile(), "Snapshot profile reloads")
	_expect(_same_json(loaded.stage_snapshot("W01S01"), profile.stage_snapshot("W01S01")), "All finite JSON values round-trip without precision loss")
	_expect(loaded.complete_stage("W01S01"), "Complete stage with existing snapshot")
	_expect(loaded.save_stage("W01S02", {"stage_specific_data": ["Root validates these rules", 7]}), "Next unlocked stage stores independent opaque snapshot")
	_expect(loaded.stage_snapshot("W01S01").has("checkpoint"), "Saving second stage retains first snapshot")
	_expect(loaded.reset_stage_snapshot("W01S01"), "Reset removes a stage snapshot durably")
	_expect(loaded.is_completed("W01S01") and loaded.is_unlocked("W01S02"), "Reset preserves earned completion and next unlock")
	profile = _profile()
	_expect(profile.load_profile(), "Reset result reloads")
	_expect(profile.stage_snapshot("W01S01").is_empty(), "Reset snapshot stays absent after reload")
	_expect(profile.stage_snapshot("W01S02").has("stage_specific_data"), "Reset leaves other stage snapshot intact")
	_expect(profile.is_completed("W01S01"), "Reset completion persists across reload")
	_expect(profile.reset_stage_snapshot("W01S01"), "Resetting absent known snapshot is safe")


func _test_backup_recovery() -> void:
	var profile = _profile()
	_expect(profile.save_stage("W01S01", {"checkpoint": 0}), "Initial snapshot saved")
	var first: String = _read(test_path)
	_expect(profile.save_stage("W01S01", {"checkpoint": 1}), "Second snapshot saved")
	_expect(_read(test_path + ".bak") == first, "Backup holds previous validated primary")
	_write(test_path, "{ truncated")
	var loaded = _profile()
	_expect(loaded.load_profile(), "Corrupt primary recovers valid backup")
	_expect(loaded.recovered_from_backup, "Backup recovery is available to UI")
	_expect(loaded.stage_snapshot("W01S01").get("checkpoint") == 0, "Recovery uses actual backup snapshot")
	_expect(loaded.save_profile(), "Recovered session repairs primary")
	_expect(_read(test_path + ".bak") == first, "Corrupt primary never replaces valid backup")
	_expect(not loaded.recovered_from_backup, "Successful repair clears recovery flag")
	_remove(test_path)
	loaded = _profile()
	_expect(loaded.load_profile() and loaded.recovered_from_backup, "Backup-only profile recovers with missing primary")
	_expect(loaded.save_profile(), "Backup-only recovery recreates primary")
	_expect(_read(test_path + ".bak") == first, "Backup-only save retains its valid recovery source")
	_expect(loaded.complete_stage("W01S01"), "Completion can be saved after recovery")
	var completed_primary: String = _read(test_path)
	_write(test_path + ".bak", completed_primary)
	_write(test_path, first)
	loaded = _profile()
	_expect(loaded.load_profile(), "Older valid primary loads with newer valid backup")
	_expect(loaded.is_completed("W01S01"), "Validated backup completion history cannot regress")
	_expect(not loaded.recovered_from_backup, "Valid primary remains snapshot source")
	_expect(loaded.save_profile(), "Merged valid history persists")
	_expect(_read(test_path + ".bak") == completed_primary, "Merging never replaces the only durable newer completion backup")
	_expect(_read(test_path).contains("W01S01"), "Merged clear reaches primary")
	_write(test_path + ".bak", "{ broken backup")
	loaded = _profile()
	_expect(loaded.load_profile() and loaded.is_completed("W01S01"), "Corrupt backup does not spoil valid primary")
	_write(test_path, "null")
	_expect(not loaded.load_profile(), "Both invalid generations report failure")
	_expect(loaded.is_completed("W01S01"), "Failed reload retains existing valid session completion")
	_expect(not loaded.last_error.is_empty(), "Corruption exposes a readable failure reason")
	var fresh = _profile()
	_expect(not fresh.load_profile() and fresh.completed_ids().is_empty(), "Both invalid generations never invent completions")
	_cleanup()
	_write(test_path + ".tmp", completed_primary)
	fresh = _profile()
	_expect(not fresh.load_profile(), "Uncommitted temporary file is never promoted on load")
	_expect(fresh.completed_ids().is_empty(), "Interrupted uncommitted write does not award completion")
	_expect(fresh.save_profile(), "Fresh save safely replaces stale temporary file")


func _test_invalid_profiles() -> void:
	var valid: Dictionary = {"format": Progress.FORMAT, "version": 1, "completed": [], "stage_snapshots": {}}
	var cases: Array = [null, [], "not a profile", {}, {"format": Progress.FORMAT}]
	for field: String in ["format", "version", "completed", "stage_snapshots"]:
		var missing: Dictionary = valid.duplicate(true)
		missing.erase(field)
		cases.append(missing)
	for bad_version: Variant in [null, true, "1", 0, -1, 1.5, 2]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid["version"] = bad_version
		cases.append(invalid)
	for bad_completed: Variant in [true, {}, "W01S01", ["W01S02"], ["W01S01", "W01S01"], ["W01S01", "W01S03"], ["W01S01", 2], ["VS01"], Progress.STAGE_IDS + ["W01S06"]]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid["completed"] = bad_completed
		cases.append(invalid)
	for bad_snapshots: Variant in [null, [], "state", {"VS01": {}}, {"W01S06": {}}, {"W01S02": {}}, {"W01S01": null}, {"W01S01": []}]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid["stage_snapshots"] = bad_snapshots
		cases.append(invalid)
	var extra: Dictionary = valid.duplicate(true)
	extra["unexpected"] = true
	cases.append(extra)
	var wrong_format: Dictionary = valid.duplicate(true)
	wrong_format["format"] = "tiny_trouble.profile"
	cases.append(wrong_format)
	for index in cases.size():
		_write(test_path, JSON.stringify(cases[index]))
		var profile = _profile()
		_expect(not profile.load_profile(), "Malformed envelope rejected: %d" % index)
		_expect(profile.completed_ids().is_empty(), "Malformed envelope awards no clear: %d" % index)
		_expect(not profile.is_unlocked("W01S02"), "Malformed envelope unlocks no later stage: %d" % index)
	_write(test_path, "x".repeat(Progress.MAX_PROFILE_BYTES + 1))
	var oversized = _profile()
	_expect(not oversized.load_profile(), "Oversized on-disk input is rejected before parsing")
	for malformed_number: String in ["1.8e308", "-1.8e308", "NaN", "Infinity"]:
		_write(test_path, '{"format":"%s","version":1,"completed":[],"stage_snapshots":{"W01S01":{"x":%s}}}' % [Progress.FORMAT, malformed_number])
		var invalid_number = _profile()
		_expect(not invalid_number.load_profile(), "Non-finite or non-JSON on-disk number is rejected: " + malformed_number)
		_expect(invalid_number.stage_snapshot("W01S01").is_empty(), "Invalid on-disk number never reaches a scene")
	var forged: Dictionary = valid.duplicate(true)
	forged["completed"] = Progress.STAGE_IDS.duplicate()
	forged["stage_snapshots"] = {"UNKNOWN": {}}
	_write(test_path + ".bak", JSON.stringify(forged))
	_write(test_path, JSON.stringify(valid))
	var profile = _profile()
	_expect(profile.load_profile(), "Valid primary is usable beside malformed backup")
	_expect(profile.completed_ids().is_empty(), "Malformed backup's claimed five clears contribute nothing")


func _test_snapshot_boundaries() -> void:
	var profile = _profile()
	_expect(profile.save_stage("W01S01", {"checkpoint": 3}), "Baseline profile for rejected mutations saves")
	var before: String = _read(test_path)
	var invalids: Array[Dictionary] = [{"bad": NAN}, {"bad": INF}, {"bad": -INF}, {"bad": Vector3.ZERO}, {"bad": Color.WHITE}, {1: "non-string key"}, {"bad": PackedByteArray([1, 2])}, {"bad": Progress.MAX_EXACT_INTEGER + 1}, {"bad": -Progress.MAX_EXACT_INTEGER - 1}, {"bad": "x".repeat(Progress.MAX_SNAPSHOT_BYTES)}, {"bad": "☀".repeat(22000)}]
	var deep: Dictionary = {"leaf": 1}
	for index in Progress.MAX_JSON_DEPTH + 1:
		deep = {"nested": deep}
	invalids.append(deep)
	var many: Array = []
	many.resize(Progress.MAX_JSON_NODES + 1)
	invalids.append({"many": many})
	var node := Node.new()
	invalids.append({"object": node})
	for index in invalids.size():
		_expect(not profile.save_stage("W01S01", invalids[index]), "Unsafe or unbounded snapshot rejected: %d" % index)
		_expect(profile.stage_snapshot("W01S01").get("checkpoint") == 3, "Rejected snapshot leaves memory unchanged: %d" % index)
		_expect(_read(test_path) == before, "Rejected snapshot leaves disk unchanged: %d" % index)
		_expect(not profile.last_error.is_empty(), "Rejected snapshot returns failure feedback: %d" % index)
	node.free()
	invalids.clear()
	var recursive: Dictionary = {}
	recursive["self"] = recursive
	_expect(not profile.save_stage("W01S01", recursive), "Recursive dictionary is rejected before deep copying or serialization")
	recursive.clear()
	_expect(_read(test_path) == before, "Recursive data cannot alter saved checkpoint")
	# The per-snapshot limit includes JSON punctuation and uses UTF-8 bytes.
	var exact: Dictionary = {"x": "a".repeat(Progress.MAX_SNAPSHOT_BYTES - 8)}
	_expect(JSON.stringify(exact).to_utf8_buffer().size() == Progress.MAX_SNAPSHOT_BYTES, "Boundary fixture is exactly 64 KiB")
	_expect(profile.save_stage("W01S01", exact), "Snapshot exactly at byte limit is accepted")
	var loaded = _profile()
	_expect(loaded.load_profile() and loaded.stage_snapshot("W01S01") == exact, "Maximum snapshot round-trips")
	exact["x"] += "a"
	_expect(not profile.save_stage("W01S01", exact), "Snapshot one byte above limit is rejected")
	_expect(profile.complete_stage("W01S01"), "Large first-stage snapshot can coexist with completion")
	_expect(not profile.save_stage("W01S02", {"x": "b".repeat(Progress.MAX_SNAPSHOT_BYTES - 8)}), "Combined snapshots exceeding profile cap are rejected")
	_expect(profile.stage_snapshot("W01S02").is_empty(), "Profile cap failure never mutates second snapshot")
	_expect(profile.is_completed("W01S01"), "Profile cap failure retains earned completion")


func _test_future_version_and_write_failure() -> void:
	var future: Dictionary = {"format": Progress.FORMAT, "version": 2, "completed": ["W01S01"], "stage_snapshots": {}}
	var future_text: String = JSON.stringify(future)
	_write(test_path, future_text)
	var profile = _profile()
	_expect(not profile.load_profile(), "Future-version primary is not interpreted")
	_expect(not profile.save_profile(), "Old code cannot overwrite future profile")
	_expect(not profile.complete_stage("W01S01"), "Future profile blocks completion writes")
	_expect(not profile.save_stage("W01S01", {"x": 1}), "Future profile blocks snapshot writes")
	_expect(not profile.reset_stage_snapshot("W01S01"), "Future profile blocks reset writes")
	_expect(_read(test_path) == future_text, "Future primary bytes remain intact")
	_expect(profile.completed_ids().is_empty(), "Rejected future data never grants completion")
	_expect(profile.last_error.contains("newer"), "Future-version rejection explains compatibility")
	_write(test_path + ".bak", JSON.stringify({"format": Progress.FORMAT, "version": 1, "completed": [], "stage_snapshots": {}}))
	_expect(profile.load_profile() and profile.recovered_from_backup, "Readable previous-version backup can be used in memory")
	_expect(not profile.save_profile() and _read(test_path) == future_text, "Backup recovery never downgrades future primary")
	_write(test_path, _read(test_path + ".bak"))
	_write(test_path + ".bak", future_text)
	_expect(profile.load_profile() and not profile.recovered_from_backup, "Current primary remains readable beside future backup")
	_expect(not profile.save_profile() and _read(test_path + ".bak") == future_text, "Future backup also survives attempted writes")
	_cleanup()
	var large_future: Dictionary = future.duplicate(true)
	large_future["future_payload"] = "x".repeat(Progress.MAX_PROFILE_BYTES)
	var large_future_text: String = JSON.stringify(large_future)
	_write(test_path, large_future_text)
	profile = _profile()
	_expect(not profile.load_profile(), "Oversized future profile is not parsed")
	_expect(not profile.save_profile(), "Oversized future primary cannot be overwritten")
	_expect(_read(test_path) == large_future_text, "Oversized future primary bytes remain intact")
	_write(test_path + ".bak", large_future_text)
	_write(test_path, JSON.stringify({"format": Progress.FORMAT, "version": 1, "completed": [], "stage_snapshots": {}}))
	_expect(profile.load_profile(), "Valid primary remains usable beside oversized future backup")
	_expect(not profile.save_profile(), "Oversized future backup cannot be rotated away")
	_expect(_read(test_path + ".bak") == large_future_text, "Oversized future backup bytes remain intact")
	_cleanup()
	_expect(profile.save_stage("W01S01", {"checkpoint": 4}), "Profile saves once future data is absent")
	var before: String = _read(test_path)
	# Parent directory is deliberately absent; writes fail without touching real data.
	profile.save_path = test_path + "_missing_directory/profile.json"
	_expect(not profile.save_profile(), "Unwritable path reports save failure")
	_expect(not profile.complete_stage("W01S01"), "Failed completion write returns false")
	_expect(not profile.is_completed("W01S01"), "Failed write does not grant in-memory completion")
	_expect(not profile.save_stage("W01S01", {"checkpoint": 99}), "Failed stage write returns false")
	_expect(profile.stage_snapshot("W01S01").get("checkpoint") == 4, "Failed stage write retains previous snapshot")
	_expect(not profile.reset_stage_snapshot("W01S01"), "Failed reset write returns false")
	_expect(profile.stage_snapshot("W01S01").get("checkpoint") == 4, "Failed reset preserves snapshot")
	_expect(_read(test_path) == before, "Write failures preserve previous on-disk profile")
	_expect(not profile.last_error.is_empty(), "Failed durable writes expose feedback")


func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "Test fixture can be written: " + path)
		return
	file.store_string(value)
	file.close()


func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		_remove(test_path + suffix)


func _same_json(left: Variant, right: Variant) -> bool:
	# JSON has one numeric type; Godot parses both saved ints and floats as floats.
	if (typeof(left) == TYPE_INT or typeof(left) == TYPE_FLOAT) and (typeof(right) == TYPE_INT or typeof(right) == TYPE_FLOAT):
		return left == right
	if typeof(left) != typeof(right): return false
	if left is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _same_json(left[key], right[key]): return false
		return true
	if left is Array:
		if left.size() != right.size(): return false
		for index in left.size():
			if not _same_json(left[index], right[index]): return false
		return true
	return left == right


func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
