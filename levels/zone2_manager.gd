extends Node

func _ready() -> void:
	# Listen for genome fragments collection and nests being cleared to open barriers
	PlayerData.genome_collected.connect(_on_genome_collected)

func _on_genome_collected() -> void:
	# If player has 2 or more fragments, open Zone 3 barrier
	if PlayerData.genome_fragments >= 2:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_subtitle"):
			hud.show_subtitle("System", "Zone 3 Barrier unlocked.")
