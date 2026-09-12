extends Node

## One effect per victim: maximum three stacks; further applications refresh expiry.
var stacks := 0
var damage_per_stack := 3.0
var remaining := 0.0
var tick := 0.0

static func apply(victim: Node, damage: float, duration: float = 4.0) -> void:
	if not is_instance_valid(victim) or victim.get("is_dead"):
		return
	var effect = victim.get_node_or_null("AdaptationPoison")
	if effect == null:
		effect = load("res://combat/adaptation_poison.gd").new()
		effect.name = "AdaptationPoison"
		victim.add_child(effect)
	effect.stacks = mini(3, effect.stacks + 1)
	effect.damage_per_stack = maxf(effect.damage_per_stack, damage)
	effect.remaining = duration

func _physics_process(delta: float) -> void:
	if get_parent().get("is_dead"):
		queue_free()
		return
	var active_delta := minf(delta, remaining)
	remaining -= delta
	tick += active_delta
	while tick >= 1.0:
		tick -= 1.0
		get_parent().take_damage(damage_per_stack * stacks)
		if get_parent().get("is_dead"):
			break
	if remaining <= 0.0:
		queue_free()
