extends RefCounted
class_name TTChapterArt
## Chapter art remains editable procedural geometry. No collision or gameplay state.
## Sugar and freestanding details use floor-centred pivots and face +Z.
## The tray intentionally uses the chapter's local-world coordinates.

const Art = preload("res://scripts/art.gd")
const SUGAR_SIZE := 1.35
const TRAY_MIN := Vector2(-10.8, 1.8)
const TRAY_MAX := Vector2(-7.4, 4.6)
const TRAY_FLOOR_TOP := 0.06
const TRAY_WALL_HEIGHT := 1.0
const TRAY_WALL_THICKNESS := 0.12

static func sugar_cube() -> Node3D:
	var root := Node3D.new()
	root.name = "SugarCubeArt"
	var sugar := Art.CREAM.lerp(Color.WHITE, 0.40)
	Art._box(root, Vector3(0, 0.665, 0), Vector3(1.31, 1.33, 1.31), sugar, 0.135, 0.97).name = "Body"
	# The broad, shallow crystalline faces and individual grains stay inside 1.35³.
	# Six unrotated centre grains reach the exact bound; none extends below y=0.
	var grains := MultiMesh.new()
	grains.transform_format = MultiMesh.TRANSFORM_3D
	grains.use_colors = true
	grains.mesh = _crystal_mesh()
	grains.instance_count = 150
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	var rng := RandomNumberGenerator.new()
	rng.seed = 71319
	var index := 0
	for face in range(3):
		var normal := axes[face]
		var u := axes[(face + 1) % 3]
		var v := axes[(face + 2) % 3]
		for side in [-1.0, 1.0]:
			for grain in range(25):
				var radius := 0.020 if grain == 0 else rng.randf_range(0.011, 0.019)
				var p: Vector3 = normal * side * 0.655 + Vector3(0, 0.675, 0)
				var basis := Basis.IDENTITY
				if grain != 0:
					p += u * rng.randf_range(-0.485, 0.485) + v * rng.randf_range(-0.485, 0.485)
					basis = Basis.from_euler(Vector3(rng.randf(), rng.randf(), rng.randf()) * TAU)
				grains.set_instance_transform(index, Transform3D(basis.scaled(Vector3.ONE * radius), p))
				grains.set_instance_color(index, sugar.lerp(Color.WHITE, rng.randf_range(0.02, 0.28)))
				index += 1
	var crystals := MultiMeshInstance3D.new()
	crystals.name = "CrystalGrains"
	crystals.multimesh = grains
	crystals.material_override = _vertex_material()
	crystals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(crystals)
	var facets := Art._add(root, _sugar_facets(), Color.WHITE, Vector3(0, 0.675, 0))
	facets.name = "QuietFacets"
	facets.material_override = _vertex_material()
	facets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

static func paper_tray() -> Node3D:
	var root := Node3D.new()
	root.name = "SugarCorridorTray"
	var paper := Art.CREAM.lerp(Color.WHITE, 0.16)
	Art._box(root, Vector3(-9.1, 0.03, 3.2), Vector3(3.4, 0.06, 2.8), paper, 0.023, 0.99).name = "Floor"
	for z in [1.8, 4.6]:
		var wall := Art._box(root, Vector3(-9.1, 0.5, z), Vector3(3.4, 1.0, 0.12), paper, 0.045, 0.99)
		wall.name = "WallFar" if z < 3.0 else "WallNear"
		Art._box(root, Vector3(-9.1, 0.955, z), Vector3(3.32, 0.052, 0.128), Art.TEAL.lerp(paper, 0.4), 0.02, 0.98).name = "RimFar" if z < 3.0 else "RimNear"
		# Fold line belongs on the inward face, above the paper floor.
		var inward := 0.062 if z < 3.0 else -0.062
		Art._box(root, Vector3(-9.1, 0.115, z + inward), Vector3(3.24, 0.012, 0.009), Color("d6c7af"), 0.003, 1.0)
	Art._box(root, Vector3(-10.8, 0.5, 3.2), Vector3(0.12, 1.0, 2.8), paper, 0.045, 0.99).name = "WallClosed"
	Art._box(root, Vector3(-10.8, 0.955, 3.2), Vector3(0.128, 0.052, 2.74), Art.TEAL.lerp(paper, 0.4), 0.02, 0.98).name = "RimClosed"
	# A short crease at the open lip gives the low floor a readable thickness.
	Art._box(root, Vector3(-7.414, 0.062, 3.2), Vector3(0.027, 0.009, 2.61), Color("d6c7af"), 0.003, 1.0).name = "OpenLipCrease"
	var fibres := MultiMesh.new()
	fibres.transform_format = MultiMesh.TRANSFORM_3D
	fibres.mesh = Art._round_mesh(Vector3(0.08, 0.002, 0.004), 0.0008)
	fibres.instance_count = 22
	var rng := RandomNumberGenerator.new()
	rng.seed = 91942
	for i in range(fibres.instance_count):
		var p := Vector3(rng.randf_range(-10.55, -7.6), 0.0615, rng.randf_range(2.02, 4.38))
		fibres.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.12, 0.12)), p))
	var grain := MultiMeshInstance3D.new()
	grain.name = "PaperFibres"
	grain.multimesh = fibres
	grain.material_override = Art._mat(paper.lerp(Color("d6c7af"), 0.3), 1.0)
	grain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(grain)
	return root

static func crumb_friends() -> Node3D:
	var root := Node3D.new()
	root.name = "CrumbFriends"
	for i in range(2):
		var crumb := Node3D.new()
		crumb.name = "CrumbL" if i == 0 else "CrumbR"
		crumb.position = Vector3(-0.35 if i == 0 else 0.35, 0, 0.045 if i == 0 else -0.045)
		root.add_child(crumb)
		var color := Art.AMBER if i == 0 else Art.AMBER.lerp(Art.CREAM, 0.35)
		Art._box(crumb, Vector3(0, 0.205, 0), Vector3(0.43, 0.29, 0.34), color, 0.12, 0.95).name = "Body"
		for x in [-0.115, 0.115]:
			Art._ball(crumb, Vector3(x, 0.045, 0.045), Vector3(0.11, 0.09, 0.14), Art.TEAL).name = "FootL" if x < 0 else "FootR"
			Art._ball(crumb, Vector3(x * 0.68, 0.245, 0.163), Vector3(0.039, 0.059, 0.025), Art.SLATE, 0.65).name = "EyeL" if x < 0 else "EyeR"
			Art._ball(crumb, Vector3(x, 0.19, 0.17), Vector3(0.045, 0.02, 0.01), Art.CORAL)
		for p in [Vector3(-0.10, 0.351, -0.02), Vector3(0.04, 0.351, 0.06), Vector3(0.115, 0.338, -0.07)]:
			Art._ball(crumb, p, Vector3(0.024, 0.009, 0.019), color.darkened(0.12), 1.0)
		var arm := Node3D.new()
		arm.name = "WaveArm"
		arm.position = Vector3(-0.20 if i == 0 else 0.20, 0.25, 0.04)
		crumb.add_child(arm)
		var direction := -1.0 if i == 0 else 1.0
		Art._line(arm, Vector3.ZERO, Vector3(direction * 0.07, 0.105, 0), 0.018, Art.TEAL)
		Art._ball(arm, Vector3(direction * 0.078, 0.118, 0), Vector3(0.06, 0.073, 0.045), Art.TEAL).name = "Hand"
	return root

static func paper_pinwheel() -> Node3D:
	var root := Node3D.new()
	root.name = "PaperPinwheel"
	Art._box(root, Vector3(0, 0.04, 0), Vector3(0.36, 0.08, 0.28), Art.CREAM, 0.035, 0.99).name = "PaperFoot"
	Art._line(root, Vector3(0, 0.07, -0.025), Vector3(0, 1.49, -0.025), 0.026, Art.AMBER).name = "Stem"
	var rotor := Node3D.new()
	rotor.name = "Rotor"
	rotor.position = Vector3(0, 1.48, 0.02)
	root.add_child(rotor)
	var blade_mesh := _pinwheel_blade()
	for i in range(4):
		var color: Color = [Art.TEAL, Art.CREAM, Art.CORAL, Art.CREAM][i]
		var blade := Art._add(rotor, blade_mesh, color, Vector3.ZERO, Vector3.ONE, 0.97)
		blade.name = "Blade" + str(i)
		blade.rotation.z = i * PI * 0.5
		var material := Art._mat(color, 0.97).duplicate() as StandardMaterial3D
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		blade.material_override = material
	Art._ball(rotor, Vector3(0, 0, 0.135), Vector3(0.15, 0.15, 0.08), Art.AMBER, 0.85).name = "Hub"
	Art._ball(rotor, Vector3(0, 0, 0.178), Vector3(0.046, 0.046, 0.015), Art.CREAM, 0.85).name = "Pin"
	return root

static func _vertex_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.97
	return material

static func _crystal_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	for triangle in [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]:
		_triangle(st, points[triangle[0]], points[triangle[2]], points[triangle[1]], Color.WHITE)
	return st.commit()

static func _sugar_facets() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	var tone := Art.CREAM.lerp(Color.WHITE, 0.49)
	for face in range(3):
		for side in [-1.0, 1.0]:
			var n: Vector3 = axes[face] * side
			var u := axes[(face + 1) % 3]
			var v: Vector3 = axes[(face + 2) % 3] * side
			for offset in [Vector2(-0.29, 0.19), Vector2(0.18, -0.21), Vector2(0.22, 0.30)]:
				var a: Vector3 = n * 0.6558 + u * (offset.x - 0.09) + v * (offset.y - 0.045)
				var b: Vector3 = n * 0.6558 + u * (offset.x + 0.05) + v * (offset.y - 0.09)
				var c: Vector3 = n * 0.657 + u * (offset.x + 0.1) + v * (offset.y + 0.07)
				_triangle(st, a, c, b, tone)
	return st.commit()

static func _pinwheel_blade() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hub := Vector3(0, 0, 0.045)
	var upper := Vector3(0.04, 0.58, 0.0)
	var tip := Vector3(0.55, 0.43, 0.005)
	var outer := Vector3(0.38, 0.045, 0.025)
	var fold := Vector3(0.19, 0.22, 0.13)
	_triangle(st, hub, upper, fold, Color.WHITE)
	_triangle(st, upper, tip, fold, Color.WHITE)
	_triangle(st, tip, outer, fold, Color.WHITE)
	_triangle(st, outer, hub, fold, Color.WHITE)
	return st.commit()

static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (c - a).cross(b - a).normalized()
	for vertex in [a, b, c]:
		st.set_color(color)
		st.set_normal(normal)
		st.add_vertex(vertex)
