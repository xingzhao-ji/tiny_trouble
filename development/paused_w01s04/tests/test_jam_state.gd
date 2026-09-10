# UNVERIFIED WIP: authored tests have not been parsed or executed.
extends SceneTree
## Pure W01S04 rules: scene contact is represented only by arrive_central/place.
## No scene, player settings, profile files, or InputMap is touched.
const State = preload("res://scripts/chapter/jam_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_preparation_orders()
	_test_optional_rest_and_delivery_experiments()
	_test_invalid_actions()
	_test_canonical_recovery()
	_test_interrupted_carry()
	_test_corrupt_saves()
	_test_copy_isolation_and_completion()
	_test_reversible_sequences()
	print("%s: %d Jam Detour checks; continuous carrying, free preparation order, earned delivery, canonical recovery, and atomic corruption rejection." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_preparation_orders() -> void:
	var orders: Array = [["knife", "biscuit_b", "arrival"], ["biscuit_b", "knife", "arrival"], ["knife", "arrival", "biscuit_b"], ["biscuit_b", "arrival", "knife"], ["arrival", "knife", "biscuit_b"], ["arrival", "biscuit_b", "knife"]]
	for order: Array in orders:
		for use_rest: bool in [false, true]:
			var state = State.new()
			_expect(state.sizes == {"biscuit_a": 1, "biscuit_b": 1, "knife": 1, "parcel": 1}, "Opening has four independently named normal props")
			_ok(state.resize("biscuit_a", 2), "Enlarge the first stepping biscuit")
			_expect(state.checkpoint == 0 and not state.central_reached, "A large first biscuit alone does not invent parcel arrival")
			_ok(state.resize("parcel", 0), "Make the seed parcel carryable")
			_ok(state.interact("parcel"), "Pick up the small seed parcel")
			for action: String in order:
				if action == "arrival":
					if use_rest: _ok(state.place("central"), "Optional central placement proves actual parcel arrival")
					else: _ok(state.arrive_central(), "Scene confirms arrival while Pip keeps carrying the parcel")
					_expect(state.central_reached and state.checkpoint >= 1, "Transport earns central arrival")
				else:
					_ok(state.resize(action, 2), "Prepare " + action + " in freely chosen order")
				if not state.central_reached:
					_expect(state.checkpoint == 0, "Early ramp preparation does not invent central transport")
				if not use_rest:
					_expect(state.carried == "parcel" and state.sockets["parcel"] == "carried", "Preparing the route never requires a hidden parcel drop")
			_expect(state.checkpoint == 2 and state.ramp_ready() and not state.delivered, "Any preparation order earns ready checkpoint after actual arrival")
			if use_rest: _ok(state.interact("parcel"), "Retrieve the parcel from the optional central rest")
			var before: Dictionary = state.to_dict()
			_bad(state.finish(), "Reaching checkpoint two does not claim delivery or the flag")
			_expect(state.to_dict() == before, "Premature finish preserves the carried parcel")
			# The scene may now have transported Pip to the far bank. Safe empty
			# support experiments must not create an invisible delivery gate there.
			_ok(state.resize("knife", 0), "Change the empty knife after the crossing")
			_ok(state.resize("biscuit_b", 1), "Change the empty counterweight after the crossing")
			_expect(not state.ramp_ready() and state.checkpoint == 2, "Current alignment may change without losing earned crossing readiness")
			_ok(state.place("far"), "Earned readiness permits actual far-rest delivery after a safe empty-ramp experiment")
			_expect(state.checkpoint == 3 and state.delivered and not state.completed and state.carried == "", "Delivery establishes checkpoint three, separately from the flag")
			_round_trip(state, "Delivered parcel with experimentally changed knife")
			_ok(state.finish(), "Small delivered parcel permits the scene's far-flag finish")
			_expect(state.completed and not state.discovered, "Optional discovery never gates delivery or completion")
			_round_trip(state, "Completed route in each supported preparation order")
	# Arrival proof belongs to physical scene contact. It must not require the
	# original biscuit to remain large after Pip and the parcel have crossed.
	var state = State.new()
	state.resize("parcel", 0)
	state.interact("parcel")
	state.resize("biscuit_a", 0)
	_ok(state.arrive_central(), "Actual arrival remains valid after the empty first biscuit changes size")
	_expect(state.checkpoint == 1 and int(state.sizes["biscuit_a"]) == 0, "Arrival records history without silently rebuilding the current first biscuit")


func _test_optional_rest_and_delivery_experiments() -> void:
	var state = _checkpoint(1)
	for parcel_size: int in [1, 2]:
		_ok(state.resize("parcel", parcel_size), "Resting parcel may be resized on the independent dry central rest")
		var before: Dictionary = state.to_dict()
		_bad(state.interact("parcel"), "A bulky resting parcel is not carryable")
		_expect(state.to_dict() == before, "Failed pickup does not relocate or shrink the parcel")
	state.resize("parcel", 0)
	state.interact("parcel")
	var before: Dictionary = state.to_dict()
	_bad(state.place("far"), "Central arrival without earned ramp readiness does not deliver")
	_expect(state.to_dict() == before, "Rejected far placement retains the carried parcel")
	_ok(state.place("near"), "Parcel may return to its near rest")
	_expect(state.central_reached and state.checkpoint == 1 and not state.delivered, "Returning cargo does not erase prior central arrival")
	_round_trip(state, "Central history with parcel returned near")
	state.resize("knife", 2)
	state.resize("biscuit_b", 2)
	_expect(state.checkpoint == 2, "A previously transported parcel need not be dropped centrally again to record later readiness")
	state.interact("parcel")
	state.place("far")
	state.resize("parcel", 2)
	_expect(state.delivered and state.checkpoint == 3, "Growing a resting delivered parcel retains its placement and earned history")
	before = state.to_dict()
	_bad(state.finish(), "The flag requires the current delivered parcel to be small")
	_expect(state.to_dict() == before, "Bulky-delivery finish rejection is atomic")
	_round_trip(state, "Large parcel resting at the far destination")
	state.resize("parcel", 0)
	_ok(state.interact("parcel"), "Delivered parcel may be picked up again before finishing")
	_expect(not state.delivered and state.checkpoint == 3 and state.carried == "parcel", "Pickup clears current delivery while retaining earned delivery checkpoint")
	_bad(state.finish(), "Historical delivery alone cannot finish while holding the parcel")
	_ok(state.place("central"), "Parcel may be returned to the central rest")
	_expect(not state.delivered and state.checkpoint == 3 and state.sockets["parcel"] == "central", "Repositioned parcel is not falsely reported delivered")
	_round_trip(state, "Historical delivery with current central parcel")
	state.reset_checkpoint()
	_assert_canonical(state, 3)
	_ok(state.finish(), "Checkpoint recovery restores the delivery that was actually earned")


func _test_invalid_actions() -> void:
	var state = State.new()
	var original: Dictionary = state.to_dict()
	for kind: String in ["", "biscuit", "spoon", "cargo", "parcel_2"]:
		_bad(state.resize(kind, 0), "Unknown resize family is rejected")
		_bad(state.interact(kind), "Unknown interaction family is rejected")
	for kind: String in State.PROP_KINDS:
		_bad(state.resize(kind, -1), "Negative size is rejected")
		_bad(state.resize(kind, 3), "Fourth size is rejected")
		_bad(state.interact(kind), "Anchors or an opening bulky parcel cannot be carried")
	for socket: String in ["near", "central", "far", "", "tray", "pivot", "carried"]:
		_bad(state.place(socket), "A rest cannot create an uncarried parcel")
	_bad(state.arrive_central(), "Pip alone cannot award central parcel arrival")
	_bad(state.finish(), "An untouched stage cannot finish")
	_expect(state.to_dict() == original, "Rejected opening actions preserve every live and checkpoint field")
	state.resize("parcel", 0)
	state.interact("parcel")
	original = state.to_dict()
	_bad(state.resize("parcel", 1), "A carried parcel cannot grow to normal")
	_bad(state.resize("parcel", 2), "A carried parcel cannot grow large")
	_bad(state.interact("parcel"), "Repeated carry input does not teleport the parcel back to a remote rest")
	_bad(state.place("far"), "A carried opening parcel has not earned crossing history")
	_bad(state.place("ballast"), "Parcel cannot occupy a biscuit's anchor")
	_expect(state.to_dict() == original, "Invalid carry actions preserve the same small carried parcel")
	_ok(state.resize("parcel", 0), "Already-small carried resize is harmless")
	_expect(state.to_dict() == original, "A carried no-op does not create checkpoint progress")
	state.place("near")
	original = state.to_dict()
	_bad(state.arrive_central(), "A small parcel resting elsewhere is not central arrival proof")
	_expect(state.to_dict() == original, "Invalid arrival cannot move a resting parcel")


func _test_canonical_recovery() -> void:
	for checkpoint: int in range(4):
		var state = _checkpoint(checkpoint)
		state.discover()
		for kind: String in ["biscuit_a", "biscuit_b", "knife"]: state.resize(kind, 0)
		state.resize("parcel", 2)
		_expect(state.checkpoint == checkpoint, "Safe resting experiments retain checkpoint %d" % checkpoint)
		_round_trip(state, "Resting checkpoint %d experiments" % checkpoint)
		state.reset_checkpoint()
		_assert_canonical(state, checkpoint)
		_expect(state.discovered and not state.completed and not state.recovered_carry, "Reset retains earned discovery and safely reopens the checkpoint")
		_round_trip(state, "Canonical checkpoint %d" % checkpoint)
		var once: Dictionary = state.to_dict()
		state.reset_checkpoint()
		_expect(state.to_dict() == once, "Repeated reset is stable at checkpoint %d" % checkpoint)


func _test_interrupted_carry() -> void:
	for checkpoint: int in range(4):
		var source = _checkpoint(checkpoint)
		source.resize("parcel", 0)
		source.interact("parcel")
		source.resize("biscuit_a", 0)
		source.resize("knife", 0)
		source.discover()
		var before: Dictionary = source.to_dict()
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(before))
		var caller_before: PackedByteArray = var_to_bytes(parsed)
		var recovered = State.new()
		_expect(recovered.restore(parsed) and recovered.recovered_carry, "Interrupted carry restores with an explanatory transient flag")
		_assert_canonical(recovered, checkpoint)
		_expect(recovered.discovered, "Carry recovery preserves discovery earned after the checkpoint")
		_expect(source.to_dict() == before and var_to_bytes(parsed) == caller_before, "Carry recovery does not mutate the source or caller snapshot")
		_expect(not recovered.to_dict().has("recovered_carry"), "Recovery explanation is never serialized as campaign state")
		var stable: Dictionary = recovered.to_dict()
		var invalid: Dictionary = stable.duplicate(true)
		invalid["stage"] = 4
		_expect(not recovered.restore(invalid) and recovered.to_dict() == stable and recovered.recovered_carry, "Rejected recovery load preserves both state and prior recovery notice")
		_expect(recovered.restore(stable) and not recovered.recovered_carry, "A valid resting save clears the previous carry-recovery notice")
		recovered.restore(parsed)
		recovered.reset_checkpoint()
		_expect(not recovered.recovered_carry, "Explicit checkpoint reset clears transient carry-recovery metadata")
		source.reset_checkpoint()
		_assert_canonical(source, checkpoint)
		_expect(source.discovered, "Manual carry interruption also retains discovery")


func _test_corrupt_saves() -> void:
	var source = _checkpoint(3)
	var clean: Dictionary = source.to_dict()
	var mutations: Array[Dictionary] = [{}]
	for key: String in clean:
		var bad: Dictionary = clean.duplicate(true)
		bad.erase(key)
		mutations.append(bad)
	for key: String in ["schema_version", "checkpoint"]:
		for value: Variant in [-1, 4, 1.5, true, false, null, "1", [], {}, INF, NAN]:
			var bad: Dictionary = clean.duplicate(true)
			bad[key] = value
			mutations.append(bad)
	for value: Variant in [0, 2]:
		var bad: Dictionary = clean.duplicate(true)
		bad["schema_version"] = value
		mutations.append(bad)
	for value: Variant in [4, 1.5, true, false, null, [], {}, "", "W01S03", "W01S05"]:
		var bad: Dictionary = clean.duplicate(true)
		bad["stage"] = value
		mutations.append(bad)
	for section: String in ["sizes", "sockets", "checkpoint_state"]:
		for value: Variant in [null, [], true, 2, "{}"]:
			var bad: Dictionary = clean.duplicate(true)
			bad[section] = value
			mutations.append(bad)
	for kind: String in State.PROP_KINDS:
		for value: Variant in [-1, 3, 1.5, true, false, "0", null, [], {}, INF, NAN]:
			var bad: Dictionary = clean.duplicate(true)
			bad["sizes"][kind] = value
			mutations.append(bad)
		for value: Variant in ["", "wrong", 1, true, null, [], {}]:
			var bad: Dictionary = clean.duplicate(true)
			bad["sockets"][kind] = value
			mutations.append(bad)
		for section: String in ["sizes", "sockets"]:
			var bad: Dictionary = clean.duplicate(true)
			bad[section].erase(kind)
			mutations.append(bad)
			bad = clean.duplicate(true)
			bad[section]["extra_prop"] = 1
			mutations.append(bad)
	for key: String in ["central_reached", "delivered", "discovered", "completed"]:
		for value: Variant in [0, 1, "false", null, [], {}]:
			var bad: Dictionary = clean.duplicate(true)
			bad[key] = value
			mutations.append(bad)
	for value: Variant in ["biscuit_a", "knife", "cargo", 0, true, null, [], {}]:
		var bad: Dictionary = clean.duplicate(true)
		bad["carried"] = value
		mutations.append(bad)
	for key: String in clean["checkpoint_state"]:
		var bad: Dictionary = clean.duplicate(true)
		bad["checkpoint_state"].erase(key)
		mutations.append(bad)
	for key: String in ["sizes", "sockets"]:
		var bad: Dictionary = clean.duplicate(true)
		bad["checkpoint_state"][key] = null
		mutations.append(bad)
	for kind: String in State.PROP_KINDS:
		var bad: Dictionary = clean.duplicate(true)
		bad["checkpoint_state"]["sizes"][kind] = (int(bad["checkpoint_state"]["sizes"][kind]) + 1) % 3
		mutations.append(bad)
	var bad: Dictionary = clean.duplicate(true)
	bad["recovered_carry"] = true
	mutations.append(bad)
	bad = clean.duplicate(true)
	bad["checkpoint_state"]["extra"] = false
	mutations.append(bad)
	bad = clean.duplicate(true)
	bad["checkpoint_state"]["completed"] = true
	mutations.append(bad)
	bad = clean.duplicate(true)
	bad["checkpoint_state"]["discovered"] = true
	mutations.append(bad)
	bad = clean.duplicate(true)
	bad["checkpoint_state"]["checkpoint"] = 2
	mutations.append(bad)
	# Coherent types do not excuse impossible transport/delivery histories.
	for checkpoint: int in range(4):
		var fixture = _checkpoint(checkpoint)
		bad = fixture.to_dict()
		bad["central_reached"] = not bad["central_reached"]
		mutations.append(bad)
		bad = fixture.to_dict()
		bad["delivered"] = not bad["delivered"]
		mutations.append(bad)
		bad = fixture.to_dict()
		bad["carried"] = "parcel"
		mutations.append(bad)
		if checkpoint < 3:
			bad = fixture.to_dict()
			bad["completed"] = true
			mutations.append(bad)
			bad = fixture.to_dict()
			bad["sockets"]["parcel"] = "far"
			bad["delivered"] = true
			mutations.append(bad)
	bad = _checkpoint(0).to_dict()
	bad["sockets"]["parcel"] = "central"
	mutations.append(bad)
	bad = _checkpoint(1).to_dict()
	bad["sizes"]["knife"] = 2
	bad["sizes"]["biscuit_b"] = 2
	mutations.append(bad)
	bad = _checkpoint(3).to_dict()
	bad["sizes"]["parcel"] = 2
	bad["completed"] = true
	mutations.append(bad)
	for kind: String in ["biscuit_a", "biscuit_b", "knife"]:
		bad = clean.duplicate(true)
		bad["sockets"][kind] = "carried"
		mutations.append(bad)
	var carrier = _checkpoint(2)
	carrier.interact("parcel")
	for size: int in [1, 2]:
		bad = carrier.to_dict()
		bad["sizes"]["parcel"] = size
		mutations.append(bad)
	bad = carrier.to_dict()
	bad["carried"] = ""
	mutations.append(bad)
	var target = State.new()
	target.restore(carrier.to_dict())
	_expect(target.recovered_carry, "Corruption tests begin with an existing recovery notice to protect")
	for index: int in mutations.size():
		var before: Dictionary = target.to_dict()
		var input_before: PackedByteArray = var_to_bytes(mutations[index])
		var result: Variant = target.restore(mutations[index])
		_expect(typeof(result) == TYPE_BOOL and result == false, "Malformed snapshot %d rejects cleanly" % index)
		_expect(target.to_dict() == before and target.recovered_carry, "Malformed snapshot %d cannot partially mutate state or recovery metadata" % index)
		_expect(var_to_bytes(mutations[index]) == input_before, "Rejected snapshot %d leaves caller-owned data untouched" % index)


func _test_copy_isolation_and_completion() -> void:
	var state = _checkpoint(2)
	var before: Dictionary = state.to_dict()
	var copy: Dictionary = state.to_dict()
	copy["sizes"]["knife"] = 0
	copy["sockets"]["parcel"] = "far"
	copy["checkpoint_state"]["sizes"]["biscuit_a"] = 0
	_expect(state.to_dict() == before, "Exported live and checkpoint dictionaries do not alias state")
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(before))
	parsed["schema_version"] = 1.0
	parsed["checkpoint"] = 2.0
	parsed["checkpoint_state"]["checkpoint"] = 2.0
	var loaded = State.new()
	_expect(loaded.restore(parsed), "Finite whole-number JSON fields normalize safely")
	parsed["sizes"]["knife"] = 0
	parsed["checkpoint_state"]["sizes"]["biscuit_a"] = 0
	_expect(loaded.to_dict() == before, "Restored live and checkpoint dictionaries do not alias input")
	state.interact("parcel")
	state.place("far")
	state.finish()
	before = state.to_dict()
	for kind: String in State.PROP_KINDS:
		_bad(state.resize(kind, 1), "Completed stage rejects changed prop sizes")
		_bad(state.interact(kind), "Completed stage rejects new carry interactions")
	for socket: String in ["near", "central", "far"]: _bad(state.place(socket), "Completed stage rejects relocation")
	_bad(state.arrive_central(), "Completed stage rejects new arrival proofs")
	_bad(state.discover(), "An unearned discovery waits for exploration")
	_expect(state.to_dict() == before, "Completed mutations leave the exact completed save intact")
	_ok(state.resize("parcel", 0), "Repeated completed parcel size is harmless")
	_ok(state.finish(), "Repeated completed finish is harmless")
	_expect(state.to_dict() == before, "Completed no-ops preserve the exact record")
	state.reset_checkpoint()
	_ok(state.discover(), "Exploration after completed reset can earn the optional print")
	_ok(state.finish(), "Recovered delivery may finish again")
	before = state.to_dict()
	_ok(state.discover(), "An earned discovery remains idempotent after completion")
	_expect(state.to_dict() == before, "Repeated discovery cannot disturb completed progress")
	_round_trip(state, "Completed discovered state")


func _test_reversible_sequences() -> void:
	# Deterministic legal/illegal experiments exercise combinations beyond the
	# authored solution, including changing supports after historical checkpoints.
	for start_cp: int in range(4):
		var state = _checkpoint(start_cp)
		var rng := RandomNumberGenerator.new()
		rng.seed = 4901 + start_cp
		for step: int in range(100):
			var before: Dictionary = state.to_dict()
			var result: Dictionary = {}
			match rng.randi_range(0, 6):
				0: result = state.resize(State.PROP_KINDS[rng.randi_range(0, 3)], rng.randi_range(0, 2))
				1: result = state.interact("parcel")
				2: result = state.place(["near", "central", "far"][rng.randi_range(0, 2)])
				3: result = state.arrive_central()
				4: result = state.discover()
				5: result = state.finish()
				6: state.reset_checkpoint()
			if not result.is_empty() and not result["ok"]:
				_expect(state.to_dict() == before, "Rejected mixed experiment preserves exact state")
			_expect(state.checkpoint >= int(before["checkpoint"]), "Mixed experiments never regress earned checkpoints")
			_expect(state.sockets["biscuit_a"] == "step" and state.sockets["biscuit_b"] == "ballast" and state.sockets["knife"] == "pivot", "Mixed experiments preserve authored anchors")
			var recovered = State.new()
			_expect(recovered.restore(state.to_dict()), "Every reachable mixed state has a valid restorable snapshot")
			if state.carried == "parcel":
				_expect(recovered.recovered_carry and recovered.carried == "" and recovered.checkpoint == state.checkpoint, "Mixed carried snapshot restores only its earned safe checkpoint")
			else:
				_expect(recovered.to_dict() == state.to_dict() and not recovered.recovered_carry, "Mixed resting snapshot round-trips without erasing experiments")


func _checkpoint(value: int):
	var state = State.new()
	if value >= 1:
		state.resize("biscuit_a", 2)
		state.resize("parcel", 0)
		state.interact("parcel")
		state.place("central")
	if value >= 2:
		state.resize("knife", 2)
		state.resize("biscuit_b", 2)
	if value == 3:
		state.interact("parcel")
		state.place("far")
	return state


func _assert_canonical(state, checkpoint: int) -> void:
	var expected_sizes: Array[Dictionary] = [
		{"biscuit_a": 1, "biscuit_b": 1, "knife": 1, "parcel": 1},
		{"biscuit_a": 2, "biscuit_b": 1, "knife": 1, "parcel": 0},
		{"biscuit_a": 2, "biscuit_b": 2, "knife": 2, "parcel": 0},
		{"biscuit_a": 2, "biscuit_b": 2, "knife": 2, "parcel": 0}]
	var parcel_rests: Array[String] = ["near", "central", "central", "far"]
	_expect(state.checkpoint == checkpoint and state.sizes == expected_sizes[checkpoint], "Checkpoint %d reconstructs its authored stable sizes" % checkpoint)
	_expect(state.carried == "" and state.sockets == {"biscuit_a": "step", "biscuit_b": "ballast", "knife": "pivot", "parcel": parcel_rests[checkpoint]}, "Checkpoint %d restores the parcel only to an earned safe rest" % checkpoint)
	_expect(state.central_reached == (checkpoint >= 1) and state.delivered == (checkpoint == 3) and not state.completed, "Checkpoint %d preserves earned transport and keeps flag completion separate" % checkpoint)


func _round_trip(state, label: String) -> void:
	var data: Dictionary = state.to_dict()
	var restored = State.new()
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	_expect(typeof(parsed) == TYPE_DICTIONARY and restored.restore(parsed), label + " restores through JSON")
	_expect(restored.to_dict() == data and not restored.recovered_carry, label + " retains the current resting experiment")


func _ok(result: Dictionary, message: String) -> void:
	_expect(result.size() == 2 and typeof(result.get("ok")) == TYPE_BOOL and result.get("ok") == true and typeof(result.get("message")) == TYPE_STRING and not result.get("message").is_empty(), message)


func _bad(result: Dictionary, message: String) -> void:
	_expect(result.size() == 2 and typeof(result.get("ok")) == TYPE_BOOL and result.get("ok") == false and typeof(result.get("message")) == TYPE_STRING and not result.get("message").is_empty(), message)


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
