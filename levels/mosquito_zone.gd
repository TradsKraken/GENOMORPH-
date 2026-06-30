extends Area3D

var _tutorial_shown: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is MosquitoSwarm:
				enemy.is_active = true
				
		if not _tutorial_shown:
			_tutorial_shown = true
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_tutorial"):
				hud.show_tutorial("MOSQUITO SWARM!", "A swarm of blood-suckers is approaching!\n\nTap the 🦵 button (Webbed Lunge) to attack them before they drain your health!")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is MosquitoSwarm:
				enemy.is_active = false
