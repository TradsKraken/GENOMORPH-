extends SceneTree
func _init():
    var scene = load('res://levels/node_3d.scn')
    var inst = scene.instantiate()
    var out = FileAccess.open('res://lolo_check.txt', FileAccess.WRITE)
    var npc = inst.find_child('NPC Frog', true, false)
    if npc:
        out.store_line('Found NPC: ' + npc.name)
        var p = npc.get_parent()
        out.store_line('Parent: ' + (p.name if p else 'null'))
    else:
        out.store_line('NPC not found')
    out.close()
    quit()
