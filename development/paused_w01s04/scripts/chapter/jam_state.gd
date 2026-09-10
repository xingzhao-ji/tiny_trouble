# UNVERIFIED WIP: paused at the presentation gate; not parsed, tested or integrated.
class_name JamState
extends RefCounted
## W01S04 rules. The scene proves central arrival and placement range, owns
## occupied-support/growth guards, and calls finish only at the far flag.

const SAVE_VERSION: int = 1
const PROP_KINDS: Array[String] = ["biscuit_a", "biscuit_b", "knife", "parcel"]
const PROP_SOCKETS: Dictionary = {"biscuit_a": ["step"], "biscuit_b": ["ballast"], "knife": ["pivot"], "parcel": ["near", "central", "far", "carried"]}
const STATE_KEYS: Array[String] = ["sizes", "sockets", "carried", "checkpoint", "central_reached", "delivered", "discovered", "completed"]

var sizes: Dictionary = {"biscuit_a": 1, "biscuit_b": 1, "knife": 1, "parcel": 1}
var sockets: Dictionary = {"biscuit_a": "step", "biscuit_b": "ballast", "knife": "pivot", "parcel": "near"}
var carried: String = ""
var checkpoint: int = 0
var central_reached: bool = false
var delivered: bool = false
var discovered: bool = false
var completed: bool = false
var recovered_carry: bool = false
var _checkpoint_state: Dictionary = {}


func _init() -> void:
	_checkpoint_state = _canonical_checkpoint(0, false)


func ramp_ready() -> bool:
	return int(sizes["knife"]) == 2 and int(sizes["biscuit_b"]) == 2


func resize(kind: String, size: int) -> Dictionary:
	if not PROP_KINDS.has(kind): return _result(false, "Choose a biscuit, the butter knife, or the seed parcel.")
	if size < 0 or size > 2: return _result(false, "Choose small, normal, or large.")
	if int(sizes[kind]) == size: return _result(true, "Already that size.")
	if completed: return _result(false, "Delivery complete! Explore or replay to try another size.")
	if carried == kind and size != 0: return _result(false, "Set the seed parcel on a dry rest before growing it.")
	sizes[kind] = size
	_advance_checkpoint()
	if kind == "knife" or kind == "biscuit_b":
		return _result(true, "The butter knife meets the far landing!" if ramp_ready() else "A little change. Watch where the butter knife points.")
	return _result(true, "A roomy biscuit step!" if kind == "biscuit_a" and size == 2 else "Size changed.")


func interact(kind: String) -> Dictionary:
	if not PROP_KINDS.has(kind): return _result(false, "Move closer to the seed parcel or a dry parcel rest.")
	if completed: return _result(false, "Delivery complete! Explore or replay to carry the parcel again.")
	if kind != "parcel": return _result(false, "This prop stays on its rest. A size change can help the crossing.")
	if carried == "parcel": return _result(false, "Find a dry parcel rest to set the seed parcel down.")
	if int(sizes["parcel"]) != 0: return _result(false, "Make the seed parcel small before picking it up.")
	carried = "parcel"
	sockets["parcel"] = "carried"
	delivered = false
	return _result(true, "Seed parcel aboard! Find a dry path across the jam.")


func arrive_central() -> Dictionary:
	if completed: return _result(false, "The seed delivery is already complete.")
	if carried != "parcel" or int(sizes["parcel"]) != 0:
		return _result(false, "Bring the small seed parcel onto the dry central area.")
	central_reached = true
	_advance_checkpoint()
	return _result(true, "The seed parcel reached dry ground. Your checkpoint is safe!")


func place(socket: String) -> Dictionary:
	if completed: return _result(false, "Delivery complete! Explore or replay to place the parcel again.")
	if socket not in ["near", "central", "far"]: return _result(false, "Choose a dry seed-parcel rest.")
	if carried != "parcel" or int(sizes["parcel"]) != 0: return _result(false, "Pick up the small seed parcel first.")
	# Readiness is historical here: after crossing, Pip may safely change an
	# empty ramp. Delivery must not introduce an invisible current-size gate.
	if socket == "far" and (not central_reached or checkpoint < 2):
		return _result(false, "Bring the seed parcel through the central area and prepare the butter-knife crossing first.")
	carried = ""
	sockets["parcel"] = socket
	delivered = socket == "far"
	if socket == "central": central_reached = true
	_advance_checkpoint()
	if delivered: return _result(true, "Seed parcel delivered! The little flag is waiting nearby.")
	return _result(true, "The seed parcel rests safely on dry ground.")


func discover() -> Dictionary:
	if discovered: return _result(true, "Your little jam-print discovery is still here.")
	if completed: return _result(false, "Explore the detour to inspect the little surprise.")
	discovered = true
	return _result(true, "A tiny pattern hides in the jam prints. A sweet little discovery!")


func finish() -> Dictionary:
	if checkpoint != 3 or not delivered or sockets["parcel"] != "far" or carried != "" or int(sizes["parcel"]) != 0:
		return _result(false, "Leave the small seed parcel on the far receiving rest, then visit the flag.")
	if completed: return _result(true, "The Jam Detour is already complete.")
	completed = true
	return _result(true, "The Jam Detour complete! A small seed made a mighty journey.")


func reset_checkpoint() -> void:
	var keep_discovery: bool = discovered
	_apply_state(_checkpoint_state)
	discovered = discovered or keep_discovery
	recovered_carry = false


func to_dict() -> Dictionary:
	var data: Dictionary = _state_dict()
	data["schema_version"] = SAVE_VERSION
	data["stage"] = "W01S04"
	data["checkpoint_state"] = _checkpoint_state.duplicate(true)
	return data


func restore(data: Dictionary) -> bool:
	if data.size() != STATE_KEYS.size() + 3 or not _is_integer(data.get("schema_version"), SAVE_VERSION, SAVE_VERSION): return false
	if typeof(data.get("stage")) != TYPE_STRING or data["stage"] != "W01S04" or typeof(data.get("checkpoint_state")) != TYPE_DICTIONARY: return false
	if not _valid_state(data): return false
	var snapshot: Dictionary = data["checkpoint_state"]
	if snapshot.size() != STATE_KEYS.size() or not _valid_state(snapshot): return false
	if int(snapshot["checkpoint"]) != int(data["checkpoint"]): return false
	if bool(snapshot["discovered"]) and not bool(data["discovered"]): return false
	var expected: Dictionary = _canonical_checkpoint(int(data["checkpoint"]), bool(snapshot["discovered"]))
	if _normalize_state(snapshot) != expected: return false
	var interrupted: bool = data["carried"] == "parcel"
	var restored: Dictionary = expected.duplicate(true) if interrupted else _normalize_state(data)
	if interrupted: restored["discovered"] = bool(data["discovered"])
	_apply_state(restored)
	_checkpoint_state = expected
	recovered_carry = interrupted
	return true


func _advance_checkpoint() -> void:
	if central_reached and checkpoint < 1: _set_checkpoint(1)
	if central_reached and ramp_ready() and checkpoint < 2: _set_checkpoint(2)
	if delivered and checkpoint < 3: _set_checkpoint(3)


func _set_checkpoint(value: int) -> void:
	checkpoint = value
	_checkpoint_state = _canonical_checkpoint(value, discovered)


func _canonical_checkpoint(value: int, found: bool) -> Dictionary:
	return {"sizes": {"biscuit_a": 2 if value >= 1 else 1, "biscuit_b": 2 if value >= 2 else 1, "knife": 2 if value >= 2 else 1, "parcel": 0 if value >= 1 else 1},
		"sockets": {"biscuit_a": "step", "biscuit_b": "ballast", "knife": "pivot", "parcel": "far" if value == 3 else ("central" if value >= 1 else "near")},
		"carried": "", "checkpoint": value, "central_reached": value >= 1,
		"delivered": value == 3, "discovered": found, "completed": false}


func _state_dict() -> Dictionary:
	return {"sizes": sizes.duplicate(true), "sockets": sockets.duplicate(true), "carried": carried,
		"checkpoint": checkpoint, "central_reached": central_reached, "delivered": delivered,
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
	sockets = clean["sockets"]
	carried = clean["carried"]
	checkpoint = clean["checkpoint"]
	central_reached = clean["central_reached"]
	delivered = clean["delivered"]
	discovered = clean["discovered"]
	completed = clean["completed"]


func _valid_state(data: Dictionary) -> bool:
	for key: String in STATE_KEYS:
		if not data.has(key): return false
	if typeof(data["sizes"]) != TYPE_DICTIONARY or data["sizes"].size() != PROP_KINDS.size(): return false
	if typeof(data["sockets"]) != TYPE_DICTIONARY or data["sockets"].size() != PROP_KINDS.size(): return false
	for kind: String in PROP_KINDS:
		if not _is_integer(data["sizes"].get(kind), 0, 2): return false
		if typeof(data["sockets"].get(kind)) != TYPE_STRING or not PROP_SOCKETS[kind].has(data["sockets"][kind]): return false
	if typeof(data["carried"]) != TYPE_STRING or data["carried"] not in ["", "parcel"]: return false
	if not _is_integer(data["checkpoint"], 0, 3): return false
	for key: String in ["central_reached", "delivered", "discovered", "completed"]:
		if typeof(data[key]) != TYPE_BOOL: return false
	var saved_cp: int = int(data["checkpoint"])
	var parcel_socket: String = data["sockets"]["parcel"]
	var has_parcel: bool = data["carried"] == "parcel"
	if has_parcel != (parcel_socket == "carried"): return false
	if has_parcel and int(data["sizes"]["parcel"]) != 0: return false
	if bool(data["central_reached"]) != (saved_cp >= 1): return false
	if parcel_socket == "central" and saved_cp < 1: return false
	if bool(data["delivered"]) != (parcel_socket == "far"): return false
	if parcel_socket == "far" and saved_cp != 3: return false
	# A live prepared mechanism with earned arrival necessarily promotes cp2.
	# Larger historical checkpoints may retain any safe empty-support experiment.
	if saved_cp == 1 and int(data["sizes"]["knife"]) == 2 and int(data["sizes"]["biscuit_b"]) == 2: return false
	if bool(data["completed"]) and (saved_cp != 3 or not bool(data["delivered"]) or has_parcel or int(data["sizes"]["parcel"]) != 0): return false
	return true


func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= maximum


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
