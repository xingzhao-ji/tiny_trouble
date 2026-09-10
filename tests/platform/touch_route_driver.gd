extends "../replay_route.gd"
## The ordinary Harbor route with injected finger events instead of key/actions.
## This is macOS viewport simulation, never physical mobile input evidence.
var pad_down := false
var pad_position := Vector2.ZERO
var toast_samples := 0
var actor_overlap_frames := 0
var cargo_overlap_frames := 0
var worst_overlap: Array[Dictionary] = []
var camera_candidate_scale := 1.0
var camera_candidate_applied := false
var actor_pixel_heights: Array[float] = []
var actor_card_overlap_frames := 0
var card_visibility_samples := 0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--camera-study-scale="):
			camera_candidate_scale = clampf(float(arg.trim_prefix("--camera-study-scale=")), 0.7, 1.0)
	RenderingServer.frame_post_draw.connect(_inspect_toast)

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(game) and is_instance_valid(game.camera) and not camera_candidate_applied:
		game.camera.size *= camera_candidate_scale
		camera_candidate_applied = true

func _inspect_toast() -> void:
	if not is_instance_valid(game) or not game.started or game.paused: return
	var hud = game.hud
	var actor: Rect2 = _mesh_rect(game.pip)
	actor_pixel_heights.append(actor.size.y * float(DisplayServer.window_get_size().y) / get_viewport().get_visible_rect().size.y)
	if not hud.overlay.visible:
		card_visibility_samples += 1
		if (hud.top_card.visible and hud.top_card.get_global_rect().intersects(actor)) or (hud.target_card.visible and hud.target_card.get_global_rect().intersects(actor)):
			actor_card_overlap_frames += 1
	if hud.overlay.visible or not hud.message.visible or hud.message.modulate.a < 0.15: return
	toast_samples += 1
	var toast: Rect2 = hud.message.get_global_rect()
	var cargo: Rect2 = _mesh_rect(game.props.cargo) if game.state.aboard else Rect2()
	var actor_overlap: bool = toast.intersects(actor)
	var cargo_overlap: bool = cargo.has_area() and toast.intersects(cargo)
	actor_overlap_frames += 1 if actor_overlap else 0
	cargo_overlap_frames += 1 if cargo_overlap else 0
	if (actor_overlap or cargo_overlap) and worst_overlap.size() < 20:
		worst_overlap.append({"phase": game.state.phase, "toast": str(toast), "actor": str(actor), "cargo": str(cargo)})

func _mesh_rect(node: Node3D) -> Rect2:
	var bounds := Rect2()
	var initialized := false
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree() or mesh.mesh == null: continue
		var aabb = mesh.mesh.get_aabb()
		for i in 8:
			var point: Vector2 = game.camera.unproject_position(mesh.global_transform * aabb.get_endpoint(i))
			if not initialized:
				bounds = Rect2(point, Vector2.ZERO)
				initialized = true
			else: bounds = bounds.expand(point)
	return bounds

func finish_visibility_checks() -> Dictionary:
	check(toast_samples > 30, "Touch route samples actual rendered toast/actor geometry")
	check(actor_overlap_frames == 0 and cargo_overlap_frames == 0, "Transient feedback leaves actual Pip and aboard cargo mesh bounds visible")
	check(card_visibility_samples > 30 and actor_card_overlap_frames == 0, "Persistent objective and target cards leave actual Pip mesh bounds visible throughout the route")
	actor_pixel_heights.sort()
	return {"render_post_draw_samples": toast_samples, "actor_overlap_frames": actor_overlap_frames,
		"aboard_cargo_overlap_frames": cargo_overlap_frames, "first_overlaps": worst_overlap,
		"card_visibility_samples": card_visibility_samples, "actor_card_overlap_frames": actor_card_overlap_frames,
		"camera_study_scale": camera_candidate_scale,
		"actor_pixel_height_min": actor_pixel_heights[0] if not actor_pixel_heights.is_empty() else null,
		"actor_pixel_height_p50": actor_pixel_heights[int(actor_pixel_heights.size() * 0.5)] if not actor_pixel_heights.is_empty() else null,
		"method": "Projection of actual MeshInstance3D AABB corners at render-post-draw; conservative screen bounds, not pixel segmentation. Captures are separate from real-time performance."}

func key(code: int) -> void:
	var point := Vector2.ZERO
	if code == KEY_ENTER:
		for child in game.hud.menu_box.get_children():
			if child is Button:
				point = child.get_global_rect().get_center()
				break
		var event = InputEventMouseButton.new()
		event.position = get_viewport().get_final_transform() * point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		Input.parse_input_event(event)
		await get_tree().process_frame
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
	else:
		var action = {KEY_E: "interact", KEY_TAB: "target", KEY_1: "size_small", KEY_2: "size_normal", KEY_3: "size_large", KEY_SPACE: "jump", KEY_H: "hint"}.get(code, "")
		if action == "":
			check(false, "Touch route has a mapped control for key " + str(code))
			return
		point = game.hud.touch_controls.actions[action].get_center()
		_touch(2, point, true)
		await get_tree().process_frame
		_touch(2, point, false)
	await wait_seconds(0.25)

func _window_point(local: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * game.hud.touch_controls.get_global_transform_with_canvas() * local

func _touch(finger: int, point: Vector2, pressed: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index = finger
	event.position = _window_point(point)
	event.pressed = pressed
	Input.parse_input_event(event)

func drive(axis: Vector2) -> void:
	var touch = game.hud.touch_controls
	pad_position = touch.pad_center + axis * touch.pad_radius
	if not pad_down:
		_touch(1, pad_position, true)
		pad_down = true
	else:
		var event = InputEventScreenDrag.new()
		event.index = 1
		event.position = _window_point(pad_position)
		Input.parse_input_event(event)

func release_movement() -> void:
	if pad_down: _touch(1, pad_position, false)
	pad_down = false
