@tool
extends EditorScript

func _run() -> void:
	var root = StaticBody3D.new()
	root.name = "TrashPile"
	root.set_script(load("res://levels/trash_pile.gd"))
	
	# Load the GLB
	var glb = load("res://Models/TRASH_PLANTS ASSETS.glb")
	if glb:
		var mesh_instance = glb.instantiate()
		mesh_instance.name = "Model"
		root.add_child(mesh_instance)
		mesh_instance.owner = root
		
		# Move it up slightly so it doesn't clip into the ground
		mesh_instance.position = Vector3(0, 0.5, 0)
	else:
		print("Could not load TRASH_PLANTS ASSETS.glb")
		
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.0, 1.5, 2.0)
	collision.shape = shape
	collision.position = Vector3(0, 0.75, 0)
	root.add_child(collision)
	collision.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	
	var err = ResourceSaver.save(scene, "res://levels/trash_pile.tscn")
	if err == OK:
		print("Successfully saved res://levels/trash_pile.tscn")
	else:
		print("Error saving trash_pile.tscn: ", err)
