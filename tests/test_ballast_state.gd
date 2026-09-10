extends SceneTree
## Pure W01S02 state checks; no scene, profile, settings, or input mutation.
const State = preload("res://scripts/chapter/ballast_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_both_solutions()
	_test_weights_and_reversible_rolls()
	_test_checkpoints_and_completed_lock()
	_test_invalid_actions()
	_test_corrupt_saves()
	_test_history_and_aliases()
	_test_varied_action_order()
	print("%s: %d Blueberry Ballast checks; both balance solutions, reversible loads, canonical recovery, and atomic save validation." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_both_solutions() -> void:
	for small_berry: String in State.PROP_KINDS:
		var state = State.new()
		_expect(State.TARGET_WEIGHT == 5 and State.MASSES == [1, 2, 4], "Authored ballast target and masses are exposed")
		_expect(state.sizes == {"berry_a": 1, "berry_b": 1} and state.total_weight() == 0, "Opening normal berries do not weigh on the flap from their trays")
		_expect(not state.is_balanced() and state.checkpoint == 0 and state.carried == "", "Opening crossing is unsolved and has no carried prop")
		_bad(state.finish(), "Opening cannot finish")
		for kind: String in State.PROP_KINDS:
			_ok(state.resize(kind, 2), "Grow " + kind + " for rolling")
			_ok(state.interact(kind), "Roll " + kind + " into its pocket")
		_expect(state.checkpoint == 1 and state.total_weight() == 8 and not state.is_balanced(), "Two large berries establish the overweight checkpoint")
		_round_trip(state, "Two loaded berries")
		_bad(state.finish(), "Overweight flap cannot finish")
		_ok(state.resize(small_berry, 0), "Make " + small_berry + " the small counterbalancing berry")
		_expect(state.checkpoint == 2 and state.total_weight() == 5 and state.is_balanced(), "Either large/small arrangement balances the target")
		_round_trip(state, "Balanced using " + small_berry)
		_ok(state.discover(), "Inspect optional breakfast detail")
		_ok(state.finish(), "Finish current balanced crossing")
		_expect(state.completed and state.discovered, "Completion and optional discovery are recorded independently")
		_round_trip(state, "Completed using " + small_berry)
		state.reset_checkpoint()
		_expect(state.is_balanced() and not state.completed and state.discovered, "Completed reset reopens a safe balanced crossing and preserves discovery")
		_expect(state.sizes == {"berry_a": 2, "berry_b": 0}, "Both accepted solutions recover to the authored canonical orientation")
	# The player need not make the flap overweight first. Both pockets are
	# genuinely loaded even when the first berry was already made small.
	for first: String in State.PROP_KINDS:
		var second: String = "berry_b" if first == "berry_a" else "berry_a"
		var state = State.new()
		state.resize(first, 2)
		state.interact(first)
		state.resize(first, 0)
		_expect(state.checkpoint == 0 and state.total_weight() == 1, "A single small pocket berry does not claim the loading checkpoint")
		state.resize(second, 2)
		_ok(state.interact(second), "Roll the second berry into an already prepared balance")
		_expect(state.is_balanced() and state.checkpoint == 2, "Loading the second berry can legitimately reach the balanced checkpoint directly")
		_round_trip(state, "Pre-sized first berry " + first)


func _test_weights_and_reversible_rolls() -> void:
	var expected_totals: Array = [[2, 3, 5], [3, 4, 6], [5, 6, 8]]
	for a_size: int in range(3):
		for b_size: int in range(3):
			var state = _loaded()
			state.resize("berry_a", a_size)
			state.resize("berry_b", b_size)
			_expect(state.total_weight() == expected_totals[a_size][b_size], "Two loaded sizes %d/%d have their authored mass" % [a_size, b_size])
			_expect(state.is_balanced() == ((a_size == 0 and b_size == 2) or (a_size == 2 and b_size == 0)), "Only opposite small/large sizes balance %d/%d" % [a_size, b_size])
			_round_trip(state, "Loaded mass pair %d/%d" % [a_size, b_size])
			for kind: String in State.PROP_KINDS:
				var size: int = int(state.sizes[kind])
				var checkpoint: int = state.checkpoint
				_ok(state.interact(kind), "Return a pocket berry to its tray at size %d" % size)
				_expect(state.sockets[kind] == "tray" and int(state.sizes[kind]) == size and state.carried == "", "Returning a berry preserves size and never creates a carried prop")
				_expect(not state.is_balanced() and state.checkpoint == checkpoint, "Unloading removes current balance while retaining earned progress")
				if size != 2:
					var before: Dictionary = state.to_dict()
					_bad(state.interact(kind), "A returned nonlarge berry cannot roll back into a pocket")
					_expect(state.to_dict() == before, "Rejected reroll preserves the live experiment")
			_expect(state.total_weight() == 0, "Both returned berries contribute no flap weight")
			state.resize("berry_a", 2)
			state.resize("berry_b", 2)
			_expect(state.total_weight() == 0, "Growing tray berries does not silently reload their pockets")
			_round_trip(state, "Both berries returned to trays")


func _test_checkpoints_and_completed_lock() -> void:
	for checkpoint: int in range(3):
		var state = State.new() if checkpoint == 0 else (_loaded() if checkpoint == 1 else _balanced())
		state.discover()
		for kind: String in State.PROP_KINDS:
			if state.sockets[kind] == "flap": state.interact(kind)
			state.resize(kind, 0)
		_expect(state.checkpoint == checkpoint, "Unloading and shrinking both berries does not regress checkpoint %d" % checkpoint)
		_round_trip(state, "Detached checkpoint %d" % checkpoint)
		var before: Dictionary = state.to_dict()
		_bad(state.finish(), "Historical checkpoint alone cannot finish an unbalanced experiment")
		_expect(state.to_dict() == before, "Rejected experimental finish is atomic")
		state.reset_checkpoint()
		_assert_canonical(state, checkpoint)
		_expect(state.discovered and not state.completed and state.carried == "", "Canonical reset retains discovery and reopens play at %d" % checkpoint)
		_round_trip(state, "Reset checkpoint %d" % checkpoint)
		before = state.to_dict()
		state.reset_checkpoint()
		_expect(state.to_dict() == before, "Repeated checkpoint reset is stable")
	var state = _balanced()
	state.finish()
	var finished: Dictionary = state.to_dict()
	for kind: String in State.PROP_KINDS:
		_bad(state.resize(kind, 1), "Completed ballast rejects a changed size")
		_bad(state.interact(kind), "Completed ballast rejects unloading")
	_bad(state.discover(), "A new discovery waits until completed crossing is reopened")
	_expect(state.to_dict() == finished, "Rejected completed-state actions cannot alter completed save")
	_ok(state.resize("berry_a", 2), "Selecting the existing completed size is idempotent")
	_ok(state.finish(), "Repeated finish is idempotent")
	_expect(state.to_dict() == finished, "Completed no-op actions preserve the exact save")
	state.reset_checkpoint()
	_ok(state.discover(), "Reopening a completed crossing permits optional inspection")
	state.finish()
	finished = state.to_dict()
	_ok(state.discover(), "An already earned completed discovery is idempotent")
	_expect(state.to_dict() == finished, "Repeated inspection does not mutate the completed record")


func _test_invalid_actions() -> void:
	var state = State.new()
	var before: Dictionary = state.to_dict()
	for kind: String in ["", "blueberry", "sugar", "spoon", "berry_c"]:
		_bad(state.resize(kind, 0), "Unknown prop cannot resize: " + kind)
		_bad(state.interact(kind), "Unknown prop cannot roll: " + kind)
	for kind: String in State.PROP_KINDS:
		_bad(state.resize(kind, -1), "Negative berry size is invalid")
		_bad(state.resize(kind, 3), "Fourth berry size is invalid")
		_bad(state.interact(kind), "Normal tray berry cannot enter the flap")
	_expect(state.to_dict() == before, "All rejected opening interactions leave state and checkpoint untouched")
	for kind: String in State.PROP_KINDS:
		state.resize(kind, 0)
		before = state.to_dict()
		_bad(state.interact(kind), "Small tray berry cannot enter the flap")
		_expect(state.to_dict() == before, "Rejected small roll leaves state untouched")


func _test_corrupt_saves() -> void:
	var state = _balanced()
	var source: Dictionary = state.to_dict()
	var mutations: Array[Dictionary] = [{}]
	for key: String in source:
		var bad: Dictionary = source.duplicate(true)
		bad.erase(key)
		mutations.append(bad)
	for value: Variant in [0, 2, -1, "1", true, null, 1.5, INF, NAN]:
		var bad: Dictionary = source.duplicate(true)
		bad["schema_version"] = value
		mutations.append(bad)
	for value: Variant in ["VS01", "W01S01", "W01S03", "", null, 2]:
		var bad: Dictionary = source.duplicate(true)
		bad["stage"] = value
		mutations.append(bad)
	for value: Variant in [-1, 3, "2", true, null, 1.5, INF, NAN]:
		var bad: Dictionary = source.duplicate(true)
		bad["checkpoint"] = value
		mutations.append(bad)
	for kind: String in State.PROP_KINDS:
		for value: Variant in [-1, 3, "2", true, null, 1.5, INF, NAN, {}, []]:
			var bad: Dictionary = source.duplicate(true)
			bad["sizes"][kind] = value
			mutations.append(bad)
		for value: Variant in ["carried", "bridge", "ballast", "", null, true, 1, []]:
			var bad: Dictionary = source.duplicate(true)
			bad["sockets"][kind] = value
			mutations.append(bad)
	for field: String in ["sizes", "sockets", "checkpoint_state"]:
		for value: Variant in [null, [], true, "{}"]:
			var bad: Dictionary = source.duplicate(true)
			bad[field] = value
			mutations.append(bad)
	for value: Variant in ["berry_a", "berry_b", null, false, 0]:
		var bad: Dictionary = source.duplicate(true)
		bad["carried"] = value
		mutations.append(bad)
	for field: String in ["discovered", "completed"]:
		for value: Variant in [0, 1, "false", null]:
			var bad: Dictionary = source.duplicate(true)
			bad[field] = value
			mutations.append(bad)
	for field: String in ["sizes", "sockets"]:
		var bad: Dictionary = source.duplicate(true)
		bad[field]["berry_c"] = 1 if field == "sizes" else "tray"
		mutations.append(bad)
		bad = source.duplicate(true)
		bad[field].erase("berry_a")
		mutations.append(bad)
	var bad: Dictionary = source.duplicate(true)
	bad["counterweight"] = 4
	mutations.append(bad)
	for key: String in source["checkpoint_state"]:
		bad = source.duplicate(true)
		bad["checkpoint_state"].erase(key)
		mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["completed"] = true
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["discovered"] = true
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["checkpoint"] = 1
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["sizes"] = {"berry_a": 0, "berry_b": 2}
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["sockets"] = {"berry_a": "tray", "berry_b": "tray"}
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["completed"] = true
	bad["sockets"]["berry_b"] = "tray"
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["completed"] = true
	bad["sizes"]["berry_b"] = 2
	mutations.append(bad)
	for index: int in range(mutations.size()):
		_expect(not state.restore(mutations[index]), "Malformed/future ballast save %d is rejected" % index)
		_expect(state.to_dict() == source, "Rejected save %d cannot mutate current rules or recovery" % index)


func _test_history_and_aliases() -> void:
	var state = State.new()
	var before: Dictionary = state.to_dict()
	var bad: Dictionary = before.duplicate(true)
	bad["checkpoint"] = 2
	bad["checkpoint_state"]["checkpoint"] = 2
	_expect(not state.restore(bad), "Changing checkpoint labels alone cannot forge an achieved two-berry balance")
	_expect(state.to_dict() == before, "Forged checkpoint leaves opening state untouched")
	bad = _loaded().to_dict()
	bad["checkpoint"] = 0
	bad["checkpoint_state"] = before["checkpoint_state"]
	_expect(not state.restore(bad), "Two loaded berries cannot retain an unearned opening checkpoint")
	bad = _balanced().to_dict()
	bad["checkpoint"] = 1
	bad["checkpoint_state"] = _loaded().to_dict()["checkpoint_state"]
	_expect(not state.restore(bad), "A current balanced setup must record the balanced checkpoint")
	bad = before.duplicate(true)
	bad["completed"] = true
	_expect(not state.restore(bad), "Opening save cannot claim completion")
	state = _balanced()
	state.interact("berry_a")
	state.interact("berry_b")
	state.resize("berry_a", 1)
	state.resize("berry_b", 1)
	_round_trip(state, "Earned checkpoint with both berries moved off the flap")
	var data: Dictionary = state.to_dict()
	var copy = State.new()
	_expect(copy.restore(data), "Valid historical checkpoint restores for alias checks")
	data["sizes"]["berry_a"] = 0
	data["sockets"]["berry_b"] = "flap"
	data["checkpoint_state"]["sizes"]["berry_a"] = 0
	_expect(copy.to_dict() == state.to_dict(), "Restored live data and historical snapshot do not alias the caller")
	copy.reset_checkpoint()
	_expect(copy.is_balanced() and copy.sizes == {"berry_a": 2, "berry_b": 0}, "Caller mutation cannot corrupt restored checkpoint recovery")
	data = copy.to_dict()
	data["sizes"]["berry_a"] = 0
	data["checkpoint_state"]["sizes"]["berry_a"] = 0
	copy.reset_checkpoint()
	_expect(copy.is_balanced() and copy.total_weight() == 5, "Exported dictionaries cannot alter private checkpoint recovery")
	copy.discover()
	data = copy.to_dict()
	_expect(data["discovered"] and not data["checkpoint_state"]["discovered"], "Postcheckpoint discovery remains independent of the canonical snapshot")
	_round_trip(copy, "Discovery earned after checkpoint")
	copy.reset_checkpoint()
	_expect(copy.discovered, "Postcheckpoint discovery survives restore and reset")


func _test_varied_action_order() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 22092026
	for opening: int in range(4):
		var state = State.new() if opening == 0 else (_loaded() if opening == 1 else _balanced())
		if opening == 3: state.finish()
		for step: int in range(120):
			var before: Dictionary = state.to_dict()
			var result: Dictionary = {"ok": true}
			match random.randi_range(0, 6):
				0, 1: result = state.resize(State.PROP_KINDS[random.randi_range(0, 1)], random.randi_range(-1, 3))
				2: result = state.interact(State.PROP_KINDS[random.randi_range(0, 1)])
				3: result = state.discover()
				4: result = state.finish()
				5: state.reset_checkpoint()
				6: result = state.interact("unknown")
			if not result["ok"]:
				_expect(state.to_dict() == before, "Rejected generated action %d:%d is atomic" % [opening, step])
			_expect(state.checkpoint >= int(before["checkpoint"]) and state.carried == "", "Generated action %d:%d preserves checkpoint history and never carries berries" % [opening, step])
			var copy = State.new()
			var parsed: Variant = JSON.parse_string(JSON.stringify(state.to_dict()))
			_expect(copy.restore(parsed), "Generated action %d:%d remains JSON-saveable" % [opening, step])
			_expect(copy.to_dict() == state.to_dict(), "Generated action %d:%d round-trips current experiments exactly" % [opening, step])
			copy.reset_checkpoint()
			var recovered = State.new()
			_expect(recovered.restore(copy.to_dict()), "Generated action %d:%d retains a valid recovery snapshot" % [opening, step])
			_expect(not copy.completed and (copy.checkpoint != 2 or copy.is_balanced()), "Generated action %d:%d can recover to a playable crossing" % [opening, step])


func _loaded() -> State:
	var state = State.new()
	for kind: String in State.PROP_KINDS:
		state.resize(kind, 2)
		state.interact(kind)
	return state


func _balanced() -> State:
	var state = _loaded()
	state.resize("berry_b", 0)
	return state


func _assert_canonical(state: State, checkpoint: int) -> void:
	_expect(state.checkpoint == checkpoint, "Canonical recovery keeps checkpoint %d" % checkpoint)
	_expect(state.sizes == ({"berry_a": 1, "berry_b": 1} if checkpoint == 0 else ({"berry_a": 2, "berry_b": 2} if checkpoint == 1 else {"berry_a": 2, "berry_b": 0})), "Checkpoint %d restores authored berry sizes" % checkpoint)
	_expect(state.sockets == ({"berry_a": "tray", "berry_b": "tray"} if checkpoint == 0 else {"berry_a": "flap", "berry_b": "flap"}), "Checkpoint %d restores authored berry sockets" % checkpoint)
	_expect(state.total_weight() == [0, 8, 5][checkpoint], "Checkpoint %d restores the expected flap weight" % checkpoint)


func _round_trip(state: State, label: String) -> void:
	var parsed: Variant = JSON.parse_string(JSON.stringify(state.to_dict()))
	var copy = State.new()
	_expect(copy.restore(parsed), label + " accepts JSON numeric representation")
	_expect(copy.to_dict() == state.to_dict(), label + " preserves live state and historical checkpoint")


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
