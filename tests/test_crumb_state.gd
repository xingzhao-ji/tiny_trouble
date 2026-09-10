extends SceneTree
## Run with Godot --headless --path . --script tests/test_crumb_state.gd.
const State = preload("res://scripts/chapter/crumb_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_solution_and_recovery()
	_test_invalid_actions()
	_test_canonical_checkpoints()
	_test_save_validation()
	_test_malformed_stage_types()
	_test_varied_action_order()
	print("%s: %d Crumb Crossing checks; solution, reversible bridge, canonical recovery, and validated saves." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_solution_and_recovery() -> void:
	var state = State.new()
	_expect(state.sizes.size() == 2 and state.sockets.size() == 2, "Stage contains only its sugar and teaspoon prop families")
	_bad(state.finish(), "Cannot finish an unsolved crossing")
	_ok(state.resize("sugar", 0), "Shrink blocking sugar")
	_expect(state.checkpoint == 0, "Shrinking alone does not count as passing the obstacle")
	_ok(state.pass_sugar(), "Pass the small sugar")
	_expect(state.checkpoint == 1 and state.sugar_passed, "Physical sugar passage establishes first checkpoint")
	_round_trip(state, "Sugar passage")
	_ok(state.resize("spoon", 0), "Shrink teaspoon")
	_ok(state.interact("spoon"), "Carry teaspoon")
	_ok(state.pass_handle(), "Carry through handle")
	_expect(state.handle_passed and state.checkpoint == 1, "Handle passage does not skip bridge preparation")
	_ok(state.place("bridge"), "Rest teaspoon across gap")
	_ok(state.resize("spoon", 1), "Try normal spoon")
	_expect(not state.bridge_placed and state.checkpoint == 1, "Normal spoon does not span the authored gap")
	_ok(state.resize("spoon", 2), "Grow full crossing")
	_expect(state.bridge_placed and state.checkpoint == 2, "Large spoon creates crossing checkpoint")
	_round_trip(state, "Built bridge")
	_ok(state.resize("spoon", 0), "Experimentally shrink bridge while scene confirms unoccupied")
	_ok(state.interact("spoon"), "Remove former bridge")
	_expect(not state.bridge_placed and state.checkpoint == 2, "Reversible bridge removal keeps earned checkpoint")
	_round_trip(state, "Carried bridge after checkpoint")
	state.reset_checkpoint()
	_expect(state.bridge_placed and state.carried.is_empty() and state.sockets["spoon"] == "bridge" and int(state.sizes["spoon"]) == 2, "Local recovery rebuilds full bridge without stranding Pip")
	_ok(state.discover(), "Optional crumb discovery")
	_ok(state.finish(), "Finish after crossing")
	_expect(state.completed and state.discovered, "Completion and optional discovery are independently stored")
	_bad(state.resize("spoon", 0), "Completed crossing remains stable until replay")
	_round_trip(state, "Completed stage")
	state.reset_checkpoint()
	_expect(not state.completed and state.discovered and state.bridge_placed, "Replay restores safe bridge and preserves optional discovery")


func _test_invalid_actions() -> void:
	var state = State.new()
	var before: Dictionary = state.to_dict()
	_bad(state.resize("blueberry", 0), "Unknown prop is rejected")
	_bad(state.resize("sugar", -1), "Negative size is rejected")
	_bad(state.resize("sugar", 3), "Fourth size is rejected")
	_bad(state.interact("sugar"), "Sugar cannot be carried")
	_bad(state.interact("spoon"), "Normal spoon cannot be carried")
	_bad(state.interact("unknown"), "Unknown interaction is rejected")
	_bad(state.pass_sugar(), "Normal sugar does not permit passage")
	_bad(state.pass_handle(), "Handle cannot be reached before sugar passage")
	_bad(state.place("bridge"), "Empty hands cannot place bridge")
	_expect(state.to_dict() == before, "Rejected opening actions do not mutate save or checkpoint")
	state.resize("spoon", 0)
	state.interact("spoon")
	before = state.to_dict()
	_bad(state.resize("spoon", 2), "Held spoon cannot grow inside Pip")
	_bad(state.place("bridge"), "Handle passage is mandatory")
	_bad(state.place("ballast"), "Foreign stage socket is rejected")
	_bad(state.pass_handle(), "Carrying does not bypass sugar gate")
	_expect(state.to_dict() == before, "Rejected carrying actions preserve held teaspoon")
	_ok(state.interact("spoon"), "Repeated interaction safely drops teaspoon")
	_expect(state.carried.is_empty() and state.sockets["spoon"] == "tray", "Drop returns principal prop to safe tray")
	for kind: String in State.PROP_KINDS:
		for size: int in range(3):
			var experiment = State.new()
			_ok(experiment.resize(kind, size), "%s supports authored size %d" % [kind, size])
			_round_trip(experiment, "%s size %d" % [kind, size])


func _test_canonical_checkpoints() -> void:
	var state = State.new()
	state.resize("sugar", 2)
	state.resize("spoon", 0)
	state.interact("spoon")
	state.discover()
	state.reset_checkpoint()
	_expect(state.sizes == {"sugar": 1, "spoon": 1} and state.carried.is_empty(), "Opening recovery restores authored normal props")
	_expect(state.discovered, "Opening recovery preserves earned discovery")
	state.resize("spoon", 0)
	state.interact("spoon")
	state.resize("sugar", 0)
	state.pass_sugar()
	_expect(state.carried == "spoon", "Capturing checkpoint does not steal currently held prop")
	_round_trip(state, "Checkpoint reached while carrying")
	state.pass_handle()
	state.resize("sugar", 2)
	state.reset_checkpoint()
	_expect(state.sizes == {"sugar": 0, "spoon": 1} and state.sockets["spoon"] == "tray", "Checkpoint one restores small sugar and normal spoon tray")
	_expect(state.sugar_passed and not state.handle_passed and state.discovered, "Checkpoint one keeps gate progress and discovery only")
	state = _bridge()
	state.resize("sugar", 2)
	state.resize("spoon", 0)
	state.interact("spoon")
	state.place("tray")
	state.reset_checkpoint()
	_expect(state.sizes == {"sugar": 0, "spoon": 2} and state.bridge_placed and state.handle_passed, "Checkpoint two canonical route survives both prop experiments")
	var snapshot: Dictionary = state.to_dict()["checkpoint_state"]
	state.resize("spoon", 0)
	state.resize("spoon", 2)
	_expect(state.to_dict()["checkpoint_state"] == snapshot, "Re-growing solved bridge does not replace stable checkpoint")


func _test_save_validation() -> void:
	var state = _bridge()
	var source: Dictionary = state.to_dict()
	var mutations: Array[Dictionary] = []
	var bad: Dictionary = source.duplicate(true)
	bad["schema_version"] = 2
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["stage"] = "VS01"
	mutations.append(bad)
	bad = source.duplicate(true)
	bad.erase("handle_passed")
	mutations.append(bad)
	for invalid_size: Variant in ["2", 1.5, INF, -1, 3, true]:
		bad = source.duplicate(true)
		bad["sizes"]["sugar"] = invalid_size
		mutations.append(bad)
	bad = source.duplicate(true)
	bad["sizes"]["butter"] = 0
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["carried"] = "sugar"
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["carried"] = "spoon"
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["sockets"]["sugar"] = "carried"
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["sockets"]["spoon"] = "lever"
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["bridge_placed"] = false
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["sugar_passed"] = false
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["handle_passed"] = false
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["discovered"] = 1
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["checkpoint"] = 1
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["sizes"]["sugar"] = 2
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["completed"] = true
	mutations.append(bad)
	bad = source.duplicate(true)
	bad["checkpoint_state"]["discovered"] = true
	mutations.append(bad)
	mutations.append({})
	for index: int in range(mutations.size()):
		_expect(not state.restore(mutations[index]), "Corrupt or future save variant %d is rejected" % index)
		_expect(state.to_dict() == source, "Rejected variant %d leaves current progress untouched" % index)
	var early = State.new()
	bad = early.to_dict()
	bad["completed"] = true
	_expect(not early.restore(bad), "Opening cannot claim completed crossing")
	var copy = State.new()
	var data: Dictionary = source.duplicate(true)
	_expect(copy.restore(data), "Valid source restores before alias check")
	data["sizes"]["spoon"] = 0
	data["checkpoint_state"]["sizes"]["spoon"] = 0
	_expect(copy.bridge_placed and int(copy.sizes["spoon"]) == 2, "Restored live state does not alias caller data")
	copy.reset_checkpoint()
	_expect(copy.bridge_placed and int(copy.sizes["spoon"]) == 2, "Restored checkpoint does not alias caller data")
	data = copy.to_dict()
	data["checkpoint_state"]["sizes"]["spoon"] = 0
	copy.reset_checkpoint()
	_expect(int(copy.sizes["spoon"]) == 2, "Exported save cannot mutate private recovery")


func _test_malformed_stage_types() -> void:
	# Use an earned checkpoint with a detached carried bridge and a later
	# discovery so rejection must preserve both live play and safe recovery.
	var state = _bridge()
	state.discover()
	state.resize("spoon", 0)
	state.interact("spoon")
	var before: Dictionary = state.to_dict()
	for malformed: Variant in [7, 7.5, true, false, [], ["W01S01"], {}, {"stage": "W01S01"}, null]:
		var data: Dictionary = before.duplicate(true)
		data["stage"] = malformed
		var result: Variant = state.restore(data)
		_expect(typeof(result) == TYPE_BOOL and result == false, "Malformed stage type %d returns an explicit rejection" % typeof(malformed))
		_expect(state.to_dict() == before, "Malformed stage type %d preserves live progress and checkpoint atomically" % typeof(malformed))
		var recovered = State.new()
		_expect(recovered.restore(state.to_dict()), "Rejected malformed stage still permits a valid reload")
		recovered.reset_checkpoint()
		_expect(recovered.checkpoint == 2 and recovered.bridge_placed and recovered.discovered and recovered.carried == "", "Rejected malformed stage preserves canonical bridge recovery and discovery")


func _test_varied_action_order() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 11092026
	for start: int in range(3):
		var state = State.new() if start == 0 else _bridge()
		if start == 2:
			state.finish()
		for step: int in range(120):
			match random.randi_range(0, 7):
				0: state.resize(State.PROP_KINDS[random.randi_range(0, 1)], random.randi_range(0, 2))
				1: state.interact(State.PROP_KINDS[random.randi_range(0, 1)])
				2: state.place("bridge" if random.randi_range(0, 1) == 0 else "tray")
				3: state.pass_sugar()
				4: state.pass_handle()
				5: state.discover()
				6: state.finish()
				7: state.reset_checkpoint()
			var copy = State.new()
			_expect(copy.restore(state.to_dict()), "Action order %d:%d remains saveable" % [start, step])
			copy.reset_checkpoint()
			var recovered = State.new()
			_expect(recovered.restore(copy.to_dict()), "Action order %d:%d retains valid recovery" % [start, step])


func _bridge() -> RefCounted:
	var state = State.new()
	state.resize("sugar", 0)
	state.pass_sugar()
	state.resize("spoon", 0)
	state.interact("spoon")
	state.pass_handle()
	state.place("bridge")
	state.resize("spoon", 2)
	return state


func _round_trip(state: RefCounted, label: String) -> void:
	var encoded: String = JSON.stringify(state.to_dict())
	var data: Variant = JSON.parse_string(encoded)
	var restored = State.new()
	_expect(restored.restore(data), label + " accepts JSON numeric representation")
	_expect(restored.to_dict() == state.to_dict(), label + " preserves live experiments and stable snapshot")


func _ok(result: Dictionary, label: String) -> void:
	_expect(bool(result["ok"]), label)
	_expect(not String(result["message"]).is_empty(), label + " supplies feedback")


func _bad(result: Dictionary, label: String) -> void:
	_expect(not bool(result["ok"]), label)
	_expect(not String(result["message"]).is_empty(), label + " explains recovery")


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
