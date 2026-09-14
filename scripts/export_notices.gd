extends SceneTree
## Obtain third-party notices from the pinned binary, without loading gameplay.
func _initialize() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): folder = arg.trim_prefix("--output=")
	if folder.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	var file := FileAccess.open(folder.path_join("GODOT_LICENSE.txt"), FileAccess.WRITE)
	if file == null: quit(1); return
	file.store_string("This game uses Godot Engine.\n\n" + Engine.get_license_text() + "\n")
	file.close()
	file = FileAccess.open(folder.path_join("GODOT_COMPONENT_NOTICES.txt"), FileAccess.WRITE)
	file.store_string("Godot Engine third-party components\nExtracted from " + Engine.get_version_info().string + "\n\n")
	for entry in Engine.get_copyright_info():
		file.store_string(str(entry.name) + "\n")
		for part in entry.parts:
			file.store_string("Files: " + ", ".join(part.files) + "\n")
			file.store_string("Copyright: " + "\n".join(part.copyright) + "\nLicense: " + str(part.license) + "\n\n")
	file.store_string("\nLicense texts\n\n")
	var licenses := Engine.get_license_info()
	for name in licenses:
		file.store_string(str(name) + "\n" + str(licenses[name]) + "\n\n")
	file.close()
	file = FileAccess.open(folder.path_join("engine-provenance.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info(), "executable_sha256": FileAccess.get_sha256(OS.get_executable_path()), "generator_sha256": FileAccess.get_sha256(get_script().resource_path)}, "\t") + "\n")
	file.close()
	print("Engine license and component notices exported")
	quit()
