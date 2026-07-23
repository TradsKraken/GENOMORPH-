class_name FeralTilapia
extends EnemyBase

@export var damage_per_second: float = 8.0
@export var attack_range: float = 1.5
@export var aggro_range: float = 20.0
@export var territory_radius: float = 40.0

var _attack_timer: float = 0.0
var _minigame_target: Node3D = null
var _anim_player: AnimationPlayer = null

func _ready() -> void:
	super._ready()
	# Tilapia can swim (float)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	
	health = max_health
	if is_equal_approx(speed, 0.3):
		speed = 5.0 # Fast pack hunters
	speed += randf_range(-1.0, 1.0) 
	
	_anim_player = _find_animation_player(self)
	_play_anim("idle")

func _process_movement(delta: float) -> void:
	var move_target = _minigame_target
	
	# If player attacked us, or no minigame target, target player
	if not is_instance_valid(move_target):
		move_target = target
		
	if not is_instance_valid(move_target):
		return
		
	var dist_to_target = global_position.distance_to(move_target.global_position)
	
	# Look at target
	var dir_to_target = (move_target.global_position - global_position)
	if dir_to_target.length() > 0.1:
		dir_to_target = dir_to_target.normalized()
		var target_angle = atan2(dir_to_target.x, dir_to_target.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 8.0 * delta)
		
	if dist_to_target <= attack_range:
		# Attack
		velocity = Vector3.ZERO
		_play_anim("attack")
		_attack_timer += delta
		if _attack_timer >= 1.0:
			_attack_timer -= 1.0
			if move_target.has_method("take_damage"):
				move_target.take_damage(damage_per_second)
	else:
		# Move towards target
		velocity = dir_to_target * speed
		_play_anim("swim")
		_attack_timer = 0.0
		
	move_and_slide()

func _find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _play_anim(keyword: String) -> void:
	if not is_instance_valid(_anim_player): return
	
	var current = _anim_player.current_animation
	if current != "" and keyword.to_lower() in current.to_lower() and _anim_player.is_playing():
		return # Already playing a matching animation
		
	if _anim_player.has_animation(keyword):
		_anim_player.play(keyword)
		return
		
	for a in _anim_player.get_animation_list():
		if keyword.to_lower() in a.to_lower():
			_anim_player.play(a)
			return
			
	# Fallback to playing the first animation if idle is requested but not found
	if keyword == "idle" and _anim_player.get_animation_list().size() > 0:
		_anim_player.play(_anim_player.get_animation_list()[0])
