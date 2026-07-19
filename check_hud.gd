extends SceneTree
func _init():
    var scene = load('res://ui/hud.tscn')
    if not scene:
        print('Failed to load hud.tscn')
        quit()
        return
    var inst = scene.instantiate()
    var root = inst.get_node('Root')
    print('Children of Root:')
    for c in root.get_children():
        print('- ', c.name)
    quit()
