@tool
extends EditorScript

func _run() -> void:
	var packed := ResourceLoader.load("res://levels/main terrain.scn")
	if packed:
		var scene = packed.instantiate()
		var file = FileAccess.open("res://tree_dump.txt", FileAccess.WRITE)
		_print_tree(scene, "", file)
		file.close()
		scene.queue_free()
		print("DUMP SUCCESS")
	else:
		print("FAILED TO LOAD SCENE")

func _print_tree(node: Node, indent: String, file: FileAccess) -> void:
	file.store_line(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_tree(child, indent + "  ", file)
