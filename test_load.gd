extends SceneTree
func _init():
    var pd = preload("res://player/player_data.gd").new()
    pd.load_game(2)
    print("current_scene_path: ", pd.current_scene_path)
    print("player_position: ", pd.player_position)
    print("LOAD DONE")
    quit()
