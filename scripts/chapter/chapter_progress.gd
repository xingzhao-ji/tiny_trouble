extends RefCounted
class_name ChapterProgress
## Breakfast Chapter profile only. Unlocks do not imply stage content exists.
## Stage authors validate the meaning of snapshots before restoring a scene.

const FORMAT := "tiny_trouble.breakfast_chapter"
const VERSION := 1
const STAGE_IDS = ["W01S01", "W01S02", "W01S03", "W01S04", "W01S05"]
const MAX_SNAPSHOT_BYTES := 65536
const MAX_PROFILE_BYTES := 131072
const MAX_JSON_DEPTH := 16
const MAX_JSON_NODES := 8192
const MAX_EXACT_INTEGER := 9007199254740991

var save_path := "user://breakfast_chapter_v1.json"
var last_error := ""
var recovered_from_backup := false
var _completed: Array[String] = []
var _stage_snapshots: Dictionary = {}


func load_profile() -> bool:
	last_error = ""
	recovered_from_backup = false
	var primary: Dictionary = _read_profile(save_path)
	var backup: Dictionary = _read_profile(save_path + ".bak")
	var selected: Dictionary = primary if not primary.is_empty() else backup
	if selected.is_empty():
		if FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak"):
			last_error = "The chapter profile could not be read; existing session progress was retained."
		return false
	# Valid completion history is monotonic even when an older primary survives.
	# Invalid files contribute nothing, including their claimed completion IDs.
	if not backup.is_empty() and backup["completed"].size() > selected["completed"].size():
		selected["completed"] = backup["completed"].duplicate()
	_apply_profile(selected)
	recovered_from_backup = primary.is_empty()
	return true


func save_profile() -> bool:
	return _commit(_profile_data())


func save_stage(stage_id: String, snapshot: Dictionary) -> bool:
	if not is_unlocked(stage_id):
		return _reject("Cannot save an unknown or locked chapter stage.")
	if not _valid_snapshot(snapshot):
		return _reject("The stage snapshot is not bounded, finite JSON data.")
	var candidate: Dictionary = _profile_data()
	candidate["stage_snapshots"][stage_id] = snapshot.duplicate(true)
	return _commit(candidate)


func stage_snapshot(stage_id: String) -> Dictionary:
	if not STAGE_IDS.has(stage_id): return {}
	return _stage_snapshots.get(stage_id, {}).duplicate(true)


func complete_stage(stage_id: String) -> bool:
	if not is_unlocked(stage_id):
		return _reject("Complete the previous chapter stage first.")
	var candidate: Dictionary = _profile_data()
	if not candidate["completed"].has(stage_id):
		candidate["completed"].append(stage_id)
	return _commit(candidate)


func complete_stage_with_snapshot(stage_id: String, snapshot: Dictionary) -> bool:
	if not is_unlocked(stage_id):
		return _reject("Complete the previous chapter stage first.")
	if not _valid_snapshot(snapshot):
		return _reject("The stage snapshot is not bounded, finite JSON data.")
	var candidate: Dictionary = _profile_data()
	candidate["stage_snapshots"][stage_id] = snapshot.duplicate(true)
	if not candidate["completed"].has(stage_id):
		candidate["completed"].append(stage_id)
	return _commit(candidate)


func completed_ids() -> Array[String]:
	return _completed.duplicate()


func is_completed(stage_id: String) -> bool:
	return STAGE_IDS.has(stage_id) and _completed.has(stage_id)


func is_unlocked(stage_id: String) -> bool:
	var index: int = STAGE_IDS.find(stage_id)
	return index == 0 or (index > 0 and _completed.has(STAGE_IDS[index - 1]))


func reset_stage_snapshot(stage_id: String) -> bool:
	if not STAGE_IDS.has(stage_id):
		return _reject("Unknown chapter stage.")
	var candidate: Dictionary = _profile_data()
	candidate["stage_snapshots"].erase(stage_id)
	return _commit(candidate)


func _profile_data() -> Dictionary:
	return {"format": FORMAT, "version": VERSION, "completed": _completed.duplicate(),
		"stage_snapshots": _stage_snapshots.duplicate(true)}


func _apply_profile(data: Dictionary) -> void:
	_completed.clear()
	for stage_id: String in data["completed"]:
		_completed.append(stage_id)
	_stage_snapshots = data["stage_snapshots"].duplicate(true)


func _commit(candidate: Dictionary) -> bool:
	last_error = ""
	if not _valid_profile(candidate):
		return _reject("The chapter profile is invalid or exceeds its size limit.")
	# An older build must not silently replace a newer chapter format.
	if _is_unsupported_profile(save_path) or _is_unsupported_profile(save_path + ".bak"):
		return _reject("This chapter profile is from a newer version or exceeds the supported size; it was preserved.")
	var temporary: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _reject("Could not write chapter progress; the previous profile is safe.")
	file.store_string(_encode(candidate))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK or _read_profile(temporary).is_empty():
		_remove_temporary(temporary)
		return _reject("The chapter write did not validate; the previous profile is safe.")
	var absolute: String = ProjectSettings.globalize_path(save_path)
	# A corrupt primary must never overwrite the valid backup used to recover it.
	# Nor may an older primary erase the only durable newer completion history
	# before the final atomic rename succeeds.
	var primary: Dictionary = _read_profile(save_path)
	var backup: Dictionary = _read_profile(save_path + ".bak")
	var keep_backup: bool = not backup.is_empty() and (primary.is_empty() or backup["completed"].size() > primary["completed"].size())
	if not primary.is_empty() and not keep_backup:
		var backup_error: Error = DirAccess.copy_absolute(absolute, absolute + ".bak.tmp")
		if backup_error == OK:
			if _read_profile(save_path + ".bak.tmp").is_empty():
				backup_error = ERR_FILE_CORRUPT
			else:
				backup_error = DirAccess.rename_absolute(absolute + ".bak.tmp", absolute + ".bak")
		if backup_error != OK:
			_remove_temporary(temporary)
			_remove_temporary(save_path + ".bak.tmp")
			return _reject("Could not preserve the chapter backup; the previous profile is safe.")
	if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
		_remove_temporary(temporary)
		return _reject("Could not replace chapter progress; the previous profile is safe.")
	_apply_profile(candidate)
	recovered_from_backup = false
	return true


func _read_profile(path: String) -> Dictionary:
	var parsed: Variant = _read_json(path)
	if not parsed is Dictionary or not _valid_profile(parsed): return {}
	return parsed


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null: return null
	if file.get_length() > MAX_PROFILE_BYTES:
		file.close()
		return null
	var text: String = file.get_as_text()
	file.close()
	var parser = JSON.new()
	if parser.parse(text) != OK: return null
	return parser.data


func _is_unsupported_profile(path: String) -> bool:
	# An oversized file may belong to a future format. Do not parse or replace it.
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null: return true
		var oversized: bool = file.get_length() > MAX_PROFILE_BYTES
		file.close()
		if oversized: return true
	var data: Variant = _read_json(path)
	if not data is Dictionary or data.get("format") != FORMAT: return false
	var version: Variant = data.get("version")
	return (typeof(version) == TYPE_INT or typeof(version) == TYPE_FLOAT) and is_finite(float(version)) and float(version) > VERSION


func _valid_profile(data: Dictionary) -> bool:
	if data.size() != 4 or data.get("format") != FORMAT: return false
	var version: Variant = data.get("version")
	if (typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT) or float(version) != VERSION: return false
	if typeof(data.get("completed")) != TYPE_ARRAY or typeof(data.get("stage_snapshots")) != TYPE_DICTIONARY: return false
	var completed: Array = data["completed"]
	if completed.size() > STAGE_IDS.size(): return false
	for index in completed.size():
		if typeof(completed[index]) != TYPE_STRING or completed[index] != STAGE_IDS[index]: return false
	for stage_id: Variant in data["stage_snapshots"]:
		if typeof(stage_id) != TYPE_STRING: return false
		var index: int = STAGE_IDS.find(stage_id)
		if index < 0 or index > completed.size(): return false
		var snapshot: Variant = data["stage_snapshots"][stage_id]
		if not snapshot is Dictionary or not _valid_snapshot(snapshot): return false
	if not _json_safe(data, 0, [0]): return false
	return _encode(data).to_utf8_buffer().size() <= MAX_PROFILE_BYTES


func _valid_snapshot(snapshot: Dictionary) -> bool:
	return _json_safe(snapshot, 0, [0]) and _encode(snapshot).to_utf8_buffer().size() <= MAX_SNAPSHOT_BYTES


func _encode(value: Dictionary) -> String:
	# Preserve finite float precision across checkpoint round-trips.
	return JSON.stringify(value, "", true, true)


func _json_safe(value: Variant, depth: int, visited: Array) -> bool:
	visited[0] += 1
	if depth > MAX_JSON_DEPTH or visited[0] > MAX_JSON_NODES: return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL:
			return true
		TYPE_INT:
			# Godot's JSON parser stores numbers as doubles; avoid silent integer loss.
			return value >= -MAX_EXACT_INTEGER and value <= MAX_EXACT_INTEGER
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_STRING:
			return value.length() <= MAX_PROFILE_BYTES
		TYPE_ARRAY:
			if value.size() > MAX_JSON_NODES: return false
			for item: Variant in value:
				if not _json_safe(item, depth + 1, visited): return false
			return true
		TYPE_DICTIONARY:
			if value.size() > MAX_JSON_NODES: return false
			for key: Variant in value:
				if typeof(key) != TYPE_STRING or key.length() > MAX_PROFILE_BYTES: return false
				if not _json_safe(value[key], depth + 1, visited): return false
			return true
	return false


func _remove_temporary(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _reject(message: String) -> bool:
	last_error = message
	return false
