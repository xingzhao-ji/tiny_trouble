extends RefCounted
class_name ChapterNavigation
## The caller awaits stop_audio() before switching. Paths are assigned before
## _ready so chapter playtests and real profiles remain isolated across scenes.


static func switch_scene(current: Node, scene_path: String, chapter_save_path: String, settings_path: String) -> Node:
	if not is_instance_valid(current) or not current.is_inside_tree(): return null
	if not ResourceLoader.exists(scene_path, "PackedScene"): return null
	var packed := load(scene_path) as PackedScene
	if packed == null: return null
	var next := packed.instantiate()
	if next == null: return null
	if not _has_property(next, "settings_path"):
		next.free()
		return null
	next.set("settings_path", settings_path)
	if _has_property(current, "save_path") and _has_property(next, "save_path"):
		next.set("save_path", current.get("save_path"))
	if _has_property(next, "chapter_profile_path"):
		next.set("chapter_profile_path", chapter_save_path)
	var tree := current.get_tree()
	tree.root.add_child(next)
	tree.current_scene = next
	current.queue_free()
	return next


static func _has_property(node: Node, property_name: String) -> bool:
	for property: Dictionary in node.get_property_list():
		if property["name"] == property_name: return true
	return false
