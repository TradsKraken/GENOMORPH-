extends Control

func _ready() -> void:
	# Focus the first button automatically so keyboard/controller navigation works
	$MarginContainer/VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed() -> void:
	# Change to your game scene.
	get_tree().change_scene_to_file("res://node_3d.tscn")

func _on_options_button_pressed() -> void:
	print("Open Options Menu")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
