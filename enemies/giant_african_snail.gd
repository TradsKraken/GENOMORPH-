class_name GiantAfricanSnail
extends EnemyBase

@export var damage_per_second: float = 0.0 # Uses spit instead
@export var attack_range: float = 15.0 # Ranged attack from further away
@export var aggro_range: float = 20.0
@export var territory_radius: float = 25.0
@export var spit_cooldown: float = 3.0
@export var spit_scene: PackedScene = preload("res://enemies/toxic_spit.tscn")

var _attack_timer: float = 0.0
var _anim_player: AnimationPlayer = null
var _anim_cache: Dictionary = {}
var _cached_anim_keys: Array = []
func _ready() -> void:
	base_scale = 0.4 # Shrink the snail by default!
	label_height_offset = 3.5 # The Snail is massive, raise the level text!
	super._ready()
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	health = max_health
	if is_equal_approx(speed, 0.3):
		speed = 1.0 # Snails are slow!
	speed += randf_range(-0.2, 0.2) 
	spit_cooldown += randf_range(-0.5, 0.5)
	_attack_timer = randf_range(0.0, spit_cooldown * 0.8)

	_anim_player = _find_animation_player(self)
	if is_instance_valid(_anim_player):
		var anims = _anim_player.get_animation_list()
		for a in anims:
			_anim_cache[a.to_lower()] = a
		_cached_anim_keys = _anim_cache.keys()
	_play_anim("idle")
	
	if is_instance_valid(_anim_player) and _anim_player.is_playing():
		var anim_len = _anim_player.current_animation_length
		if anim_len > 0:
			_anim_player.seek(randf_range(0.0, anim_len), true)

func _process_movement(delta: float) -> void:
	if not is_instance_valid(target): return
	
	var dist_to_target = global_position.distance_to(target.global_position)
	
	if dist_to_target <= aggro_range:
		PlayerData.unlock_knowledge("giant_african_snail")
	
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
		_attack_timer += delta
		
		# Play attack animation slightly before spitting
		if _attack_timer >= spit_cooldown - 0.5 and _attack_timer - delta < spit_cooldown - 0.5:
			_play_anim("attack")
			
		if _attack_timer >= spit_cooldown:
			_attack_timer = 0.0
			_spit_at_target()
			
		# Play idle while waiting for cooldown
		if _attack_timer < spit_cooldown - 0.5:
			_play_anim("idle")
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
	
	var keyword_lower = keyword.to_lower()
	var current_lower = _anim_player.current_animation.to_lower()
	
	if current_lower != "" and keyword_lower in current_lower and _anim_player.is_playing():
		return # Already playing a matching animation
		
	if _anim_player.has_animation(keyword):
		_anim_player.play(keyword)
		return
		
	for key in _cached_anim_keys:
		if keyword_lower in key:
			_anim_player.play(_anim_cache[key])
			return
			
	# Fallback to playing the first animation if idle is requested but not found
	if keyword_lower == "idle" and _cached_anim_keys.size() > 0:
		_anim_player.play(_anim_cache[_cached_anim_keys[0]])

func _spit_at_target() -> void:
	if not spit_scene or not is_instance_valid(target): return
	
	var spit = spit_scene.instantiate()
	get_tree().current_scene.add_child(spit)
	
	spit.global_position = global_position + Vector3(0, 0.5, 0)
	
	# Calculate direction to target with a slight arc or just straight
	var target_pos = target.global_position + Vector3(0, 1.0, 0)
	var dir = (target_pos - spit.global_position).normalized()
	spit.direction = dir
	
	spit.look_at(target_pos, Vector3.UP)
	
	AudioManager.play_sfx("spit", randf_range(0.8, 1.2))
