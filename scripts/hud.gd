extends CanvasLayer
class_name TinyHUD

signal command(action: String, value: Variant)
const Design = preload("res://scripts/platform/design_tokens.gd")
const INK = Design.COLOR_INK
const CREAM = Design.COLOR_CREAM
const TEAL = Design.COLOR_TEAL
const DEFAULT_BINDINGS = {"move_up": "W", "move_down": "S", "move_left": "A", "move_right": "D",
	"jump": "Space", "interact": "E", "shrink": "Q", "grow": "F", "target": "Tab", "hint": "H", "reset": "R"}
const KEY_ACTIONS = {"Space": "jump", "E": "interact", "Tab": "target", "Q": "shrink", "F": "grow", "H": "hint", "R": "reset"}
var root: Control
var chapter: Label
var objective: Label
var subgoal: Label
var target_title: Label
var target_help: Label
var target_card: PanelContainer
var message: Label
var progress: Label
var controls: Label
var overlay: ColorRect
var menu: PanelContainer
var menu_box: VBoxContainer
var font: Font
var started := false
var pause_open := false
var toast_time := 0.0
var size_buttons: Array[Button] = []
var menu_mode := ""
var target_signature := ""
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate()
var interaction_label := "Carry / Place"
var key_pattern: RegEx
var target_help_source := "Walk over to the spoon to try your Scale Spool."
var toast_source := ""
var top_card: PanelContainer
var pause_button: Button
var menu_center: CenterContainer
var touch_controls: Control
var menu_scroll: ScrollContainer
var mobile_menu_center: CenterContainer
var rotation_guard: ColorRect
var touch_mode := false
var input_mode := "keyboard"
var safe_insets_override := Vector4(-1, -1, -1, -1)
var safe_rect := Rect2()
var text_scale := 1.0
var selected_size := -1
var layout_pending := false
var card_fit_pending := false

func _ready() -> void:
	touch_mode = touch_mode or OS.has_feature("mobile") or "--touch-ui" in OS.get_cmdline_user_args()
	if touch_mode: input_mode = "touch"
	font = load("res://assets/fonts/Nunito.ttf")
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 18
	var variation = FontVariation.new()
	variation.base_font = font
	# Godot's font variation dictionary accepts the friendly axis name or integer tag.
	variation.variation_opentype = {"weight": Design.TYPE_WEIGHT}
	font = variation
	theme.default_font = font
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", CREAM)
	theme.set_color("font_pressed_color", "Button", CREAM)
	theme.set_stylebox("normal", "Button", box(Design.COLOR_BUTTON_NORMAL, 12, 12))
	theme.set_stylebox("hover", "Button", box(TEAL, 12, 12))
	theme.set_stylebox("pressed", "Button", box(Design.COLOR_BUTTON_PRESSED, 12, 12))
	theme.set_stylebox("focus", "Button", border(Color.TRANSPARENT, Design.COLOR_FOCUS, 12))
	root.theme = theme
	top_card = PanelContainer.new()
	var top = top_card
	top.position = Vector2(28, 24)
	top.size = Vector2(322, 130)
	top.add_theme_stylebox_override("panel", box(CREAM, 18, 20))
	root.add_child(top)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	top.add_child(col)
	chapter = label("T I N Y   T R O U B L E", 13, TEAL)
	col.add_child(chapter)
	objective = label("The Toast Express", 27)
	col.add_child(objective)
	progress = label("BREAKFAST TABLE  /  01", 12, Design.COLOR_MUTED)
	col.add_child(progress)
	subgoal = label("A small adventure. A very big breakfast.", 16)
	subgoal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subgoal.custom_minimum_size.x = 292
	col.add_child(subgoal)
	pause_button = button("Ⅱ  Pause", func(): command.emit("pause", null))
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-148, 26)
	pause_button.size = Vector2(120, 44)
	pause_button.focus_mode = Control.FOCUS_NONE
	root.add_child(pause_button)
	target_card = PanelContainer.new()
	target_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	target_card.position = Vector2(28, -178)
	target_card.size = Vector2(380, 126)
	target_card.add_theme_stylebox_override("panel", box(CREAM, 16, 17))
	root.add_child(target_card)
	target_card.resized.connect(func(): call_deferred("_anchor_target_card"))
	var target_col = VBoxContainer.new()
	target_col.add_theme_constant_override("separation", 5)
	target_card.add_child(target_col)
	target_title = label("A tiny new beginning", 22)
	target_col.add_child(target_title)
	target_help = label("Walk over to the spoon to try your Scale Spool.", 15)
	target_help.custom_minimum_size.x = 335
	target_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_col.add_child(target_help)
	var sizes = HBoxContainer.new()
	sizes.add_theme_constant_override("separation", 7)
	target_col.add_child(sizes)
	for i in 3:
		var b = button(["1  Small", "2  Normal", "3  Large"][i], func(): command.emit("size", i))
		b.custom_minimum_size = Vector2(106, 34)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 14)
		sizes.add_child(b)
		size_buttons.append(b)
	controls = label("", 14, INK)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 0
	controls.offset_right = 0
	controls.offset_top = -32
	controls.offset_bottom = -8
	controls.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(controls)
	controls.resized.connect(_fit_footer)
	message = label("", 18, INK)
	message.add_theme_stylebox_override("normal", box(CREAM, 14, 12))
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message.position = Vector2(-205, -112)
	message.size = Vector2(595, 74)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	message.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(message)
	touch_controls = preload("res://scripts/platform/touch_controls.gd").new()
	root.add_child(touch_controls)
	touch_controls.action_pressed.connect(func(action): command.emit("touch", action))
	touch_controls.hide()
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.13, 0.19, 0.20, 0.36)
	root.add_child(overlay)
	menu_center = CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(menu_center)
	menu = PanelContainer.new()
	menu.custom_minimum_size = Vector2(Design.LAYOUT_DESKTOP_MENU_WIDTH, 0)
	menu.add_theme_stylebox_override("panel", box(CREAM, 25, 32))
	menu_center.add_child(menu)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 12)
	menu.add_child(menu_box)
	rotation_guard = ColorRect.new()
	rotation_guard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rotation_guard.color = CREAM
	root.add_child(rotation_guard)
	var rotate_center = CenterContainer.new()
	rotate_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rotation_guard.add_child(rotate_center)
	var rotate_text = label("Turn your device sideways.\n\nPip's adventure plays in landscape.\nYour progress is safe.", 52, INK)
	rotate_text.custom_minimum_size.x = 1000
	rotate_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotate_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotate_center.add_child(rotate_text)
	rotation_guard.hide()
	get_viewport().size_changed.connect(_queue_layout)
	for text_node in [objective, subgoal, target_title, target_help]:
		text_node.minimum_size_changed.connect(_queue_card_fit)
	_refresh_binding_text()
	_queue_layout()

func set_bindings(names: Dictionary) -> void:
	var updated: Dictionary = DEFAULT_BINDINGS.duplicate()
	for action in DEFAULT_BINDINGS:
		if names.has(action): updated[action] = str(names[action])
	if updated == bindings: return
	bindings = updated
	# The next target update may have the same authored text but new key labels.
	target_signature = ""
	_refresh_binding_text()

func _movement_keys() -> String:
	return "/".join([bindings["move_up"], bindings["move_left"], bindings["move_down"], bindings["move_right"]])

func _format_keys(source: String) -> String:
	if key_pattern == null:
		key_pattern = RegEx.new()
		key_pattern.compile("\\b(?:WASD|Space|Tab|E|Q|F|H|R)\\b")
	var result := ""
	var cursor := 0
	# Match only original text. A replacement that is another default key must
	# never be replaced a second time (for example E -> Q and Q -> E).
	for token: RegExMatch in key_pattern.search_all(source):
		result += source.substr(cursor, token.get_start() - cursor)
		var key: String = token.get_string()
		var display_bindings = bindings
		if input_mode == "touch":
			display_bindings = {"jump": "Hop", "interact": "Use", "target": "Target", "shrink": "Small", "grow": "Large", "hint": "Hint", "reset": "Pause → Reset"}
		elif input_mode == "controller":
			display_bindings = {"jump": "A", "interact": "X", "target": "Y", "shrink": "LB", "grow": "RB", "hint": "Back", "reset": "Start → Reset"}
		result += (_movement_keys() if input_mode == "keyboard" else "left stick" if input_mode == "controller" else "thumb pad") if key == "WASD" else str(display_bindings[KEY_ACTIONS[key]])
		cursor = token.get_end()
	result += source.substr(cursor)
	if input_mode == "touch":
		result = result.replace("1 / Small", "Small").replace("3 / Large", "Large").replace("1 /Small", "Small").replace("3 /Large", "Large")
		result = result.replace("Press 1", "Choose Small").replace("Press 2", "Choose Normal").replace("Press 3", "Choose Large")
	elif input_mode == "controller":
		result = result.replace("1 / LB", "LB").replace("3 / RB", "RB")
		result = result.replace("Press 1", "Use LB to choose Small").replace("Press 3", "Use RB to choose Large")
	return result

func _refresh_binding_text() -> void:
	if is_instance_valid(controls):
		controls.text = "%s  Move     %s  Hop     %s  %s     %s  Target     %s / %s  Resize     %s  Hint     %s  Reset" % [
			_movement_keys(), bindings["jump"], bindings["interact"], interaction_label, bindings["target"], bindings["shrink"], bindings["grow"], bindings["hint"], bindings["reset"]]
		if input_mode == "controller": controls.text = "Left stick  Move     A  Hop     X  %s     Y  Target     LB / RB  Resize     Back  Hint     Start  Pause" % interaction_label
		_fit_footer()
	if is_instance_valid(target_help): target_help.text = _format_keys(target_help_source)
	if is_instance_valid(message): message.text = _format_keys(toast_source)

func _fit_footer() -> void:
	if not is_instance_valid(controls) or font == null: return
	if touch_mode: return
	var available: float = get_viewport().get_visible_rect().size.x - 32.0
	var font_size := 14
	while font_size > 11 and font.get_string_size(controls.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available:
		font_size -= 1
	if controls.get_theme_font_size("font_size") != font_size:
		controls.add_theme_font_size_override("font_size", font_size)

func _anchor_target_card() -> void:
	if not is_instance_valid(target_card): return
	if touch_mode:
		var y: float = safe_rect.end.y - 120 - target_card.size.y
		var center_x: float = safe_rect.get_center().x - target_card.size.x * 0.5
		var candidates: Array[float] = [target_card.position.x, center_x,
			touch_controls.pad_center.x + touch_controls.pad_radius + 24,
			safe_rect.end.x - target_card.size.x - 24]
		var actor: Rect2 = actor_screen_rect()
		var obstacles: Array[Rect2] = [top_card.get_rect()]
		if touch_controls.enabled:
			for rect: Rect2 in touch_controls.actions.values(): obstacles.append(rect)
			obstacles.append(Rect2(touch_controls.pad_center - Vector2.ONE * touch_controls.pad_radius, Vector2.ONE * touch_controls.pad_radius * 2))
		var best_score := INF
		for x: float in candidates:
			var candidate := Rect2(Vector2(x, y), target_card.size)
			if not safe_rect.encloses(candidate): continue
			var score: float = candidate.intersection(actor).get_area() * 100.0
			for obstacle in obstacles: score += candidate.intersection(obstacle).get_area()
			if score < best_score:
				best_score = score
				target_card.position = candidate.position
		return
	# Longer remapped prompts grow upward, preserving a fixed gap above footer.
	target_card.offset_top = -52.0 - target_card.size.y
	target_card.offset_bottom = -52.0

func box(color: Color, radius: int, padding: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	s.shadow_color = Color(0.18, 0.14, 0.09, 0.16)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 4)
	return s

func border(color: Color, stroke: Color, radius: int) -> StyleBoxFlat:
	var s = box(color, radius, 12)
	s.border_color = stroke
	s.set_border_width_all(2)
	return s

func label(text: String, size: int, color: Color = INK) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func button(text: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.pressed.connect(callback)
	if touch_mode:
		b.custom_minimum_size.y = Design.LAYOUT_TOUCH_MIN_TARGET
		b.add_theme_font_size_override("font_size", 24)
	return b

func menu_label(text: String, size: int, color: Color = INK) -> void:
	var l = label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 400
	menu_box.add_child(l)

func clear_menu(mode: String) -> void:
	menu_mode = mode
	toast_time = 0.0
	message.modulate.a = 0.0
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	overlay.show()
	call_deferred("focus_menu")
	menu.custom_minimum_size = Vector2(Design.LAYOUT_DESKTOP_MENU_WIDTH, 0)
	menu.size = Vector2(Design.LAYOUT_DESKTOP_MENU_WIDTH, 0)
	_queue_layout()

func show_title(has_save: bool) -> void:
	clear_menu("title")
	menu_label("A HANDMADE LITTLE ADVENTURE", 12, TEAL)
	menu_label("Tiny\nTrouble", 64)
	menu_label("THE TOAST EXPRESS", 18, Color("a9563f"))
	menu_label("Meet Pip. Make small things mighty.\nCatch the most unlikely ride home.", 18)
	menu_box.add_child(button("Continue breakfast" if has_save else "Wake up, Pip   →", func(): command.emit("start", true)))
	if has_save:
		menu_box.add_child(button("Start a fresh breakfast", func(): command.emit("new", null)))
	menu_box.add_child(button("Visit the Matchbox Workshop", func(): command.emit("chapter", null)))
	menu_label("A solo diorama • Touch controls" if touch_mode else "A solo diorama • Keyboard, mouse or controller", 13, Design.COLOR_MUTED)

func hide_menu() -> void:
	overlay.hide()
	pause_open = false

func show_pause(reduced: bool, music: float, effects: float, text_scale: float) -> void:
	clear_menu("pause")
	pause_open = true
	menu_label("A LITTLE BREATHER", 12, TEAL)
	menu_label("Breakfast can wait.", 30)
	menu_box.add_child(button("Back to Pip", func(): command.emit("resume", null)))
	menu_box.add_child(button("Reset this puzzle", func(): command.emit("reset", null)))
	var c = CheckButton.new()
	c.text = "Reduced motion"
	c.button_pressed = reduced
	c.toggled.connect(func(v): command.emit("reduced", v))
	menu_box.add_child(c)
	for entry in [["Music", music, "music"], ["Effects", effects, "effects"], ["Text size", text_scale, "text"]]:
		var row = HBoxContainer.new()
		var l = label(entry[0], 17)
		l.custom_minimum_size.x = 115
		row.add_child(l)
		var slider = HSlider.new()
		slider.min_value = 1.0 if entry[2] == "text" else 0.0
		slider.max_value = 1.25 if entry[2] == "text" else 1.0
		slider.step = 0.05
		slider.value = entry[1]
		slider.custom_minimum_size.x = 250
		slider.value_changed.connect(func(v): command.emit(entry[2], v))
		row.add_child(slider)
		menu_box.add_child(row)
	menu_box.add_child(button("Controls & remapping", func(): command.emit("controls", null)))
	menu_box.add_child(button("Save & return to title", func(): command.emit("title", null)))

func show_controls(bindings: Dictionary) -> void:
	clear_menu("controls")
	menu.custom_minimum_size.x = 680
	menu_label("MAKE YOURSELF AT HOME", 12, TEAL)
	menu_label("Your controls", 30)
	menu_label("Select a key to change it. Escape cancels a change.", 15)
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 8)
	menu_box.add_child(grid)
	for action in bindings:
		var action_name = label(action.capitalize().replace("_", " "), 16)
		action_name.custom_minimum_size.x = 117
		grid.add_child(action_name)
		var b = Button.new()
		b.text = bindings[action]
		b.pressed.connect(func():
			b.text = "Press a key…"
			command.emit("rebind", action))
		b.custom_minimum_size = Vector2(140, 34)
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_stylebox_override("normal", box(Design.COLOR_BUTTON_NORMAL, 8, 7))
		b.add_theme_stylebox_override("hover", box(TEAL, 8, 7))
		b.add_theme_stylebox_override("pressed", box(Design.COLOR_BUTTON_PRESSED, 8, 7))
		grid.add_child(b)
	menu_label("Gamepad: left stick move · A hop · X interact\nLB/RB size · Y target · Start pause", 14)
	menu_box.add_child(button("Back", func(): command.emit("pause", null)))

func show_complete(secret: bool) -> void:
	clear_menu("complete")
	menu_label("DELIVERY FOR THE MATCHBOX WORKSHOP", 12, TEAL)
	menu_label("Toastally brilliant.", 36)
	menu_label("One small Pip. One enormous breakfast.\nYou made it home aboard a slice of toast.", 18)
	menu_label("✦  Secret picnic discovered" if secret else "A tiny picnic is still tucked away somewhere…", 17, TEAL)
	menu_box.add_child(button("Another helping   ↻", func(): command.emit("new", null)))
	menu_box.add_child(button("Keep exploring", func(): command.emit("explore", null)))
	menu_box.add_child(button("Return to title", func(): command.emit("title", null)))

func toast(text: String, seconds := 3.8) -> void:
	toast_source = text
	message.text = _format_keys(text)
	toast_time = seconds
	if touch_mode: call_deferred("_fit_touch_toast")

func update_target(title: String, help_text: String, size: int) -> void:
	var signature = title + "\n" + help_text + "\n" + str(size)
	if signature == target_signature: return
	target_signature = signature
	target_title.text = title
	target_help_source = help_text
	target_help.text = _format_keys(help_text)
	selected_size = size
	if is_instance_valid(touch_controls):
		touch_controls.selected_size = size
		touch_controls.size_enabled = size >= 0
		touch_controls.queue_redraw()
	for i in size_buttons.size():
		size_buttons[i].disabled = size < 0
		size_buttons[i].add_theme_stylebox_override("normal", border(Design.COLOR_SELECTED if size == i else Design.COLOR_BUTTON_NORMAL, TEAL if size == i else Color.TRANSPARENT, 8))

func _process(delta: float) -> void:
	toast_time = maxf(0, toast_time - delta)
	message.modulate.a = minf(toast_time * 2, 1)
	touch_controls.set_enabled(touch_mode and input_mode == "touch" and not overlay.visible and not rotation_guard.visible)
	if touch_mode and not overlay.visible:
		_anchor_target_card()
		if toast_time > 0: _place_touch_toast()

func _input(event: InputEvent) -> void:
	var next_mode = input_mode
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25): next_mode = "controller"
	elif event is InputEventScreenTouch and touch_mode: next_mode = "touch"
	elif event is InputEventKey: next_mode = "keyboard"
	elif event is InputEventMouseButton and event.device >= 0: next_mode = "touch" if touch_mode and "--touch-ui" in OS.get_cmdline_user_args() else "keyboard"
	if next_mode != input_mode:
		input_mode = next_mode
		target_signature = ""
		_refresh_binding_text()
		_queue_layout()
		if input_mode != "touch": touch_controls.set_enabled(false)
		if touch_mode and input_mode == "touch" and not overlay.visible and not rotation_guard.visible:
			touch_controls.set_enabled(true)
			touch_controls._input(event)

func apply_text_scale(value: float) -> void:
	text_scale = value
	touch_controls.text_scale = value
	touch_controls.queue_redraw()
	target_help.add_theme_font_size_override("font_size", int((Design.TYPE_TOUCH_BODY_MIN if touch_mode else Design.TYPE_DESKTOP_TARGET_HELP) * value))
	subgoal.add_theme_font_size_override("font_size", int((Design.TYPE_TOUCH_BODY_MIN if touch_mode else 16) * value))
	_queue_layout()

func _queue_layout() -> void:
	if layout_pending: return
	layout_pending = true
	call_deferred("_layout")

func _layout() -> void:
	layout_pending = false
	if not is_instance_valid(root): return
	var extent: Vector2 = get_viewport().get_visible_rect().size
	safe_rect = Rect2(Vector2.ZERO, extent)
	if safe_insets_override.x >= 0:
		safe_rect = Rect2(Vector2(safe_insets_override.x, safe_insets_override.y), extent - Vector2(safe_insets_override.x + safe_insets_override.z, safe_insets_override.y + safe_insets_override.w))
	elif OS.has_feature("mobile"):
		var pixels = Vector2(DisplayServer.window_get_size())
		var area = Rect2(DisplayServer.get_display_safe_area())
		if pixels.x > 0 and pixels.y > 0 and area.has_area():
			var ratio = extent / pixels
			safe_rect = Rect2((area.position - Vector2(DisplayServer.window_get_position())) * ratio, area.size * ratio).intersection(safe_rect)
	if not touch_mode: return
	var portrait: bool = extent.y > extent.x
	if portrait and not rotation_guard.visible: command.emit("orientation", true)
	rotation_guard.visible = portrait
	controls.hide()
	if input_mode != "touch":
		controls.text = "Left stick Move · A Hop · X Use · Y Target · LB/RB Size · Start Pause" if input_mode == "controller" else "%s Move · %s Hop · %s Use · %s Target\n%s/%s Size · %s Hint · %s Reset · Esc Pause" % [_movement_keys(), bindings.jump, bindings.interact, bindings.target, bindings.shrink, bindings.grow, bindings.hint, bindings.reset]
		controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		controls.position = Vector2(safe_rect.position.x + 24, safe_rect.end.y - 80)
		controls.size = Vector2(safe_rect.size.x - 48, 64)
		controls.add_theme_font_size_override("font_size", 24)
		controls.show()
	touch_controls.arrange(safe_rect)
	top_card.position = safe_rect.position + Vector2(24, 16)
	top_card.size.x = Design.LAYOUT_TOUCH_OBJECTIVE_WIDTH
	chapter.hide()
	progress.hide()
	objective.add_theme_font_size_override("font_size", int(Design.TYPE_TOUCH_OBJECTIVE * text_scale))
	subgoal.custom_minimum_size.x = 480
	top_card.reset_size()
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	pause_button.position = Vector2(safe_rect.end.x - 164, safe_rect.position.y + 16)
	pause_button.size = Vector2(140, 88)
	pause_button.hide() # The multi-touch Pause target shares this same rectangle.
	target_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	target_help.custom_minimum_size.x = 460
	target_title.add_theme_font_size_override("font_size", int(Design.TYPE_TOUCH_TARGET_TITLE * text_scale))
	for b in size_buttons: b.hide()
	target_card.size.x = Design.LAYOUT_TOUCH_TARGET_CARD_WIDTH
	target_card.reset_size()
	_anchor_target_card()
	message.set_anchors_preset(Control.PRESET_TOP_LEFT)
	message.add_theme_font_size_override("font_size", int(Design.TYPE_TOUCH_BODY_MIN * text_scale))
	message.size = Vector2(Design.LAYOUT_TOUCH_TOAST_WIDTH, Design.LAYOUT_TOUCH_TOAST_MIN_HEIGHT)
	call_deferred("_fit_touch_toast")
	_queue_card_fit()
	if menu_scroll == null:
		menu_scroll = ScrollContainer.new()
		menu_scroll.follow_focus = true
		menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		overlay.add_child(menu_scroll)
		mobile_menu_center = CenterContainer.new()
		mobile_menu_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mobile_menu_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		menu_scroll.add_child(mobile_menu_center)
		menu.reparent(mobile_menu_center)
	menu_scroll.position = safe_rect.position + Vector2(20, 20)
	menu_scroll.size = safe_rect.size - Vector2(40, 40)
	mobile_menu_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mobile_menu_center.custom_minimum_size = Vector2(0, menu_scroll.size.y)
	menu.custom_minimum_size.x = minf(Design.LAYOUT_TOUCH_MENU_MAX_WIDTH, menu_scroll.size.x - 24)
	menu.size.x = menu.custom_minimum_size.x
	_tune_touch_menu(menu_box)
	menu.reset_size()
	if menu_mode == "workshop":
		top_card.hide()
		pause_button.hide()
		target_card.hide()
		message.hide()

func _fit_touch_toast() -> void:
	# Preserve the wrapping width while changing anchors; a zero-width intermediate
	# creates a stale, one-word-per-line Label minimum height after rotation.
	message.reset_size()
	message.size = Vector2(Design.LAYOUT_TOUCH_TOAST_WIDTH, maxf(Design.LAYOUT_TOUCH_TOAST_MIN_HEIGHT, message.get_combined_minimum_size().y))
	_place_touch_toast()

func _queue_card_fit() -> void:
	if not touch_mode or card_fit_pending: return
	card_fit_pending = true
	call_deferred("_fit_gameplay_cards")

func _fit_gameplay_cards() -> void:
	card_fit_pending = false
	# Containers grow for wrapped objectives, but do not shrink their assigned
	# height when the next objective becomes shorter. Refit after minimum changes.
	top_card.size = Vector2(Design.LAYOUT_TOUCH_OBJECTIVE_WIDTH, 0)
	target_card.size = Vector2(Design.LAYOUT_TOUCH_TARGET_CARD_WIDTH, 0)
	_anchor_target_card()
	_place_touch_toast()

func actor_screen_rect() -> Rect2:
	var scene = get_parent()
	var actor = scene.get("pip")
	var view = scene.get("camera")
	if not actor is Node3D or not view is Camera3D: return Rect2()
	var center: Vector2 = view.unproject_position(actor.global_position + Vector3(0, 0.45, 0))
	return Rect2(center - Vector2(70, 90), Vector2(140, 150))

func _place_touch_toast() -> void:
	if not is_instance_valid(message) or not safe_rect.has_area(): return
	var size: Vector2 = message.size
	var below_objective: float = top_card.position.y + top_card.size.y + 16
	var above_target: float = target_card.position.y - size.y - 16
	# Retain a clear placement so walking past an edge does not make the message
	# jump back and forth. Relocate only when another position improves clearance.
	var positions = [message.position, Vector2(safe_rect.position.x + 24, below_objective),
		Vector2(safe_rect.get_center().x - size.x / 2, above_target),
		Vector2(safe_rect.end.x - size.x - 24, safe_rect.position.y + 216),
		Vector2(safe_rect.position.x + 24, above_target)]
	var obstacles: Array[Rect2] = [top_card.get_rect(), target_card.get_rect()]
	if touch_controls.enabled:
		for rect: Rect2 in touch_controls.actions.values(): obstacles.append(rect)
		obstacles.append(Rect2(touch_controls.pad_center - Vector2.ONE * touch_controls.pad_radius, Vector2.ONE * touch_controls.pad_radius * 2))
	elif controls.visible: obstacles.append(controls.get_rect())
	var actor = actor_screen_rect()
	var best_score := INF
	for point: Vector2 in positions:
		var candidate = Rect2(point, size)
		if not safe_rect.encloses(candidate): continue
		var score: float = candidate.intersection(actor).get_area() * 100.0
		for obstacle in obstacles: score += candidate.intersection(obstacle).get_area()
		if score < best_score:
			best_score = score
			message.position = point

func _tune_touch_menu(node: Node) -> void:
	for child in node.get_children():
		if child is Label or child is Button:
			if not child.has_meta("touch_font_base"):
				child.set_meta("touch_font_base", maxi(Design.TYPE_TOUCH_BODY_MIN, child.get_theme_font_size("font_size")))
			child.add_theme_font_size_override("font_size", int(float(child.get_meta("touch_font_base")) * text_scale))
		if child is Button or child is Slider: child.custom_minimum_size.y = maxf(Design.LAYOUT_TOUCH_MIN_TARGET, child.custom_minimum_size.y)
		if child is GridContainer: child.columns = 2
		_tune_touch_menu(child)

func focus_menu() -> void:
	if not overlay.visible: return
	for child in menu_box.get_children():
		if child is Button:
			child.grab_focus()
			return
