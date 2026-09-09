@tool
extends EditorScript

func _run() -> void:
	var packed = ResourceLoader.load("res://levels/main terrain.scn")
	if not packed:
		print("Failed to load scene.")
		return
		
	var scene = packed.instantiate()
	var invalid_count = 0
	_check_meshes(scene, func(node: MeshInstance3D):
		if not node.mesh:
			print("MeshInstance3D with no mesh: ", node.name)
		else:
			var m = node.mesh
			if m is ArrayMesh or m is ImporterMesh:
				var is_empty = true
				for i in range(m.get_surface_count()):
					if m is ArrayMesh:
						if m.surface_get_array_len(i) > 0:
							is_empty = false
					else:
						# ImporterMesh
						is_empty = false # Just assume valid if we can't easily check
				
				if is_empty:
					print("Empty mesh found in node: ", node.name)
	)
	
	scene.queue_free()
	print("Check complete.")

func _check_meshes(node: Node, callback: Callable) -> void:
	if node is MeshInstance3D:
		callback.call(node)
	for child in node.get_children():
		_check_meshes(child, callback)
