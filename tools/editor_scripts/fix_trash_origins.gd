@tool
extends EditorScript

func _run() -> void:
	var interface = get_editor_interface()
	var edited_scene = interface.get_edited_scene_root()
	if not edited_scene:
		print("No scene open.")
		return
		
	var region = edited_scene.find_child("Q03TrashRegion", true, false)
	if not region:
		print("Q03TrashRegion not found in the open scene.")
		return
		
	print("Found Q03TrashRegion. Fixing children...")
	
	var fixed_count = 0
	for trash_node in region.get_children():
		if not trash_node is Node3D:
			continue
			
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(trash_node, meshes)
		if meshes.size() == 0:
			continue
			
		# Compute world-space AABB of all meshes in this trash node
		var wmin := Vector3(INF, INF, INF)
		var wmax := Vector3(-INF, -INF, -INF)
		
		for mesh in meshes:
			var aabb = mesh.get_aabb()
			for x in [aabb.position.x, aabb.end.x]:
				for y in [aabb.position.y, aabb.end.y]:
					for z in [aabb.position.z, aabb.end.z]:
						var wp = mesh.global_transform * Vector3(x, y, z)
						wmin.x = minf(wmin.x, wp.x)
						wmin.y = minf(wmin.y, wp.y)
						wmin.z = minf(wmin.z, wp.z)
						wmax.x = maxf(wmax.x, wp.x)
						wmax.y = maxf(wmax.y, wp.y)
						wmax.z = maxf(wmax.z, wp.z)
		
		var world_center = (wmin + wmax) * 0.5
		var mesh_bottom_center = Vector3(world_center.x, wmin.y, world_center.z)
		
		# We'll use the center for the origin, or bottom center. Let's use world_center
		# so it's directly in the middle of the trash.
		var new_origin = world_center
		
		# Save child global transforms
		var child_transforms = []
		for child in trash_node.get_children():
			if child is Node3D:
				child_transforms.append(child.global_transform)
			else:
				child_transforms.append(Transform3D.IDENTITY)
				
		# Move the trash node's origin to the center of its meshes
		trash_node.global_position = new_origin
		
		# Restore child global transforms so they don't visually move
		var idx = 0
		for child in trash_node.get_children():
			if child is Node3D:
				child.global_transform = child_transforms[idx]
			idx += 1
			
		fixed_count += 1
		print("Fixed origin for: ", trash_node.name)
		
	print("Finished! Fixed origins for ", fixed_count, " trash objects.")

func _collect_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_collect_meshes(child, meshes)
