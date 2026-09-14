class_name Snake
extends EnemyBase

@export var damage_per_second: float = 3.0

@export var aggro_range: float = 12.0
@export var territory_radius: float = 20.0


var _attack_timer: float = 0.0
var _wake_delay: float = 0.0
var _anim_player: AnimationPlayer = null

enum State { IDLE, ATTACK, RETURN }
var _current_state: State = State.IDLE
var _start_position: Vector3

func _ready() -> void:
	super._ready()
	_start_position = global_position
	# Snake is on the ground
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	health = max_health
	if is_equal_approx(speed, 0.3):
		speed = 2.5
	speed += randf_range(-0.5, 0.5) 
	aggro_range += randf_range(-2.0, 2.0) 
	_wake_delay = randf_range(0.0, 1.0) 
	_anim_player = _find_animation_player(self)
	if _anim_player:
		var crawl_animation := _find_crawl_animation(_anim_player)
		if crawl_animation != "":
			var animation := _anim_player.get_animation(crawl_animation)
			if animation:
				animation.loop_mode = Animation.LOOP_LINEAR
			_anim_player.play(crawl_animation)

func _find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _find_crawl_animation(player: AnimationPlayer) -> String:
	for animation_name in player.get_animation_list():
		if "snake crawl" in animation_name.to_lower():
			return animation_name
	return ""

func _apply_level_scaling() -> void:
	super._apply_level_scaling()
	
	# +10% Damage per level
	var level_multiplier = float(maxi(1, enemy_level)) - 1.0
	damage_per_second += (damage_per_second * 0.10) * level_multiplier

@export var is_passive: bool = false
@export var can_auto_wake: bool = true
var is_active: bool = false:
	set(value):
		if value != is_active:
			is_active = value
			if is_active:
				show_on_minimap()
				if _current_state == State.IDLE:
					_current_state = State.ATTACK
			else:
				hide_from_minimap()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if not is_active and _current_state == State.IDLE:
		_process_movement(delta)
		move_and_slide()
		return
		
	_process_movement(delta)
	
	# Only rotate Y axis so it doesn't pitch into the floor
	if velocity.length_squared() > 0.1:
		var look_dir = Vector3(velocity.x, 0, velocity.z)
		if look_dir.length_squared() > 0.001:
			var target_transform = transform.looking_at(global_position + look_dir, Vector3.UP)
			global_transform = global_transform.interpolate_with(target_transform, delta * 10.0)
			
	move_and_slide()
	_process_attack(delta)

func _process_movement(delta: float) -> void:
	if target == null:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 5.0)
		return
		
	var dist_to_player = global_position.distance_to(target.global_position)
	var dist_player_to_start = target.global_position.distance_to(_start_position)
	
	match _current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, speed * delta * 5.0)
			velocity.z = move_toward(velocity.z, 0, speed * delta * 5.0)
			
			if can_auto_wake and dist_player_to_start <= territory_radius and dist_to_player <= aggro_range:
				if _wake_delay > 0.0:
					_wake_delay -= delta
				else:
					is_active = true
					_current_state = State.ATTACK
					
		State.ATTACK:
			if dist_player_to_start > territory_radius:
				is_active = false
				_current_state = State.RETURN
				return
			
			var dir = global_position.direction_to(target.global_position)
			dir.y = 0
			dir = dir.normalized()
			
			if dist_to_player > attack_range * 0.8:
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
			else:
				velocity.x = move_toward(velocity.x, 0, speed * delta * 10.0)
				velocity.z = move_toward(velocity.z, 0, speed * delta * 10.0)
				
		State.RETURN:
			var dist_to_start = global_position.distance_to(_start_position)
			if dist_to_start < 1.0:
				velocity.x = move_toward(velocity.x, 0, speed * delta * 10.0)
				velocity.z = move_toward(velocity.z, 0, speed * delta * 10.0)
				_current_state = State.IDLE
			else:
				var dir = global_position.direction_to(_start_position)
				dir.y = 0
				dir = dir.normalized()
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed

func _process_attack(delta: float) -> void:
	if _current_state != State.ATTACK or target == null:
		return
		
	var dist = global_position.distance_to(target.global_position)
	if dist <= attack_range:
		_attack_timer += delta
		if _attack_timer >= 1.0:
			_attack_timer = 0.0
			_bite()
	else:
		_attack_timer = 0.0

func _bite() -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage_per_second)
		if AudioManager.sounds.has("hit"):
			AudioManager.play_sfx("hit", randf_range(1.2, 1.5))
		
func die() -> void:
	if is_dead: return
	super.die()
	hide_from_minimap()
	
	if target and target.has_method("add_exp"):
		target.add_exp(exp_value)
		
	if AudioManager.sounds.has("pop"):
		AudioManager.play_sfx("pop", randf_range(0.8, 1.2))
	queue_free()
