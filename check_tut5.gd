extends SceneTree
func _init():
    var scene = load('res://levels/node_3d.scn')
    var inst = scene.instantiate()
    var out = FileAccess.open('res://tut5_check.txt', FileAccess.WRITE)
    var tut5 = inst.find_child('tut5', true, false)
    if tut5:
        out.store_line('tut5 minigame_enemies paths:')
        for path in tut5.get('minigame_enemies'):
            var node = inst.get_node_or_null(path)
            if node:
                out.store_line('- ' + str(path) + ' (' + node.get_class() + ')')
                if node.get_class() == 'Node3D' and node.get_script():
                    out.store_line('  script: ' + node.get_script().resource_path)
                    if 'EnemySpawner' in node.get_script().resource_path:
                        out.store_line('  enemy_scene: ' + str(node.get('enemy_scene').resource_path if node.get('enemy_scene') else 'null'))
                        out.store_line('  max_spawns: ' + str(node.get('max_spawns')))
                        
        out.store_line('tut5 children:')
        for c in tut5.get_children():
            out.store_line('- ' + c.name + ' (' + c.get_class() + ')')
            if c.get_script():
                out.store_line('  script: ' + c.get_script().resource_path)
    out.close()
    quit()
