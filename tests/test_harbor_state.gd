extends SceneTree
## Pure Milk Harbor rules and interrupted-voyage recovery; no user files.
const State = preload("res://scripts/chapter/harbor_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_complete_route()
	_test_cargo_and_boarding_gates()
	_test_canonical_recovery()
	_test_interrupted_motion()
	_test_invalid_saves()
	_test_aliases_and_completed_lock()
	_test_varied_action_order()
	print("%s: %d Milk Harbor checks; shallow-water gate, moored saves, interrupted-voyage recovery, canonical checkpoints, and atomic corruption rejection." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_complete_route() -> void:
	var state = State.new()
	_expect(state.sizes == {"cereal": 1, "cargo": 1} and state.phase == "near" and not state.aboard and state.carried == "", "Opening is a normal raft and parcel beside the near dock")
	_bad(state.board(), "Normal cereal raft cannot board")
	_bad(state.depart(), "Unboarded opening cannot depart")
	_bad(state.arrive(), "An idle raft cannot award an arrival")
	_bad(state.finish(), "Opening cannot finish")
	_ok(state.resize("cereal", 2), "Grow the cereal raft")
	_expect(state.checkpoint == 1 and not state.dock_open, "Large near-dock raft earns checkpoint one without opening the far dock")
	_ok(state.board(), "Board the large raft")
	_ok(state.board(), "Repeated near-dock boarding is harmless")
	_ok(state.disembark(), "Step back onto the near dock")
	_ok(state.board(), "Reboard for the voyage")
	_round_trip(state, "Near-dock aboard save")
	_ok(state.depart(), "Depart with the normal parcel")
	_expect(state.phase == "to_shoal" and state.checkpoint == 1 and state.aboard, "First voyage carries Pip toward the shoal without claiming arrival")
	var before: Dictionary = state.to_dict()
	_bad(state.depart(), "Cannot begin another voyage while drifting")
	_bad(state.disembark(), "Cannot step into the milk during transit")
	_bad(state.board(), "Transit is not another boarding dock")
	_bad(state.resize("cargo", 1), "Even no-op cargo resize is unavailable during transit")
	_bad(state.resize("cereal", 2), "Even no-op raft resize is unavailable during transit")
	_expect(state.to_dict() == before, "Transit rejections preserve the in-progress voyage")
	_ok(state.arrive(), "Reach the shoal")
	_expect(state.phase == "shoal" and state.aboard and state.checkpoint == 2 and not state.dock_open, "Shoal arrival keeps Pip aboard and captures checkpoint two")
	_bad(state.disembark(), "The shoal is not a safe dock for Pip")
	_bad(state.depart(), "Normal cargo grounds the raft on the shallow ridge")
	_ok(state.resize("cargo", 0), "Make the parcel small at the shoal")
	_expect(state.cargo_clear(), "Small cargo clears the visible shallow ridge")
	_round_trip(state, "Prepared shoal save remains aboard")
	_ok(state.depart(), "Depart over the shallow ridge")
	_expect(state.phase == "to_far" and state.checkpoint == 2 and not state.dock_open, "Farward departure does not prematurely open the dock")
	_ok(state.arrive(), "Reach the far harbor")
	_expect(state.phase == "far" and state.checkpoint == 3 and state.dock_open and state.aboard, "Far arrival latches the dock open and leaves Pip aboard")
	_round_trip(state, "Far-dock aboard save")
	_bad(state.finish(), "Pip must step ashore before finishing")
	_ok(state.resize("cargo", 2), "Moored cargo may grow again at the far dock")
	_expect(state.dock_open and not state.cargo_clear(), "Far dock remains open after a cargo experiment")
	_ok(state.disembark(), "Disembark at the far harbor")
	_ok(state.discover(), "Inspect an optional harbor detail")
	_ok(state.finish(), "Finish on the open far dock")
	_expect(state.completed and state.discovered and not state.aboard, "Completion records a safe landing and independent discovery")
	_round_trip(state, "Completed harbor save")


func _test_cargo_and_boarding_gates() -> void:
	for cargo_size: int in range(3):
		var state = _checkpoint(1)
		state.resize("cargo", cargo_size)
		state.board()
		_ok(state.depart(), "Any authored cargo size can leave the deep near harbor")
		_expect(int(state.sizes["cargo"]) == cargo_size and state.phase == "to_shoal", "First voyage preserves its chosen cargo size")
		state.arrive()
		var before: Dictionary = state.to_dict()
		if cargo_size == 0:
			_ok(state.depart(), "Small cargo already permits the second leg")
		else:
			_bad(state.depart(), "Normal or large cargo must be reduced at the shoal")
			_expect(state.to_dict() == before, "Grounding leaves phase and checkpoint unchanged")
		for kind: String in State.PROP_KINDS:
			if state.phase == "to_far":
				before = state.to_dict()
				_bad(state.resize(kind, 0), "Transit refuses changes to " + kind)
				_expect(state.to_dict() == before, "Transit resize rejection is atomic")
	var state = _checkpoint(1)
	state.board()
	var before: Dictionary = state.to_dict()
	_bad(state.resize("cereal", 0), "A raft cannot shrink under its rider")
	_expect(state.to_dict() == before, "Occupied raft rejection preserves its safe size")
	_ok(state.resize("cargo", 0), "Cargo may resize while moored and aboard")
	state.disembark()
	_ok(state.resize("cereal", 0), "Unboarded near-dock raft may shrink experimentally")
	_expect(state.checkpoint == 1, "Raft experiments retain earned checkpoint one")
	_bad(state.board(), "Small experimental raft cannot board")
	state.reset_checkpoint()
	_expect(int(state.sizes["cereal"]) == 2 and not state.aboard, "Near checkpoint rebuilds a boardable raft")
	state = _checkpoint(2)
	before = state.to_dict()
	_bad(state.board(), "Shoal is not a boarding dock")
	_bad(state.disembark(), "Shoal requires Pip to remain aboard")
	_bad(state.resize("cereal", 1), "Raft cannot resize away from the near dock")
	_expect(state.to_dict() == before, "All unsafe shoal actions preserve the resting raft")
	state = _checkpoint(3)
	state.disembark()
	before = state.to_dict()
	_bad(state.resize("cereal", 0), "Far-dock raft cannot resize even after disembarking")
	_bad(state.depart(), "The one-way voyage cannot depart backward from the far harbor")
	_expect(state.to_dict() == before, "Far-dock restrictions preserve the open dock")
	_ok(state.board(), "Far dock allows boarding the moored large raft")
	_bad(state.depart(), "Reboarding does not invent a return voyage")
	_ok(state.disembark(), "Far dock allows stepping back ashore")
	for kind: String in ["", "spoon", "parcel", "raft"]:
		before = state.to_dict()
		_bad(state.resize(kind, 0), "Unknown resize target is rejected")
		_expect(state.to_dict() == before, "Unknown target cannot alter progress")
	for size: int in [-1, 3]:
		before = state.to_dict()
		_bad(state.resize("cargo", size), "Out-of-range cargo size is rejected")
		_expect(state.to_dict() == before, "Rejected cargo size preserves progress")


func _test_canonical_recovery() -> void:
	for checkpoint: int in range(4):
		var state = _checkpoint(checkpoint)
		state.discover()
		if state.aboard and state.phase != "shoal": state.disembark()
		if checkpoint < 2: state.resize("cereal", 0)
		state.resize("cargo", 2)
		if checkpoint == 3: state.board()
		_expect(state.checkpoint == checkpoint, "Moored experiments retain historical checkpoint %d" % checkpoint)
		_round_trip(state, "Live checkpoint %d experiment" % checkpoint)
		state.reset_checkpoint()
		_assert_canonical(state, checkpoint)
		_expect(state.discovered and not state.completed and not state.recovered_motion, "Manual reset preserves discovery without claiming recovered transit")
		_round_trip(state, "Canonical checkpoint %d" % checkpoint)
		var before: Dictionary = state.to_dict()
		state.reset_checkpoint()
		_expect(state.to_dict() == before, "Repeated canonical reset is idempotent")


func _test_interrupted_motion() -> void:
	for destination: String in ["to_shoal", "to_far"]:
		var checkpoint: int = 1 if destination == "to_shoal" else 2
		var source = _checkpoint(checkpoint)
		if not source.aboard: source.board()
		source.resize("cargo", 0)
		source.depart()
		source.discover()
		_expect(source.phase == destination, "Interrupted fixture is genuinely in the requested voyage leg")
		var before: Dictionary = source.to_dict()
		var parsed: Variant = JSON.parse_string(JSON.stringify(before))
		var recovered = State.new()
		_expect(recovered.restore(parsed) and recovered.recovered_motion, "Valid interrupted voyage restores with an explanatory recovery flag")
		_assert_canonical(recovered, checkpoint)
		_expect(recovered.discovered and int(recovered.sizes["cargo"]) == 1, "Transit recovery retains discovery while restoring canonical cargo")
		_expect(source.to_dict() == before and parsed["phase"] == destination, "Recovery does not mutate the source voyage or caller save")
		_expect(not recovered.to_dict().has("recovered_motion"), "Recovery notice metadata is never serialized")
		var stable: Dictionary = recovered.to_dict()
		var invalid: Dictionary = stable.duplicate(true)
		invalid["stage"] = 3
		var result: Variant = recovered.restore(invalid)
		_expect(typeof(result) == TYPE_BOOL and result == false and recovered.to_dict() == stable and recovered.recovered_motion, "Rejected load preserves recovered state and its unsaved notice flag")
		_expect(recovered.restore(stable) and not recovered.recovered_motion, "Restoring an ordinary moored save clears the previous motion-recovery notice")
		recovered.restore(parsed)
		recovered.reset_checkpoint()
		_expect(not recovered.recovered_motion, "Explicit reset clears the transient recovery notice")
		source.reset_checkpoint()
		_assert_canonical(source, checkpoint)
		_expect(source.discovered and not source.recovered_motion, "Reset can also interrupt an active voyage without inventing restored motion")


func _test_invalid_saves() -> void:
	var target = _checkpoint(3)
	target.disembark()
	target.discover()
	var original: Dictionary = target.to_dict()
	var mutations: Array[Dictionary] = [{}]
	for key: String in original:
		var bad: Dictionary = original.duplicate(true)
		bad.erase(key)
		mutations.append(bad)
	for field: String in ["stage", "phase"]:
		for value: Variant in [7, 1.5, true, false, null, [], {}, "W01S02" if field == "stage" else "returning"]:
			var bad: Dictionary = original.duplicate(true)
			bad[field] = value
			mutations.append(bad)
	for field: String in ["schema_version", "checkpoint"]:
		for value: Variant in [-1, 4, 1.5, true, null, "1", INF, NAN]:
			var bad: Dictionary = original.duplicate(true)
			bad[field] = value
			mutations.append(bad)
	for field: String in ["aboard", "dock_open", "discovered", "completed"]:
		for value: Variant in [0, 1, "false", null]:
			var bad: Dictionary = original.duplicate(true)
			bad[field] = value
			mutations.append(bad)
	for kind: String in State.PROP_KINDS:
		for value: Variant in [-1, 3, 1.5, true, "0", null, INF, NAN, [], {}]:
			var bad: Dictionary = original.duplicate(true)
			bad["sizes"][kind] = value
			mutations.append(bad)
	for field: String in ["sizes", "checkpoint_state"]:
		for value: Variant in [[], null, 2, "{}"]:
			var bad: Dictionary = original.duplicate(true)
			bad[field] = value
			mutations.append(bad)
	for value: Variant in ["cargo", "cereal", null, 0, false]:
		var bad: Dictionary = original.duplicate(true)
		bad["carried"] = value
		mutations.append(bad)
	var bad: Dictionary = original.duplicate(true)
	bad["sizes"]["spoon"] = 0
	mutations.append(bad)
	bad = original.duplicate(true)
	bad["recovered_motion"] = true
	mutations.append(bad)
	bad = original.duplicate(true)
	bad["checkpoint_state"]["completed"] = true
	mutations.append(bad)
	bad = original.duplicate(true)
	bad["checkpoint_state"]["aboard"] = true
	mutations.append(bad)
	bad = original.duplicate(true)
	bad["checkpoint_state"]["sizes"]["cargo"] = 2
	mutations.append(bad)
	bad = original.duplicate(true)
	bad["checkpoint_state"]["checkpoint"] = 2
	mutations.append(bad)
	bad = original.duplicate(true)
	bad["checkpoint_state"]["discovered"] = true
	bad["discovered"] = false
	mutations.append(bad)
	# Coherent JSON can still describe impossible phase/rider/checkpoint pairs.
	for checkpoint: int in range(4):
		var fixture = _checkpoint(checkpoint)
		bad = fixture.to_dict()
		bad["checkpoint"] = (checkpoint + 1) % 4
		bad["checkpoint_state"]["checkpoint"] = bad["checkpoint"]
		mutations.append(bad)
		bad = fixture.to_dict()
		bad["dock_open"] = not bad["dock_open"]
		mutations.append(bad)
		bad = fixture.to_dict()
		bad["completed"] = true
		# _checkpoint(3) still has Pip aboard, so every fixture is unfinished.
		mutations.append(bad)
	bad = _checkpoint(2).to_dict()
	bad["aboard"] = false
	mutations.append(bad)
	bad = _checkpoint(2).to_dict()
	bad["sizes"]["cereal"] = 1
	mutations.append(bad)
	bad = _checkpoint(0).to_dict()
	bad["sizes"]["cereal"] = 2
	mutations.append(bad)
	for destination: String in ["to_shoal", "to_far"]:
		var transit = _checkpoint(1 if destination == "to_shoal" else 2)
		if not transit.aboard: transit.board()
		transit.resize("cargo", 0)
		transit.depart()
		bad = transit.to_dict()
		bad["aboard"] = false
		mutations.append(bad)
		bad = transit.to_dict()
		bad["sizes"]["cereal"] = 0
		mutations.append(bad)
		bad = transit.to_dict()
		bad["dock_open"] = true
		mutations.append(bad)
		if destination == "to_far":
			bad = transit.to_dict()
			bad["sizes"]["cargo"] = 1
			mutations.append(bad)
	for index: int in range(mutations.size()):
		var result: Variant = target.restore(mutations[index])
		_expect(typeof(result) == TYPE_BOOL and result == false, "Malformed or impossible harbor save %d returns a clean rejection" % index)
		_expect(target.to_dict() == original and not target.recovered_motion, "Rejected harbor save %d preserves live state and checkpoint atomically" % index)


func _test_aliases_and_completed_lock() -> void:
	var state = _checkpoint(3)
	state.disembark()
	var data: Dictionary = state.to_dict()
	var copy = State.new()
	_expect(copy.restore(data), "Valid moored source restores before alias test")
	var before: Dictionary = copy.to_dict()
	data["sizes"]["cargo"] = 2
	data["checkpoint_state"]["sizes"]["cereal"] = 0
	_expect(copy.to_dict() == before, "Restored live and recovery state do not alias caller dictionaries")
	copy.reset_checkpoint()
	_assert_canonical(copy, 3)
	data = copy.to_dict()
	data["sizes"]["cargo"] = 2
	data["checkpoint_state"]["dock_open"] = false
	copy.reset_checkpoint()
	_expect(copy.dock_open and copy.cargo_clear(), "Exported dictionaries cannot corrupt the latched recovery dock")
	copy.finish()
	before = copy.to_dict()
	_bad(copy.resize("cargo", 2), "Completed harbor rejects a changed cargo size")
	_bad(copy.resize("cereal", 0), "Completed harbor rejects a changed raft size")
	_bad(copy.board(), "Completed harbor cannot begin another boarding action")
	_bad(copy.depart(), "Completed harbor cannot depart")
	_bad(copy.arrive(), "Completed harbor cannot invent another arrival")
	_bad(copy.discover(), "A new inspection waits until completed play is reopened")
	_expect(copy.to_dict() == before, "Rejected completed mutations preserve the exact save")
	_ok(copy.finish(), "Completed finish is idempotent")
	_ok(copy.disembark(), "Already-disembarked completion remains stable")
	_ok(copy.resize("cargo", 0), "Existing cargo size remains an idempotent action")
	_expect(copy.to_dict() == before, "Completed no-op actions leave the save unchanged")
	copy.reset_checkpoint()
	copy.discover()
	copy.finish()
	before = copy.to_dict()
	_ok(copy.discover(), "Repeating an earned discovery is idempotent")
	_expect(copy.to_dict() == before, "Repeated completed inspection cannot alter history")


func _test_varied_action_order() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 23092026
	for initial: int in range(5):
		var state = _checkpoint(mini(initial, 3))
		if initial == 4:
			state.disembark()
			state.finish()
		for step: int in range(100):
			var before: Dictionary = state.to_dict()
			var result: Dictionary = {"ok": true}
			match random.randi_range(0, 8):
				0: result = state.resize(State.PROP_KINDS[random.randi_range(0, 1)], random.randi_range(-1, 3))
				1: result = state.board()
				2: result = state.disembark()
				3: result = state.depart()
				4: result = state.arrive()
				5: result = state.discover()
				6: result = state.finish()
				7: state.reset_checkpoint()
				8: result = state.resize("unknown", 0)
			if not result["ok"]:
				_expect(state.to_dict() == before, "Rejected generated harbor action %d:%d is atomic" % [initial, step])
			_expect(state.checkpoint >= int(before["checkpoint"]) and state.carried == "", "Generated action preserves earned checkpoint and never carries props")
			var copy = State.new()
			_expect(copy.restore(JSON.parse_string(JSON.stringify(state.to_dict()))), "Generated harbor action remains JSON-saveable")
			if state.phase in ["to_shoal", "to_far"]:
				_expect(copy.recovered_motion and copy.phase in ["near", "shoal"] and copy.checkpoint == state.checkpoint, "Generated interrupted voyage recovers to its earned safe stop")
			else:
				_expect(not copy.recovered_motion and copy.to_dict() == state.to_dict(), "Generated moored experiment round-trips exactly")
			copy.reset_checkpoint()
			var recovered = State.new()
			_expect(recovered.restore(copy.to_dict()) and not recovered.recovered_motion and not recovered.completed, "Generated action retains a valid playable canonical recovery")


func _checkpoint(value: int) -> State:
	var state = State.new()
	if value >= 1: state.resize("cereal", 2)
	if value >= 2:
		state.board()
		state.depart()
		state.arrive()
	if value >= 3:
		state.resize("cargo", 0)
		state.depart()
		state.arrive()
	return state


func _assert_canonical(state: State, value: int) -> void:
	_expect(state.checkpoint == value and state.carried == "", "Canonical checkpoint %d preserves safe progress with empty hands" % value)
	_expect(state.sizes == {"cereal": 1 if value == 0 else 2, "cargo": 0 if value == 3 else 1}, "Canonical checkpoint %d restores authored raft and cargo sizes" % value)
	_expect(state.phase == ("near" if value < 2 else ("shoal" if value == 2 else "far")) and state.aboard == (value == 2), "Canonical checkpoint %d restores the correct dock and rider" % value)
	_expect(state.dock_open == (value == 3) and not state.completed, "Canonical checkpoint %d preserves the latched dock and reopens play" % value)


func _round_trip(state: State, label: String) -> void:
	var restored = State.new()
	_expect(restored.restore(JSON.parse_string(JSON.stringify(state.to_dict()))), label + " accepts serialized JSON")
	_expect(restored.to_dict() == state.to_dict() and not restored.recovered_motion, label + " preserves moored live state exactly")


func _ok(result: Dictionary, label: String) -> void:
	_expect(result.get("ok") == true, label)
	_expect(typeof(result.get("message")) == TYPE_STRING and not result["message"].is_empty(), label + " supplies feedback")


func _bad(result: Dictionary, label: String) -> void:
	_expect(result.get("ok") == false, label)
	_expect(typeof(result.get("message")) == TYPE_STRING and not result["message"].is_empty(), label + " explains the rejection")


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
