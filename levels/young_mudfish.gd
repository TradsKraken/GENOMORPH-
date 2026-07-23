extends CharacterBody3D

@export var max_health: float = 20.0
var health: float

var is_dead: bool = false

func _ready() -> void:
	add_to_group("mudfish")
	health = max_health

func take_damage(amount: float) -> void:
	if is_dead: return
	health -= amount
	
	if health <= 0:
		die()
	else:
		# Dim the light slightly
		var light = get_node_or_null("OmniLight3D")
		if light:
			light.light_energy = (health / max_health) * 2.0

func die() -> void:
	is_dead = true
	var minigame = get_tree().get_first_node_in_group("oxygen_defense")
	if minigame and minigame.has_method("_on_mudfish_died"):
		minigame._on_mudfish_died(self)
		
	queue_free()
