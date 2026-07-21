class_name MosquitoSwarm
extends EnemyBase

@export var damage_per_second: float = 2.0
@export var attack_range: float = 2.0
@export var aggro_range: float = 15.0

@export var territory_radius: float = 25.0

var _attack_timer: float = 0.0
var _wake_delay: float = 0.0

enum State { IDLE, ATTACK, RETURN }
var _current_state: State = State.IDLE
var _start_position: Vector3

func _ready() -> void:
	super._ready()
	_start_position = global_position
	# Flying enemies need Floating mode so they don't get stuck on terrain!
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	
	# Randomize slightly around the inspector-defined values so they don't move in perfect sync
	health = max_health
	if is_equal_approx(speed, 0.3): # 0.3 is the base enemy default, which is too slow for mosquitoes
		speed = 4.0
	speed += randf_range(-1.0, 1.5) 
	aggro_range += randf_range(-3.0, 3.0) 
	_wake_delay = randf_range(0.0, 1.5) 
	# We no longer hard-override max_health, exp_value, or enemy_level here.
	# This allows you to configure them manually in the Godot inspector for each mosquito!
	
	# Find and play the mosquito animation
	var anim_player = _find_animation_player(self)
	if anim_player:
		var anims = anim_player.get_animation_list()
		if anims.size() > 0:
			var anim = anim_player.get_animation(anims[0])
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.play(anims[0])
			
	# Add 3D audio for flying sound
	if AudioManager.sounds.has("mosquito_fly") and AudioManager.sounds["mosquito_fly"] != null:
		var fly_sfx = AudioStreamPlayer3D.new()
		fly_sfx.stream = AudioManager.sounds["mosquito_fly"]
		fly_sfx.autoplay = true
		fly_sfx.unit_size = 5.0
		fly_sfx.max_distance = 40.0
		fly_sfx.volume_db = 12.0
		fly_sfx.bus = "Master"
		add_child(fly_sfx)
		fly_sfx.play()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

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

func _process_movement(delta: float) -> void:
	if target == null:
		return
		
	var dist_to_player = global_position.distance_to(target.global_position)
	var dist_player_to_start = target.global_position.distance_to(_start_position)
	
	match _current_state:
		State.IDLE:
			# Wake up if the player is within the territory and within aggro range
			if can_auto_wake and dist_player_to_start <= territory_radius and dist_to_player <= aggro_range:
				if _wake_delay > 0.0:
					_wake_delay -= delta
				else:
					is_active = true
					_current_state = State.ATTACK
					
		State.ATTACK:
			# If player leaves the territory, lose interest and go back
			if dist_player_to_start > territory_radius:
				is_active = false
				_current_state = State.RETURN
				return
			
			var face_dir = global_position.direction_to(target.global_position)
			face_dir.y = 0
			if face_dir.length_squared() > 0.001:
				face_dir = face_dir.normalized()
				look_at(global_position + face_dir, Vector3.UP)
			
			if not is_passive and dist_to_player > attack_range * 0.9:
				_fly_towards(face_dir, target.global_position.y + 1.0)
			else:
				velocity = Vector3.ZERO
				
			if not is_passive and dist_to_player <= attack_range:
				_attack_timer += delta
				if _attack_timer >= 1.0:
					_attack_timer = 0.0
					if target.has_method("take_damage"):
						var final_damage = damage_per_second
						if target.is_in_group("player") and enemy_level > PlayerData.level:
							final_damage *= 10.0
						target.take_damage(final_damage)
			else:
				_attack_timer = 0.0
				
		State.RETURN:
			var dist_to_start = global_position.distance_to(_start_position)
			if dist_to_start < 1.0:
				velocity = Vector3.ZERO
				_current_state = State.IDLE
			else:
				var move_dir = global_position.direction_to(_start_position)
				move_dir.y = 0
				if move_dir.length_squared() > 0.001:
					move_dir = move_dir.normalized()
					look_at(global_position + move_dir, Vector3.UP)
				
				_fly_towards(move_dir, _start_position.y)
				
				# Re-aggro if player enters territory and range again
				if can_auto_wake and dist_player_to_start <= territory_radius and dist_to_player <= aggro_range:
					is_active = true
					_current_state = State.ATTACK

func _fly_towards(intended_dir: Vector3, target_y: float) -> void:
	var move_dir = intended_dir
	var space_state = get_world_3d().direct_space_state
	var ray_length = 3.0
	
	var exclude_rids = [self.get_rid()]
	if target and target is CollisionObject3D:
		exclude_rids.append(target.get_rid())
		
	var forward_query = PhysicsRayQueryParameters3D.create(global_position, global_position + intended_dir * ray_length)
	forward_query.exclude = exclude_rids
	
	var is_blocked = space_state.intersect_ray(forward_query)
	if is_blocked:
		var best_dir = intended_dir
		var best_score = -999.0
		
		for i in range(12):
			var angle = i * (TAU / 12.0)
			var dir = Vector3(cos(angle), 0, sin(angle))
			var score = dir.dot(intended_dir)
			
			var query = PhysicsRayQueryParameters3D.create(global_position, global_position + dir * ray_length)
			query.exclude = exclude_rids
			var result = space_state.intersect_ray(query)
			
			if result:
				var dist_to_hit = global_position.distance_to(result.position)
				score -= (ray_length - dist_to_hit) * 5.0
				
			if score > best_score:
				best_score = score
				best_dir = dir
				
		move_dir = best_dir.normalized()
		target_y += 2.5 # Fly up to get over the obstacle
		
	var y_diff = target_y - global_position.y
	velocity = Vector3(move_dir.x * speed, y_diff * 2.0, move_dir.z * speed)
	move_and_slide()
