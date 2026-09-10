extends RefCounted
class_name TTArt
## Tiny Trouble authored procedural art. All pivots are floor-centred; Pip faces +Z.
## Geometry is generated once and remains editable here; collisions belong to the game.

const CREAM := Color("f5e6cc")
const AMBER := Color("e5a54b")
const CORAL := Color("c95c54")
const TEAL := Color("4a9290")
const SLATE := Color("384657")
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}

static func _mat(color: Color, rough: float = 0.75, metallic: float = 0.0) -> StandardMaterial3D:
	var key := str(color) + str(rough) + str(metallic)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	_materials[key] = m
	return m

static func _add(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, scale_v: Vector3 = Vector3.ONE, rough: float = 0.75, metallic: float = 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = _mat(color, rough, metallic)
	n.position = pos
	n.scale = scale_v
	parent.add_child(n)
	return n

static func _ball(parent: Node3D, pos: Vector3, dims: Vector3, color: Color, rough: float = 0.75, metallic: float = 0.0) -> MeshInstance3D:
	if not _meshes.has("sphere"):
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 24
		mesh.rings = 12
		_meshes["sphere"] = mesh
	return _add(parent, _meshes["sphere"], color, pos, dims, rough, metallic)

static func _round_mesh(size: Vector3, radius: float) -> ArrayMesh:
	var key := str(size) + ":" + str(radius)
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var core := half - Vector3.ONE * radius
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for face in range(3):
		var a := axes[face]
		var b := axes[(face + 1) % 3]
		var c := axes[(face + 2) % 3]
		var bh: float = half[(face + 1) % 3]
		var ch: float = half[(face + 2) % 3]
		var bs: Array[float] = [-bh, -bh + radius * 0.3, -bh + radius * 0.65, -bh + radius, bh - radius, bh - radius * 0.65, bh - radius * 0.3, bh]
		var cs: Array[float] = [-ch, -ch + radius * 0.3, -ch + radius * 0.65, -ch + radius, ch - radius, ch - radius * 0.65, ch - radius * 0.3, ch]
		for sign_v in [-1.0, 1.0]:
			for i in range(7):
				for j in range(7):
					var coords := [Vector2(bs[i], cs[j]), Vector2(bs[i + 1], cs[j]), Vector2(bs[i + 1], cs[j + 1]), Vector2(bs[i], cs[j + 1])]
					var ids: Array = [0, 2, 1, 0, 3, 2] if sign_v > 0.0 else [0, 1, 2, 0, 2, 3]
					for idx in ids:
						var p: Vector3 = a * half[face] * sign_v + b * coords[idx].x + c * coords[idx].y
						var q := Vector3(clampf(p.x, -core.x, core.x), clampf(p.y, -core.y, core.y), clampf(p.z, -core.z, core.z))
						var norm := (p - q).normalized()
						st.set_normal(norm)
						st.set_uv(Vector2(coords[idx].x / size[(face + 1) % 3] + 0.5, coords[idx].y / size[(face + 2) % 3] + 0.5))
						st.add_vertex(q + norm * radius)
	st.index()
	var result := st.commit()
	_meshes[key] = result
	return result

static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, radius: float = 0.08, rough: float = 0.75, metallic: float = 0.0) -> MeshInstance3D:
	return _add(parent, _round_mesh(size, minf(radius, minf(size.x, minf(size.y, size.z)) * 0.48)), color, pos, Vector3.ONE, rough, metallic)

static func _cyl(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, rough: float = 0.75, metallic: float = 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	return _add(parent, mesh, color, pos, Vector3.ONE, rough, metallic)

static func _torus(parent: Node3D, pos: Vector3, inner: float, outer: float, color: Color, scale_v: Vector3 = Vector3.ONE, rough: float = 0.6, metallic: float = 0.0) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 32
	mesh.ring_segments = 10
	return _add(parent, mesh, color, pos, scale_v, rough, metallic)

static func _line(parent: Node3D, start: Vector3, end: Vector3, width: float, color: Color) -> MeshInstance3D:
	var delta := end - start
	var n := _cyl(parent, (start + end) * 0.5, width, delta.length(), color)
	if absf(delta.normalized().dot(Vector3.UP)) < 0.999:
		n.quaternion = Quaternion(Vector3.UP, delta.normalized())
	return n

static func pip() -> Node3D:
	var root := Node3D.new()
	root.name = "PipArt"
	var body := _ball(root, Vector3(0, 0.53, 0), Vector3(0.65, 0.78, 0.52), CREAM, 0.84)
	body.name = "Body"
	var foot_l := _ball(root, Vector3(-0.22, 0.13, 0.08), Vector3(0.34, 0.26, 0.46), TEAL)
	foot_l.name = "FootL"
	var foot_r := _ball(root, Vector3(0.22, 0.13, 0.08), Vector3(0.34, 0.26, 0.46), TEAL)
	foot_r.name = "FootR"
	for x in [-0.14, 0.14]:
		var eye := _ball(root, Vector3(x, 0.67, 0.24), Vector3(0.105, 0.155, 0.061), SLATE, 0.28)
		eye.name = "EyeL" if x < 0 else "EyeR"
		_ball(eye, Vector3(-0.16, 0.23, 0.38), Vector3(0.22, 0.18, 0.19), CREAM, 0.4)
		_ball(root, Vector3(x * 1.4, 0.535, 0.219), Vector3(0.085, 0.037, 0.028), CORAL)
	var tail := Node3D.new()
	tail.name = "Tail"
	root.add_child(tail)
	_ball(tail, Vector3(0, 0.23, -0.33), Vector3(0.15, 0.14, 0.32), TEAL).rotation.x = -0.3
	_ball(tail, Vector3(0, 0.27, -0.46), Vector3(0.21, 0.11, 0.17), TEAL)
	# Small, restrained stitched seam at the belly.
	for i in range(6):
		var x := -0.135 + i * 0.054
		_line(root, Vector3(x, 0.36, 0.239), Vector3(x + 0.018, 0.388, 0.243), 0.006, Color("c8b99f"))
	var tool := Node3D.new()
	tool.name = "Tool"
	tool.position = Vector3(0.34, 0.46, -0.015)
	tool.rotation.z = -0.3
	root.add_child(tool)
	_cyl(tool, Vector3.ZERO, 0.08, 0.24, AMBER)
	_cyl(tool, Vector3(0, -0.11, 0), 0.13, 0.05, CORAL)
	_cyl(tool, Vector3(0, 0.11, 0), 0.13, 0.05, CORAL)
	_torus(tool, Vector3.ZERO, 0.08, 0.09, CREAM)
	_ball(tool, Vector3(0, 0.17, 0), Vector3(0.12, 0.12, 0.12), TEAL, 0.35)
	return root

static func prop(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = kind.capitalize() + "Art"
	match kind:
		"spoon": _spoon(root)
		"blueberry": _blueberry(root)
		"cereal": _cereal(root)
		"napkin": _napkin(root)
		"butter": _butter(root)
		"toaster": _toaster(root)
		"toast": _toast(root)
	return root

static func _spoon(root: Node3D) -> void:
	var metal := Color("b3c4c5")
	_box(root, Vector3(0.42, 0.14, 0), Vector3(1.98, 0.13, 0.44), metal, 0.12, 0.28, 0.62)
	# A shallow concave spoon bowl with a rolled lip, rather than a solid oval.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(8):
		for sector in range(48):
			var ids := [Vector2(ring, sector), Vector2(ring + 1, sector), Vector2(ring + 1, sector + 1), Vector2(ring, sector), Vector2(ring + 1, sector + 1), Vector2(ring, sector + 1)]
			for id in ids:
				var r: float = id.x / 8.0
				var a: float = id.y / 48.0 * TAU
				st.set_normal(Vector3(-0.36 * r * cos(a) / 0.63, 1.0, -0.36 * r * sin(a) / 0.44).normalized())
				st.add_vertex(Vector3(-0.77 + cos(a) * 0.63 * r, 0.05 + 0.18 * r * r, sin(a) * 0.44 * r))
	var bowl := _add(root, st.commit(), metal, Vector3.ZERO, Vector3.ONE, 0.3, 0.62)
	var bowl_mat := _mat(metal, 0.3, 0.62).duplicate() as StandardMaterial3D
	bowl_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bowl.material_override = bowl_mat
	_torus(root, Vector3(-0.77, 0.23, 0), 0.405, 0.44, metal, Vector3(1.43, 0.7, 1), 0.28, 0.62)
	_box(root, Vector3(0.85, 0.215, 0), Vector3(0.43, 0.014, 0.135), TEAL, 0.006, 0.7)
	for x in [0.73, 0.87, 1.01]:
		_ball(root, Vector3(x, 0.23, 0), Vector3(0.035, 0.01, 0.035), CREAM)

static func _blueberry(root: Node3D) -> void:
	_ball(root, Vector3(0, 0.29, 0), Vector3(0.6, 0.57, 0.59), Color("505779"), 0.82)
	_ball(root, Vector3(-0.07, 0.38, 0.08), Vector3(0.44, 0.35, 0.43), Color("596384"), 0.89)
	_cyl(root, Vector3(0, 0.571, 0), 0.095, 0.014, SLATE)
	for i in range(5):
		var a := i * TAU / 5.0
		var leaf := _ball(root, Vector3(cos(a) * 0.08, 0.585, sin(a) * 0.08), Vector3(0.055, 0.025, 0.13), Color("404761"))
		leaf.rotation.y = -a + PI / 2
	for v in [Vector3(-0.16, 0.45, 0.18), Vector3(0.11, 0.41, 0.24), Vector3(-0.23, 0.28, 0.17)]:
		_ball(root, v, Vector3(0.035, 0.028, 0.018), Color("79829a"))

static func _cereal(root: Node3D) -> void:
	# Four face sections preserve a real launch window through the carton.
	var paper := Color("e7b962")
	for z in [-0.55, 0.55]:
		var face_name := "Front" if z > 0 else "Back"
		_box(root, Vector3(0, 0.69, z), Vector3(2.3, 1.38, 0.12), paper, 0.045).name = face_name + "Lower"
		_box(root, Vector3(0, 3.075, z), Vector3(2.3, 0.65, 0.12), CORAL, 0.045).name = face_name + "Upper"
		for x in [-0.98, 0.98]:
			_box(root, Vector3(x, 2.065, z), Vector3(0.34, 1.37, 0.12), paper, 0.035).name = face_name + ("Left" if x < 0 else "Right")
	for x in [-1.09, 1.09]:
		_box(root, Vector3(x, 1.7, 0), Vector3(0.12, 3.4, 1.12), Color("d59945"), 0.05)
	_box(root, Vector3(0, 3.36, 0), Vector3(2.28, 0.08, 1.08), CREAM, 0.03)
	_box(root, Vector3(0, 3.42, 0), Vector3(2.2, 0.04, 0.08), CORAL, 0.018)
	# Broad cut-paper breakfast emblem, avoiding raster lettering.
	var badge := _cyl(root, Vector3(0, 0.83, 0.627), 0.51, 0.025, CREAM)
	badge.rotation.x = PI / 2
	var ring := _torus(root, Vector3(0, 0.88, 0.65), 0.2, 0.3, AMBER, Vector3.ONE)
	ring.rotation.x = PI / 2
	for x in [-0.17, 0.17]:
		_ball(root, Vector3(x, 0.9, 0.68), Vector3(0.055, 0.085, 0.03), SLATE)
	# Trim sits outside the real opening. It must not reduce launch clearance.
	for x in [-0.85, 0.85]:
		_box(root, Vector3(x, 2.065, 0.623), Vector3(0.075, 1.45, 0.033), CREAM, 0.02).name = "WindowTrim" + ("Left" if x < 0 else "Right")
	for y in [1.34, 2.79]:
		_box(root, Vector3(0, y, 0.623), Vector3(1.775, 0.075, 0.033), CREAM, 0.02).name = "WindowTrim" + ("Bottom" if y < 2 else "Top")
	var secret := _box(root, Vector3(-1.164, 0.49, 0.03), Vector3(0.03, 0.64, 0.72), TEAL, 0.014)
	secret.name = "SecretPanel"
	var picnic := Node3D.new()
	picnic.name = "Picnic"
	picnic.visible = false
	root.add_child(picnic)
	_box(picnic, Vector3(-1.5, 0.035, 0), Vector3(0.6, 0.025, 0.55), CREAM, 0.01)
	for z in [-0.15, 0.15]:
		_cyl(picnic, Vector3(-1.5, 0.07, z), 0.115, 0.025, TEAL)
		_ball(picnic, Vector3(-1.5, 0.115, z), Vector3(0.12, 0.07, 0.1), AMBER)

static func _napkin(root: Node3D) -> void:
	# Soft draped cloth with stitched perimeter. Mesh undulation survives all sizes.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 16
	for x in range(count):
		for z in range(count):
			for q in [Vector2(x, z), Vector2(x + 1, z + 1), Vector2(x, z + 1), Vector2(x, z), Vector2(x + 1, z), Vector2(x + 1, z + 1)]:
				var u: float = q.x / count
				var v: float = q.y / count
				var px: float = (u - 0.5) * 1.8
				var pz: float = (v - 0.5) * 1.4
				var py := 0.036 + sin(u * PI) * sin(v * PI) * 0.055 + sin(u * TAU * 2) * 0.011
				var du := cos(u * PI) * sin(v * PI) * PI * 0.055 + cos(u * TAU * 2) * TAU * 2 * 0.011
				var dv := sin(u * PI) * cos(v * PI) * PI * 0.055
				st.set_normal(Vector3(-du / 1.8, 1.0, -dv / 1.4).normalized())
				st.set_uv(Vector2(u, v))
				st.add_vertex(Vector3(px, py, pz))
	var cloth := _add(root, st.commit(), CREAM, Vector3.ZERO, Vector3.ONE, 0.95)
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cloth_mat := _mat(CREAM, 0.95).duplicate() as StandardMaterial3D
	cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloth.material_override = cloth_mat
	for z in [-0.63, 0.63]:
		_box(root, Vector3(0, 0.046, z), Vector3(1.64, 0.015, 0.06), TEAL, 0.006)
	for x in [-0.82, 0.82]:
		_box(root, Vector3(x, 0.047, 0), Vector3(0.06, 0.015, 1.3), TEAL, 0.006)
	for i in range(15):
		for z in [-0.68, 0.68]:
			_line(root, Vector3(-0.8 + i * 0.11, 0.055, z), Vector3(-0.77 + i * 0.11, 0.055, z), 0.006, Color("b8ab92"))
	# Folded corner is deliberately small to preserve a clear landing surface.
	var fold := _box(root, Vector3(0.70, 0.073, 0.51), Vector3(0.27, 0.025, 0.25), Color("dfd0b9"), 0.011)
	fold.rotation = Vector3(-0.15, 0.15, 0.1)

static func _butter(root: Node3D) -> void:
	_box(root, Vector3(0, 0.175, 0), Vector3(0.75, 0.35, 0.5), Color("f3ce70"), 0.095, 0.73)
	_box(root, Vector3(0, 0.347, 0), Vector3(0.56, 0.025, 0.34), Color("ffe09a"), 0.011, 0.8)
	for i in range(4):
		_box(root, Vector3(-0.22 + i * 0.145, 0.361, 0), Vector3(0.04, 0.009, 0.26), Color("edbf5d"), 0.004)
	_ball(root, Vector3(0.36, 0.11, 0.03), Vector3(0.05, 0.09, 0.1), Color("f3ce70"))

static func _toaster(root: Node3D) -> void:
	_box(root, Vector3(0, 0.74, 0), Vector3(2.0, 1.32, 1.4), TEAL, 0.25, 0.36, 0.12)
	_box(root, Vector3(0, 0.13, 0), Vector3(2.06, 0.21, 1.44), SLATE, 0.1, 0.55, 0.3)
	for x in [-0.72, 0.72]:
		for z in [-0.45, 0.45]:
			_ball(root, Vector3(x, 0.04, z), Vector3(0.22, 0.1, 0.23), SLATE)
	_box(root, Vector3(0, 1.358, 0), Vector3(1.74, 0.10, 1.12), Color("b7c8c7"), 0.045, 0.25, 0.6)
	for z in [-0.28, 0.28]:
		_box(root, Vector3(0, 1.411, z), Vector3(1.45, 0.026, 0.22), SLATE, 0.012)
		_box(root, Vector3(0, 1.427, z), Vector3(1.18, 0.014, 0.075), Color("202d35"), 0.005)
	_box(root, Vector3(1.009, 0.87, 0), Vector3(0.025, 0.65, 0.13), SLATE, 0.012)
	var lever := Node3D.new()
	lever.name = "Lever"
	lever.position = Vector3(1.08, 1.04, 0)
	root.add_child(lever)
	_box(lever, Vector3(0.13, 0, 0), Vector3(0.35, 0.075, 0.10), Color("b7c8c7"), 0.035, 0.3, 0.7)
	_box(lever, Vector3(0.32, 0, 0), Vector3(0.28, 0.16, 0.37), CORAL, 0.07, 0.55)
	var dial := _cyl(root, Vector3(0.52, 0.54, 0.716), 0.18, 0.07, CREAM, 0.48)
	dial.rotation.x = PI / 2
	_box(root, Vector3(0.52, 0.62, 0.756), Vector3(0.022, 0.11, 0.018), CORAL, 0.007)
	_box(root, Vector3(-0.37, 0.64, 0.704), Vector3(0.62, 0.24, 0.03), Color("357d7c"), 0.014)
	for x in [-0.55, -0.37, -0.19]:
		_ball(root, Vector3(x, 0.64, 0.727), Vector3(0.055, 0.055, 0.025), AMBER)
	for i in range(5):
		_box(root, Vector3(-0.32 + i * 0.15, 0.29, 0.715), Vector3(0.08, 0.016, 0.012), SLATE, 0.006)

static func _toast(root: Node3D) -> void:
	_box(root, Vector3(0, 0.075, 0.04), Vector3(1.27, 0.15, 0.9), Color("a76534"), 0.07, 0.96)
	_ball(root, Vector3(-0.28, 0.075, -0.38), Vector3(0.76, 0.15, 0.5), Color("a76534"), 0.96)
	_ball(root, Vector3(0.28, 0.075, -0.38), Vector3(0.76, 0.15, 0.5), Color("a76534"), 0.96)
	_box(root, Vector3(0, 0.157, 0.04), Vector3(1.06, 0.027, 0.74), AMBER, 0.012, 0.98)
	_ball(root, Vector3(-0.26, 0.157, -0.31), Vector3(0.59, 0.026, 0.38), AMBER, 0.98)
	_ball(root, Vector3(0.26, 0.157, -0.31), Vector3(0.59, 0.026, 0.38), AMBER, 0.98)
	for i in range(17):
		var x := sin(i * 12.7) * 0.43
		var z := cos(i * 9.37) * 0.29
		_ball(root, Vector3(x, 0.175, z), Vector3(0.035, 0.009, 0.025), Color("ce9347"), 1.0)

static func table() -> Node3D:
	var root := Node3D.new()
	root.name = "TableArt"
	_box(root, Vector3(0, -0.45, 0), Vector3(25.4, 0.9, 15.4), Color("d5aa73"), 0.36, 0.92)
	# Quiet inset grain lines create scale without competing with puzzle targets.
	for i in range(11):
		var z := -6.8 + i * 1.34
		_box(root, Vector3(0, 0.004, z), Vector3(24.5, 0.007, 0.013), Color("c59c69"), 0.003)
		for j in range(3):
			var x := -9.0 + j * 8.3 + sin(float(i * 3 + j)) * 1.3
			var line := _torus(root, Vector3(x, 0.007, z + 0.28), 0.18, 0.19, Color("c9a372"), Vector3(2.8, 0.022, 0.62))
			line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_box(root, Vector3(0, -2.5, 0), Vector3(140, 0.6, 140), Color("d9cbb7"), 0.2)
	# Off-route ceramic dishes and paper/fabric dressing on the far tabletop edges.
	for pos in [Vector3(-10.2, 0.06, -5.8), Vector3(8.6, 0.06, -6.2)]:
		_cyl(root, pos, 1.15, 0.12, CREAM, 0.37)
		_torus(root, pos + Vector3(0, 0.06, 0), 1.0, 1.16, CREAM, Vector3(1, 0.35, 1), 0.37)
		_torus(root, pos + Vector3(0, 0.068, 0), 0.83, 0.85, TEAL, Vector3(1, 0.18, 1), 0.42)
	var cloth := _box(root, Vector3(-9.4, 0.017, 5.9), Vector3(3.5, 0.035, 1.55), Color("b5c8bb"), 0.016, 0.99)
	cloth.rotation.y = 0.14
	for i in range(5):
		_box(cloth, Vector3(-1.4 + i * 0.7, 0.023, 0), Vector3(0.028, 0.009, 1.48), CREAM, 0.004)
	# Deterministic crumbs are small, pale, and confined to decorative edge zones.
	for i in range(24):
		var x := sin(i * 17.13) * 11.2
		var z := (-1.0 if i % 2 == 0 else 1.0) * (6.0 + cos(i * 4.6) * 0.45)
		var crumb := _ball(root, Vector3(x, 0.045, z), Vector3(0.06 + (i % 3) * 0.023, 0.09, 0.08), AMBER, 1.0)
		crumb.rotation.y = i * 0.9
	return root
