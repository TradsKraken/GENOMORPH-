extends SceneTree
func _init():
    var glb = preload("res://Models/Snail-Cane toad chimera/Snail-Cane Toad Chimera.glb")
    var scene = glb.instantiate()
    var f = FileAccess.open("res://test_anim_out.txt", FileAccess.WRITE)
    
    var anim = _find_anim(scene)
    if anim:
        f.store_line("ANIMATIONS FOUND:")
        for a in anim.get_animation_list():
            f.store_line(a)
    else:
        f.store_line("NO ANIMATION PLAYER FOUND")
    f.close()
    quit()

func _find_anim(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer: return node
    for c in node.get_children():
        var a = _find_anim(c)
        if a: return a
    return null
