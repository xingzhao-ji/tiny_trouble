extends "res://tests/chapter/capture_crumb_art.gd"
## UNVERIFIED WIP — content expansion paused before Godot parse, native bounds or visual review.
## Authored W01S04 studio. Run only after the shared renderer slot is released.
## Isolated factory geometry checks and native stills; no stage or performance claim.
const JamArt = preload("res://scripts/chapter/jam_art.gd")
var pixels := Vector2i(1280, 720)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this art studio with a native renderer after profiling completes")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://evidence/jam_art"))
	report["display_driver"] = DisplayServer.get_name()
	report["engine"] = Engine.get_version_info().string
	_validate()
	_studio()
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		pixels = resolution
		root.size = pixels
		await _biscuits()
		await _knife_states()
		await _seed_states()
		await _printed_details()
	report["result"] = "PASS" if failures == 0 else "FAIL"
	var file := FileAccess.open("res://evidence/jam_art/art_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("JAM ART: ", report["result"], " / ", report["checks"].size(), " checks")
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _close(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001

func _validate() -> void:
	for dimensions in [Vector2(1.05, 0.09), Vector2(0.42, 0.16)]:
		for ratio in [0.5, 1.0, 2.0]:
			var disk := JamArt.biscuit(dimensions.x, dimensions.y)
			disk.scale = Vector3.ONE * ratio
			var bounds := _bounds(disk)
			var key := "biscuit_" + str(dimensions.x) + "_" + str(ratio)
			report["bounds"][key] = _bounds_json(bounds)
			_check(_close(bounds.position.y, 0) and _close(bounds.end.y, dimensions.y * ratio), key + " floor and top match the actual mesh")
			_check(_close(bounds.size.x, dimensions.x * 2 * ratio) and _close(bounds.size.z, dimensions.x * 2 * ratio), key + " retains exact cardinal diameter")
			var top_bounds := _bounds(disk.get_node("ImpressedTop"))
			_check(top_bounds.position.y < dimensions.y and _close(top_bounds.end.y, dimensions.y), key + " pattern is recessed below a clear top datum")
			disk.free()
	for ratio in [0.5, 1.0, 2.0]:
		var knife := JamArt.butter_knife()
		knife.scale = Vector3.ONE * ratio
		var bounds := _bounds(knife)
		report["bounds"]["knife_" + str(ratio)] = _bounds_json(bounds)
		_check(_close(bounds.position.x, -0.95 * ratio) and _close(bounds.end.x, 2.1 * ratio), "Knife " + str(ratio) + " extends around hinge with required reach")
		_check(_close(bounds.position.y, -0.06 * ratio) and _close(bounds.end.y, 0) and _close(bounds.size.z, 0.86 * ratio), "Knife " + str(ratio) + " clear top / underside / width")
		knife.free()
	var knife := JamArt.butter_knife()
	var blade: Node3D = knife.get_node("Blade")
	var blade_bounds := _bounds(blade.get_node("BladeSurface"))
	var handle_bounds := _bounds(blade.get_node("HandleSurface"))
	_check(_close(blade_bounds.position.x, 0) and _close(blade_bounds.end.x, 2.1) and _close(blade_bounds.size.z, 0.86), "BladeSurface is X0..2.1 / Z±.43")
	_check(_close(handle_bounds.position.x, -0.95) and _close(handle_bounds.end.x, 0) and _close(handle_bounds.size.z, 0.68), "HandleSurface is X−.95..0 / Z±.34")
	_check(blade.position.is_equal_approx(Vector3.ZERO) and blade.has_node("BallastAnchor") and blade.has_node("TipAnchor"), "Blade is the independent origin hinge with two placement anchors")
	_check(blade.get_node("BallastAnchor").position.is_equal_approx(Vector3(-0.6, 0, 0)), "BallastAnchor sits on the handle top at−.6")
	_check(blade.get_node("TipAnchor").position.is_equal_approx(Vector3(2.1, 0, 0)), "TipAnchor sits at2.1 on the blade top datum")
	blade.rotation.z = 0.25
	var tip: Vector3 = blade.transform * blade.get_node("TipAnchor").position
	var ballast: Vector3 = blade.transform * blade.get_node("BallastAnchor").position
	_check(_close(tip.y, sin(0.25) * 2.1) and _close(ballast.y, -sin(0.25) * 0.6), "Positive leaf rotation raises blade and depresses ballast handle")
	knife.free()
	var rest := JamArt.knife_rest()
	var rest_bounds := _bounds(rest)
	var axle_bounds := _bounds(rest.get_node("Axle"))
	_check(_close(rest_bounds.position.y, 0), "Optional knife rest has floor pivot")
	_check(_close(rest.get_node("HingeAnchor").position.y - 0.06, axle_bounds.end.y), "Level knife underside meets support axle at optional rest anchor")
	report["bounds"]["knife_rest"] = _bounds_json(rest_bounds)
	rest.free()
	for ratio in [0.5, 1.0, 2.0]:
		var parcel := JamArt.seed_parcel()
		parcel.scale = Vector3.ONE * ratio
		var bounds := _bounds(parcel)
		report["bounds"]["seed_parcel_" + str(ratio)] = _bounds_json(bounds)
		_check(_close(bounds.position.y, 0), "Seed parcel " + str(ratio) + " keeps floor pivot")
		_check(bounds.size.is_equal_approx(Vector3(0.62, 0.56, 0.58) * ratio), "Seed parcel " + str(ratio) + " remains inside required normal dimensions")
		_check(parcel.has_node("SeedEmblem/LeafL") and parcel.has_node("SeedEmblem/LeafR") and parcel.has_node("SeedEmblem/TopSeed"), "Seed parcel " + str(ratio) + " includes front and top seed identity")
		parcel.free()
	var prints := JamArt.jam_prints()
	var print_bounds := _bounds(prints)
	_check(print_bounds.position.y >= -0.0001 and print_bounds.end.y <= 0.0201, "Jam impressions remain a thin surface detail")
	_check(prints.has_node("SmallPrint") and prints.has_node("NormalPrint") and prints.has_node("LargePrint"), "Jam prints expose three independent size marks")
	report["bounds"]["jam_prints"] = _bounds_json(print_bounds)
	prints.free()
	var helper := JamArt.crumb_helper()
	_check(helper.position.is_equal_approx(Vector3.ZERO) and helper.has_node("WaveArm/Hand"), "Reused crumb helper keeps independent floor / wave pivots")
	helper.free()

func _biscuits() -> void:
	caption.text = "TINY TROUBLE / W01S04 ART\nScalloped biscuit platforms · Small / Normal / Large · recessed stamps"
	for i in range(3):
		var ratio: float = [0.5, 1.0, 2.0][i]
		var disk := JamArt.biscuit()
		disk.position = Vector3([-3.6, -1.3, 2.15][i], 0, 0)
		disk.scale = Vector3.ONE * ratio
		content.add_child(disk)
		var ballast := JamArt.biscuit(0.42, 0.16)
		ballast.position = Vector3([-3.6, -1.3, 2.15][i], 0, 2.35)
		ballast.scale = Vector3.ONE * ratio
		content.add_child(ballast)
	camera.size = 8.0
	camera.position = Vector3(7, 10, 13)
	camera.look_at(Vector3(-0.35, 0.2, 0.55))
	await _capture("biscuit_states")
	_clear()

func _knife_states() -> void:
	caption.text = "TINY TROUBLE / W01S04 ART\nButter knife · hinge-scaled sizes / raised blade / fixed ballast scale"
	for i in range(3):
		var ratio: float = [0.5, 1.0, 2.0][i]
		var knife := JamArt.butter_knife()
		knife.position = Vector3(-1.0, 0.16, -2.5 + i * 1.5)
		knife.scale = Vector3.ONE * ratio
		content.add_child(knife)
	var raised := JamArt.butter_knife()
	raised.position = Vector3(-1.0, 0.72, 2.25)
	raised.scale = Vector3.ONE * 2.0
	raised.get_node("Blade").rotation.z = 0.20
	content.add_child(raised)
	var ballast := JamArt.biscuit(0.42, 0.16)
	ballast.scale = Vector3.ONE * 2.0
	content.add_child(ballast)
	ballast.global_transform = raised.get_node("Blade/BallastAnchor").global_transform
	# Global basis above inherits knife size; explicit ratio remains exactly2.
	var pip := Art.pip()
	pip.position = Vector3(1.0, 0.72 + 2.0 * tan(0.20), 2.25)
	pip.rotation.z = 0.20
	content.add_child(pip)
	camera.size = 7.1
	camera.position = Vector3(8, 10, 14)
	camera.look_at(Vector3(0.55, 0.3, 0))
	await _capture("knife_states")
	_clear()

func _seed_states() -> void:
	caption.text = "TINY TROUBLE / W01S04 ART\nWrapped seed parcel · Small / Normal / Large · clear sprout emblem"
	for i in range(3):
		var parcel := JamArt.seed_parcel()
		parcel.position = Vector3([-1.4, -0.5, 1.0][i], 0, 0)
		parcel.scale = Vector3.ONE * [0.5, 1.0, 2.0][i]
		content.add_child(parcel)
	camera.size = 3.5
	camera.position = Vector3(4, 3.4, 7)
	camera.look_at(Vector3(0, 0.45, 0))
	await _capture("seed_states")
	_clear()

func _printed_details() -> void:
	caption.text = "TINY TROUBLE / W01S04 ART\nExperiment prints / reused crumb helper / optional hinge rest"
	Art._box(content, Vector3(-1.0, 0.015, 0), Vector3(3.0, 0.03, 1.7), Art.CORAL.lightened(0.08), 0.014, 0.35)
	var prints := JamArt.jam_prints()
	prints.position = Vector3(-1.0, 0.031, -0.15)
	content.add_child(prints)
	var helper := JamArt.crumb_helper()
	helper.position = Vector3(0.4, 0, 0.95)
	helper.get_node("WaveArm").rotation.z = 0.3
	content.add_child(helper)
	var rest := JamArt.knife_rest()
	rest.position = Vector3(1.6, 0, -0.25)
	content.add_child(rest)
	camera.size = 4.6
	camera.position = Vector3(6, 5.4, 9)
	camera.look_at(Vector3(-0.05, 0.15, 0.25))
	await _capture("printed_details")
	_clear()

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://evidence/jam_art/" + name + "_" + str(pixels.x) + ".png"
	var image := root.get_texture().get_image()
	_check(image.get_size() == pixels, "Native capture dimensions match " + str(pixels))
	_check(image.save_png(path) == OK, "Saved " + name + " " + str(pixels.x))
	report["captures"].append({"path": path, "pixels": [image.get_width(), image.get_height()], "kind": "actual native Godot studio; illustrative asset arrangement, no stage or performance claim"})
