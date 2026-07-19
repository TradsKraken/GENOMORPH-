extends Node

func _ready() -> void:
	print("Restoring Minimap and Root name...")
	
	var current_scene = load("res://ui/hud.tscn")
	var instance = current_scene.instantiate()
	
	# Find the auto-generated Root node
	var root_node = null
	for child in instance.get_children():
		if child is Control:
			root_node = child
			break
			
	if root_node:
		print("Found root node: ", root_node.name)
		root_node.name = "Root"
	else:
		print("Could not find root node!")
		get_tree().quit()
		return
		
	var old_scene = load("res://ui/hud_head.tscn")
	var old_instance = old_scene.instantiate()
	var old_root = old_instance.get_node("Root")
	
	if old_root and old_root.has_node("MinimapPanel"):
		var minimap = old_root.get_node("MinimapPanel")
		old_root.remove_child(minimap)
		root_node.add_child(minimap)
		_set_owner_recursive(minimap, instance)
		print("Restored MinimapPanel!")
	else:
		print("MinimapPanel not found in hud_head.tscn")
		
	var new_packed = PackedScene.new()
	new_packed.pack(instance)
	ResourceSaver.save(new_packed, "res://ui/hud.tscn")
	print("Successfully saved restored HUD!")
	
	old_instance.free()
	instance.free()
	get_tree().quit()

func _set_owner_recursive(node: Node, r: Node) -> void:
	if node != r and node.owner == null:
		node.owner = r
	for child in node.get_children():
		_set_owner_recursive(child, r)
