extends Node

func _ready():
	var hud = load("res://ui/hud.gd").new()
	add_child(hud)
	hud.name = "GameHUD"
	hud.layer = 10
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_to_group("hud")

	# _ready will be called when added to the tree, which builds the whole HUD.
	
	if hud._minimap_viewport:
		hud._minimap_viewport.world_3d = null

	_set_owner_recursive(hud, hud)

	var packed = PackedScene.new()
	packed.pack(hud)
	ResourceSaver.save(packed, "res://ui/hud.tscn")
	print("Saved hud.tscn successfully")
	get_tree().quit()

func _set_owner_recursive(node: Node, owner: Node):
	if node != owner:
		node.owner = owner
		if node.name == "" or node.name.begins_with("@"):
			node.name = node.get_class() + str(node.get_instance_id())
	for child in node.get_children():
		_set_owner_recursive(child, owner)
