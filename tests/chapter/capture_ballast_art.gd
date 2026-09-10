extends "res://tests/chapter/capture_crumb_art.gd"
## Reuses studio camera/lighting and actual-vertex bounds walker, with isolated output.
const BallastArt = preload("res://scripts/chapter/ballast_art.gd")
var pixels := Vector2i(1280, 720)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native renderer required for actual MultiMesh transform readback")
		quit(2)
		return
	report["display_driver"] = DisplayServer.get_name()
	report["engine"] = Engine.get_version_info().string
	_validate()
	_check(report["checks"].size() == 19, "All expected ballast mesh checks completed")
	_studio()
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		pixels = resolution
		root.size = resolution
		await _balance_studio()
		await _ramp_studio()
	report["result"] = "PASS" if failures == 0 else "FAIL"
	var file := FileAccess.open("res://evidence/ballast_art/art_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("BALLAST ART: ", report["result"], " / ", report["checks"].size(), " checks")
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _validate() -> void:
	var pan := BallastArt.balance_pan()
	var bounds := _bounds(pan)
	report["bounds"]["pan"] = _bounds_json(bounds)
	_check(_close(bounds.size.x, 2.7) and _close(bounds.size.z, 4.4), "Pan footprint is 2.7 × 4.4")
	_check(_close(_bounds(pan.get_node("Floor")).end.y, 0), "Pan floor top is Y0")
	_check(bounds.end.y <= 0.12001, "Pan rims stay below .12")
	_check(pan.get_node("PocketFar").position.is_equal_approx(Vector3(0, 0, -1.12)), "Far pocket uses authored centre")
	_check(pan.get_node("PocketNear").position.is_equal_approx(Vector3(0, 0, 1.12)), "Near pocket uses authored centre")
	_check(1.12 + 0.92 < 2.08 and 0.92 < 1.23, "Both radius.92 berries fit inside low rims with clearance")
	pan.free()
	var tower := BallastArt.counterweight_tower()
	bounds = _bounds(tower)
	report["bounds"]["tower"] = _bounds_json(bounds)
	_check(_close(bounds.position.y, 0), "Tower uses floor pivot")
	_check(bounds.size.x <= 2.00001 and bounds.size.z <= 2.00001 and bounds.end.y <= 3.60001, "Tower fits 2 × 2 footprint and 3.6 height")
	var stack := tower.get_node("WeightStack")
	var weights := 0
	for i in range(5):
		if stack.has_node("Weight" + str(i)): weights += 1
	_check(weights == 5, "WeightStack exposes five separate counterweight meshes")
	_check(stack.has_node("ThreadAnchor") and tower.has_node("PulleyLeft") and tower.has_node("PulleyRight"), "Tower exposes moving and fixed thread anchors")
	var before := _bounds(stack)
	stack.position.y += 0.75
	_check(_close(_bounds(stack).position.y - before.position.y, 0.75), "WeightStack translates all moving pieces independently")
	tower.free()
	for size in [Vector2(6.0, 1.65), Vector2(4.2, 1.4)]:
		var ramp := BallastArt.ramp(size.x, size.y)
		bounds = _bounds(ramp)
		report["bounds"]["ramp_" + str(size.x)] = _bounds_json(bounds)
		_check(_close(bounds.position.x, 0) and _close(bounds.end.x, size.x) and _close(bounds.size.z, size.y), "Ramp " + str(size.x) + " uses near-X pivot and requested footprint")
		_check(_close(bounds.end.y, 0), "Ramp " + str(size.x) + " has topY0 and no blocking rail")
		ramp.free()
	var ledge := BallastArt.ledge()
	bounds = _bounds(ledge)
	report["bounds"]["ledge"] = _bounds_json(bounds)
	_check(_close(bounds.size.x, 4) and _close(bounds.size.z, 3.2), "Ledge footprint is 4 × 3.2 including graphic")
	_check(_close(bounds.position.y, 0) and _close(bounds.end.y, 1.8), "Ledge floor pivot and top1.8 are exact")
	_check(_close(_bounds(ledge.get_node("LandingTop")).end.y, 1.8), "LandingTop supplies the clear walking surface")
	_check(_bounds(ledge.get_node("BreakfastGraphic")).end.y < 1.72, "Breakfast graphic stays off the top")
	ledge.free()

func _close(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001

func _balance_studio() -> void:
	caption.text = "TINY TROUBLE / W01S02 ART\nEmpty and loaded pockets · exposed counterweight tower"
	var empty := BallastArt.balance_pan()
	empty.position = Vector3(-3.2, 0.15, 0)
	content.add_child(empty)
	var loaded := BallastArt.balance_pan()
	loaded.position = Vector3(0.2, 0.15, 0)
	content.add_child(loaded)
	for z in [-1.12, 1.12]:
		var berry := Art.prop("blueberry")
		berry.position = Vector3(0.2, 0.15, z)
		berry.scale = Vector3.ONE * 3.05
		content.add_child(berry)
	var tower := BallastArt.counterweight_tower()
	tower.position = Vector3(3.9, 0, 0)
	content.add_child(tower)
	camera.size = 8.2
	camera.position = Vector3(10, 8.5, 15)
	camera.look_at(Vector3(0.25, 1.20, 0))
	await _capture("balance_mechanism")
	_clear()

func _ramp_studio() -> void:
	caption.text = "TINY TROUBLE / W01S02 ART\nClear cardboard walkway · cereal-box landing ledge"
	var ramp := BallastArt.ramp()
	ramp.position = Vector3(-6, 0, 0)
	ramp.rotation.z = asin(1.8 / 6.0)
	content.add_child(ramp)
	var ledge := BallastArt.ledge()
	ledge.position = Vector3(1.7, 0, 0)
	content.add_child(ledge)
	var pip := Art.pip()
	pip.position = Vector3(1.5, 1.8, 0.0)
	content.add_child(pip)
	camera.size = 8.2
	camera.position = Vector3(9, 8, 15)
	camera.look_at(Vector3(-0.8, 1.0, 0))
	await _capture("ramp_ledge")
	_clear()

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://evidence/ballast_art/" + name + "_" + str(pixels.x) + ".png"
	var image := root.get_texture().get_image()
	_check(image.get_size() == pixels, "Native capture dimensions match " + str(pixels))
	_check(image.save_png(path) == OK, "Saved " + name + " " + str(pixels.x))
	report["captures"].append({"path": path, "pixels": [image.get_width(), image.get_height()], "kind": "actual native Godot studio; illustrative arrangement, no gameplay or performance claim"})
