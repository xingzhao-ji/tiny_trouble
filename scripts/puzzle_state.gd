class_name PuzzleState
extends RefCounted
## Authored, deterministic rules for the VS01 Toast Express puzzle.
## World-space range, player collision, and launch animation belong to the scene.

const SAVE_VERSION: int = 1
const PROP_KINDS: Array[String] = ["spoon", "blueberry", "cereal", "napkin", "butter", "toaster"]
const CARRYABLES: Array[String] = ["spoon", "blueberry", "napkin", "butter"]
const PROP_SOCKETS: Dictionary = {
	"spoon": ["tray", "carried", "bridge"],
	"blueberry": ["tray", "carried", "ballast", "lever"],
	"cereal": ["tray"],
	"napkin": ["tray", "carried", "landing"],
	"butter": ["tray", "carried", "wedge"],
	"toaster": ["tray"],
}
const STATE_KEYS: Array[String] = [
	"sizes", "sockets", "carried", "checkpoint", "discovered", "completed",
	"handle_passed", "bridge_placed", "ramp_latched", "napkin_ready", "toast_lowered",
]

var sizes: Dictionary = {"spoon": 1, "blueberry": 1, "cereal": 1, "napkin": 1, "butter": 1, "toaster": 1}
var sockets: Dictionary = {"spoon": "tray", "blueberry": "tray", "cereal": "tray", "napkin": "tray", "butter": "tray", "toaster": "tray"}
var carried: String = ""
var checkpoint: int = 0
var discovered: bool = false
var completed: bool = false
var handle_passed: bool = false
var bridge_placed: bool = false
var ramp_latched: bool = false
var napkin_ready: bool = false
var toast_lowered: bool = false
var _checkpoint_state: Dictionary = {}


func _init() -> void:
	_checkpoint_state = _state_dict()


func resize(kind: String, size: int) -> Dictionary:
	if not sizes.has(kind):
		return _result(false, "That prop cannot be resized.")
	if size < 0 or size > 2:
		return _result(false, "Choose small, normal, or large.")
	if int(sizes[kind]) == size:
		return _result(true, "Already that size.")
	if completed:
		return _result(false, "Trip complete! Replay from the launch checkpoint to experiment again.")
	if carried == kind and size != 0:
		return _result(false, "Set it down before making it bigger.")
	if kind == "spoon" and bridge_placed and not ramp_latched and size < 2:
		return _result(false, "Keep the bridge in place until the return route is latched.")
	if kind == "butter" and ramp_latched and size == 0:
		return _result(false, "The butter wedge is holding the safe return route.")
	if kind == "blueberry" and sockets[kind] == "ballast" and not ramp_latched and sockets["butter"] == "wedge" and size < 2:
		return _result(false, "Grow the butter wedge first to hold the ramp safely.")
	sizes[kind] = size
	_refresh()
	if kind == "spoon" and bridge_placed:
		return _result(true, "A spoon bridge! The first checkpoint is safe.")
	if kind == "butter" and ramp_latched:
		return _result(true, "The ramp is latched. The blueberry is free to travel.")
	if kind == "blueberry" and sockets[kind] == "ballast" and ramp_raised():
		return _result(true, "The heavy blueberry raises the cereal ramp. Add the butter wedge.")
	if kind == "napkin" and napkin_ready:
		return _result(true, "A soft landing is ready.")
	if kind == "blueberry" and toast_lowered:
		return _result(true, "The toast is lowered. Prepare the landing, then hop aboard.")
	return _result(true, "Size changed.")


func interact(kind: String) -> Dictionary:
	if not sizes.has(kind):
		return _result(false, "Move closer to an interesting prop.")
	if completed:
		return _result(false, "Trip complete! Replay from the launch checkpoint to explore again.")
	if kind == "cereal":
		if int(sizes[kind]) != 0:
			return _result(false, "A tiny panel is hiding in the cereal box. Try shrinking it.")
		if discovered:
			return _result(true, "The tiny breakfast picnic is still here.")
		discovered = true
		return _result(true, "You found the tiny breakfast picnic!")
	if kind == "toaster":
		if can_launch():
			return _result(true, "Hop aboard the toast, then shrink the blueberry to launch.")
		return _result(false, "Latch the ramp, spread the napkin, and weigh down the toaster lever.")
	if carried == kind:
		return place("tray")
	if not carried.is_empty():
		return _result(false, "Set down the prop you are carrying first.")
	if int(sizes[kind]) != 0:
		return _result(false, "Shrink it to small before picking it up.")
	if kind == "butter" and ramp_latched:
		return _result(false, "The butter wedge is holding the safe return route.")
	carried = kind
	sockets[kind] = "carried"
	_refresh()
	return _result(true, "Picked up the %s. Find its marked resting place." % kind)


func pass_handle() -> Dictionary:
	if completed:
		return _result(false, "Trip complete! Replay to carry the spoon again.")
	if carried != "spoon" or int(sizes["spoon"]) != 0:
		return _result(false, "Carry the small spoon through the cup handle.")
	handle_passed = true
	return _result(true, "The small spoon fits through the cup handle!")


func place(socket: String) -> Dictionary:
	if completed:
		return _result(false, "Trip complete! Replay to place props again.")
	if carried.is_empty():
		return _result(false, "Pick up a small prop first.")
	var kind: String = carried
	if not PROP_SOCKETS[kind].has(socket) or socket == "carried":
		return _result(false, "This resting place is for a different prop.")
	if socket == "bridge" and not handle_passed:
		return _result(false, "Carry the small spoon through the cup handle first.")
	if socket in ["ballast", "wedge"] and not (bridge_placed or ramp_latched):
		return _result(false, "Build the spoon bridge to reach the cereal ramp.")
	if socket == "wedge" and not ramp_raised():
		return _result(false, "A large blueberry must raise the ramp before adding the wedge.")
	if socket in ["landing", "lever"] and not ramp_latched:
		return _result(false, "Latch the cereal ramp with the butter wedge first.")
	sockets[kind] = socket
	carried = ""
	_refresh()
	if socket == "tray":
		return _result(true, "Returned to its safe tray.")
	return _result(true, "Placed the %s. Try growing it here." % kind)


func ramp_raised() -> bool:
	return ramp_latched or (sockets["blueberry"] == "ballast" and int(sizes["blueberry"]) == 2)


func can_launch() -> bool:
	return ramp_latched and napkin_ready and toast_lowered and carried.is_empty() and not completed


func release_launch() -> Dictionary:
	if not can_launch():
		return _result(false, "The ramp, landing napkin, and toaster lever must all be ready.")
	# Release is atomic, so animation interruption cannot leave a half-sized weight.
	# The scene marks completed only after Pip lands successfully.
	sizes["blueberry"] = 0
	toast_lowered = false
	return _result(true, "Toast Express, away!")


func reset_checkpoint() -> void:
	var keep_discovery: bool = discovered
	_apply_state(_checkpoint_state)
	discovered = discovered or keep_discovery


func to_dict() -> Dictionary:
	var data: Dictionary = _state_dict()
	data["schema_version"] = SAVE_VERSION
	data["stage"] = "VS01"
	data["checkpoint_state"] = _checkpoint_state.duplicate(true)
	return data


func restore(data: Dictionary) -> bool:
	# Validate every value before mutating this instance. A rejected save leaves
	# the current working game untouched, including its recovery snapshot.
	if data.size() != STATE_KEYS.size() + 3:
		return false
	if not _is_integer(data.get("schema_version"), SAVE_VERSION, SAVE_VERSION):
		return false
	if data.get("stage") != "VS01" or typeof(data.get("checkpoint_state")) != TYPE_DICTIONARY:
		return false
	if not _valid_state(data):
		return false
	var saved_checkpoint: Dictionary = data["checkpoint_state"]
	if saved_checkpoint.size() != STATE_KEYS.size() or not _valid_state(saved_checkpoint):
		return false
	if int(saved_checkpoint["checkpoint"]) != int(data["checkpoint"]):
		return false
	if not String(saved_checkpoint["carried"]).is_empty() or bool(saved_checkpoint["completed"]):
		return false
	if int(saved_checkpoint["checkpoint"]) == 3 and not (bool(saved_checkpoint["napkin_ready"]) and bool(saved_checkpoint["toast_lowered"])):
		return false
	if int(saved_checkpoint["checkpoint"]) == 0 and bool(saved_checkpoint["handle_passed"]):
		return false
	_apply_state(data)
	_checkpoint_state = _normalize_state(saved_checkpoint)
	# A mid-flight save resumes safely aboard the prepared launcher.
	if checkpoint == 3 and not completed and not toast_lowered:
		reset_checkpoint()
	return true


func _refresh() -> void:
	bridge_placed = sockets["spoon"] == "bridge" and int(sizes["spoon"]) == 2
	napkin_ready = sockets["napkin"] == "landing" and int(sizes["napkin"]) == 2
	toast_lowered = sockets["blueberry"] == "lever" and int(sizes["blueberry"]) == 2
	if sockets["butter"] == "wedge" and int(sizes["butter"]) >= 1 and ramp_raised():
		ramp_latched = true
	if checkpoint == 0 and bridge_placed:
		_set_checkpoint(1)
	if checkpoint == 1 and ramp_latched:
		_set_checkpoint(2)
	if checkpoint == 2 and can_launch():
		_set_checkpoint(3)


func _set_checkpoint(value: int) -> void:
	checkpoint = value
	_checkpoint_state = _state_dict()
	# A player may resize a placed prop while carrying a different one. Recovery
	# always puts that carried prop on its accessible tray before respawning Pip.
	if not carried.is_empty():
		_checkpoint_state["sockets"][carried] = "tray"
		_checkpoint_state["carried"] = ""


func _state_dict() -> Dictionary:
	return {
		"sizes": sizes.duplicate(true), "sockets": sockets.duplicate(true),
		"carried": carried, "checkpoint": checkpoint, "discovered": discovered,
		"completed": completed, "handle_passed": handle_passed,
		"bridge_placed": bridge_placed, "ramp_latched": ramp_latched,
		"napkin_ready": napkin_ready, "toast_lowered": toast_lowered,
	}


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
	var normalized: Dictionary = _normalize_state(data)
	sizes = normalized["sizes"]
	sockets = normalized["sockets"]
	carried = normalized["carried"]
	checkpoint = normalized["checkpoint"]
	discovered = normalized["discovered"]
	completed = normalized["completed"]
	handle_passed = normalized["handle_passed"]
	bridge_placed = normalized["bridge_placed"]
	ramp_latched = normalized["ramp_latched"]
	napkin_ready = normalized["napkin_ready"]
	toast_lowered = normalized["toast_lowered"]


func _valid_state(data: Dictionary) -> bool:
	for key: String in STATE_KEYS:
		if not data.has(key):
			return false
	for key: String in ["discovered", "completed", "handle_passed", "bridge_placed", "ramp_latched", "napkin_ready", "toast_lowered"]:
		if typeof(data[key]) != TYPE_BOOL:
			return false
	if typeof(data["sizes"]) != TYPE_DICTIONARY or typeof(data["sockets"]) != TYPE_DICTIONARY:
		return false
	if data["sizes"].size() != PROP_KINDS.size() or data["sockets"].size() != PROP_KINDS.size():
		return false
	if typeof(data["carried"]) != TYPE_STRING or not _is_integer(data["checkpoint"], 0, 3):
		return false
	var saved_sizes: Dictionary = data["sizes"]
	var saved_sockets: Dictionary = data["sockets"]
	var saved_carried: String = data["carried"]
	var saved_cp: int = int(data["checkpoint"])
	var carry_count: int = 0
	for kind: String in PROP_KINDS:
		if not _is_integer(saved_sizes.get(kind), 0, 2):
			return false
		if typeof(saved_sockets.get(kind)) != TYPE_STRING or not PROP_SOCKETS[kind].has(saved_sockets[kind]):
			return false
		if saved_sockets[kind] == "carried":
			carry_count += 1
			if saved_carried != kind or int(saved_sizes[kind]) != 0:
				return false
	if (saved_carried.is_empty() and carry_count != 0) or (not saved_carried.is_empty() and (carry_count != 1 or not CARRYABLES.has(saved_carried))):
		return false
	if bool(data["bridge_placed"]) != (saved_sockets["spoon"] == "bridge" and int(saved_sizes["spoon"]) == 2):
		return false
	if bool(data["napkin_ready"]) != (saved_sockets["napkin"] == "landing" and int(saved_sizes["napkin"]) == 2):
		return false
	if bool(data["toast_lowered"]) != (saved_sockets["blueberry"] == "lever" and int(saved_sizes["blueberry"]) == 2):
		return false
	if saved_sockets["spoon"] == "bridge" and not bool(data["handle_passed"]):
		return false
	if saved_cp >= 1 and not bool(data["handle_passed"]):
		return false
	if saved_cp == 0 and (bool(data["bridge_placed"]) or bool(data["ramp_latched"])):
		return false
	if saved_cp == 1 and (not bool(data["bridge_placed"]) or bool(data["ramp_latched"])):
		return false
	if (saved_cp >= 2) != bool(data["ramp_latched"]):
		return false
	if bool(data["ramp_latched"]) and (saved_sockets["butter"] != "wedge" or int(saved_sizes["butter"]) < 1):
		return false
	if not bool(data["ramp_latched"]):
		if saved_sockets["napkin"] == "landing" or saved_sockets["blueberry"] == "lever":
			return false
		if saved_sockets["butter"] == "wedge" and (int(saved_sizes["butter"]) != 0 or saved_sockets["blueberry"] != "ballast" or int(saved_sizes["blueberry"]) != 2):
			return false
	if saved_cp == 0 and (saved_sockets["blueberry"] == "ballast" or saved_sockets["butter"] == "wedge"):
		return false
	if bool(data["completed"]) and (saved_cp != 3 or not bool(data["napkin_ready"]) or bool(data["toast_lowered"])):
		return false
	return true


func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= maximum


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
