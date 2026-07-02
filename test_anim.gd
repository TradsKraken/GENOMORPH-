extends SceneTree

func _init():
    var scene = load("res://Models/mosquito/mosquito1.glb").instantiate()
    var anim_player = scene.get_node_or_null("AnimationPlayer")
    if anim_player:
        print("ANIMATIONS: ", anim_player.get_animation_list())
    else:
        print("NO ANIMATION PLAYER FOUND")
    quit()
