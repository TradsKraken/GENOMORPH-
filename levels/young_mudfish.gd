extends CharacterBody3D

@export var max_health: float = 20.0
var health: float

var is_dead: bool = false

@export var wander_radius: float = 4.0
@export var speed: float = 2.0

var _start_pos: Vector3
var _target_pos: Vector3
var _wander_timer: float = 0.0

func _ready() -> void:
	add_to_group("mudfish")
	health = max_health
	_start_pos = global_position
	_pick_new_target()

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_new_target()
		
	var dir = (_target_pos - global_position).normalized()
	velocity = dir * speed
	
	# Look at the direction they are moving
	if dir.length() > 0.1:
		var look_pos = global_position + dir
		look_pos.y = global_position.y # Keep it horizontal
		if global_position.distance_squared_to(look_pos) > 0.01:
			look_at(look_pos, Vector3.UP)
			
	move_and_slide()

func _pick_new_target() -> void:
	# Pick a random point around the starting position
	_target_pos = _start_pos + Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	_wander_timer = randf_range(2.0, 4.0)

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
