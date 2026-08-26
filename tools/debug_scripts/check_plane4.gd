extends SceneTree
func _init():
    var scene = load('res://Models/FINAL TERRAIN LEVEL 1.glb')
    var inst = scene.instantiate()
    var plane = inst.find_child('*Plane_002*', true, false)
    var out = FileAccess.open('res://plane_check4.txt', FileAccess.WRITE)
    if plane:
        var before = plane.get_children().size()
        var parent_before = plane.get_parent().get_children().size()
        plane.create_trimesh_collision()
        var after = plane.get_children().size()
        var parent_after = plane.get_parent().get_children().size()
        out.store_line('Child count before: ' + str(before) + ' after: ' + str(after))
        out.store_line('Parent child count before: ' + str(parent_before) + ' after: ' + str(parent_after))
        
        var added = plane.get_child(plane.get_child_count() - 1)
        out.store_line('Added node name: ' + added.name)
        out.store_line('Added node owner: ' + str(added.owner))
    out.close()
    quit()
