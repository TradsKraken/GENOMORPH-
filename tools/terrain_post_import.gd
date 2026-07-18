@tool
extends EditorScenePostImport

func _post_import(scene):
	_add_collisions(scene)
	return scene

func _add_collisions(node: Node):
	if node is MeshInstance3D:
		var n = node.name.to_lower()
		# Skip anything with grass/leaf/flower in the name
		if not ("grass" in n or "leaf" in n or "flower" in n):
			node.create_trimesh_collision()
			
	for child in node.get_children():
		_add_collisions(child)
