class_name BallastState
extends RefCounted
## W01S02 Blueberry Ballast rules. The scene owns rolling range, visual flap
## motion, occupied-support guards, and reaching the exit. Only flap loads count.

const SAVE_VERSION: int = 1
const TARGET_WEIGHT: int = 5
const MASSES: Array[int] = [1, 2, 4]
const PROP_KINDS: Array[String] = ["berry_a", "berry_b"]
const STATE_KEYS: Array[String] = ["sizes", "sockets", "carried", "checkpoint", "discovered", "completed"]

var sizes: Dictionary = {"berry_a": 1, "berry_b": 1}
var sockets: Dictionary = {"berry_a": "tray", "berry_b": "tray"}
var carried: String = ""
var checkpoint: int = 0
var discovered: bool = false
var completed: bool = false
var _checkpoint_state: Dictionary = {}


func _init() -> void:
	_checkpoint_state = _canonical_checkpoint(0, false)


func total_weight() -> int:
	var weight: int = 0
	for kind: String in PROP_KINDS:
		if sockets[kind] == "flap": weight += MASSES[int(sizes[kind])]
	return weight


func is_balanced() -> bool:
	return _both_loaded(sockets) and total_weight() == TARGET_WEIGHT


func resize(kind: String, size: int) -> Dictionary:
	if not PROP_KINDS.has(kind):
		return _result(false, "Choose one of the two blueberries.")
	if size < 0 or size > 2:
		return _result(false, "Choose small, normal, or large.")
	if int(sizes[kind]) == size:
		return _result(true, "Already that size.")
	if completed:
		return _result(false, "Crossing complete! Explore or replay to change the berries.")
	sizes[kind] = size
	_advance_checkpoint()
	return _result(true, "Just enough. The path meets the landing!" if is_balanced() else "Berry size changed. Watch how the cardboard path moves.")


func interact(kind: String) -> Dictionary:
	if not PROP_KINDS.has(kind):
		return _result(false, "Move closer to one of the blueberries.")
	if completed:
		return _result(false, "Crossing complete! Explore or replay to roll the berries again.")
	if sockets[kind] == "flap":
		sockets[kind] = "tray"
		return _result(true, "Berry rolled back to its safe tray. Your checkpoint is still here.")
	if int(sizes[kind]) != 2:
		return _result(false, "Make the blueberry large before rolling it into the flap pocket.")
	sockets[kind] = "flap"
	_advance_checkpoint()
	if is_balanced():
		return _result(true, "Just enough. Both berries have balanced the flap!")
	return _result(true, "Both berries are in place. A little less weight will balance the flap." if _both_loaded(sockets) else "One berry in its pocket. Roll the other one into place.")


func discover() -> Dictionary:
	if discovered:
		return _result(true, "Your little breakfast discovery is still here.")
	if completed:
		return _result(false, "Explore the crossing to inspect the little surprise.")
	discovered = true
	return _result(true, "The berry flap pulls down, the cereal stack rises, and the thread lifts your path. A tiny breakfast machine!")


func finish() -> Dictionary:
	if checkpoint != 2 or not is_balanced():
		return _result(false, "Balance both berries against the counterweight before crossing onward.")
	if completed:
		return _result(true, "Blueberry Ballast is already complete.")
	completed = true
	return _result(true, "Blueberry Ballast complete! A little balance goes a long way.")


func reset_checkpoint() -> void:
	var keep_discovery: bool = discovered
	_apply_state(_checkpoint_state)
	discovered = discovered or keep_discovery


func to_dict() -> Dictionary:
	var data: Dictionary = _state_dict()
	data["schema_version"] = SAVE_VERSION
	data["stage"] = "W01S02"
	data["checkpoint_state"] = _checkpoint_state.duplicate(true)
	return data


func restore(data: Dictionary) -> bool:
	if data.size() != STATE_KEYS.size() + 3 or not _is_integer(data.get("schema_version"), SAVE_VERSION, SAVE_VERSION):
		return false
	if typeof(data.get("stage")) != TYPE_STRING or data["stage"] != "W01S02" or typeof(data.get("checkpoint_state")) != TYPE_DICTIONARY:
		return false
	if not _valid_state(data):
		return false
	var snapshot: Dictionary = data["checkpoint_state"]
	if snapshot.size() != STATE_KEYS.size() or not _valid_state(snapshot):
		return false
	if int(snapshot["checkpoint"]) != int(data["checkpoint"]):
		return false
	if bool(snapshot["discovered"]) and not bool(data["discovered"]):
		return false
	var expected: Dictionary = _canonical_checkpoint(int(data["checkpoint"]), bool(snapshot["discovered"]))
	# Live experiments may unload both pockets after earning a checkpoint, but
	# their recovery record must still describe the canonical achieved setup.
	if _normalize_state(snapshot) != expected:
		return false
	_apply_state(data)
	_checkpoint_state = expected
	return true


func _advance_checkpoint() -> void:
	if _both_loaded(sockets) and checkpoint < 1:
		_set_checkpoint(1)
	if is_balanced() and checkpoint < 2:
		_set_checkpoint(2)


func _set_checkpoint(value: int) -> void:
	checkpoint = value
	_checkpoint_state = _canonical_checkpoint(value, discovered)


func _canonical_checkpoint(value: int, found: bool) -> Dictionary:
	return {"sizes": {"berry_a": 1 if value == 0 else 2, "berry_b": 1 if value == 0 else (0 if value == 2 else 2)},
		"sockets": {"berry_a": "tray" if value == 0 else "flap", "berry_b": "tray" if value == 0 else "flap"},
		"carried": "", "checkpoint": value, "discovered": found, "completed": false}


func _state_dict() -> Dictionary:
	return {"sizes": sizes.duplicate(true), "sockets": sockets.duplicate(true), "carried": carried,
		"checkpoint": checkpoint, "discovered": discovered, "completed": completed}


func _normalize_state(data: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	for key: String in STATE_KEYS:
		clean[key] = data[key]
	clean = clean.duplicate(true)
	for kind: String in PROP_KINDS:
		clean["sizes"][kind] = int(clean["sizes"][kind])
	clean["checkpoint"] = int(clean["checkpoint"])
	return clean


func _apply_state(data: Dictionary) -> void:
	var clean: Dictionary = _normalize_state(data)
	sizes = clean["sizes"]
	sockets = clean["sockets"]
	carried = clean["carried"]
	checkpoint = clean["checkpoint"]
	discovered = clean["discovered"]
	completed = clean["completed"]


func _valid_state(data: Dictionary) -> bool:
	for key: String in STATE_KEYS:
		if not data.has(key): return false
	for key: String in ["discovered", "completed"]:
		if typeof(data[key]) != TYPE_BOOL: return false
	if typeof(data["sizes"]) != TYPE_DICTIONARY or typeof(data["sockets"]) != TYPE_DICTIONARY:
		return false
	if data["sizes"].size() != 2 or data["sockets"].size() != 2:
		return false
	for kind: String in PROP_KINDS:
		if not _is_integer(data["sizes"].get(kind), 0, 2): return false
		if typeof(data["sockets"].get(kind)) != TYPE_STRING or data["sockets"][kind] not in ["tray", "flap"]:
			return false
	if typeof(data["carried"]) != TYPE_STRING or data["carried"] != "": return false
	if not _is_integer(data["checkpoint"], 0, 2): return false
	var saved_cp: int = int(data["checkpoint"])
	var both: bool = _both_loaded(data["sockets"])
	var balanced: bool = both and MASSES[int(data["sizes"]["berry_a"])] + MASSES[int(data["sizes"]["berry_b"])] == TARGET_WEIGHT
	if both and saved_cp == 0: return false
	if balanced and saved_cp != 2: return false
	if bool(data["completed"]) and (saved_cp != 2 or not balanced): return false
	return true


func _both_loaded(placements: Dictionary) -> bool:
	return placements["berry_a"] == "flap" and placements["berry_b"] == "flap"


func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= maximum


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
