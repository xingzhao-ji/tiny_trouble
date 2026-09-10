class_name HarborState
extends RefCounted
## W01S03 Milk Harbor rules. The scene owns boat motion, boarding range,
## visible shallows, occupied geometry, and reaching the exit flag.

const SAVE_VERSION: int = 1
const PROP_KINDS: Array[String] = ["cereal", "cargo"]
const PHASES: Array[String] = ["near", "to_shoal", "shoal", "to_far", "far"]
const STATE_KEYS: Array[String] = ["sizes", "carried", "phase", "aboard", "dock_open", "checkpoint", "discovered", "completed"]

var sizes: Dictionary = {"cereal": 1, "cargo": 1}
var carried: String = ""
var phase: String = "near"
var aboard: bool = false
var dock_open: bool = false
var checkpoint: int = 0
var discovered: bool = false
var completed: bool = false
var recovered_motion: bool = false
var _checkpoint_state: Dictionary = {}


func _init() -> void:
	_checkpoint_state = _canonical_checkpoint(0, false)


func cargo_clear() -> bool:
	return int(sizes["cargo"]) == 0


func resize(kind: String, size: int) -> Dictionary:
	if not PROP_KINDS.has(kind): return _result(false, "Choose the cereal raft or its parcel.")
	if size < 0 or size > 2: return _result(false, "Choose small, normal, or large.")
	if _in_transit(): return _result(false, "Let the raft reach its next stop before changing a size.")
	if int(sizes[kind]) == size: return _result(true, "Already that size.")
	if completed: return _result(false, "Harbor reached! Explore or replay to try another size.")
	if kind == "cereal":
		if aboard: return _result(false, "Step onto the near dock before changing the raft.")
		if phase != "near": return _result(false, "The raft can change size safely at the near dock.")
	sizes[kind] = size
	if kind == "cereal" and size == 2 and checkpoint < 1:
		_set_checkpoint(1)
	if kind == "cereal" and size == 2: return _result(true, "A roomy cereal raft. Ready for a little harbor trip!")
	if kind == "cargo" and size == 0: return _result(true, "A smaller parcel helps the raft skim over the shallows.")
	return _result(true, "A little change, ready for a little adventure.")


func board() -> Dictionary:
	if phase not in ["near", "far"]: return _result(false, "Stay with the raft until it reaches a dock.")
	if int(sizes["cereal"]) != 2: return _result(false, "Make the cereal raft large enough for Pip first.")
	if aboard: return _result(true, "Pip is already aboard.")
	if completed: return _result(false, "Explore the harbor to hop aboard again.")
	aboard = true
	return _result(true, "All aboard the little cereal raft!")


func disembark() -> Dictionary:
	if phase not in ["near", "far"]: return _result(false, "The milk is deep here. Stay aboard until a dock is in reach.")
	if not aboard: return _result(true, "Pip already has both feet on the dock.")
	if completed: return _result(false, "The harbor trip is already complete.")
	aboard = false
	return _result(true, "A safe little step onto the harbor dock.")


func depart() -> Dictionary:
	if completed: return _result(false, "The harbor trip is complete. Explore or replay for another visit.")
	if _in_transit(): return _result(false, "The raft is already on its way.")
	if phase == "far": return _result(false, "The far harbor is here. Step onto the dock when you are ready.")
	if not aboard or int(sizes["cereal"]) != 2: return _result(false, "Climb aboard the large cereal raft before setting off.")
	if phase == "shoal" and not cargo_clear(): return _result(false, "The parcel weighs the raft into the shallows. Make it small to float onward.")
	phase = "to_shoal" if phase == "near" else "to_far"
	return _result(true, "A gentle drift toward the shallows." if phase == "to_shoal" else "Light enough to skim through. The far harbor is waiting!")


func arrive() -> Dictionary:
	if completed: return _result(false, "The harbor trip is already complete.")
	if phase == "to_shoal":
		phase = "shoal"
		_set_checkpoint(2)
		return _result(true, "A safe stop at the shallows. Pip and the raft are together.")
	if phase == "to_far":
		phase = "far"
		dock_open = true
		_set_checkpoint(3)
		return _result(true, "The harbor dock is open! Step ashore and find the little flag.")
	return _result(false, "The raft is already resting at its stop.")


func discover() -> Dictionary:
	if discovered: return _result(true, "Your little harbor discovery is still here.")
	if completed: return _result(false, "Explore the harbor to inspect the little surprise.")
	discovered = true
	return _result(true, "A tiny harbor surprise, tucked beside the milky water!")


func finish() -> Dictionary:
	if phase != "far" or not dock_open or aboard:
		return _result(false, "Reach the far harbor and step onto its open dock first.")
	if completed: return _result(true, "Milk Harbor is already complete.")
	completed = true
	return _result(true, "Milk Harbor complete! A little raft brought Pip a long way.")


func reset_checkpoint() -> void:
	var keep_discovery: bool = discovered
	_apply_state(_checkpoint_state)
	discovered = discovered or keep_discovery
	recovered_motion = false


func to_dict() -> Dictionary:
	var data: Dictionary = _state_dict()
	data["schema_version"] = SAVE_VERSION
	data["stage"] = "W01S03"
	data["checkpoint_state"] = _checkpoint_state.duplicate(true)
	return data


func restore(data: Dictionary) -> bool:
	if data.size() != STATE_KEYS.size() + 3 or not _is_integer(data.get("schema_version"), SAVE_VERSION, SAVE_VERSION): return false
	if typeof(data.get("stage")) != TYPE_STRING or data["stage"] != "W01S03" or typeof(data.get("checkpoint_state")) != TYPE_DICTIONARY: return false
	if not _valid_state(data): return false
	var snapshot: Dictionary = data["checkpoint_state"]
	if snapshot.size() != STATE_KEYS.size() or not _valid_state(snapshot): return false
	if int(snapshot["checkpoint"]) != int(data["checkpoint"]): return false
	if bool(snapshot["discovered"]) and not bool(data["discovered"]): return false
	var expected: Dictionary = _canonical_checkpoint(int(data["checkpoint"]), bool(snapshot["discovered"]))
	if _normalize_state(snapshot) != expected: return false
	var interrupted: bool = data["phase"] in ["to_shoal", "to_far"]
	var restored: Dictionary = expected.duplicate(true) if interrupted else _normalize_state(data)
	# Discoveries made after the checkpoint remain earned, including a voyage
	# interrupted before its next safe stop. Motion itself is never resumed.
	if interrupted: restored["discovered"] = bool(data["discovered"])
	_apply_state(restored)
	_checkpoint_state = expected
	recovered_motion = interrupted
	return true


func _set_checkpoint(value: int) -> void:
	checkpoint = value
	_checkpoint_state = _canonical_checkpoint(value, discovered)


func _canonical_checkpoint(value: int, found: bool) -> Dictionary:
	return {"sizes": {"cereal": 1 if value == 0 else 2, "cargo": 0 if value == 3 else 1},
		"carried": "", "phase": "near" if value < 2 else ("shoal" if value == 2 else "far"),
		"aboard": value == 2, "dock_open": value == 3, "checkpoint": value,
		"discovered": found, "completed": false}


func _state_dict() -> Dictionary:
	return {"sizes": sizes.duplicate(true), "carried": carried, "phase": phase,
		"aboard": aboard, "dock_open": dock_open, "checkpoint": checkpoint,
		"discovered": discovered, "completed": completed}


func _normalize_state(data: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	for key: String in STATE_KEYS: clean[key] = data[key]
	clean = clean.duplicate(true)
	for kind: String in PROP_KINDS: clean["sizes"][kind] = int(clean["sizes"][kind])
	clean["checkpoint"] = int(clean["checkpoint"])
	return clean


func _apply_state(data: Dictionary) -> void:
	var clean: Dictionary = _normalize_state(data)
	sizes = clean["sizes"]
	carried = clean["carried"]
	phase = clean["phase"]
	aboard = clean["aboard"]
	dock_open = clean["dock_open"]
	checkpoint = clean["checkpoint"]
	discovered = clean["discovered"]
	completed = clean["completed"]


func _valid_state(data: Dictionary) -> bool:
	for key: String in STATE_KEYS:
		if not data.has(key): return false
	if typeof(data["sizes"]) != TYPE_DICTIONARY or data["sizes"].size() != 2: return false
	for kind: String in PROP_KINDS:
		if not _is_integer(data["sizes"].get(kind), 0, 2): return false
	if typeof(data["carried"]) != TYPE_STRING or data["carried"] != "": return false
	if typeof(data["phase"]) != TYPE_STRING or not PHASES.has(data["phase"]): return false
	for key: String in ["aboard", "dock_open", "discovered", "completed"]:
		if typeof(data[key]) != TYPE_BOOL: return false
	if not _is_integer(data["checkpoint"], 0, 3): return false
	var saved_cp: int = int(data["checkpoint"])
	var raft_size: int = int(data["sizes"]["cereal"])
	if bool(data["aboard"]) and raft_size != 2: return false
	if bool(data["dock_open"]) != (data["phase"] == "far"): return false
	if bool(data["completed"]) and (data["phase"] != "far" or bool(data["aboard"])): return false
	match data["phase"]:
		"near":
			if saved_cp > 1 or (raft_size == 2 and saved_cp != 1): return false
		"to_shoal":
			if saved_cp != 1 or raft_size != 2 or not bool(data["aboard"]): return false
		"shoal":
			if saved_cp != 2 or raft_size != 2 or not bool(data["aboard"]): return false
		"to_far":
			if saved_cp != 2 or raft_size != 2 or not bool(data["aboard"]) or int(data["sizes"]["cargo"]) != 0: return false
		"far":
			if saved_cp != 3 or raft_size != 2: return false
	return true


func _in_transit() -> bool:
	return phase in ["to_shoal", "to_far"]


func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= maximum


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
