extends SceneTree
## Run: tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_puzzle_state.gd

const State = preload("res://scripts/puzzle_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_opening_and_invalid_actions()
	_test_full_route_and_recovery()
	_test_checkpoint_with_carried_prop()
	_test_save_validation()
	_test_every_prop_size()
	_test_transition_invariants()
	if failures == 0:
		print("PASS: %d puzzle state checks; route, checkpoints, invalid actions, and saves." % checks)
	else:
		push_error("FAIL: %d of %d puzzle state checks failed." % [failures, checks])
	quit(0 if failures == 0 else 1)


func _test_opening_and_invalid_actions() -> void:
	var state: PuzzleState = State.new()
	_expect(state.checkpoint == 0 and not state.can_launch(), "Opening has no launch and checkpoint zero")
	var initial: Dictionary = state.to_dict()
	_bad(state.resize("missing", 1), "Unknown resize target")
	_bad(state.resize("spoon", -1), "Negative size")
	_bad(state.resize("spoon", 3), "Fourth size")
	_bad(state.interact("missing"), "Unknown interaction")
	_bad(state.interact("spoon"), "Normal spoon is not carryable")
	_bad(state.pass_handle(), "Cannot pass handle without small carried spoon")
	_bad(state.place("bridge"), "Empty hands cannot place")
	_bad(state.release_launch(), "Unprepared launch rejected")
	_expect(state.to_dict() == initial, "Invalid actions leave the entire state unchanged")
	_ok(state.resize("spoon", 0), "Shrink spoon")
	_ok(state.interact("spoon"), "Pick up spoon")
	var held: Dictionary = state.to_dict()
	_bad(state.resize("spoon", 2), "Growing held object would overlap Pip")
	_bad(state.place("bridge"), "Cup handle passage is required")
	_bad(state.place("lever"), "Wrong prop cannot occupy socket")
	_bad(state.interact("blueberry"), "Cannot carry two objects")
	_expect(state.to_dict() == held, "Rejected carry and placement preserve held prop")
	_ok(state.interact("spoon"), "Interacting with held prop safely drops it")
	_expect(state.carried.is_empty() and state.sockets["spoon"] == "tray", "Dropped spoon returns to safe tray")
	state.reset_checkpoint()
	_expect(state.to_dict() == initial, "Opening reset restores clean prop state")
	_bad(state.interact("cereal"), "Optional panel needs small cereal box")
	_ok(state.resize("cereal", 0), "Shrink cereal box")
	_ok(state.interact("cereal"), "Open optional panel")
	_expect(state.discovered and state.checkpoint == 0, "Optional discovery does not advance required progression")
	state.reset_checkpoint()
	_expect(state.discovered, "Local reset preserves optional discovery")
	_round_trip(state, "Opening with discovery")


func _test_full_route_and_recovery() -> void:
	var state: PuzzleState = State.new()
	_bridge(state)
	_expect(state.checkpoint == 1 and state.bridge_placed, "Spoon bridge establishes checkpoint one")
	_round_trip(state, "Bridge checkpoint")
	_bad(state.resize("spoon", 0), "Required bridge cannot disappear before return route exists")
	_ok(state.resize("blueberry", 0), "Shrink blueberry for ballast")
	_ok(state.interact("blueberry"), "Carry blueberry")
	_ok(state.place("ballast"), "Place blueberry on flap")
	_ok(state.resize("blueberry", 2), "Large blueberry raises flap")
	_expect(state.ramp_raised() and not state.ramp_latched, "Ballast raises reversible ramp")
	_ok(state.resize("blueberry", 0), "Ballast can be removed before wedge is inserted")
	_expect(not state.ramp_raised(), "Ramp lowers without ballast")
	state.reset_checkpoint()
	_expect(state.checkpoint == 1 and state.bridge_placed and state.sockets["blueberry"] == "tray", "Checkpoint one recovers displaced ballast")
	_ok(state.resize("butter", 0), "Shrink butter before ramp raised")
	_ok(state.interact("butter"), "Carry butter before ramp raised")
	_bad(state.place("wedge"), "Closed ramp cannot accept butter wedge")
	_ok(state.place("tray"), "Return premature butter safely")
	_ballast(state)
	_ok(state.resize("butter", 0), "Shrink butter")
	_ok(state.interact("butter"), "Carry butter")
	_ok(state.place("wedge"), "Place butter below raised ramp")
	_bad(state.resize("blueberry", 0), "Ramp cannot collapse around an unlatched wedge")
	_ok(state.resize("butter", 1), "Grow wedge to latch ramp")
	_expect(state.checkpoint == 2 and state.ramp_latched, "Wedge establishes checkpoint two")
	_round_trip(state, "Latched ramp checkpoint")
	_bad(state.resize("butter", 0), "Permanent wedge cannot be removed")
	_ok(state.resize("spoon", 0), "Bridge can shrink after safe return route opens")
	_expect(not state.bridge_placed and state.ramp_raised(), "Permanent return route survives spoon removal")
	_ok(state.resize("blueberry", 0), "Shrink freed blueberry")
	_ok(state.interact("blueberry"), "Recover blueberry for reuse")
	_expect(state.ramp_raised(), "Ramp remains raised while blueberry is carried away")
	state.reset_checkpoint()
	_expect(state.checkpoint == 2 and state.bridge_placed and state.sockets["blueberry"] == "ballast", "Checkpoint two restores reusable blueberry and bridge")
	_landing(state)
	_lever(state)
	_expect(state.checkpoint == 3 and state.can_launch(), "Landing and lever establish ready checkpoint three")
	_round_trip(state, "Prepared launch checkpoint")
	_ok(state.resize("napkin", 1), "Landing can be experimentally resized")
	_bad(state.release_launch(), "Unsafe landing prevents release")
	state.reset_checkpoint()
	_expect(state.can_launch() and state.napkin_ready, "Launch checkpoint restores safe landing")
	_ok(state.release_launch(), "Prepared launch releases")
	_expect(not state.completed and not state.toast_lowered and int(state.sizes["blueberry"]) == 0, "Launch releases weight and awaits actual landing completion")
	_bad(state.release_launch(), "Repeated release cannot double launch")
	var interrupted: PuzzleState = State.new()
	_expect(interrupted.restore(state.to_dict()), "Interrupted flight save is valid")
	_expect(interrupted.can_launch(), "Interrupted flight reload restores ready launch")
	state.reset_checkpoint()
	_expect(state.can_launch() and not state.completed, "Failed flight resets to prepared launcher")
	_ok(state.release_launch(), "Retry launch")
	state.completed = true
	_expect(not state.can_launch(), "Completed finale cannot relaunch accidentally")
	_bad(state.resize("napkin", 0), "Completion preserves the successful landing until replay")
	_bad(state.interact("blueberry"), "Completion cannot create an invalid carried launch weight")
	_round_trip(state, "Completed finale")
	state.reset_checkpoint()
	_expect(not state.completed and state.can_launch(), "Completion can replay from ready launch")


func _test_checkpoint_with_carried_prop() -> void:
	var state: PuzzleState = State.new()
	_ok(state.resize("spoon", 0), "Shrink spoon for snapshot test")
	_ok(state.interact("spoon"), "Carry spoon for snapshot test")
	_ok(state.pass_handle(), "Handle passage for snapshot test")
	_ok(state.place("bridge"), "Place bridge for snapshot test")
	_ok(state.resize("napkin", 0), "Shrink another prop")
	_ok(state.interact("napkin"), "Carry another prop during bridge resize")
	_ok(state.resize("spoon", 2), "Build bridge while carrying napkin")
	_expect(state.carried == "napkin", "Checkpoint creation preserves current held prop")
	_round_trip(state, "Checkpoint created while carrying")
	state.reset_checkpoint()
	_expect(state.carried.is_empty() and state.sockets["napkin"] == "tray", "Checkpoint recovery safely returns carried prop to tray")


func _test_save_validation() -> void:
	var state: PuzzleState = State.new()
	_bridge(state)
	_ballast(state)
	_wedge(state)
	_landing(state)
	_lever(state)
	var source: Dictionary = state.to_dict()
	var bad: Dictionary = source.duplicate(true)
	bad["schema_version"] = 2
	_reject_save(state, bad, source, "Future schema")
	bad = source.duplicate(true)
	bad["schema_version"] = "1"
	_reject_save(state, bad, source, "String schema")
	bad = source.duplicate(true)
	bad["stage"] = "W12S05"
	_reject_save(state, bad, source, "Different stage")
	bad = source.duplicate(true)
	bad.erase("sizes")
	_reject_save(state, bad, source, "Missing required field")
	bad = source.duplicate(true)
	bad["sizes"]["blueberry"] = 1.5
	_reject_save(state, bad, source, "Fractional prop size")
	bad = source.duplicate(true)
	bad["sizes"]["blueberry"] = "2"
	_reject_save(state, bad, source, "String prop size")
	bad = source.duplicate(true)
	bad["sizes"]["blueberry"] = INF
	_reject_save(state, bad, source, "Nonfinite prop size")
	bad = source.duplicate(true)
	bad["sizes"]["seventh_prop"] = 0
	_reject_save(state, bad, source, "Unexpected prop")
	bad = source.duplicate(true)
	bad["sockets"]["spoon"] = "lever"
	_reject_save(state, bad, source, "Incompatible prop socket")
	bad = source.duplicate(true)
	bad["carried"] = "blueberry"
	_reject_save(state, bad, source, "Phantom carried prop")
	bad = source.duplicate(true)
	bad["sockets"]["napkin"] = "carried"
	bad["sockets"]["blueberry"] = "carried"
	bad["carried"] = "napkin"
	_reject_save(state, bad, source, "Two carried props")
	bad = source.duplicate(true)
	bad["ramp_latched"] = 1
	_reject_save(state, bad, source, "Nonboolean route flag")
	bad = source.duplicate(true)
	bad["bridge_placed"] = false
	_reject_save(state, bad, source, "Derived bridge flag disagrees with geometry")
	bad = source.duplicate(true)
	bad["handle_passed"] = false
	_reject_save(state, bad, source, "Bridge without cup passage")
	bad = source.duplicate(true)
	bad["sockets"]["butter"] = "tray"
	_reject_save(state, bad, source, "Latched route without wedge")
	bad = source.duplicate(true)
	bad["checkpoint_state"]["checkpoint"] = 1
	_reject_save(state, bad, source, "Snapshot checkpoint mismatch")
	bad = source.duplicate(true)
	bad["checkpoint_state"]["sizes"]["napkin"] = 0
	_reject_save(state, bad, source, "Corrupt recovery snapshot")
	bad = source.duplicate(true)
	bad["checkpoint_state"]["completed"] = true
	_reject_save(state, bad, source, "Completed checkpoint cannot recover launch")
	_reject_save(state, {}, source, "Empty corrupt save")
	# Callers may retain or edit serialized data; neither live state nor the
	# private checkpoint may alias caller-owned dictionaries.
	var copy: PuzzleState = State.new()
	var input: Dictionary = source.duplicate(true)
	_expect(copy.restore(input), "Valid save accepted before alias check")
	input["sizes"]["spoon"] = 0
	input["checkpoint_state"]["sizes"]["spoon"] = 0
	_expect(int(copy.sizes["spoon"]) == 2, "Restore deep copies caller state")
	copy.reset_checkpoint()
	_expect(int(copy.sizes["spoon"]) == 2, "Restore deep copies caller checkpoint")
	var output: Dictionary = copy.to_dict()
	output["sizes"]["spoon"] = 0
	output["checkpoint_state"]["sizes"]["spoon"] = 0
	copy.reset_checkpoint()
	_expect(int(copy.sizes["spoon"]) == 2, "Serialization cannot mutate live state or recovery")


func _test_every_prop_size() -> void:
	for kind: String in State.PROP_KINDS:
		for size: int in range(3):
			var state: PuzzleState = State.new()
			_ok(state.resize(kind, size), "%s authored size %d" % [kind, size])
			_expect(int(state.sizes[kind]) == size, "Authored size is stored")
			_round_trip(state, "%s size %d save" % [kind, size])


func _test_transition_invariants() -> void:
	# Vary action order and resets from every solved boundary. This catches valid
	# actions whose resulting state would accidentally be rejected on reload.
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 9102026
	var destinations: Array[String] = ["tray", "bridge", "ballast", "wedge", "landing", "lever", "unknown"]
	for start: int in range(5):
		var state: PuzzleState = State.new()
		if start >= 1:
			_bridge(state)
		if start >= 2:
			_ballast(state)
			_wedge(state)
		if start >= 3:
			_landing(state)
			_lever(state)
		if start == 4:
			state.release_launch()
			state.completed = true
		for step: int in range(160):
			var kind: String = State.PROP_KINDS[random.randi_range(0, 5)]
			match random.randi_range(0, 5):
				0:
					state.resize(kind, random.randi_range(0, 2))
				1:
					state.interact(kind)
				2:
					state.place(destinations[random.randi_range(0, destinations.size() - 1)])
				3:
					state.pass_handle()
				4:
					state.release_launch()
				5:
					state.reset_checkpoint()
			var restored: PuzzleState = State.new()
			_expect(restored.restore(state.to_dict()), "Action sequence %d:%d remains saveable" % [start, step])
			restored.reset_checkpoint()
			var recovered: PuzzleState = State.new()
			_expect(recovered.restore(restored.to_dict()), "Action sequence %d:%d keeps a valid recovery" % [start, step])


func _bridge(state: PuzzleState) -> void:
	_ok(state.resize("spoon", 0), "Shrink bridge spoon")
	_ok(state.interact("spoon"), "Carry bridge spoon")
	_ok(state.pass_handle(), "Pass spoon through handle")
	_ok(state.place("bridge"), "Place bridge spoon")
	_ok(state.resize("spoon", 2), "Grow spoon bridge")


func _ballast(state: PuzzleState) -> void:
	_ok(state.resize("blueberry", 0), "Shrink ballast blueberry")
	_ok(state.interact("blueberry"), "Carry ballast blueberry")
	_ok(state.place("ballast"), "Place ballast blueberry")
	_ok(state.resize("blueberry", 2), "Grow ballast blueberry")


func _wedge(state: PuzzleState) -> void:
	_ok(state.resize("butter", 0), "Shrink wedge butter")
	_ok(state.interact("butter"), "Carry wedge butter")
	_ok(state.place("wedge"), "Place wedge butter")
	_ok(state.resize("butter", 1), "Grow butter latch")


func _landing(state: PuzzleState) -> void:
	_ok(state.resize("napkin", 0), "Shrink landing napkin")
	_ok(state.interact("napkin"), "Carry landing napkin")
	_ok(state.place("landing"), "Place landing napkin")
	_ok(state.resize("napkin", 2), "Grow soft landing")


func _lever(state: PuzzleState) -> void:
	_ok(state.resize("blueberry", 0), "Shrink reusable blueberry")
	_ok(state.interact("blueberry"), "Carry reusable blueberry")
	_ok(state.place("lever"), "Place blueberry on lever")
	_ok(state.resize("blueberry", 2), "Grow blueberry to lower toast")


func _round_trip(state: PuzzleState, label: String) -> void:
	var encoded: String = JSON.stringify(state.to_dict())
	var decoded: Variant = JSON.parse_string(encoded)
	_expect(typeof(decoded) == TYPE_DICTIONARY, label + " parses as JSON")
	var restored: PuzzleState = State.new()
	_expect(restored.restore(decoded), label + " restores JSON numbers safely")
	_expect(restored.to_dict() == state.to_dict(), label + " round trip preserves exact progress")


func _reject_save(state: PuzzleState, bad: Dictionary, before: Dictionary, label: String) -> void:
	_expect(not state.restore(bad), label + " is rejected")
	_expect(state.to_dict() == before, label + " leaves current state untouched")


func _ok(result: Dictionary, label: String) -> void:
	_expect(bool(result.get("ok", false)), label + ": " + String(result.get("message", "missing feedback")))
	_expect(not String(result.get("message", "")).is_empty(), "Action provides readable feedback")


func _bad(result: Dictionary, label: String) -> void:
	_expect(not bool(result.get("ok", true)), label)
	_expect(not String(result.get("message", "")).is_empty(), "Rejected action explains recovery")


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
