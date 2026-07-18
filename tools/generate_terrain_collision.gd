@tool
extends EditorScript

func _run():
	var root = get_editor_interface().get_edited_scene_root()
	if not root:
		print("ERROR: Please open your level scene first!")
		return
		
	var meshes = _get_all_meshes(root)
	var added_count = 0
	var skipped_count = 0
	
	for mesh in meshes:
		var n = mesh.name.to_lower()
		
		# Skip anything with "grass" in the name
		if "grass" in n or "leaf" in n or "flower" in n:
			skipped_count += 1
			continue
			
		# Check if it already has a static body
		var has_body = false
		for child in mesh.get_children():
			if child is StaticBody3D:
				has_body = true
				break
				
		if not has_body:
			# Generate the trimesh collision
			mesh.create_trimesh_collision()
			
			# Assign the owner to the scene root so it gets saved properly!
			# create_trimesh_collision() automatically adds a StaticBody3D -> CollisionShape3D
			for child in mesh.get_children():
				if child is StaticBody3D:
					child.owner = root
					for shape in child.get_children():
						shape.owner = root
						
			added_count += 1
			
	print("--- Collision Generation Complete ---")
	print("Added collisions to: ", added_count, " meshes.")
	print("Skipped grass/foliage: ", skipped_count, " meshes.")
	print("Make sure to Save your scene (Ctrl+S)!")

func _get_all_meshes(node: Node) -> Array:
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_get_all_meshes(child))
	return result
