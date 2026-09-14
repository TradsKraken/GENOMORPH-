@tool
extends EditorScript

func _run() -> void:
	var files = [
		"res://Models/Salamander/SalamanderFIXED.glb",
		"res://Models/Water Monitor Lizard/Monitor Lizard FIXED.glb"
	]
	
	for path in files:
		print("========================================")
		print("Animations in: " + path)
		var scene = load(path)
		if scene == null:
			print("Failed to load scene")
			continue
			
		var state = scene.get_state()
		for i in range(state.get_node_count()):
			var node_name = state.get_node_name(i)
			var node_type = state.get_node_type(i)
			if node_type == "AnimationPlayer":
				for j in range(state.get_node_property_count(i)):
					var prop_name = state.get_node_property_name(i, j)
					if prop_name.begins_with("libraries/"):
						var anim_lib = state.get_node_property_value(i, j)
						if anim_lib is AnimationLibrary:
							for anim_name in anim_lib.get_animation_list():
								print("- " + anim_name)
