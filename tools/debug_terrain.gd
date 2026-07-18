@tool
extends EditorScript

var out_file

func _run():
	out_file = FileAccess.open("res://debug_out.txt", FileAccess.WRITE)
	var scene = load("res://Models/FINAL TERRAIN LEVEL 1.glb")
	if scene == null:
		out_file.store_line("FAILED TO LOAD GLB")
		out_file.close()
		return
	var root = scene.instantiate()
	_print_node(root, "")
	out_file.close()

func _print_node(node, indent):
	if node is MeshInstance3D:
		var info = indent + node.name + " (" + str(node.get_class()) + ") "
		info += "cast_shadow=" + str(node.cast_shadow) + " "
		if node.mesh:
			var mat = node.mesh.surface_get_material(0)
			if mat and mat is StandardMaterial3D:
				info += "shading=" + str(mat.shading_mode) + " dither=" + str(mat.distance_fade_mode) + " cull=" + str(mat.cull_mode) + " trans=" + str(mat.transparency) + " emission=" + str(mat.emission_enabled)
		out_file.store_line(info)
	elif "DirectionalLight3D" in node.get_class():
		out_file.store_line(indent + node.name + " LIGHT! shadow=" + str(node.shadow_enabled))
	for child in node.get_children():
		_print_node(child, indent + "  ")
