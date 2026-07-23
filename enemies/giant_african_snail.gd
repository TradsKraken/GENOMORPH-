class_name GiantAfricanSnail
extends EnemyBase

@export var damage_per_second: float = 0.0 # Uses spit instead
@export var attack_range: float = 8.0 # Ranged attack
@export var aggro_range: float = 12.0
@export var territory_radius: float = 25.0
@export var spit_cooldown: float = 3.0
@export var spit_scene: PackedScene = preload("res://enemies/toxic_spit.tscn")

var _attack_timer: float = 0.0
var _anim_player: AnimationPlayer = null

func _ready() -> void:
	super._ready()
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	health = max_health
	if is_equal_approx(speed, 0.3):
		speed = 1.0 # Snails are slow!
	speed += randf_range(-0.2, 0.2) 

	_anim_player = _find_animation_player(self)
	_play_anim("idle")

func _process_movement(delta: float) -> void:
	if not is_instance_valid(target): return
	
	var dist_to_target = global_position.distance_to(target.global_position)
	
	# Lose aggro if too far
	if dist_to_target > territory_radius:
		# Return to spawn or just wander
		return
		
	# Look at target
	var dir_to_target = (target.global_position - global_position)
	dir_to_target.y = 0
	if dir_to_target.length() > 0.1:
		dir_to_target = dir_to_target.normalized()
		var target_angle = atan2(dir_to_target.x, dir_to_target.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)
		
	if dist_to_target <= attack_range:
		# In range to spit
		velocity = Vector3.ZERO
		_play_anim("attack")
		_attack_timer += delta
		if _attack_timer >= spit_cooldown:
			_attack_timer = 0.0
			_spit_at_target()
	else:
		# Move towards target
		velocity = dir_to_target * speed
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		_play_anim("walk")
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

func _spit_at_target() -> void:
	if not spit_scene or not is_instance_valid(target): return
	
	var spit = spit_scene.instantiate()
	spit.global_position = global_position + Vector3(0, 0.5, 0)
	
	# Calculate direction to target with a slight arc or just straight
	var dir = (target.global_position + Vector3(0, 1.0, 0) - spit.global_position).normalized()
	spit.direction = dir
	
	get_tree().current_scene.add_child(spit)
	AudioManager.play_sfx("spit", randf_range(0.8, 1.2))
