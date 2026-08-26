extends SceneTree
func _init():
    var scene = load('res://levels/node_3d.scn')
    var inst = scene.instantiate()
    var out = FileAccess.open('res://path_check.txt', FileAccess.WRITE)
    
    var find_script = func(node, script_name, f):
        var script = node.get_script()
        if script and script_name in script.resource_path:
            out.store_line('Found script at: ' + str(node.get_path()))
        for c in node.get_children():
            f.call(c, script_name, f)
            
    find_script.call(inst, 'npc_frog.gd', find_script)
    
    var tut5 = inst.find_child('tut5', true, false)
    if tut5:
        out.store_line('Found tut5 at: ' + str(tut5.get_path()))
    
    out.close()
    quit()
