extends SceneTree
## External harness for the exported PCK. Not included in the shipped app.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://export_route_test_%d.json" % OS.get_process_id()
	game.settings_path = "user://export_route_settings_%d.cfg" % OS.get_process_id()
	root.add_child(game)
	var runner_script = get_script().resource_path.get_base_dir().path_join("replay_route.gd")
	var runner = load(runner_script).new()
	root.add_child(runner)
	runner.run(game)
