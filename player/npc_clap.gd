extends Node3D

func _ready() -> void:
	# Find the AnimationPlayer node recursively
	var anim_player: AnimationPlayer = _find_anim_player(self)
	if anim_player:
		var anims = anim_player.get_animation_list()
		for anim_name in anims:
			# Skip the default RESET animation and play the actual animation
			if anim_name != "RESET":
				var anim = anim_player.get_animation(anim_name)
				if anim:
					# Enable looping on the animation data
					anim.loop_mode = Animation.LOOP_LINEAR
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
