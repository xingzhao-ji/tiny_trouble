extends RefCounted
class_name TTBallastArt
## Editable W01S02 cardboard mechanism. Runtime owns collision, motion and threads.
## Pan/ramp pivot Y is the walking surface; tower/ledge use floor pivots.

const Art = preload("res://scripts/art.gd")
const BOARD := Color("c99b60")
const CUT_EDGE := Color("a87946")
const PAPER := Color("eed8b1")

static func balance_pan() -> Node3D:
	var root := Node3D.new()
	root.name = "BalancePan"
	Art._box(root, Vector3(0, -0.07, 0), Vector3(2.7, 0.14, 4.4), PAPER, 0.055, 0.98).name = "Floor"
	for x in [-1.29, 1.29]:
		Art._box(root, Vector3(x, -0.01, 0), Vector3(0.12, 0.22, 4.4), BOARD, 0.032, 0.98).name = "RimLeft" if x < 0 else "RimRight"
	for z in [-2.14, 2.14]:
		Art._box(root, Vector3(0, -0.01, z), Vector3(2.46, 0.22, 0.12), BOARD, 0.032, 0.98).name = "RimFar" if z < 0 else "RimNear"
	for i in range(2):
		var pocket := Node3D.new()
		pocket.name = "PocketFar" if i == 0 else "PocketNear"
		pocket.position = Vector3(0, 0, -1.12 if i == 0 else 1.12)
		root.add_child(pocket)
		var color: Color = Art.TEAL if i == 0 else Art.CORAL
		Art._torus(pocket, Vector3(0, 0.006, 0), 0.91, 0.955, color, Vector3(1, 0.18, 1), 0.99).name = "PocketCue"
		for x in [-1.09, 1.09]:
			Art._box(pocket, Vector3(x, 0.006, 0), Vector3(0.055, 0.012, 0.42), color, 0.005, 0.99)
	var rib_positions: Array[Vector3] = []
	for i in range(17):
		for x in [-1.346, 1.346]:
			rib_positions.append(Vector3(x, -0.075, -2.02 + i * 0.25))
	_instances(root, Art._round_mesh(Vector3(0.008, 0.07, 0.07), 0.003), rib_positions, CUT_EDGE, "CorrugatedEdges")
	_anchor(root, "SuspensionAnchor", Vector3(0, -0.14, 0))
	return root

static func counterweight_tower() -> Node3D:
	var root := Node3D.new()
	root.name = "CounterweightTower"
	Art._box(root, Vector3(0, 0.07, 0), Vector3(1.9, 0.14, 1.7), BOARD, 0.06, 0.98).name = "Foot"
	for x in [-0.67, 0.67]:
		Art._box(root, Vector3(x, 1.64, -0.36), Vector3(0.20, 3.05, 0.30), PAPER, 0.055, 0.99).name = "PostLeft" if x < 0 else "PostRight"
		Art._box(root, Vector3(x, 1.62, -0.201), Vector3(0.04, 2.88, 0.018), Art.TEAL, 0.008, 0.99)
		Art._box(root, Vector3(x, 0.22, -0.12), Vector3(0.38, 0.17, 1.08), PAPER, 0.055, 0.99)
	Art._box(root, Vector3(0, 3.10, -0.28), Vector3(1.68, 0.22, 0.42), Art.CORAL, 0.07, 0.96).name = "Crossbeam"
	var pulley := Node3D.new()
	pulley.name = "Pulley"
	pulley.position = Vector3(0, 3.12, 0.04)
	root.add_child(pulley)
	Art._cyl(pulley, Vector3.ZERO, 0.29, 0.10, Art.AMBER, 0.91).rotation.x = PI * 0.5
	var wheel := Art._torus(pulley, Vector3(0, 0, 0.01), 0.275, 0.34, CUT_EDGE, Vector3.ONE, 0.93)
	wheel.rotation.x = PI * 0.5
	Art._ball(pulley, Vector3(0, 0, 0.083), Vector3(0.14, 0.14, 0.045), Art.TEAL, 0.8).name = "AxleCap"
	_anchor(root, "PulleyLeft", Vector3(-0.308, 3.12, 0.05))
	_anchor(root, "PulleyRight", Vector3(0.308, 3.12, 0.05))
	# Slender guide rods expose rather than enclose the moving cereal stack.
	for x in [-0.53, 0.53]:
		Art._line(root, Vector3(x, 0.18, 0.28), Vector3(x, 2.72, 0.28), 0.018, Art.SLATE)
	var stack := Node3D.new()
	stack.name = "WeightStack"
	stack.position = Vector3(0, 0.35, 0.28)
	root.add_child(stack)
	Art._box(stack, Vector3(0, 0.04, 0), Vector3(0.98, 0.08, 0.64), Art.TEAL, 0.027, 0.9).name = "Cradle"
	var scores: Array[Vector3] = []
	for i in range(5):
		var y := 0.20 + i * 0.26
		var color: Color = Art.CREAM if i % 2 == 0 else Art.AMBER.lerp(Art.CREAM, 0.48)
		Art._box(stack, Vector3(0, y, 0), Vector3(0.86, 0.22, 0.54), color, 0.06, 0.99).name = "Weight" + str(i)
		for x in [-0.18, 0.18]:
			scores.append(Vector3(x, y, 0.270))
	_instances(stack, Art._round_mesh(Vector3(0.028, 0.13, 0.006), 0.002), scores, BOARD, "WeightScoring")
	Art._line(stack, Vector3(0, 0.08, 0), Vector3(0, 1.48, 0), 0.020, CUT_EDGE).name = "StackSpindle"
	var loop := Art._torus(stack, Vector3(0, 1.50, 0), 0.064, 0.09, Art.TEAL, Vector3.ONE, 0.9)
	loop.rotation.x = PI * 0.5
	loop.name = "HangingLoop"
	_anchor(stack, "ThreadAnchor", Vector3(0, 1.59, 0))
	return root

static func ramp(length: float = 6.0, width: float = 1.65) -> Node3D:
	assert(length >= 0.6 and width >= 0.6, "Cardboard ramp dimensions must leave a walking surface")
	var root := Node3D.new()
	root.name = "CardboardRamp"
	Art._box(root, Vector3(length * 0.5, -0.07, 0), Vector3(length, 0.14, width - 0.24), PAPER, 0.035, 0.99).name = "Surface"
	for side in [-1.0, 1.0]:
		var z: float = side * (width * 0.5 - 0.062)
		Art._box(root, Vector3(length * 0.5, -0.15, z), Vector3(length, 0.26, 0.12), BOARD, 0.035, 0.98).name = "SidewallNear" if side > 0 else "SidewallFar"
		Art._box(root, Vector3(length * 0.5, -0.009, z), Vector3(length, 0.018, 0.12), Art.TEAL, 0.007, 0.98).name = "EdgeTrimNear" if side > 0 else "EdgeTrimFar"
	var flutes: Array[Vector3] = []
	var count := maxi(2, int(floor(length / 0.24)))
	for i in range(count):
		var x := 0.14 + (length - 0.28) * i / float(count - 1)
		for side in [-1.0, 1.0]:
			flutes.append(Vector3(x, -0.155, side * (width * 0.5 - 0.006)))
	_instances(root, Art._round_mesh(Vector3(0.055, 0.13, 0.012), 0.004), flutes, CUT_EDGE, "CorrugatedSidewalls")
	# All edge detail stays below the Y=0 walking plane; no top rail blocks Pip.
	_anchor(root, "NearAnchor", Vector3.ZERO)
	_anchor(root, "FarAnchor", Vector3(length, 0, 0))
	return root

static func ledge() -> Node3D:
	var root := Node3D.new()
	root.name = "CerealBoxLedge"
	Art._box(root, Vector3(0, 0.86, 0), Vector3(3.96, 1.72, 3.12), Art.AMBER.lerp(PAPER, 0.35), 0.12, 0.98).name = "BoxBody"
	Art._box(root, Vector3(0, 1.76, 0), Vector3(4.0, 0.08, 3.2), PAPER, 0.032, 0.99).name = "LandingTop"
	for side in [-1.0, 1.0]:
		Art._box(root, Vector3(0, 1.64, side * 1.567), Vector3(3.9, 0.09, 0.027), Art.TEAL, 0.01, 0.99).name = "EdgeBandNear" if side > 0 else "EdgeBandFar"
		Art._box(root, Vector3(side * 1.925, 0.87, 0), Vector3(0.05, 1.49, 3.02), Art.CORAL, 0.02, 0.98)
	Art._box(root, Vector3(0, 0.10, 1.566), Vector3(3.64, 0.08, 0.015), BOARD, 0.007, 0.99).name = "FrontFold"
	# Friendly printed-breakfast effect from shallow geometry, never text or numbers.
	var graphic := Node3D.new()
	graphic.name = "BreakfastGraphic"
	root.add_child(graphic)
	Art._cyl(graphic, Vector3(0, 0.92, 1.566), 0.57, 0.016, Art.CREAM, 0.99).rotation.x = PI * 0.5
	var cereal := Art._torus(graphic, Vector3(0, 0.96, 1.579), 0.18, 0.33, Art.AMBER, Vector3(1, 0.06, 1), 0.99)
	cereal.rotation.x = PI * 0.5
	for x in [-0.11, 0.11]:
		Art._ball(graphic, Vector3(x, 1.0, 1.589), Vector3(0.042, 0.064, 0.012), Art.SLATE, 0.99)
		Art._ball(graphic, Vector3(x * 1.9, 0.885, 1.587), Vector3(0.068, 0.027, 0.009), Art.CORAL, 0.99)
	var smile := Art._add(graphic, _smile_mesh(), Art.SLATE, Vector3(0, 0.815, 1.591), Vector3.ONE, 0.99)
	smile.name = "Smile"
	return root

static func _instances(parent: Node3D, mesh: Mesh, positions: Array[Vector3], color: Color, name: String) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = positions.size()
	for i in range(positions.size()):
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	var node := MultiMeshInstance3D.new()
	node.name = name
	node.multimesh = multimesh
	node.material_override = Art._mat(color, 0.99)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

static func _anchor(parent: Node3D, name: String, position: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = name
	node.position = position
	parent.add_child(node)
	return node

static func _smile_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var angle_a := PI * (0.15 + 0.70 * i / 12.0)
		var angle_b := PI * (0.15 + 0.70 * (i + 1) / 12.0)
		var a := Vector3(cos(angle_a) * 0.10, -sin(angle_a) * 0.065, 0)
		var b := Vector3(cos(angle_b) * 0.10, -sin(angle_b) * 0.065, 0)
		for vertex in [a, b, b + Vector3(0, 0.015, 0), a, b + Vector3(0, 0.015, 0), a + Vector3(0, 0.015, 0)]:
			st.set_normal(Vector3.BACK)
			st.add_vertex(vertex)
	return st.commit()
