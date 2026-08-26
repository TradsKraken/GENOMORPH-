extends SceneTree
func _init():
    var scene = load('res://Models/FINAL TERRAIN LEVEL 1.glb')
    if not scene:
        print('Failed to load scene')
        quit()
        return
    var inst = scene.instantiate()
    var plane = inst.find_child('*Plane_002*', true, false)
    var out = FileAccess.open('res://plane_check.txt', FileAccess.WRITE)
    if plane:
        out.store_line('Found Plane_002: ' + plane.name)
        out.store_line('Is MeshInstance3D: ' + str(plane is MeshInstance3D))
        out.store_line('Children:')
        for c in plane.get_children():
            out.store_line('- ' + c.name + ' (' + c.get_class() + ')')
            if c is StaticBody3D:
                for c2 in c.get_children():
                    out.store_line('  - ' + c2.name + ' (' + c2.get_class() + ')')
    else:
        out.store_line('Plane_002 not found')
    out.close()
    quit()
