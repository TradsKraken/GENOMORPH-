extends Node

func _ready() -> void:
	# This node just instantly kicks off the SceneLoader to load the Main Menu.
	# Because the Main Menu has to load the 3D world in the background, 
	# this ensures the player sees a loading screen immediately upon opening the app.
	
	# Give the engine one frame to stabilize, then load.
	call_deferred("_start_loading")

func _start_loading() -> void:
	get_node("/root/SceneLoader").load_scene("res://ui/main_menu.tscn")
