extends SceneTree
## Deterministic native table-only capture and draw-call comparison.
const Art = preload("res://scripts/art.gd")
var report: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d8c8ae")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f5e6cc")
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	scene.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-58, -28, 0)
	key.light_color = Color("fff0d4")
	key.light_energy = 0.58
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 55
	key.shadow_blur = 2.5
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 130, 0)
	fill.light_color = Color("b4d3d4")
	fill.light_energy = 0.12
	scene.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.7
	camera.position = Vector3(10, 16, 22)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var mode := "after" if "--after" in OS.get_cmdline_user_args() else "before"
	var table: Node3D = Art.table(mode == "after")
	scene.add_child(table)
	for i in 60:
		await process_frame
	var times: Array[float] = []
	var draw_samples: Array[float] = []
	var object_samples: Array[float] = []
	for i in 120:
		var start := Time.get_ticks_usec()
		await process_frame
		times.append((Time.get_ticks_usec() - start) / 1000.0)
		draw_samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		object_samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	times.sort()
	draw_samples.sort()
	object_samples.sort()
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("res://evidence/table_" + mode + ".png")
	report = {"mode":mode,"resolution":str(img.get_size()),"draw_calls_median":draw_samples[60],"rendered_objects_median":object_samples[60],"frame_ms_p50":times[60],"frame_ms_p95":times[114],"frame_ms_p99":times[118],"mesh_nodes":_mesh_nodes(table),"multimesh_nodes":_multimesh_nodes(table),"renderer":"Godot4.5.1 GL Compatibility / Apple M4 Pro","timing_note":"Native wall-clock samples include system load/vsync; draw count and fixed-image equivalence are the primary controlled comparison."}
	var f := FileAccess.open("res://evidence/table_" + mode + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report,"\t"))
	scene.queue_free()
	await process_frame
	quit()

func _mesh_nodes(n: Node) -> int:
	var total := 1 if n is MeshInstance3D else 0
	for child in n.get_children(): total += _mesh_nodes(child)
	return total

func _multimesh_nodes(n: Node) -> int:
	var total := 1 if n is MultiMeshInstance3D else 0
	for child in n.get_children(): total += _multimesh_nodes(child)
	return total
