extends RefCounted
## UNVERIFIED WIP — content expansion paused before Godot parse, native bounds or visual review.
class_name TTJamArt
## Original W01S04 native assets. Runtime owns scaling, contacts, motion and placement.
## Biscuit/parcel/helper pivots are on the floor. ButterKnife/Blade pivots at the hinge.
const Art = preload("res://scripts/art.gd")
const HarborArt = preload("res://scripts/chapter/harbor_art.gd")
const ChapterArt = preload("res://scripts/chapter/chapter_art.gd")
const BAKED := Color("d5a05b")
const EDGE := Color("b67d3f")
const PAPER := Color("efdfbf")
const METAL := Color("b3c4c5")

static func biscuit(radius: float = 1.05, height: float = 0.09) -> Node3D:
	assert(radius > 0.0 and height > 0.0, "Biscuit dimensions must be positive")
	var root := Node3D.new()
	root.name = "Biscuit"
	# Sixteen shallow scallops retain exact cardinal radius, with a rounded edge.
	Art._add(root, _biscuit_top(radius, height), BAKED, Vector3.ZERO, Vector3.ONE, 0.98).name = "ImpressedTop"
	Art._add(root, _biscuit_edge(radius, height), EDGE, Vector3.ZERO, Vector3.ONE, 0.96).name = "ScallopedEdge"
	HarborArt._anchor(root, "TopAnchor", Vector3(0, height, 0))
	root.set_meta("authored_radius", radius)
	root.set_meta("authored_height", height)
	return root

static func butter_knife() -> Node3D:
	var root := Node3D.new()
	root.name = "ButterKnife"
	var leaf := Node3D.new()
	leaf.name = "Blade"
	root.add_child(leaf)
	var blade_outline: Array[Vector2] = [Vector2(0, 0.32), Vector2(0.32, 0.43), Vector2(1.67, 0.43)]
	for i in range(1, 25):
		var angle := PI * 0.5 - float(i) / 24.0 * PI
		blade_outline.append(Vector2(1.67 + cos(angle) * 0.43, sin(angle) * 0.43))
	blade_outline.append(Vector2(0.32, -0.43))
	blade_outline.append(Vector2(0, -0.32))
	Art._add(leaf, _plate(blade_outline, Vector2(0.8, 0), 0.06), METAL, Vector3.ZERO, Vector3.ONE, 0.40, 0.34).name = "BladeSurface"
	var handle_outline: Array[Vector2] = [Vector2(0, -0.32), Vector2(-0.61, -0.34)]
	for i in range(1, 25):
		var angle := -PI * 0.5 - float(i) / 24.0 * PI
		handle_outline.append(Vector2(-0.61 + cos(angle) * 0.34, sin(angle) * 0.34))
	handle_outline.append(Vector2(0, 0.32))
	# Both pieces meet at X0 and share the exact Y0 top, with no raised grips.
	Art._add(leaf, _plate(handle_outline, Vector2(-0.40, 0), 0.06), Art.TEAL, Vector3.ZERO, Vector3.ONE, 0.74, 0.12).name = "HandleSurface"
	HarborArt._anchor(leaf, "BallastAnchor", Vector3(-0.6, 0, 0))
	HarborArt._anchor(leaf, "TipAnchor", Vector3(2.1, 0, 0))
	HarborArt._anchor(leaf, "HingeAnchor", Vector3.ZERO)
	return root

static func knife_rest() -> Node3D:
	# Optional floor-pivot support. Runtime positions its axle under the actual hinge.
	var root := Node3D.new()
	root.name = "KnifeRest"
	Art._box(root, Vector3(0, 0.05, 0), Vector3(0.56, 0.10, 0.84), PAPER, 0.045, 0.96).name = "PaperFoot"
	for z in [-0.31, 0.31]:
		Art._box(root, Vector3(0, 0.185, z), Vector3(0.20, 0.25, 0.12), Art.TEAL, 0.045, 0.84).name = "CheekNear" if z > 0 else "CheekFar"
	var axle := Art._cyl(root, Vector3(0, 0.30, 0), 0.065, 0.76, METAL, 0.43, 0.32)
	axle.rotation.x = PI * 0.5
	axle.name = "Axle"
	HarborArt._anchor(root, "HingeAnchor", Vector3(0, 0.425, 0))
	return root

static func seed_parcel() -> Node3D:
	var root := Node3D.new()
	root.name = "SeedParcel"
	Art._box(root, Vector3(0, 0.265, 0), Vector3(0.60, 0.53, 0.56), PAPER, 0.065, 0.98).name = "PaperWrap"
	var twine := Art._add(root, HarborArt._twine_mesh(), Art.CORAL, Vector3.ZERO, Vector3(0.62 / 0.58, 0.54 / 0.58, 1), 0.94)
	twine.name = "CoralTwine"
	Art._ball(root, Vector3(0, 0.545, 0), Vector3(0.055, 0.030, 0.045), Art.CORAL).name = "Knot"
	# Two seed leaves form an emblem, separate from the cargo parcel's sugar corner.
	var emblem := Node3D.new()
	emblem.name = "SeedEmblem"
	root.add_child(emblem)
	Art._ball(emblem, Vector3(-0.13, 0.275, 0.281), Vector3(0.19, 0.235, 0.008), Art.CREAM).name = "PaperSeal"
	Art._line(emblem, Vector3(-0.13, 0.21, 0.286), Vector3(-0.13, 0.33, 0.286), 0.0035, Art.TEAL).name = "Stem"
	var left := Art._ball(emblem, Vector3(-0.157, 0.30, 0.286), Vector3(0.073, 0.043, 0.008), Art.TEAL)
	left.rotation.z = -0.50
	left.name = "LeafL"
	var right := Art._ball(emblem, Vector3(-0.104, 0.322, 0.286), Vector3(0.075, 0.043, 0.008), Art.TEAL)
	right.rotation.z = 0.50
	right.name = "LeafR"
	var top_leaf := Art._ball(emblem, Vector3(-0.16, 0.534, 0.12), Vector3(0.17, 0.008, 0.09), Art.TEAL)
	top_leaf.rotation.y = -0.48
	top_leaf.name = "TopSeed"
	HarborArt._anchor(root, "CarryAnchor", Vector3(0, 0.28, 0))
	return root

static func jam_prints() -> Node3D:
	var root := Node3D.new()
	root.name = "JamPrints"
	var sizes := [0.23, 0.32, 0.43]
	for i in range(3):
		var radius: float = sizes[i]
		var ring := Art._torus(root, Vector3(-0.85 + i * 0.9, 0.01, 0), radius - 0.024, radius, Art.CORAL.darkened(0.18), Vector3(1, 0.02 / 0.024, 1), 0.78)
		ring.name = ["SmallPrint", "NormalPrint", "LargePrint"][i]
	for i in range(4):
		var footprint := Art._ball(root, Vector3(-0.45 + i * 0.28, 0.005, 0.67 + (0.055 if i % 2 == 0 else -0.055)), Vector3(0.11, 0.01, 0.17), Art.CORAL.darkened(0.26), 0.84)
		footprint.name = "Footprint" + str(i)
	return root

static func crumb_helper() -> Node3D:
	# Reuse the existing chapter crumb, including its editable wave pivot.
	var pair := ChapterArt.crumb_friends()
	var helper: Node3D = pair.get_node("CrumbL")
	pair.remove_child(helper)
	pair.free()
	helper.name = "JamHelper"
	helper.position = Vector3.ZERO
	return helper

static func _radial(radius: float, angle: float) -> Vector2:
	var edge := radius * (0.988 + 0.012 * cos(16.0 * angle))
	return Vector2(cos(angle), sin(angle)) * edge

static func _biscuit_top(radius: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := [0.0, 0.14, 0.28, 0.40, 0.52, 0.64, 0.76, 0.90, 0.975]
	var points: Array[PackedVector3Array] = []
	for r in range(rings.size()):
		var row := PackedVector3Array()
		for i in range(96):
			var angle := float(i) / 96.0 * TAU
			var point := _radial(radius, angle) * float(rings[r])
			# Actual shallow recesses, not raised dots on the walking plane.
			var impression := minf(height * 0.16, 0.014) if r == 4 and i % 8 == 0 else 0.0
			row.append(Vector3(point.x, height - impression, point.y))
		points.append(row)
	for r in range(rings.size() - 1):
		for i in range(96):
			var next := (i + 1) % 96
			var a: Vector3 = points[r][i]
			var b: Vector3 = points[r + 1][i]
			var c: Vector3 = points[r + 1][next]
			var d: Vector3 = points[r][next]
			_top_triangle(st, a, b, c)
			if r > 0: _top_triangle(st, a, c, d)
	st.index()
	return st.commit()

static func _top_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0: normal = -normal
	HarborArt._triangle(st, a, b, c, normal)

static func _biscuit_edge(radius: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bevel := minf(height * 0.25, 0.022)
	for i in range(96):
		var angle_a := float(i) / 96.0 * TAU
		var angle_b := float(i + 1) / 96.0 * TAU
		var pa := _radial(radius, angle_a)
		var pb := _radial(radius, angle_b)
		var levels_a := [Vector3(pa.x * 0.975, height, pa.y * 0.975), Vector3(pa.x, height - bevel, pa.y), Vector3(pa.x, bevel, pa.y), Vector3(pa.x * 0.975, 0, pa.y * 0.975)]
		var levels_b := [Vector3(pb.x * 0.975, height, pb.y * 0.975), Vector3(pb.x, height - bevel, pb.y), Vector3(pb.x, bevel, pb.y), Vector3(pb.x * 0.975, 0, pb.y * 0.975)]
		var outward := Vector3(cos((angle_a + angle_b) * 0.5), 0, sin((angle_a + angle_b) * 0.5))
		for band in range(3):
			var normal := (outward + Vector3.UP * float([1.8, 0.0, -1.8][band])).normalized()
			HarborArt._triangle(st, levels_a[band], levels_a[band + 1], levels_b[band + 1], normal)
			HarborArt._triangle(st, levels_a[band], levels_b[band + 1], levels_b[band], normal)
		HarborArt._triangle(st, Vector3.ZERO, levels_a[3], levels_b[3], Vector3.DOWN)
	st.index()
	return st.commit()

static func _plate(outline: Array[Vector2], center: Vector2, depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var area := 0.0
	for i in range(outline.size()): area += outline[i].cross(outline[(i + 1) % outline.size()])
	for i in range(outline.size()):
		var next := (i + 1) % outline.size()
		var pa := outline[i]
		var pb := outline[next]
		var tangent_a := outline[next] - outline[(i - 1 + outline.size()) % outline.size()]
		var tangent_b := outline[(next + 1) % outline.size()] - pa
		var na := Vector3(tangent_a.y, 0, -tangent_a.x).normalized() * signf(area)
		var nb := Vector3(tangent_b.y, 0, -tangent_b.x).normalized() * signf(area)
		var top_a := Vector3(pa.x, 0, pa.y)
		var top_b := Vector3(pb.x, 0, pb.y)
		var bottom_a := top_a - na * 0.012 + Vector3.DOWN * depth
		var bottom_b := top_b - nb * 0.012 + Vector3.DOWN * depth
		HarborArt._triangle(st, Vector3(center.x, 0, center.y), top_a, top_b, Vector3.UP)
		HarborArt._triangle(st, Vector3(center.x, -depth, center.y), bottom_b, bottom_a, Vector3.DOWN)
		var middle_a := top_a + Vector3.DOWN * (depth - 0.012)
		var middle_b := top_b + Vector3.DOWN * (depth - 0.012)
		HarborArt._triangle(st, top_a, middle_a, middle_b, (na + nb).normalized())
		HarborArt._triangle(st, top_a, middle_b, top_b, (na + nb).normalized())
		HarborArt._triangle(st, middle_a, bottom_a, bottom_b, (na + nb + Vector3.DOWN).normalized())
		HarborArt._triangle(st, middle_a, bottom_b, middle_b, (na + nb + Vector3.DOWN).normalized())
	st.index()
	return st.commit()
