extends SceneTree
## Standalone menu rendering: does not mutate saves or operate the live game window.
const HUD = preload("res://scripts/hud.gd")
var results: Array = []
var failed := false
var bindings := {"move_up":"W", "move_down":"S", "move_left":"A", "move_right":"D", "jump":"Space", "interact":"E", "shrink":"Q", "grow":"F", "target":"Tab", "hint":"H", "reset":"R"}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("d5ba91")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var hud = HUD.new()
	root.add_child(hud)
	await process_frame
	for resolution in [Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = resolution
		await process_frame
		for kind in ["title", "pause", "controls", "complete"]:
			match kind:
				"title": hud.show_title(true)
				"pause": hud.show_pause(false, 0.55, 0.8, 1.25)
				"controls": hud.show_controls(bindings)
				"complete": hud.show_complete(true)
			await process_frame
			await process_frame
			await process_frame
			var rect: Rect2 = hud.menu.get_global_rect()
			var viewport_rect: Rect2 = hud.root.get_global_rect()
			var contained: bool = viewport_rect.encloses(rect)
			var controls_short: bool = kind != "controls" or rect.size.y < 670
			var result := {"menu":kind,"window":str(resolution),"viewport":str(viewport_rect),"menu_rect":str(rect),"fully_inside":contained,"controls_under_670":controls_short}
			results.append(result)
			print(result)
			if not contained or not controls_short:
				failed = true
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://evidence/ui_" + kind + "_" + str(resolution.x) + ".png")
	var file := FileAccess.open("res://evidence/ui_layout_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	hud.queue_free()
	backdrop.queue_free()
	await process_frame
	quit(1 if failed else 0)
