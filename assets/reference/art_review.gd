extends SceneTree
## Reproducible in-engine studio capture, separate from the game route.
const Art = preload("res://scripts/art.gd")

func _initialize() -> void:
	call_deferred("_setup")

func _setup() -> void:
	root.size = Vector2i(1920, 1080)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("e8d8bb")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e8e6df")
	env.ambient_light_energy = 0.26
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_color = Color("fff1d5")
	light.light_energy = 0.58
	light.shadow_enabled = true
	light.shadow_blur = 2.0
	light.directional_shadow_max_distance = 50.0
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(140, 0.3, 140)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -0.19
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("f5e6cc")
	floor_mat.roughness = 1.0
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)
	var kinds := ["spoon", "blueberry", "cereal", "napkin", "butter", "toaster", "toast"]
	for k in range(kinds.size()):
		for state in range(3):
			var p: Node3D = Art.prop(kinds[k])
			var ratio: float = [0.5, 1.0, 2.0][state]
			p.scale = Vector3.ONE * ratio
			p.position = Vector3(-16.5 + k * 5.5, 0, 5.5 - state * 6.3)
			world.add_child(p)
			_label(world, kinds[k].to_upper() + "  " + ["S", "N", "L"][state], p.position + Vector3(0, 0.03, 1.48), 0.024)
	var pip: Node3D = Art.pip()
	pip.position = Vector3(-16.5, 0, 11)
	pip.scale = Vector3.ONE * 2.4
	world.add_child(pip)
	_label(world, "PIP / RUNTIME MESHES", Vector3(-7, 0.02, 11), 0.045)
	_label(world, "TINY TROUBLE  /  GODOT ART CONTACT SHEET  /  S 0.5 - N 1 - L 2", Vector3(0, 0.02, 14), 0.035)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 26
	camera.position = Vector3(0, 27, 32)
	world.add_child(camera)
	camera.look_at(Vector3(0, 0, 1))
	camera.current = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var result := img.save_png("res://assets/reference/prop_states_engine.png")
	print("Art atlas save: ", result, " dimensions ", img.get_size())
	quit()

func _label(parent: Node3D, caption: String, pos: Vector3, pixel: float) -> void:
	var n := Label3D.new()
	n.text = caption
	n.font_size = 36
	n.pixel_size = pixel
	n.modulate = Color("384657")
	n.outline_size = 0
	n.rotation_degrees.x = -90
	n.position = pos
	parent.add_child(n)
