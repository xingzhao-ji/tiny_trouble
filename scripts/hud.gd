extends CanvasLayer
class_name TinyHUD

signal command(action: String, value: Variant)
const INK = Color("384657")
const CREAM = Color("fff6e5")
const TEAL = Color("356f70")
var root: Control
var chapter: Label
var objective: Label
var subgoal: Label
var target_title: Label
var target_help: Label
var target_card: PanelContainer
var message: Label
var progress: Label
var overlay: ColorRect
var menu: PanelContainer
var menu_box: VBoxContainer
var font: Font
var started := false
var pause_open := false
var toast_time := 0.0
var size_buttons: Array[Button] = []
var menu_mode := ""

func _ready() -> void:
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
	variation.variation_opentype = {"weight": 600}
	font = variation
	theme.default_font = font
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", CREAM)
	theme.set_color("font_pressed_color", "Button", CREAM)
	theme.set_stylebox("normal", "Button", box(Color("ecdfc5"), 12, 12))
	theme.set_stylebox("hover", "Button", box(TEAL, 12, 12))
	theme.set_stylebox("pressed", "Button", box(Color("285858"), 12, 12))
	theme.set_stylebox("focus", "Button", border(Color.TRANSPARENT, Color("c95c54"), 12))
	root.theme = theme
	var top = PanelContainer.new()
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
	progress = label("BREAKFAST TABLE  /  01", 12, Color("705e4b"))
	col.add_child(progress)
	subgoal = label("A small adventure. A very big breakfast.", 16)
	subgoal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subgoal.custom_minimum_size.x = 292
	col.add_child(subgoal)
	var pause_button = button("Ⅱ  Pause", func(): command.emit("pause", null))
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
	var controls = label("WASD  Move     Space  Hop     E  Carry / Place     Tab  Target     Q / F  Resize     H  Hint     R  Reset", 14, INK)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 0
	controls.offset_right = 0
	controls.offset_top = -32
	controls.offset_bottom = -8
	controls.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(controls)
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
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.13, 0.19, 0.20, 0.36)
	root.add_child(overlay)
	var menu_center = CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(menu_center)
	menu = PanelContainer.new()
	menu.custom_minimum_size = Vector2(470, 0)
	menu.add_theme_stylebox_override("panel", box(CREAM, 25, 32))
	menu_center.add_child(menu)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 12)
	menu.add_child(menu_box)

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
	return b

func menu_label(text: String, size: int, color: Color = INK) -> void:
	var l = label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 400
	menu_box.add_child(l)

func clear_menu(mode: String) -> void:
	menu_mode = mode
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	overlay.show()
	call_deferred("focus_menu")
	menu.custom_minimum_size = Vector2(470, 0)
	menu.size = Vector2(470, 0)

func show_title(has_save: bool) -> void:
	clear_menu("title")
	menu_label("A HANDMADE LITTLE ADVENTURE", 12, TEAL)
	menu_label("Tiny\nTrouble", 64)
	menu_label("THE TOAST EXPRESS", 18, Color("a9563f"))
	menu_label("Meet Pip. Make small things mighty.\nCatch the most unlikely ride home.", 18)
	menu_box.add_child(button("Continue breakfast" if has_save else "Wake up, Pip   →", func(): command.emit("start", true)))
	if has_save:
		menu_box.add_child(button("Start a fresh breakfast", func(): command.emit("new", null)))
	menu_label("A solo diorama • Keyboard + mouse", 13, Color("705e4b"))

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
		b.add_theme_stylebox_override("normal", box(Color("ecdfc5"), 8, 7))
		b.add_theme_stylebox_override("hover", box(TEAL, 8, 7))
		b.add_theme_stylebox_override("pressed", box(Color("285858"), 8, 7))
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
	message.text = text
	toast_time = seconds

func update_target(title: String, help_text: String, size: int) -> void:
	target_title.text = title
	target_help.text = help_text
	for i in size_buttons.size():
		size_buttons[i].disabled = size < 0
		size_buttons[i].add_theme_stylebox_override("normal", border(Color("d4e3d9") if size == i else Color("ecdfc5"), TEAL if size == i else Color.TRANSPARENT, 8))

func _process(delta: float) -> void:
	toast_time = maxf(0, toast_time - delta)
	message.modulate.a = minf(toast_time * 2, 1)

func focus_menu() -> void:
	if not overlay.visible: return
	for child in menu_box.get_children():
		if child is Button:
			child.grab_focus()
			return
