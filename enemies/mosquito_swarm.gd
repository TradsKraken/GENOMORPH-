class_name MosquitoSwarm
extends EnemyBase

@export var damage_per_second: float = 2.0
@export var attack_range: float = 2.0
@export var aggro_range: float = 15.0

var _attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Flying enemies need Floating mode so they don't get stuck on terrain!
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	
	# Override base values
	max_health = 100.0
	health = max_health
	speed = 4.0
	exp_value = 15.0
	
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
var is_active: bool = false

func _process_movement(delta: float) -> void:
	if target == null:
		return
		
	var dist = global_position.distance_to(target.global_position)
	
	# Wake up if the player is within aggro range
	if not is_active and can_auto_wake and dist <= aggro_range:
		is_active = true
		
	if not is_active:
		return
	
	# Always face the target horizontally
	var face_dir = global_position.direction_to(target.global_position)
	face_dir.y = 0
	if face_dir.length_squared() > 0.001:
		face_dir = face_dir.normalized()
		look_at(global_position + face_dir, Vector3.UP)
	
	# Move towards target (skip if passive)
	if not is_passive and dist > attack_range * 0.9:
		# --- OBSTACLE AVOIDANCE ---
		var move_dir = face_dir
		var space_state = get_world_3d().direct_space_state
		var ray_length = 3.0
		
		var exclude_rids = [self.get_rid()]
		if target is CollisionObject3D:
			exclude_rids.append(target.get_rid())
			
		var forward_query = PhysicsRayQueryParameters3D.create(global_position, global_position + face_dir * ray_length)
		forward_query.exclude = exclude_rids
		
		# If straight path is blocked, find the best alternative direction
		if space_state.intersect_ray(forward_query):
			var best_dir = face_dir
			var best_score = -999.0
			
			# Check 12 directions in a circle
			for i in range(12):
				var angle = i * (TAU / 12.0)
				var dir = Vector3(cos(angle), 0, sin(angle))
				var score = dir.dot(face_dir) # Prefer moving towards target
				
				var query = PhysicsRayQueryParameters3D.create(global_position, global_position + dir * ray_length)
				query.exclude = exclude_rids
				var result = space_state.intersect_ray(query)
				
				if result:
					var dist_to_hit = global_position.distance_to(result.position)
					score -= (ray_length - dist_to_hit) * 5.0 # Heavy penalty if blocked
					
				if score > best_score:
					best_score = score
					best_dir = dir
					
			move_dir = best_dir.normalized()
		
		# Slight vertical bobbing
		var target_y = target.global_position.y + 1.0
		if space_state.intersect_ray(forward_query):
			target_y += 2.5 # Fly up to get over the obstacle!
			
		var y_diff = target_y - global_position.y
		velocity = Vector3(move_dir.x * speed, y_diff * 2.0, move_dir.z * speed)
		
		move_and_slide()
	else:
		# Stop pushing the player once in attack range
		velocity = Vector3.ZERO
		
	# Attack logic
	if not is_passive and dist <= attack_range:
		_attack_timer += delta
		if _attack_timer >= 1.0:
			_attack_timer = 0.0
			if target.has_method("take_damage"):
				target.take_damage(damage_per_second)
	else:
		_attack_timer = 0.0
