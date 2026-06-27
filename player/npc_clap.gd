extends Node3D

@export var interact_distance: float = 3.0

func _ready() -> void:
	# Remove the placeholder StaticBody3D so we can use a mesh-based one
	if has_node("StaticBody3D"):
		$StaticBody3D.queue_free()
		
	var mesh_instance = _find_mesh_instance(self)
	if mesh_instance:
		# Let Godot automatically generate a perfectly aligned and scaled StaticBody3D from the mesh
		mesh_instance.create_trimesh_collision()
		
		# The new StaticBody3D is created as a child of the mesh instance.
		# Let's find it and connect our click event to it.
		for child in mesh_instance.get_children():
			if child is StaticBody3D:
				# Ensure it interacts with standard layers
				child.collision_layer = 1
				child.collision_mask = 1
				child.input_event.connect(_on_input_event)
				break

func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance <= interact_distance:
				_play_animation()

func _play_animation() -> void:
	# Find the AnimationPlayer node recursively
	var anim_player: AnimationPlayer = _find_anim_player(self)
	if anim_player:
		var anims = anim_player.get_animation_list()
		for anim_name in anims:
			# Skip the default RESET animation and play the actual animation
			if anim_name != "RESET":
				var anim = anim_player.get_animation(anim_name)
				if anim:
					# Play once instead of looping
					anim.loop_mode = Animation.LOOP_NONE
				# Play the animation
				anim_player.play(anim_name)
				break

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_anim_player(child)
		if result:
			return result
	return null

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null
