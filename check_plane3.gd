extends SceneTree
func _init():
    var scene = load('res://Models/FINAL TERRAIN LEVEL 1.glb')
    var inst = scene.instantiate()
    var plane = inst.find_child('*Plane_002*', true, false)
    var out = FileAccess.open('res://plane_check3.txt', FileAccess.WRITE)
    if plane:
        plane.create_trimesh_collision()
        var children = plane.get_children()
        out.store_line('Children after create_trimesh_collision: ' + str(children.size()))
        for c in children:
            out.store_line('- ' + c.name + ' (' + c.get_class() + ')')
    out.close()
    quit()
