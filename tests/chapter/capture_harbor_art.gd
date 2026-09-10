extends "res://tests/chapter/capture_crumb_art.gd"
## Native, isolated Milk Harbor asset checks; no stage gameplay or performance claim.
const HarborArt = preload("res://scripts/chapter/harbor_art.gd")
var pixels := Vector2i(1280, 720)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native renderer required for actual MultiMesh transform readback")
		quit(2)
		return
	report["display_driver"] = DisplayServer.get_name()
	report["engine"] = Engine.get_version_info().string
	_validate()
	_studio()
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		pixels = resolution
		root.size = resolution
		await _raft_states()
		await _parcel_states()
		await _dock_friends()
	report["result"] = "PASS" if failures == 0 else "FAIL"
	var file := FileAccess.open("res://evidence/harbor_art/art_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("HARBOR ART: ", report["result"], " / ", report["checks"].size(), " checks")
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _validate() -> void:
	for ratio in [0.5, 1.0, 2.0]:
		var raft := HarborArt.cereal_raft()
		raft.scale = Vector3.ONE * ratio
		var bounds := _bounds(raft)
		report["bounds"]["raft_" + str(ratio)] = _bounds_json(bounds)
		_check(_close(bounds.size.x, 1.6 * ratio) and _close(bounds.size.z, 1.6 * ratio), "Raft " + str(ratio) + " retains required cereal-ring footprint")
		_check(_close(bounds.position.y, 0) and _close(bounds.end.y, 0.30 * ratio), "Raft " + str(ratio) + " has floor pivot and deck-top height")
		raft.free()
	var raft := HarborArt.cereal_raft()
	var ring: MeshInstance3D = raft.get_node("CerealRing")
	var inner := 10.0
	for vertex: Vector3 in ring.mesh.get_faces():
		inner = minf(inner, Vector2(vertex.x, vertex.z).length())
	_check(_close(inner, 0.43) and _close(_bounds(ring).size.y, 0.24), "Cereal torus has .43 hole radius and .24 height")
	var deck_bounds := _bounds(raft.get_node("Deck"))
	_check(_close(deck_bounds.size.x, 1.15) and _close(deck_bounds.size.z, 0.70) and _close(deck_bounds.end.y, 0.30), "Clear Deck footprint is 1.15 × .70 with top .30")
	_check(raft.get_node("DeckAnchor").position.is_equal_approx(Vector3(0, 0.30, 0)), "DeckAnchor exposes the normal walking datum")
	var obstruction := false
	for child in raft.get_children():
		if child.name in ["Deck", "DeckAnchor"]: continue
		var vertices: Array[Vector3] = []
		_collect(child, Transform3D.IDENTITY, vertices)
		for vertex in vertices:
			if absf(vertex.x) <= 0.575 and absf(vertex.z) <= 0.35 and vertex.y > 0.30001:
				obstruction = true
	_check(not obstruction, "Bow, threads and grains leave the deck top unobstructed")
	_check(raft.get_node("ToastedGrains").multimesh.instance_count == 72 and raft.get_node("WaferEdges").multimesh.instance_count == 36, "Raft grains and wafer-edge marks use two MultiMeshes")
	raft.free()
	for ratio in [0.5, 1.0, 2.0]:
		var parcel := HarborArt.cargo_parcel()
		parcel.scale = Vector3.ONE * ratio
		var bounds := _bounds(parcel)
		report["bounds"]["parcel_" + str(ratio)] = _bounds_json(bounds)
		_check(_close(bounds.position.y, 0), "Parcel " + str(ratio) + " keeps floor pivot")
		_check(bounds.size.is_equal_approx(Vector3(0.58, 0.60, 0.58) * ratio), "Parcel " + str(ratio) + " matches .58 × .60 × .58 dimensions")
		parcel.free()
	var dock := HarborArt.folded_spoon_dock()
	var hinged: Node3D = dock.get_node("HingedDock")
	var bounds := _bounds(hinged)
	report["bounds"]["dock_hinged_open"] = _bounds_json(bounds)
	report["bounds"]["dock_entire_open"] = _bounds_json(_bounds(dock))
	_check(_close(bounds.position.x, -2.2) and _close(bounds.end.x, 0) and _close(bounds.size.z, 1.1), "Dock extends −X 2.2 with width1.1")
	_check(_close(bounds.end.y, 0) and _close(bounds.position.y, -0.12), "Dock top datum Y0 and underside −.12")
	_check(hinged.position.is_equal_approx(Vector3.ZERO), "HingedDock pivots at far-shore origin")
	var fixed_before: Transform3D = dock.get_node("FixedHinge").transform
	hinged.rotation.z = -PI * 0.5
	bounds = _bounds(hinged)
	report["bounds"]["dock_hinged_folded"] = _bounds_json(bounds)
	_check(_close(bounds.end.y, 2.2) and dock.get_node("FixedHinge").transform == fixed_before, "Negative Z fold raises tip to2.2 and leaves axle fixed")
	var fixed_bounds := _bounds(dock.get_node("FixedHinge"))
	_check(fixed_bounds.size.x <= 0.35001 and fixed_bounds.size.z <= 0.35001, "Fixed hinge fits .35 base footprint")
	dock.free()
	var friends := HarborArt.cereal_friends()
	bounds = _bounds(friends)
	report["bounds"]["friends"] = _bounds_json(bounds)
	_check(bounds.size.x <= 1.50001 and bounds.size.z <= 1.00001 and bounds.size.y <= 0.70001, "Cereal friends fit 1.5 × .7 × 1")
	_check(_close(bounds.position.y, 0), "Cereal friends keep floor contact")
	_check(friends.has_node("CerealL/WaveArm/Hand") and friends.has_node("CerealR/WaveArm/Hand"), "Friends expose independent WaveArm/Hand pivots")
	var right_before: Transform3D = friends.get_node("CerealR/WaveArm").transform
	friends.get_node("CerealL/WaveArm").rotation.z = 0.4
	_check(friends.get_node("CerealR/WaveArm").transform == right_before, "Left wave leaves right wave independent")
	friends.free()

func _close(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001

func _raft_states() -> void:
	caption.text = "TINY TROUBLE / W01S03 ART\nCereal raft · Small 0.5 / Normal 1 / Large 2 · fixed-size cargo"
	for i in range(3):
		var raft := HarborArt.cereal_raft()
		var ratio: float = [0.5, 1.0, 2.0][i]
		raft.position = Vector3([-3.5, -1.8, 1.65][i], 0, 0)
		raft.scale = Vector3.ONE * ratio
		content.add_child(raft)
	var pip := Art.pip()
	pip.position = Vector3(1.06, 0.60, 0)
	content.add_child(pip)
	var cargo := HarborArt.cargo_parcel()
	cargo.position = Vector3(2.24, 0.60, 0)
	content.add_child(cargo)
	camera.size = 7.2
	camera.position = Vector3(7, 9, 15)
	camera.look_at(Vector3(-0.6, 0.4, 0))
	await _capture("raft_states")
	_clear()

func _parcel_states() -> void:
	caption.text = "TINY TROUBLE / W01S03 ART\nCream sugar parcel · Small 0.5 / Normal 1 / Large 2"
	for i in range(3):
		var parcel := HarborArt.cargo_parcel()
		parcel.position = Vector3([-1.40, -0.5, 1.0][i], 0, 0)
		parcel.scale = Vector3.ONE * [0.5, 1.0, 2.0][i]
		content.add_child(parcel)
	camera.size = 3.5
	camera.position = Vector3(4, 3.8, 7)
	camera.look_at(Vector3(0, 0.48, 0))
	await _capture("parcel_states")
	_clear()

func _dock_friends() -> void:
	caption.text = "TINY TROUBLE / W01S03 ART\nSpoon dock · open and folded hinge / cereal friends"
	var open := HarborArt.folded_spoon_dock()
	open.position = Vector3(-0.7, 0.20, 0.5)
	content.add_child(open)
	var folded := HarborArt.folded_spoon_dock()
	folded.position = Vector3(1.1, 0.20, -0.85)
	folded.get_node("HingedDock").rotation.z = -PI * 0.42
	content.add_child(folded)
	var friends := HarborArt.cereal_friends()
	friends.position = Vector3(0.9, 0, 1.2)
	friends.get_node("CerealL/WaveArm").rotation.z = 0.35
	friends.get_node("CerealR/WaveArm").rotation.z = -0.20
	content.add_child(friends)
	camera.size = 4.9
	camera.position = Vector3(6, 5.8, 11)
	camera.look_at(Vector3(-0.4, 0.73, 0.3))
	await _capture("dock_friends")
	_clear()

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://evidence/harbor_art/" + name + "_" + str(pixels.x) + ".png"
	var image := root.get_texture().get_image()
	_check(image.get_size() == pixels, "Native capture dimensions match " + str(pixels))
	_check(image.save_png(path) == OK, "Saved " + name + " " + str(pixels.x))
	report["captures"].append({"path": path, "pixels": [image.get_width(), image.get_height()], "kind": "actual native Godot studio; illustrative asset arrangement, no gameplay or performance claim"})
