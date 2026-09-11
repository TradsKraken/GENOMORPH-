class_name EnemyBase
extends CharacterBody3D

@export var max_health: float = 50.0
@export var speed: float = 2.0
@export var exp_value: float = 10.0
@export var enemy_level: int = 1
@export var label_height_offset: float = 1.8
@export var base_scale: float = 1.0

# ── AI Config ───────────────────────────────────────────────────────────────
@export var detection_radius: float = 12.0
@export var attack_range: float = 2.0
@export var recovery_time: float = 1.5
@export var patrol_radius: float = 5.0
@export var patrol_speed_mult: float = 0.5
@export var gravity: float = 20.0
@export var uses_gravity: bool = true # Flying enemies can set this to false

# TEMPORARY — remove once the "enemy won't chase" bug is confirmed fixed.
@export var debug_ai: bool = false
var _debug_timer: float = 0.0
var _debug_label: Label3D = null

enum AIState { IDLE, PATROL, CHASE, ATTACK, RECOVER }
var current_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var patrol_target: Vector3 = Vector3.ZERO
var knockback_velocity: Vector3 = Vector3.ZERO
# ────────────────────────────────────────────────────────────────────────────

var health: float
var is_dead: bool = false
var is_dynamic: bool = false
var target: Node3D = null

var _hp_bg: Sprite3D
var _hp_fg: Sprite3D
var _level_label: Label3D

func _ready() -> void:
	_apply_level_scaling()
	
	health = max_health
	add_to_group("enemies")
	
	if not is_dynamic and get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		if PlayerData.is_object_destroyed(scene_path, node_path_str):
			queue_free()
			return
	
	_create_health_bar()
	
	# Find player target
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		
	# Start by idling
	current_state = AIState.IDLE
	state_timer = randf_range(1.0, 3.0)
		
func _apply_level_scaling() -> void:
	# Keep baseline stats for level 1, then scale up
	var level_multiplier = float(maxi(1, enemy_level)) - 1.0
	
	# +15% Health per level
	max_health += (max_health * 0.15) * level_multiplier
	
	# +20% EXP per level
	exp_value += (exp_value * 0.20) * level_multiplier
	
	# +5% Size per level, multiplied by their base scale
	var size_boost = 1.0 + (0.05 * level_multiplier)
	scale = Vector3(size_boost, size_boost, size_boost) * base_scale

func _update_level_label_color() -> void:
	if not _level_label:
		return
		
	var diff = enemy_level - PlayerData.level
	if diff <= -1:
		_level_label.modulate = Color(0.6, 0.6, 0.6) # Gray (Easy)
	elif diff == 0:
		_level_label.modulate = Color(1.0, 1.0, 1.0) # White (Normal)
	elif diff <= 2:
		_level_label.modulate = Color(1.0, 0.6, 0.1) # Orange (Hard)
	else:
		_level_label.modulate = Color(1.0, 0.2, 0.2) # Red (Deadly)
		
func show_on_minimap() -> void:
	var tree = get_tree()
	if not tree: return
	var hud = tree.get_first_node_in_group("hud")
	if hud and hud.has_method("add_minimap_marker"):
		hud.add_minimap_marker(self, Color(1.0, 0.1, 0.1), false)

func hide_from_minimap() -> void:
	var tree = get_tree()
	if not tree: return
	var hud = tree.get_first_node_in_group("hud")
	if hud and hud.has_method("remove_minimap_marker"):
		hud.remove_minimap_marker(self)

func _create_health_bar() -> void:
	# Background
	var bg_grad = Gradient.new()
	bg_grad.set_color(0, Color(0.1, 0.1, 0.1, 0.8))
	bg_grad.set_color(1, Color(0.1, 0.1, 0.1, 0.8))
	var bg_tex = GradientTexture2D.new()
	bg_tex.gradient = bg_grad
	bg_tex.width = 150
	bg_tex.height = 15
	
	_hp_bg = Sprite3D.new()
	_hp_bg.texture = bg_tex
	_hp_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bg.no_depth_test = true
	_hp_bg.position = Vector3(0, 1.4, 0)
	_hp_bg.pixel_size = 0.01
	_hp_bg.visible = false
	add_child(_hp_bg)
	
	# Foreground
	var fg_grad = Gradient.new()
	fg_grad.set_color(0, Color(0.9, 0.2, 0.2, 1.0))
	fg_grad.set_color(1, Color(0.9, 0.2, 0.2, 1.0))
	var fg_tex = GradientTexture2D.new()
	fg_tex.gradient = fg_grad
	fg_tex.width = 150
	fg_tex.height = 15
	
	_hp_fg = Sprite3D.new()
	_hp_fg.texture = fg_tex
	_hp_fg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_fg.no_depth_test = true
	_hp_fg.centered = false
	_hp_fg.offset = Vector2(-75, -7.5)
	_hp_fg.position = Vector3(0, 1.4, 0.001)
	_hp_fg.pixel_size = 0.01
	_hp_fg.visible = false
	add_child(_hp_fg)
	
	# Level Label
	_level_label = Label3D.new()
	_level_label.text = "Lv. %d" % enemy_level
	_level_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_level_label.no_depth_test = true
	_level_label.position = Vector3(0, label_height_offset, 0)
	_level_label.pixel_size = 0.002
	_level_label.outline_render_priority = 0
	_level_label.outline_size = 16
	_level_label.font_size = 256
	add_child(_level_label)
	
	_update_level_label_color()

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead or not visible:
		return
	
	health -= amount
	_show_damage_text(amount)
	knockback_velocity = knockback
	AudioManager.play_sfx("hit", randf_range(0.8, 1.2))
	
	# Auto-aggro when attacked
	if current_state == AIState.IDLE or current_state == AIState.PATROL:
		current_state = AIState.CHASE
	
	if health < max_health:
		_hp_bg.visible = true
		_hp_fg.visible = true
		var ratio = maxf(0.001, health / max_health)
		_hp_fg.scale.x = ratio
		_hp_fg.offset.x = -75.0 / ratio
	
	if health <= 0:
		if _level_label:
			_level_label.visible = false
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	
	if not is_dynamic and get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		PlayerData.mark_object_destroyed(scene_path, node_path_str)
	
	_spawn_exp_orb()
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if target == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			
	if uses_gravity and not is_on_floor():
		velocity.y -= gravity * delta
		
	# Handle knockback decay
	if knockback_velocity.length_squared() > 0.1:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 10.0 * delta)
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		move_and_slide()
		return # Cannot move normally while being knocked back
	
	_process_ai_state_machine(delta)
	move_and_slide()

	if debug_ai:
		if not is_instance_valid(_debug_label):
			_debug_label = Label3D.new()
			_debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_debug_label.no_depth_test = true
			_debug_label.position = Vector3(0, 2.3, 0)
			_debug_label.pixel_size = 0.006
			_debug_label.outline_size = 14
			_debug_label.font_size = 32
			_debug_label.modulate = Color.YELLOW
			add_child(_debug_label)

		_debug_timer += delta
		if _debug_timer >= 0.3:
			_debug_timer = 0.0
			var dist_str = "no target"
			if target and is_instance_valid(target):
				dist_str = "%.1fm" % global_position.distance_to(target.global_position)
			_debug_label.text = "[%s]\nvel=%.1f\ndist=%s\nphys=%s" % [
				AIState.keys()[current_state],
				velocity.length(),
				dist_str,
				str(is_physics_processing())
			]

			var player_count = get_tree().get_nodes_in_group("player").size()
			var target_name = "none"
			var target_pos = "n/a"
			if target and is_instance_valid(target):
				target_name = str(target.get_path())
				target_pos = str(target.global_position)
			print("[AI DEBUG] ", name, " state=", AIState.keys()[current_state],
				" self_pos=", global_position, " vel=", velocity,
				" target=", target_name, " target_pos=", target_pos,
				" player_nodes_in_group=", player_count)

# ── AI State Machine ──────────────────────────────────────────────────────────

func _process_ai_state_machine(delta: float) -> void:
	match current_state:
		AIState.IDLE:
			velocity.x = 0
			velocity.z = 0
			_check_player_detection()
			
			state_timer -= delta
			if state_timer <= 0:
				current_state = AIState.PATROL
				state_timer = randf_range(2.0, 5.0)
				_pick_patrol_target()
				
		AIState.PATROL:
			_check_player_detection()
			
			var dir = (patrol_target - global_position)
			if uses_gravity:
				dir.y = 0
			
			if dir.length() < 0.5:
				current_state = AIState.IDLE
				state_timer = randf_range(1.0, 3.0)
			else:
				dir = dir.normalized()
				velocity.x = dir.x * speed * patrol_speed_mult
				velocity.z = dir.z * speed * patrol_speed_mult
				_face_direction(dir, delta)
				
			state_timer -= delta
			if state_timer <= 0:
				current_state = AIState.IDLE
				state_timer = randf_range(1.0, 3.0)
				
		AIState.CHASE:
			if target and is_instance_valid(target):
				var dist_2d = Vector2(global_position.x, global_position.z).distance_to(Vector2(target.global_position.x, target.global_position.z))
				if dist_2d <= attack_range:
					current_state = AIState.ATTACK
					velocity.x = 0
					velocity.z = 0
					_perform_attack()
				else:
					var dir = (target.global_position - global_position)
					if uses_gravity:
						dir.y = 0
					else:
						# Flying enemies aim slightly above the player's center
						dir.y += 0.3 
						
					# Add separation to avoid clumping
					var separation = Vector3.ZERO
					for other in get_tree().get_nodes_in_group("enemies"):
						if other != self and is_instance_valid(other):
							var dist = global_position.distance_to(other.global_position)
							if dist < 1.5:
								separation += (global_position - other.global_position).normalized() * (1.5 - dist)
					
					dir = (dir.normalized() + separation * 0.8).normalized()
					
					velocity.x = dir.x * speed
					if not uses_gravity:
						velocity.y = dir.y * speed
					velocity.z = dir.z * speed
					_face_direction(dir, delta)
			else:
				current_state = AIState.IDLE
				
		AIState.ATTACK:
			# Base class does nothing but wait — velocity is left alone here on purpose.
			# Subclasses that override _perform_attack() (e.g. a lunge/dash) manage their
			# own velocity across the attack's frames; re-zeroing it every tick here would
			# stomp that movement one frame after it's set, which is exactly what was
			# happening (e.g. MosquitoSwarm's lunge got cancelled immediately, leaving
			# only its untouched Y-component to drift). The one-time zero at the
			# CHASE→ATTACK transition already covers subclasses that don't move at all.
			pass

		AIState.RECOVER:
			velocity.x = 0
			velocity.z = 0
			state_timer -= delta
			if state_timer <= 0:
				if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= detection_radius * 1.5:
					current_state = AIState.CHASE
				else:
					current_state = AIState.IDLE

func _check_player_detection() -> void:
	if target and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= detection_radius:
			current_state = AIState.CHASE

func _pick_patrol_target() -> void:
	var offset = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized() * randf_range(2.0, patrol_radius)
	patrol_target = global_position + offset

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() > 0.01:
		var target_y = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_y, 10.0 * delta)

# Virtual function for subclasses
func _perform_attack() -> void:
	# Default behavior: do nothing, just finish immediately
	_finish_attack()
	
func _finish_attack() -> void:
	current_state = AIState.RECOVER
	state_timer = recovery_time

# ── Spawns ────────────────────────────────────────────────────────────────────

func _spawn_exp_orb() -> void:
	var exp_script = load("res://levels/exp_orb.gd")
	if exp_script:
		AudioManager.play_sfx("exp_drop", randf_range(0.9, 1.1))
		var orb_count := randi_range(5, 10)
		for i in range(orb_count):
			var orb = exp_script.new()
			orb.global_position = global_position
			if "exp_grant" in orb:
				orb.exp_grant = 2.0
			if "velocity" in orb:
				var angle = randf() * TAU
				var spd = randf_range(3.0, 7.0)
				orb.velocity = Vector3(cos(angle) * spd, randf_range(4.0, 8.0), sin(angle) * spd)
			get_tree().current_scene.call_deferred("add_child", orb)

func _show_damage_text(amount: float) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 1.0, 0))
			hud.show_float_text(str(round(amount)), scr, Color.WHITE)
