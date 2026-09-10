extends SceneTree
## Native editable-art studio; no gameplay mutation and no performance claim.
const Art = preload("res://scripts/art.gd")
const ChapterArt = preload("res://scripts/chapter/chapter_art.gd")
var world: Node3D
var content: Node3D
var camera: Camera3D
var caption: Label
var report: Dictionary = {"checks": [], "bounds": {}, "captures": []}
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This studio requires a native renderer: headless dummy MultiMesh transform readback returns identity.")
		quit(2)
		return
	report["display_driver"] = DisplayServer.get_name()
	report["engine"] = Engine.get_version_info().string
	_validate()
	_check(report["checks"].size() == 16, "All expected geometry checks completed")
	if DisplayServer.get_name() != "headless":
		_studio()
		await _sugar_states()
		await _corridor()
		await _friends()
	report["result"] = "PASS" if failures == 0 else "FAIL"
	var f := FileAccess.open("res://evidence/crumb_art/art_report.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	print("CHAPTER ART: ", report["result"], " / ", report["checks"].size(), " checks")
	if world:
		world.queue_free()
		await process_frame
	quit(0 if failures == 0 else 1)

func _validate() -> void:
	for state in [0.35, 1.0, 2.0]:
		var sugar := ChapterArt.sugar_cube()
		sugar.scale = Vector3.ONE * state
		var bounds := _bounds(sugar)
		report["bounds"]["sugar_" + str(state)] = _bounds_json(bounds)
		_check(absf(bounds.position.y) < 0.00001, "Sugar " + str(state) + " has floor pivot")
		_check(bounds.size.is_equal_approx(Vector3.ONE * 1.35 * state), "Sugar " + str(state) + " is exactly 1.35 × state on every axis")
		_check(sugar.get_node("CrystalGrains").multimesh.instance_count == 150, "Sugar " + str(state) + " batches 150 grains into one instance node")
		sugar.free()
	var tray := ChapterArt.paper_tray()
	report["bounds"]["tray"] = _bounds_json(_bounds(tray))
	var floor: MeshInstance3D = tray.get_node("Floor")
	_check(floor.position.is_equal_approx(Vector3(-9.1, 0.03, 3.2)), "Tray floor uses required chapter coordinates")
	_check(floor.mesh.get_aabb().size.is_equal_approx(Vector3(3.4, 0.06, 2.8)), "Tray floor is 3.4 × .06 × 2.8")
	_check(tray.has_node("WallFar") and tray.has_node("WallNear") and tray.has_node("WallClosed") and not tray.has_node("WallOpen"), "Tray has three walls and open right edge")
	_check(is_equal_approx(2.8 - ChapterArt.TRAY_WALL_THICKNESS, 2.68), "Tray interior width is 2.68")
	tray.free()
	var friends := ChapterArt.crumb_friends()
	report["bounds"]["crumb_friends"] = _bounds_json(_bounds(friends))
	_check(friends.has_node("CrumbL/WaveArm/Hand") and friends.has_node("CrumbR/WaveArm/Hand"), "Crumb friends expose independent wave pivots")
	friends.free()
	var wheel := ChapterArt.paper_pinwheel()
	report["bounds"]["pinwheel"] = _bounds_json(_bounds(wheel))
	_check(wheel.get_node("Rotor").get_child_count() == 6, "Pinwheel Rotor contains four blades, hub and pin")
	_check(wheel.get_node("Rotor").position.is_equal_approx(Vector3(0, 1.48, 0.02)), "Pinwheel rotation axis is local Z at height 1.48")
	wheel.free()

func _bounds(node: Node3D) -> AABB:
	var vertices: Array[Vector3] = []
	_collect(node, Transform3D.IDENTITY, vertices)
	var result := AABB(vertices[0], Vector3.ZERO)
	for vertex in vertices:
		result = result.expand(vertex)
	return result

func _collect(node: Node3D, ancestor: Transform3D, vertices: Array[Vector3]) -> void:
	var transform := ancestor * node.transform
	if node is MeshInstance3D:
		_mesh_vertices(node.mesh, transform, vertices)
	elif node is MultiMeshInstance3D:
		for i in range(node.multimesh.instance_count):
			_mesh_vertices(node.multimesh.mesh, transform * node.multimesh.get_instance_transform(i), vertices)
	for child in node.get_children():
		if child is Node3D:
			_collect(child, transform, vertices)

func _mesh_vertices(mesh: Mesh, transform: Transform3D, vertices: Array[Vector3]) -> void:
	for surface in range(mesh.get_surface_count()):
		for vertex in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			vertices.append(transform * vertex)

func _bounds_json(value: AABB) -> Dictionary:
	return {"minimum": [value.position.x, value.position.y, value.position.z], "maximum": [value.end.x, value.end.y, value.end.z], "size": [value.size.x, value.size.y, value.size.z]}

func _check(passed: bool, text: String) -> void:
	report["checks"].append({"passed": passed, "check": text})
	print("PASS " if passed else "FAIL ", text)
	if not passed:
		failures += 1

func _studio() -> void:
	root.size = Vector2i(1920, 1080)
	world = Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("eee1c8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f6ead7")
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -28, 0)
	light.light_color = Color("fff2dc")
	light.light_energy = 0.55
	light.shadow_enabled = true
	light.shadow_blur = 2.0
	world.add_child(light)
	Art._box(world, Vector3(0, -0.13, 0), Vector3(100, 0.24, 100), Color("d8bd8e"), 0.1, 0.98)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	world.add_child(camera)
	var ui := CanvasLayer.new()
	root.add_child(ui)
	caption = Label.new()
	caption.position = Vector2(55, 38)
	var font := FontVariation.new()
	font.base_font = load("res://assets/fonts/Nunito.ttf")
	font.variation_opentype = {"weight": 600}
	caption.add_theme_font_override("font", font)
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", Art.SLATE)
	ui.add_child(caption)
	content = Node3D.new()
	world.add_child(content)

func _clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func _sugar_states() -> void:
	caption.text = "TINY TROUBLE / CHAPTER ART\nSugar cube · Small 0.35 / Normal 1 / Large 2"
	for i in range(3):
		var sugar := ChapterArt.sugar_cube()
		sugar.position = Vector3([-3.4, -1.35, 1.8][i], 0, 0)
		sugar.scale = Vector3.ONE * [0.35, 1.0, 2.0][i]
		content.add_child(sugar)
	var pip := Art.pip()
	pip.position = Vector3(-4.7, 0, 0)
	content.add_child(pip)
	camera.size = 7.6
	camera.position = Vector3(8, 7.7, 13)
	camera.look_at(Vector3(-0.75, 0.65, 0))
	await _capture("sugar_states")
	_clear()

func _corridor() -> void:
	caption.text = "TINY TROUBLE / CHAPTER ART\nPaper corridor · Normal sugar / fixed wall dimensions"
	content.add_child(ChapterArt.paper_tray())
	var sugar := ChapterArt.sugar_cube()
	sugar.position = Vector3(-8.5, 0.06, 3.2)
	content.add_child(sugar)
	var pip := Art.pip()
	pip.position = Vector3(-10, 0.06, 3.2)
	content.add_child(pip)
	var friends := ChapterArt.crumb_friends()
	friends.position = Vector3(-7.7, 0, 5.3)
	content.add_child(friends)
	var wheel := ChapterArt.paper_pinwheel()
	wheel.position = Vector3(-10.9, 0, 1.55)
	content.add_child(wheel)
	camera.size = 6.4
	camera.position = Vector3(-4, 6.7, 11)
	camera.look_at(Vector3(-9, 0.93, 3.1))
	await _capture("paper_corridor")
	caption.text = "TINY TROUBLE / CHAPTER ART\nPaper corridor · Small sugar 0.35 / upper passage pose"
	sugar.scale = Vector3.ONE * 0.35
	pip.position = Vector3(-8.5, 0.06, 2.45)
	pip.rotation.y = PI * 0.5
	await _capture("paper_corridor_small")
	_clear()

func _friends() -> void:
	caption.text = "TINY TROUBLE / CHAPTER ART\nCrumb friends · independent WaveArm pivots / pinwheel Rotor"
	var friends := ChapterArt.crumb_friends()
	friends.position = Vector3(-0.8, 0, 0)
	content.add_child(friends)
	var wheel := ChapterArt.paper_pinwheel()
	wheel.position = Vector3(0.65, 0, -0.07)
	content.add_child(wheel)
	camera.size = 3.15
	camera.position = Vector3(2.0, 2.5, 7)
	camera.look_at(Vector3(0, 1.0, 0))
	await _capture("friendly_details")

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://evidence/crumb_art/" + name + ".png"
	var image := root.get_texture().get_image()
	var result := image.save_png(path)
	_check(result == OK, "Saved native studio " + name)
	report["captures"].append({"path": path, "pixels": [image.get_width(), image.get_height()], "kind": "actual native Godot studio capture; no gameplay or performance claim"})
