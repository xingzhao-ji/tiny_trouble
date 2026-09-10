extends SceneTree
## Conservative geometric flight audit using actual procedural mesh bounds.
## No save, renderer, UI or live game instance is required.
const Art = preload("res://scripts/art.gd")
const Main = preload("res://scripts/main.gd")
const CARTON_POSITION := Vector3(4.0, 0.02, -1.0)
const CARTON_YAW := 0.79
const TOAST_YAW := 0.79
const PIP_YAW := 0.7
const SAMPLES := 2401
var checks := 0
var failures: Array = []
var checked_crossing_samples := 0
var minimum_margin := INF
var closest_record: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cereal := Art.prop("cereal")
	var toast := Art.prop("toast")
	var pip := Art.pip()
	var aperture := _aperture(cereal)
	var moving_parts: Array = []
	_gather(toast, Transform3D.IDENTITY, moving_parts, "Toast")
	for part in moving_parts:
		part["family"] = "toast"
	var pip_parts: Array = []
	_gather(pip, Transform3D.IDENTITY, pip_parts, "Pip")
	for part in pip_parts:
		part["family"] = "pip"
	moving_parts.append_array(pip_parts)
	# An unattached owner calls the real trajectory function, without _ready(),
	# a window, audio, a save load, or the landing-completion side effects.
	var owner = Main.new()
	owner.toast = toast
	owner.pip = Node3D.new()
	owner.pip_art = pip
	owner.flying = true
	var inverse_carton := Transform3D(Basis(Vector3.UP, CARTON_YAW), CARTON_POSITION).affine_inverse()
	var previous_bounds: Dictionary = {}
	for sample in range(SAMPLES):
		var u := minf(float(sample) / (SAMPLES - 1), 0.999999)
		owner.flight_time = u * 3.1
		owner.update_flight(0.0)
		var toast_transform: Transform3D = toast.transform
		# Full flying stretch plus worst-case walking bob covers animation.
		var pip_basis: Basis = pip.basis.scaled(Vector3(1.0 / sqrt(1.04), 1.04, 1.0 / sqrt(1.04)))
		var pip_transform := Transform3D(pip_basis, owner.pip.position + Vector3(0, 0.048, 0))
		var any_crossing := false
		for part in moving_parts:
			# Compose every transform before axis alignment so the test remains
			# conservative without spuriously expanding an aligned toast twice.
			var actor_transform: Transform3D = toast_transform if part.family == "toast" else pip_transform
			var mesh_in_carton: Transform3D = inverse_carton * actor_transform * part["transform"]
			var bounds: AABB = mesh_in_carton * part["bounds"]
			var current_bounds := bounds
			if previous_bounds.has(part.name):
				# During the constant-yaw linear passage the union bounds contain
				# every intermediate translated mesh, not only the sampled poses.
				bounds = bounds.merge(previous_bounds[part.name])
			previous_bounds[part.name] = current_bounds
			if bounds.end.z < aperture.z_min or bounds.position.z > aperture.z_max:
				continue
			if (u <= 0.20 or u >= 0.65) and failures.size() < 20:
				failures.append({"part":part.name,"u":u,"reason":"Carton crossing must remain in the fixed-yaw linear segment for swept-bounds proof."})
			any_crossing = true
			checks += 1
			var margins := {
				"left": bounds.position.x - aperture.left,
				"right": aperture.right - bounds.end.x,
				"bottom": bounds.position.y - aperture.bottom,
				"top": aperture.top - bounds.end.y
			}
			for edge in margins:
				var margin: float = margins[edge]
				if margin < minimum_margin:
					minimum_margin = margin
					closest_record = {"part":part.name,"edge":edge,"u":u,"margin":margin}
				if margin < -0.0001 and failures.size() < 20:
					failures.append({"part":part.name,"edge":edge,"u":u,"penetration":-margin})
		if any_crossing:
			checked_crossing_samples += 1
	var report := {
		"passed":failures.is_empty() and checks > 0,
		"method":"2401 calls to main.update_flight(); actual per-mesh AABBs swept between consecutive poses; crossing confined to fixed-yaw linear segment; flight stretch1.04 and max bob0.048",
		"aperture_local":aperture,"carton_position":str(CARTON_POSITION),"carton_yaw":CARTON_YAW,
		"mesh_plane_checks":checks,"samples_within_carton":checked_crossing_samples,
		"minimum_margin":minimum_margin,"closest":closest_record,"failures":failures,
		"limitations":"Conservative AABBs can report false positives at rounded corners. This checks authored flight geometry, not gameplay input, camera or renderer."
	}
	DirAccess.make_dir_recursive_absolute("res://evidence")
	var file := FileAccess.open("res://evidence/flight_clearance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report,"\t"))
	cereal.free()
	toast.free()
	pip.free()
	owner.pip.free()
	owner.free()
	quit(0 if report.passed else 1)

func _bounds(node: MeshInstance3D) -> AABB:
	return node.transform * node.mesh.get_aabb()

func _aperture(cereal: Node3D) -> Dictionary:
	var left := maxf(_bounds(cereal.get_node("FrontLeft")).end.x, _bounds(cereal.get_node("BackLeft")).end.x)
	left = maxf(left, _bounds(cereal.get_node("WindowTrimLeft")).end.x)
	var right := minf(_bounds(cereal.get_node("FrontRight")).position.x, _bounds(cereal.get_node("BackRight")).position.x)
	right = minf(right, _bounds(cereal.get_node("WindowTrimRight")).position.x)
	var bottom := maxf(_bounds(cereal.get_node("FrontLower")).end.y, _bounds(cereal.get_node("BackLower")).end.y)
	bottom = maxf(bottom, _bounds(cereal.get_node("WindowTrimBottom")).end.y)
	var top := minf(_bounds(cereal.get_node("FrontUpper")).position.y, _bounds(cereal.get_node("BackUpper")).position.y)
	top = minf(top, _bounds(cereal.get_node("WindowTrimTop")).position.y)
	return {"left":left,"right":right,"bottom":bottom,"top":top,"z_min":-0.64,"z_max":0.66}

func _gather(node: Node3D, parent_transform: Transform3D, parts: Array, prefix: String) -> void:
	var transform := parent_transform * node.transform
	if node is MeshInstance3D and node.mesh:
		parts.append({"name":prefix + "/" + node.name,"bounds":node.mesh.get_aabb(),"transform":transform})
	for child in node.get_children():
		if child is Node3D and child.visible:
			_gather(child, transform, parts, prefix + "/" + node.name)
