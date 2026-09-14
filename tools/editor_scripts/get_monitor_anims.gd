@tool
extends EditorScript

func _run() -> void:
	var scene = load("res://Models/Water Monitor Lizard/Monitor Lizard FIXED.glb")
	if not scene: return
	var instance = scene.instantiate()
	var ap = _find_ap(instance)
	if ap:
		print("Water Monitor Animations: ", ap.get_animation_list())
	else:
		print("No AnimationPlayer found.")

func _find_ap(node: Node) -> AnimationPlayer:
	for c in node.get_children():
		if c is AnimationPlayer: return c
		var ap = _find_ap(c)
		if ap: return ap
	return null
