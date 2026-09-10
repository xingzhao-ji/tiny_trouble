class_name CrumbState
extends RefCounted
## W01S01 Crumb Crossing rules. The scene owns range, physical passage,
## occupied-support checks, and reaching the exit; saves contain stable IDs.

const SAVE_VERSION: int = 1
const PROP_KINDS: Array[String] = ["sugar", "spoon"]
const PROP_SOCKETS: Dictionary = {"sugar": ["tray"], "spoon": ["tray", "carried", "bridge"]}
const STATE_KEYS: Array[String] = ["sizes", "sockets", "carried", "checkpoint", "sugar_passed", "handle_passed", "bridge_placed", "discovered", "completed"]

var sizes: Dictionary = {"sugar": 1, "spoon": 1}
var sockets: Dictionary = {"sugar": "tray", "spoon": "tray"}
var carried: String = ""
var checkpoint: int = 0
var sugar_passed: bool = false
var handle_passed: bool = false
var bridge_placed: bool = false
var discovered: bool = false
var completed: bool = false
var _checkpoint_state: Dictionary = {}


func _init() -> void:
	_checkpoint_state = _canonical_checkpoint(0, false)


func resize(kind: String, size: int) -> Dictionary:
	if not PROP_KINDS.has(kind):
		return _result(false, "Choose the sugar cube or teaspoon.")
	if size < 0 or size > 2:
		return _result(false, "Choose small, normal, or large.")
	if int(sizes[kind]) == size:
		return _result(true, "Already that size.")
	if completed:
		return _result(false, "Crossing complete! Replay to try another size.")
	if carried == kind and size != 0:
		return _result(false, "Set the teaspoon down before growing it.")
	sizes[kind] = size
	bridge_placed = sockets["spoon"] == "bridge" and int(sizes["spoon"]) == 2
	if bridge_placed and checkpoint < 2:
		_set_checkpoint(2)
	if kind == "spoon" and bridge_placed:
		return _result(true, "A mighty teaspoon bridge! Your crossing checkpoint is safe.")
	if kind == "sugar" and size == 0:
		return _result(true, "A little sugar leaves room for a little adventurer.")
	return _result(true, "Size changed.")


func interact(kind: String) -> Dictionary:
	if not PROP_KINDS.has(kind):
		return _result(false, "Move closer to an interesting prop.")
	if completed:
		return _result(false, "Crossing complete! Replay to explore again.")
	if kind == "sugar":
		return _result(false, "The sugar stays on its tray. Shrink it to open a passage.")
	if carried == "spoon":
		return place("tray")
	if int(sizes["spoon"]) != 0:
		return _result(false, "Shrink the teaspoon to small before picking it up.")
	carried = "spoon"
	sockets["spoon"] = "carried"
	bridge_placed = false
	return _result(true, "Picked up the tiny teaspoon. It will fit through the handle.")


func place(socket: String) -> Dictionary:
	if completed:
		return _result(false, "Crossing complete! Replay to place the teaspoon again.")
	if carried != "spoon":
		return _result(false, "Pick up the small teaspoon first.")
	if socket not in ["bridge", "tray"]:
		return _result(false, "Find the teaspoon rest or return it to the tray.")
	if socket == "bridge" and not handle_passed:
		return _result(false, "Carry the small teaspoon through the cup handle first.")
	sockets["spoon"] = socket
	carried = ""
	return _result(true, "Teaspoon returned to its safe tray." if socket == "tray" else "Teaspoon in place. Step back and make it mighty.")


func pass_sugar() -> Dictionary:
	if completed:
		return _result(false, "Crossing complete! Replay to take this route again.")
	if int(sizes["sugar"]) != 0:
		return _result(false, "Shrink the sugar cube to make room to pass.")
	sugar_passed = true
	if checkpoint == 0:
		_set_checkpoint(1)
	return _result(true, "Past the sugar! The first checkpoint is safe.")


func pass_handle() -> Dictionary:
	if completed:
		return _result(false, "Crossing complete! Replay to carry the teaspoon again.")
	if not sugar_passed:
		return _result(false, "Pass the small sugar cube before trying the cup handle.")
	if carried != "spoon" or int(sizes["spoon"]) != 0:
		return _result(false, "Carry the small teaspoon through the cup handle.")
	handle_passed = true
	return _result(true, "The tiny teaspoon fits through the handle!")


func discover() -> Dictionary:
	if discovered:
		return _result(true, "Your little crumb discovery is still here.")
	discovered = true
	return _result(true, "A tiny crumb picnic! A little surprise along the way.")


func finish() -> Dictionary:
	if checkpoint < 2:
		return _result(false, "Build the teaspoon crossing before heading onward.")
	if completed:
		return _result(true, "Crumb Crossing is already complete.")
	completed = true
	return _result(true, "Crumb Crossing complete! A bigger breakfast is waiting.")


func reset_checkpoint() -> void:
	var keep_discovery: bool = discovered
	_apply_state(_checkpoint_state)
	discovered = discovered or keep_discovery


func to_dict() -> Dictionary:
	var data: Dictionary = _state_dict()
	data["schema_version"] = SAVE_VERSION
	data["stage"] = "W01S01"
	data["checkpoint_state"] = _checkpoint_state.duplicate(true)
	return data


func restore(data: Dictionary) -> bool:
	if data.size() != STATE_KEYS.size() + 3 or not _is_integer(data.get("schema_version"), SAVE_VERSION, SAVE_VERSION):
		return false
	if typeof(data.get("stage")) != TYPE_STRING or data["stage"] != "W01S01" or typeof(data.get("checkpoint_state")) != TYPE_DICTIONARY:
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
	if _normalize_state(snapshot) != expected:
		return false
	_apply_state(data)
	_checkpoint_state = expected
	return true


func _set_checkpoint(value: int) -> void:
	checkpoint = value
	# Canonical arrangements deliberately do not retain incidental carried props
	# or reversible experiments. Local recovery always restores the safe route.
	_checkpoint_state = _canonical_checkpoint(value, discovered)


func _canonical_checkpoint(value: int, found: bool) -> Dictionary:
	return {"sizes": {"sugar": 0 if value >= 1 else 1, "spoon": 2 if value == 2 else 1},
		"sockets": {"sugar": "tray", "spoon": "bridge" if value == 2 else "tray"},
		"carried": "", "checkpoint": value, "sugar_passed": value >= 1,
		"handle_passed": value == 2, "bridge_placed": value == 2,
		"discovered": found, "completed": false}


func _state_dict() -> Dictionary:
	return {"sizes": sizes.duplicate(true), "sockets": sockets.duplicate(true),
		"carried": carried, "checkpoint": checkpoint, "sugar_passed": sugar_passed,
		"handle_passed": handle_passed, "bridge_placed": bridge_placed,
		"discovered": discovered, "completed": completed}


func _normalize_state(data: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for key: String in STATE_KEYS:
		normalized[key] = data[key]
	normalized = normalized.duplicate(true)
	for kind: String in PROP_KINDS:
		normalized["sizes"][kind] = int(normalized["sizes"][kind])
	normalized["checkpoint"] = int(normalized["checkpoint"])
	return normalized


func _apply_state(data: Dictionary) -> void:
	var clean: Dictionary = _normalize_state(data)
	sizes = clean["sizes"]
	sockets = clean["sockets"]
	carried = clean["carried"]
	checkpoint = clean["checkpoint"]
	sugar_passed = clean["sugar_passed"]
	handle_passed = clean["handle_passed"]
	bridge_placed = clean["bridge_placed"]
	discovered = clean["discovered"]
	completed = clean["completed"]


func _valid_state(data: Dictionary) -> bool:
	for key: String in STATE_KEYS:
		if not data.has(key):
			return false
	for key: String in ["sugar_passed", "handle_passed", "bridge_placed", "discovered", "completed"]:
		if typeof(data[key]) != TYPE_BOOL:
			return false
	if typeof(data["sizes"]) != TYPE_DICTIONARY or typeof(data["sockets"]) != TYPE_DICTIONARY:
		return false
	if data["sizes"].size() != 2 or data["sockets"].size() != 2:
		return false
	for kind: String in PROP_KINDS:
		if not _is_integer(data["sizes"].get(kind), 0, 2):
			return false
		if typeof(data["sockets"].get(kind)) != TYPE_STRING or not PROP_SOCKETS[kind].has(data["sockets"][kind]):
			return false
	if typeof(data["carried"]) != TYPE_STRING or data["carried"] not in ["", "spoon"]:
		return false
	if not _is_integer(data["checkpoint"], 0, 2):
		return false
	var saved_cp: int = int(data["checkpoint"])
	var held: bool = data["carried"] == "spoon"
	if held != (data["sockets"]["spoon"] == "carried") or (held and int(data["sizes"]["spoon"]) != 0):
		return false
	var bridge: bool = data["sockets"]["spoon"] == "bridge" and int(data["sizes"]["spoon"]) == 2
	if bool(data["bridge_placed"]) != bridge:
		return false
	if bool(data["sugar_passed"]) != (saved_cp >= 1):
		return false
	if bool(data["handle_passed"]) and not bool(data["sugar_passed"]):
		return false
	if data["sockets"]["spoon"] == "bridge" and not bool(data["handle_passed"]):
		return false
	if (bridge or bool(data["completed"])) and saved_cp != 2:
		return false
	if saved_cp == 2 and not bool(data["handle_passed"]):
		return false
	return true


func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= maximum


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
