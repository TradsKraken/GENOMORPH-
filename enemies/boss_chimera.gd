class_name BossChimera
extends EnemyBase

enum Phase { PHASE_1, PHASE_2, PHASE_3 }

var current_phase: Phase = Phase.PHASE_1
var _attack_timer: float = 0.0
var _sludge_timer: float = 0.0
var _current_attack: String = ""

# Boss configuration
@export var phase2_threshold: float = 0.6
@export var phase3_threshold: float = 0.3
@export var spit_scene: PackedScene = preload("res://enemies/toxic_spit.tscn")
@export var sludge_scene: PackedScene = preload("res://levels/toxic_sludge.tscn")

var _is_charging: bool = false
var _charge_dir: Vector3 = Vector3.ZERO
var _charge_timer: float = 0.0
var _is_stunned: bool = false
var _stun_timer: float = 0.0
var _slam_sequence_step: int = 0
var _slam_timer: float = 0.0
var _spin_active: bool = false

var shell_mesh: Node3D
var core_mesh: Node3D

func _ready() -> void:
	max_health = 500.0 # Boss health
	speed = 2.0
	exp_value = 200.0
	enemy_level = 5
	label_height_offset = 6.0
	base_scale = 3.0 # Massive boss
	super._ready()
	
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	# Find visual parts
	shell_mesh = get_node_or_null("Visuals/Shell")
	core_mesh = get_node_or_null("Visuals/Core")
	
	if core_mesh:
		core_mesh.visible = false # Hidden until phase 3

func take_damage(amount: float) -> void:
	if current_phase == Phase.PHASE_3 and not _is_core_exposed():
		# Shell deflects damage in phase 3
		AudioManager.play_sfx("deflect", 1.0)
		return
		
	super.take_damage(amount)
	_check_phase_transition()

func _is_core_exposed() -> bool:
	# Front-facing attack logic can be implemented here based on player position
	if not is_instance_valid(target): return true
	var dir_to_player = global_position.direction_to(target.global_position)
	var forward = -global_transform.basis.z
	var angle = forward.angle_to(dir_to_player)
	return angle < PI / 3.0 # 60 degree cone in front

func _check_phase_transition() -> void:
	var hp_pct = health / max_health
	if current_phase == Phase.PHASE_1 and hp_pct <= phase2_threshold:
		_transition_to_phase_2()
	elif current_phase == Phase.PHASE_2 and hp_pct <= phase3_threshold:
		_transition_to_phase_3()

func _transition_to_phase_2() -> void:
	current_phase = Phase.PHASE_2
	speed = 4.0
	AudioManager.play_sfx("roar", 1.0)
	# Visually crack shell
	if shell_mesh and shell_mesh is CSGSphere3D:
		shell_mesh.material.albedo_color = Color(0.8, 0.4, 0.2)

func _transition_to_phase_3() -> void:
	current_phase = Phase.PHASE_3
	speed = 2.5
	AudioManager.play_sfx("shell_break", 1.0)
	if shell_mesh:
		shell_mesh.scale = Vector3(1.2, 0.8, 0.5) # Broken look
	if core_mesh:
		core_mesh.visible = true

func _process_movement(delta: float) -> void:
	if _is_stunned:
		_stun_timer -= delta
		if _stun_timer <= 0:
			_is_stunned = false
		return
		
	if not is_instance_valid(target): return
	
	if _is_charging:
		_process_charge(delta)
		return
		
	if _current_attack != "":
		_process_attack_sequence(delta)
		return

	# Sludge trail in phase 1
	if current_phase == Phase.PHASE_1 and velocity.length() > 0.1:
		_sludge_timer += delta
		if _sludge_timer > 1.0:
			_sludge_timer = 0.0
			_spawn_sludge(global_position)
	
	# Spinning in phase 3
	if current_phase == Phase.PHASE_3 and _spin_active:
		rotation.y += 10.0 * delta
		_check_spin_collision()
		
	# Normal movement and attack decisions
	var dist_to_target = global_position.distance_to(target.global_position)
	
	# Look at target
	if not _spin_active:
		var dir_to_target = (target.global_position - global_position)
		dir_to_target.y = 0
		if dir_to_target.length() > 0.1:
			dir_to_target = dir_to_target.normalized()
			var target_angle = atan2(dir_to_target.x, dir_to_target.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)
			
	_attack_timer -= delta
	if _attack_timer <= 0:
		_choose_attack()
	else:
		# Approach
		var move_dir = (target.global_position - global_position).normalized()
		move_dir.y = 0
		velocity = move_dir * speed
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		move_and_slide()

func _choose_attack() -> void:
	velocity = Vector3.ZERO
	if current_phase == Phase.PHASE_1:
		if randf() > 0.5:
			_start_spit_volley()
		else:
			_start_shell_slam()
	elif current_phase == Phase.PHASE_2:
		var roll = randf()
		if roll < 0.33:
			_start_toxic_nova()
		elif roll < 0.66:
			_start_rapid_barrage()
		else:
			_start_charge()
	elif current_phase == Phase.PHASE_3:
		var roll = randf()
		if roll < 0.33:
			_start_spinning()
		elif roll < 0.66:
			_start_puddle_summon()
		else:
			_start_final_slam()

# --- Attack Implementations ---
func _start_spit_volley() -> void:
	_current_attack = "spit_volley"
	_attack_timer = 2.0
	_fire_spit_spread(3, 30.0)

func _fire_spit_spread(count: int, spread_deg: float) -> void:
	if not spit_scene or not is_instance_valid(target): return
	var base_dir = (target.global_position - global_position).normalized()
	base_dir.y = 0
	
	var angle_step = deg_to_rad(spread_deg) / max(1, count - 1)
	var start_angle = -deg_to_rad(spread_deg) / 2.0
	
	for i in range(count):
		var spit = spit_scene.instantiate()
		get_tree().current_scene.add_child(spit)
		spit.global_position = global_position + Vector3(0, 2.0, 0)
		var angle = start_angle + (i * angle_step)
		spit.direction = base_dir.rotated(Vector3.UP, angle)
		if "speed" in spit: spit.speed = 12.0
	AudioManager.play_sfx("spit", 1.0)

func _start_shell_slam() -> void:
	_current_attack = "shell_slam"
	_attack_timer = 2.5
	_slam_timer = 1.0 # 1 sec windup

func _execute_slam() -> void:
	# AoE Damage logic
	AudioManager.play_sfx("slam", 1.0)
	var p = get_tree().get_nodes_in_group("player")
	for player in p:
		if global_position.distance_to(player.global_position) < 8.0:
			if player.has_method("take_damage"):
				player.take_damage(20.0)

func _spawn_sludge(pos: Vector3) -> void:
	if sludge_scene:
		var sludge = sludge_scene.instantiate()
		get_tree().current_scene.add_child(sludge)
		sludge.global_position = pos
		# Orient sludge to ground
		sludge.global_position.y = 0.1

func _start_toxic_nova() -> void:
	_current_attack = "toxic_nova"
	_attack_timer = 3.0
	_fire_spit_spread(12, 360.0)

func _start_rapid_barrage() -> void:
	_current_attack = "rapid_barrage"
	_attack_timer = 3.0
	_slam_sequence_step = 6
	_slam_timer = 0.2 # fire every 0.2s

func _start_charge() -> void:
	_current_attack = "charge"
	_is_charging = true
	_charge_timer = 2.0
	_charge_dir = (target.global_position - global_position).normalized()
	_charge_dir.y = 0
	AudioManager.play_sfx("roar", 1.0)

func _process_charge(delta: float) -> void:
	velocity = _charge_dir * 15.0
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
	
	# Damage player on contact
	if global_position.distance_to(target.global_position) < 4.0:
		if target.has_method("take_damage"):
			target.take_damage(25.0)
			_is_charging = false
			_current_attack = ""
			_attack_timer = 2.0
			return
			
	# Hit wall logic (distance from center)
	# Assuming center is near 0,0,0 or we check raycast
	_charge_timer -= delta
	if _charge_timer <= 0:
		_is_charging = false
		_current_attack = ""
		_attack_timer = 2.0

func _start_spinning() -> void:
	_current_attack = "spinning"
	_spin_active = true
	_attack_timer = 4.0

func _check_spin_collision() -> void:
	if not is_instance_valid(target): return
	if global_position.distance_to(target.global_position) < 5.0:
		if target.has_method("take_damage"):
			target.take_damage(1.0) # Continuous small damage

func _start_puddle_summon() -> void:
	_current_attack = "puddle_summon"
	_attack_timer = 2.0
	if is_instance_valid(target):
		_spawn_sludge(target.global_position)
		_spawn_sludge(target.global_position + Vector3(3, 0, 0))
		_spawn_sludge(target.global_position + Vector3(-3, 0, 0))

func _start_final_slam() -> void:
	_current_attack = "final_slam"
	_attack_timer = 4.0
	_slam_sequence_step = 3
	_slam_timer = 0.8

func _process_attack_sequence(delta: float) -> void:
	if _current_attack == "shell_slam":
		_slam_timer -= delta
		if _slam_timer <= 0:
			_execute_slam()
			_current_attack = ""
	elif _current_attack == "rapid_barrage":
		_slam_timer -= delta
		if _slam_timer <= 0 and _slam_sequence_step > 0:
			_fire_spit_spread(1, 0.0)
			_slam_sequence_step -= 1
			_slam_timer = 0.3
		elif _slam_sequence_step <= 0:
			_current_attack = ""
	elif _current_attack == "final_slam":
		_slam_timer -= delta
		if _slam_timer <= 0 and _slam_sequence_step > 0:
			_execute_slam()
			_slam_sequence_step -= 1
			_slam_timer = 0.8
		elif _slam_sequence_step <= 0:
			_current_attack = ""
	elif _current_attack == "spinning":
		_attack_timer -= delta
		if _attack_timer <= 0:
			_spin_active = false
			_current_attack = ""
			_attack_timer = 2.0
	else:
		_attack_timer -= delta
		if _attack_timer <= 0:
			_current_attack = ""

func die() -> void:
	# Trigger victory sequence
	var zone_manager = get_tree().get_first_node_in_group("zone4_manager")
	if zone_manager and zone_manager.has_method("on_boss_defeated"):
		zone_manager.on_boss_defeated()
		
	# Drop the Avian Form DNA fragment
	var fragment_scene = load("res://levels/genome_fragment.tscn")
	if fragment_scene:
		var frag = fragment_scene.instantiate()
		get_tree().current_scene.add_child(frag)
		frag.global_position = global_position + Vector3(0, 1.5, 0)
		if "genome_id" in frag:
			frag.genome_id = "avian_form"
	
	super.die()
