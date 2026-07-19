extends SceneTree

func _init():
	var out_file = FileAccess.open("D:/Godot/controls/debug_output.txt", FileAccess.WRITE)
	if not out_file:
		print("Failed to open file!")
		quit()
		return
	var scene = load("res://.godot/imported/FINAL TERRAIN LEVEL 1.glb-4a6f12d743477900b0cadb176e8a6671.scn")
	if scene == null:
		out_file.store_line("FAILED TO LOAD GLB SCN")
		quit()
		return
	var root = scene.instantiate()
	var plane = root.find_child("Plane_002", true, false)
	if plane:
		out_file.store_line("FOUND Plane_002!")
		out_file.store_line("Children:")
		for c in plane.get_children():
			out_file.store_line(" - " + c.name + " (" + str(c.get_class()) + ")")
			for cc in c.get_children():
				out_file.store_line("   - " + cc.name + " (" + str(cc.get_class()) + ")")
	else:
		out_file.store_line("Plane_002 NOT FOUND!")
	out_file.close()
	quit()
