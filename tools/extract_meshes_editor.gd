@tool
extends EditorScript

func _run():
	print("Starting extraction...")
	var scene = load("res://levels/node_3d.tscn")
	if not scene:
		print("Failed to load scene.")
		return
		
	var node = scene.instantiate()
	var saved_count = 0
	
	for child in node.find_children("*", "MeshInstance3D", true, false):
		if child.mesh and (child.mesh.resource_path == "" or "::" in child.mesh.resource_path):
			var mesh = child.mesh
			var mesh_name = child.name.to_lower().replace(" ", "_").replace("(", "").replace(")", "")
			var mesh_path = "res://levels/extracted_" + mesh_name + "_" + str(hash(child.get_path())).replace("-", "") + ".res"
			
			var err = ResourceSaver.save(mesh, mesh_path)
			if err == OK:
				child.mesh = load(mesh_path)
				saved_count += 1
				print("Extracted mesh for " + child.name + " to " + mesh_path)
			else:
				print("Failed to save mesh for " + child.name)

	if saved_count > 0:
		var new_scene = PackedScene.new()
		var pack_err = new_scene.pack(node)
		if pack_err == OK:
			var save_err = ResourceSaver.save(new_scene, "res://levels/node_3d.tscn")
			if save_err == OK:
				print("Successfully updated scene. Extracted " + str(saved_count) + " meshes.")
			else:
				print("Failed to save the updated scene.")
		else:
			print("Failed to pack the updated scene.")
	else:
		print("No embedded meshes found or extracted.")
