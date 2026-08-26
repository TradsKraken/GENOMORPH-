extends SceneTree
func _init():
    var scene = load('res://levels/node_3d.scn')
    var inst = scene.instantiate()
    var out = FileAccess.open('res://tut_check.txt', FileAccess.WRITE)
    for c in inst.get_children():
        if 'tut' in c.name.to_lower():
            out.store_line('- ' + c.name + ' (' + c.get_class() + ')')
            if c.get_class() == 'Area3D' or c is Area3D:
                out.store_line('  Type: ' + str(c.get('trigger_type')))
    out.close()
    quit()
