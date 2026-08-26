extends SceneTree
func _init():
    var scene = load('res://levels/node_3d.scn')
    var inst = scene.instantiate()
    var tut = inst.find_child('*tut*', true, false)
    if tut:
        print('Found tut:', tut.name)
        var parent = tut.get_parent()
        for c in parent.get_children():
            if 'tut' in c.name.to_lower():
                print('- ', c.name, ' (', c.get_class(), ')')
    else:
        print('no tut found')
    quit()
