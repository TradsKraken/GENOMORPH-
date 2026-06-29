class_name MosquitoSwarm
extends EnemyBase

@export var damage_per_second: float = 5.0
@export var attack_range: float = 2.0

var _attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Override base values
	max_health = 100.0
	health = max_health
	speed = 4.0
	exp_value = 15.0

func _process_movement(delta: float) -> void:
	if target == null:
		return
		
	var dist = global_position.distance_to(target.global_position)
	
	# Move towards target
	if dist > attack_range * 0.9:
		var dir = global_position.direction_to(target.global_position)
		# Keep it somewhat level, mosquitoes fly a bit above ground
		dir.y = 0
		dir = dir.normalized()
		
		# Slight vertical bobbing
		var target_y = target.global_position.y + 1.0
		var y_diff = target_y - global_position.y
		velocity = Vector3(dir.x * speed, y_diff * 2.0, dir.z * speed)
		
		move_and_slide()
	else:
		# Stop pushing the player once in attack range
		velocity = Vector3.ZERO
		
	# Attack logic
	if dist <= attack_range:
		_attack_timer += delta
		if _attack_timer >= 1.0:
			_attack_timer = 0.0
			if target.has_method("take_damage"):
				target.take_damage(damage_per_second)
	else:
		_attack_timer = 0.0
