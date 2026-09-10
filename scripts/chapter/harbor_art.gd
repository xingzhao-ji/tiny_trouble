extends RefCounted
class_name TTHarborArt
## Milk Harbor's original editable toy assets. Runtime owns collision, water and motion.
## Raft/parcel/friends use floor pivots. Dock uses its far-shore hinge at local origin.
const Art = preload("res://scripts/art.gd")
const TOASTED := Color("cc964b")
const CRUMB := Color("efd094")
const PAPER := Color("f0dfbf")
const METAL := Color("b3c4c5")

static func cereal_raft() -> Node3D:
	var root := Node3D.new()
	root.name = "CerealRaft"
	# Twelve tube segments include exact top/bottom extrema at Y0/.24.
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.43
	mesh.outer_radius = 0.80
	mesh.rings = 48
	mesh.ring_segments = 12
	Art._add(root, mesh, TOASTED, Vector3(0, 0.12, 0), Vector3(1, 0.24 / 0.37, 1), 0.96).name = "CerealRing"
	var grains: Array[Vector3] = []
	for i in range(72):
		var a := float(i) * 2.39996323
		var radius := 0.61 + sin(float(i) * 1.79) * 0.10
		var tube_x := (radius - 0.615) / 0.185
		var height := 0.12 + sqrt(maxf(0, 1 - tube_x * tube_x)) * 0.12
		grains.append(Vector3(cos(a) * radius, height - 0.003, sin(a) * radius))
	_instances(root, Art._round_mesh(Vector3(0.026, 0.011, 0.021), 0.004), grains, TOASTED.darkened(0.18), "ToastedGrains")
	# TT-028: a warmer baked-wafer value separates the deck from milk and paper cargo.
	# Blend only existing palette tones; retain the exact mesh, top datum and roughness.
	Art._box(root, Vector3(0, 0.267, 0), Vector3(1.15, 0.066, 0.70), PAPER.lerp(TOASTED, 0.35), 0.022, 0.95).name = "Deck"
	# Scored wafer edges sit below the clear top, keeping Pip/cargo space free.
	var flutes: Array[Vector3] = []
	for i in range(18):
		var x := -0.53 + float(i) * 1.06 / 17.0
		for z in [-0.35, 0.35]:
			flutes.append(Vector3(x, 0.265, z))
	_instances(root, Art._round_mesh(Vector3(0.014, 0.031, 0.007), 0.003), flutes, TOASTED, "WaferEdges")
	var ties := Node3D.new()
	ties.name = "TiedThreads"
	root.add_child(ties)
	for x in [-0.43, 0.43]:
		for direction in [-1.0, 1.0]:
			Art._line(ties, Vector3(x, 0.255, direction * 0.355), Vector3(x, 0.193, direction * 0.46), 0.008, Art.CREAM)
			Art._ball(ties, Vector3(x, 0.244, direction * 0.374), Vector3(0.032, 0.021, 0.028), Art.CREAM)
	# Bow is outside Deck's X extent, never an obstruction on its walking plane.
	var bow := Node3D.new()
	bow.name = "BowMarker"
	bow.position = Vector3(0.665, 0.24, 0)
	root.add_child(bow)
	for z in [-0.037, 0.037]:
		var loop := Art._torus(bow, Vector3(0, 0, z), 0.020, 0.037, Art.TEAL, Vector3(0.64, 0.48, 1), 0.90)
		loop.rotation.x = PI * 0.5
	Art._ball(bow, Vector3.ZERO, Vector3(0.040, 0.032, 0.028), Art.TEAL)
	_anchor(root, "DeckAnchor", Vector3(0, 0.30, 0))
	return root

static func cargo_parcel() -> Node3D:
	var root := Node3D.new()
	root.name = "CargoParcel"
	Art._box(root, Vector3(0, 0.28, 0), Vector3(0.56, 0.56, 0.56), PAPER, 0.085, 0.97).name = "WrappedSugar"
	# Two narrow bindings establish the parcel identity even in its Small state.
	var binding := Node3D.new()
	binding.name = "CoralTwine"
	root.add_child(binding)
	Art._add(binding, _twine_mesh(), Art.CORAL, Vector3.ZERO, Vector3.ONE, 0.90).name = "WrappedThreads"
	Art._ball(binding, Vector3(0, 0.583, 0), Vector3(0.058, 0.034, 0.054), Art.CORAL).name = "Knot"
	# Subtle folded-paper seams and a pale sugar corner, with no baked text.
	for direction in [-1.0, 1.0]:
		Art._line(root, Vector3(direction * 0.218, 0.435, 0.267), Vector3(direction * 0.095, 0.305, 0.280), 0.005, PAPER.darkened(0.09))
	Art._box(root, Vector3(0.16, 0.551, -0.145), Vector3(0.13, 0.025, 0.13), Art.CREAM.lightened(0.15), 0.014, 1.0).name = "SugarCorner"
	return root

static func folded_spoon_dock() -> Node3D:
	var root := Node3D.new()
	root.name = "FoldedSpoonDock"
	var hinged := Node3D.new()
	hinged.name = "HingedDock"
	root.add_child(hinged)
	Art._add(hinged, _dock_mesh(), METAL, Vector3.ZERO, Vector3.ONE, 0.42, 0.32).name = "SpoonSurface"
	# The clear surface sits at most .012 below its top datum, like a shallow bowl.
	Art._box(hinged, Vector3(-0.50, -0.004, 0), Vector3(0.62, 0.008, 0.17), Art.TEAL, 0.003, 0.82).name = "HandleInset"
	for x in [-0.69, -0.5, -0.31]:
		Art._ball(hinged, Vector3(x, -0.0015, 0), Vector3(0.025, 0.003, 0.025), Art.CREAM)
	_anchor(hinged, "OuterAnchor", Vector3(-2.2, 0, 0))
	_anchor(hinged, "LandingCenter", Vector3(-1.65, 0, 0))
	var axle := Art._cyl(root, Vector3(0, -0.065, 0), 0.055, 0.34, Art.TEAL, 0.6, 0.18)
	axle.name = "FixedHinge"
	axle.rotation.x = PI * 0.5
	# Negative Z rotation raises a dock that extends toward -X.
	return root

static func cereal_friends() -> Node3D:
	var root := Node3D.new()
	root.name = "CerealFriends"
	for i in range(2):
		var friend := Node3D.new()
		friend.name = "CerealL" if i == 0 else "CerealR"
		friend.position = Vector3(-0.36 if i == 0 else 0.36, 0, 0.035 if i == 0 else -0.035)
		root.add_child(friend)
		var color := TOASTED if i == 0 else CRUMB
		var body := Art._torus(friend, Vector3(0, 0.31, 0), 0.115, 0.23, color, Vector3(1, 0.9, 1), 0.96)
		body.name = "Body"
		body.rotation.x = PI * 0.5
		for x in [-0.11, 0.11]:
			Art._line(friend, Vector3(x, 0.065, 0.035), Vector3(x, 0.15, 0), 0.020, Art.TEAL).name = "LegL" if x < 0 else "LegR"
			Art._ball(friend, Vector3(x, 0.047, 0.045), Vector3(0.12, 0.094, 0.15), Art.TEAL).name = "FootL" if x < 0 else "FootR"
			Art._ball(friend, Vector3(x * 0.85, 0.443, 0.049), Vector3(0.029, 0.043, 0.021), Art.SLATE).name = "EyeL" if x < 0 else "EyeR"
			Art._ball(friend, Vector3(x * 1.5, 0.345, 0.052), Vector3(0.036, 0.017, 0.009), Art.CORAL)
		var arm := Node3D.new()
		arm.name = "WaveArm"
		arm.position = Vector3(-0.205 if i == 0 else 0.205, 0.33, 0.02)
		friend.add_child(arm)
		var direction := -1.0 if i == 0 else 1.0
		Art._line(arm, Vector3.ZERO, Vector3(direction * 0.055, 0.09, 0), 0.017, Art.TEAL)
		Art._ball(arm, Vector3(direction * 0.065, 0.105, 0), Vector3(0.055, 0.068, 0.044), Art.TEAL).name = "Hand"
		for a in [0.55, 1.35, 2.55]:
			Art._ball(friend, Vector3(cos(a) * 0.176, 0.31 + sin(a) * 0.176, 0.052), Vector3(0.023, 0.020, 0.01), color.darkened(0.17), 1.0)
	return root

static func _instances(parent: Node3D, mesh: Mesh, positions: Array[Vector3], color: Color, name: String) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.name = name
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	node.multimesh.mesh = mesh
	node.multimesh.instance_count = positions.size()
	for i in range(positions.size()):
		node.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	node.material_override = Art._mat(color, 0.98)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

static func _anchor(parent: Node3D, name: String, position: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = name
	node.position = position
	parent.add_child(node)
	return node

static func _dock_mesh() -> ArrayMesh:
	var outline: Array[Vector2] = []
	# Clockwise perimeter: rounded near handle, then the broad spoon bowl.
	for i in range(13):
		var a := PI * 0.5 - float(i) / 12.0 * PI
		outline.append(Vector2(-0.12 + cos(a) * 0.12, sin(a) * 0.32))
	for i in range(37):
		var a := -PI * 0.25 - float(i) / 36.0 * PI * 1.5
		outline.append(Vector2(-1.65 + cos(a) * 0.55, sin(a) * 0.55))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(outline.size()):
		var next := (i + 1) % outline.size()
		var pa := outline[i]
		var pb := outline[next]
		var ea := outline[next] - outline[(i - 1 + outline.size()) % outline.size()]
		var eb := outline[(next + 1) % outline.size()] - outline[i]
		var na := Vector3(-ea.y, 0, ea.x).normalized()
		var nb := Vector3(-eb.y, 0, eb.x).normalized()
		var outer_a := Vector3(pa.x, 0, pa.y)
		var outer_b := Vector3(pb.x, 0, pb.y)
		var top_a := outer_a - na * 0.025 + Vector3.DOWN * 0.012
		var top_b := outer_b - nb * 0.025 + Vector3.DOWN * 0.012
		var bottom_a := outer_a - na * 0.025 + Vector3.DOWN * 0.12
		var bottom_b := outer_b - nb * 0.025 + Vector3.DOWN * 0.12
		_triangle(st, Vector3(-1.2, -0.012, 0), top_a, top_b, Vector3.UP)
		_triangle(st, Vector3(-1.2, -0.12, 0), bottom_b, bottom_a, Vector3.DOWN)
		var levels_a := [top_a, outer_a + Vector3.DOWN * 0.037, outer_a + Vector3.DOWN * 0.095, bottom_a]
		var levels_b := [top_b, outer_b + Vector3.DOWN * 0.037, outer_b + Vector3.DOWN * 0.095, bottom_b]
		for band in range(3):
			var normal: Vector3 = (na + nb + Vector3.UP * float([2.0, 0.0, -2.0][band])).normalized()
			_triangle(st, levels_a[band], levels_a[band + 1], levels_b[band + 1], normal)
			_triangle(st, levels_a[band], levels_b[band + 1], levels_b[band], normal)
	st.index()
	return st.commit()

static func _twine_mesh() -> ArrayMesh:
	# Two continuous rounded cord loops follow the parcel's soft paper corners.
	var path: Array[Vector3] = []
	for corner in range(4):
		var cx := 0.195 if corner in [0, 3] else -0.195
		var cy := 0.195 if corner in [0, 1] else -0.195
		for i in range(9):
			var a := float(corner) * PI * 0.5 + float(i) / 8.0 * PI * 0.5
			path.append(Vector3(cx + cos(a) * 0.083, 0.29 + cy + sin(a) * 0.083, 0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for loop in range(2):
		for i in range(path.size()):
			var next := (i + 1) % path.size()
			var tangent_a := (path[next] - path[(i - 1 + path.size()) % path.size()]).normalized()
			var tangent_b := (path[(next + 1) % path.size()] - path[i]).normalized()
			var outward_a := Vector3(tangent_a.y, -tangent_a.x, 0)
			var outward_b := Vector3(tangent_b.y, -tangent_b.x, 0)
			for j in range(8):
				var beta := float(j) / 8.0 * TAU
				var gamma := float(j + 1) / 8.0 * TAU
				var radial_a := outward_a * cos(beta) + Vector3.BACK * sin(beta)
				var radial_b := outward_b * cos(beta) + Vector3.BACK * sin(beta)
				var radial_c := outward_b * cos(gamma) + Vector3.BACK * sin(gamma)
				var radial_d := outward_a * cos(gamma) + Vector3.BACK * sin(gamma)
				var points := [path[i] + radial_a * 0.012, path[next] + radial_b * 0.012, path[next] + radial_c * 0.012, path[i] + radial_d * 0.012]
				var normal := (radial_a + radial_b + radial_c + radial_d).normalized()
				if loop == 1:
					for k in range(4): points[k] = Vector3(points[k].z, points[k].y, points[k].x)
					normal = Vector3(normal.z, normal.y, normal.x)
				_triangle(st, points[0], points[1], points[2], normal)
				_triangle(st, points[0], points[2], points[3], normal)
	st.index()
	return st.commit()

static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	st.set_normal(normal)
	if (b - a).cross(c - a).dot(normal) > 0:
		for p in [a, c, b]: st.add_vertex(p)
	else:
		for p in [a, b, c]: st.add_vertex(p)
