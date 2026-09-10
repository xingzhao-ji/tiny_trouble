extends Control
## Screen-touch input is tracked by finger ID, so moving and acting can overlap.
## Desktop tests may inject touch events; that is not physical-device testing.
signal action_pressed(action: String)
const Design = preload("res://scripts/platform/design_tokens.gd")
const INK = Design.COLOR_INK
const CREAM = Design.COLOR_CREAM
const TEAL = Design.COLOR_TEAL
var enabled := false
var safe_rect := Rect2()
var pad_center := Vector2.ZERO
var pad_radius := float(Design.LAYOUT_TOUCH_JOYSTICK_RADIUS)
var text_scale := 1.0
var pad_finger := -1
var pad_vector := Vector2.ZERO
var fingers: Dictionary = {}
var actions: Dictionary = {}
var size_enabled := true
var selected_size := -1
var font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var variation = FontVariation.new()
	variation.base_font = load("res://assets/fonts/Nunito.ttf")
	variation.variation_opentype = {"weight": Design.TYPE_WEIGHT}
	font = variation
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func arrange(rect: Rect2) -> void:
	safe_rect = rect
	pad_center = Vector2(rect.position.x + 122, rect.end.y - 120)
	var middle: float = rect.get_center().x
	actions = {
		"pause": Rect2(rect.end.x - 164, rect.position.y + 16, Design.LAYOUT_TOUCH_AUX_WIDTH, Design.LAYOUT_TOUCH_AUX_HEIGHT),
		"interact": Rect2(rect.end.x - 212, rect.end.y - 208, Design.LAYOUT_TOUCH_ACTION_WIDTH, Design.LAYOUT_TOUCH_ACTION_HEIGHT),
		"jump": Rect2(rect.end.x - 212, rect.end.y - 108, Design.LAYOUT_TOUCH_ACTION_WIDTH, Design.LAYOUT_TOUCH_ACTION_HEIGHT),
		"target": Rect2(rect.end.x - 164, rect.position.y + 116, Design.LAYOUT_TOUCH_AUX_WIDTH, Design.LAYOUT_TOUCH_AUX_HEIGHT),
		"hint": Rect2(rect.end.x - 328, rect.position.y + 16, Design.LAYOUT_TOUCH_AUX_WIDTH, Design.LAYOUT_TOUCH_AUX_HEIGHT),
		"size_small": Rect2(middle - 207, rect.end.y - 112, Design.LAYOUT_TOUCH_SIZE_WIDTH, Design.LAYOUT_TOUCH_SIZE_HEIGHT),
		"size_normal": Rect2(middle - 65, rect.end.y - 112, Design.LAYOUT_TOUCH_SIZE_WIDTH, Design.LAYOUT_TOUCH_SIZE_HEIGHT),
		"size_large": Rect2(middle + 77, rect.end.y - 112, Design.LAYOUT_TOUCH_SIZE_WIDTH, Design.LAYOUT_TOUCH_SIZE_HEIGHT)}
	queue_redraw()

func set_enabled(value: bool) -> void:
	if enabled == value: return
	enabled = value
	visible = value
	if not value: release_all()

func release_all() -> void:
	pad_finger = -1
	pad_vector = Vector2.ZERO
	fingers.clear()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		release_all()

func _input(event: InputEvent) -> void:
	if not enabled: return
	# A mouse can operate the explicit desktop touch preview. Ignore synthetic
	# mouse actions from the same real touch, while consuming their UI hit.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var touch = InputEventScreenTouch.new()
		touch.index = 100000
		touch.position = event.position
		touch.pressed = event.pressed
		if event.device >= 0: _input(touch)
		else:
			var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			if point.distance_to(pad_center) <= pad_radius + 20:
				get_viewport().set_input_as_handled()
			for rect in actions.values():
				if rect.has_point(point): get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and pad_finger == 100000:
		_move(get_global_transform_with_canvas().affine_inverse() * event.position - pad_center)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if not event.pressed or event.canceled:
			if event.index == pad_finger:
				pad_finger = -1
				_move(Vector2.ZERO)
			if fingers.erase(event.index): get_viewport().set_input_as_handled()
			queue_redraw()
			return
		if pad_finger < 0 and point.distance_to(pad_center) <= pad_radius + 20:
			pad_finger = event.index
			fingers[event.index] = "move"
			_move(point - pad_center)
			get_viewport().set_input_as_handled()
			return
		for action in actions:
			if actions[action].has_point(point):
				fingers[event.index] = action
				get_viewport().set_input_as_handled()
				if size_enabled or not str(action).begins_with("size_"):
					action_pressed.emit(action)
				queue_redraw()
				return
	elif event is InputEventScreenDrag and event.index == pad_finger:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_move(point - pad_center)
		get_viewport().set_input_as_handled()

func _move(offset: Vector2) -> void:
	pad_vector = (offset / pad_radius).limit_length()
	if pad_vector.length() < 0.16: pad_vector = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not enabled or font == null: return
	draw_circle(pad_center, pad_radius, Color(CREAM, 0.86))
	draw_arc(pad_center, pad_radius, 0, TAU, 64, TEAL, 3, true)
	draw_circle(pad_center + pad_vector * 54, 34, Color(TEAL, 0.90))
	var labels = {"pause": "Pause", "interact": "Use", "jump": "Hop", "target": "Target", "hint": "Hint",
		"size_small": "Small", "size_normal": "Normal", "size_large": "Large"}
	for action in actions:
		var rect: Rect2 = actions[action]
		var pressed: bool = action in fingers.values()
		var selected: bool = ["size_small", "size_normal", "size_large"].find(action) == selected_size and selected_size >= 0
		var disabled: bool = str(action).begins_with("size_") and not size_enabled
		var style = StyleBoxFlat.new()
		style.bg_color = Design.COLOR_DISABLED if disabled else (TEAL if pressed else (Design.COLOR_SELECTED if selected else CREAM))
		style.set_corner_radius_all(Design.RADIUS_TOUCH_BUTTON)
		style.set_border_width_all(3 if selected else 1)
		style.border_color = TEAL
		draw_style_box(style, rect)
		var text: String = labels[action]
		var font_size = int(Design.TYPE_TOUCH_BODY_MIN * text_scale)
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, rect.get_center() + Vector2(-text_size.x / 2, font.get_ascent(font_size) * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CREAM if pressed else INK)
