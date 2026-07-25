extends Area3D

@export var next_scene: String = "res://levels/boss_arena_chimera.tscn"

var _is_active = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Wait before activating so we don't teleport the player instantly on load if they saved here
	get_tree().create_timer(1.0).timeout.connect(func(): _is_active = true)

func _on_body_entered(body: Node3D) -> void:
	if not _is_active:
		return
		
	if body.is_in_group("player"):
		# Save state if needed, then change scene to the boss arena
		if PlayerData.has_method("save_game"):
			PlayerData.save_game()
		
		# Prevent player from spawning at the portal's position in the new scene
		PlayerData.has_saved_position = false
		
		# Teleport to arena safely after physics step
		get_tree().call_deferred("change_scene_to_file", next_scene)
