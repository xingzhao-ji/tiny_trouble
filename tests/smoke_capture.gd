extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://smoke_capture_v1.json"
	root.add_child(game)
	await create_timer(1.5).timeout
	await game.capture("title")
	game.on_command("new", null)
	await create_timer(1.5).timeout
	await game.capture("opening")
	await game.stop_audio()
	game.queue_free()
	await process_frame
	quit()
