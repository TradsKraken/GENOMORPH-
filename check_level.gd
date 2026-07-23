extends SceneTree

func _init():
	var scene = load("res://levels/node_3d.scn")
	if scene:
		var root = scene.instantiate()
		print("Nodes in node_3d.scn:")
		_print_nodes(root, "")
	else:
		print("Failed to load node_3d.scn")
	quit()

func _print_nodes(node: Node, indent: String):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_nodes(child, indent + "  ")
