class_name Rat
extends EnemyBase

@export var bite_damage: float = 6.0

func _ready() -> void:
	max_health = 25.0
	super._ready()

	speed = 3.5
	attack_range = 1.3
	detection_radius = 10.0
	recovery_time = 0.8
	patrol_radius = 4.0

	var anim_player = _find_animation_player(self)
	if anim_player:
		var anims = anim_player.get_animation_list()
		if anims.size() > 0:
			anim_player.play(anims[0])

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		_finish_attack()
		return

	var final_damage = DamageCalculator.calculate_enemy_damage(bite_damage)
	if target.has_method("take_damage"):
		target.take_damage(final_damage)
	AudioManager.play_sfx("hit", randf_range(1.3, 1.6))

	await get_tree().create_timer(0.15).timeout
	if is_dead:
		return

	_finish_attack()
