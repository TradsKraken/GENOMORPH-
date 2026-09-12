extends CharacterBody3D

## Capsule player – top-down movement (MOBA / ML style)
## Uses WASD / Arrow keys to move relative to the world's X-Z plane.

# ── Inspector exports ────────────────────────────────────────────────────────

## Movement speed in units per second.
@export var speed: float = 3.0

## How fast the player accelerates to full speed.
@export var acceleration: float = 20.0

## How fast the player decelerates when no input is pressed.
@export var friction: float = 20.0

## Gravity strength (keeps the player grounded on slopes).
@export var gravity: float = 20.0

## Upward velocity applied when jumping.
@export var jump_velocity: float = 8.0

## Whether the mesh rotates to face the movement direction.
@export var rotate_to_movement: bool = true

## Extra forward momentum added when jumping forward.
@export var jump_forward_boost: float = 2.5

## How fast the mesh rotates toward the movement direction (degrees/sec).
@export var rotation_speed: float = 720.0

## Maximum stamina available for actions.
@export var max_stamina: float = 100.0

## How much stamina is consumed per jump.
@export var jump_stamina_cost: float = 30.0

## How much stamina is recovered per second.
@export var stamina_recovery_rate: float = 10.0

# ── Private ──────────────────────────────────────────────────────────────────


## AnimationPlayer from the imported frog .glb (child of the mesh node).
## Set this in the Inspector once you have imported the frog model.
@export var animation_player: AnimationPlayer = null

## Name of the idle animation track (must match the name in the .glb).
@export var anim_idle: String = "FrogArmature|Frog_Idle"

## Name of the walk animation track.
@export var anim_walk: String = "FrogArmature|Frog_Jump"

## Name of the jump animation track.
@export var anim_jump: String = "FrogArmature|Frog_Jump"

## Speed at which animations blend/transition.
@export var anim_blend_time: float = 0.15

const FROG_IDLE_ANIMATION := "FrogArmature|Frog_Idle"
const FROG_WALK_ANIMATION := "FrogArmature|Frog_Jump"
const FROG_JUMP_ANIMATION := "FrogArmature|Frog_Jump"
const FROG_ATTACK_ANIMATION := "FrogArmature|Frog_Attack"
const SALAMANDER_FORM_SCENE := preload("res://Models/Salamander/Salamander.glb")

## Reference to the on-screen virtual joystick (found at runtime via group).
var _joystick = null

# ── Splashdown Jump State ────────────────────────────────────────────────────
var is_aiming_jump: bool = false
var is_jumping: bool = false
var jump_target_pos: Vector3 = Vector3.ZERO
var _aim_offset: Vector3 = Vector3.ZERO
var _reticle: Decal
var input_locked: bool = false
var _time_since_combat: float = 5.0
var _heal_timer: float = 0.0
var _respawn_point: Vector3 = Vector3.ZERO
var _is_using_skill: bool = false
var _skill1_cooldown_timer: float = 0.0
var damage_cooldown_timer: float = 0.0
var _attack_debug_timer: float = 0.0 # TEMPORARY — remove once the attack-spam bug is confirmed fixed.
@export var damage_cooldown_duration: float = 1.0
var _attack_animation: String = FROG_ATTACK_ANIMATION
var _salamander_form: Node3D
const AdaptationCombat = preload("res://combat/adaptation_combat.gd")
var _adaptation: Node
var _monitor_form: Node3D
var _basic_cooldown := 0.0

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_adaptation = AdaptationCombat.new()
	add_child(_adaptation)
	if PlayerData.has_saved_position:
		global_position = PlayerData.player_position
		PlayerData.has_saved_position = false
		
	_respawn_point = global_position
	rotation.y = PI
	add_to_group("player")
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	if not InputMap.has_action("skill1"):
		InputMap.add_action("skill1")
	if not InputMap.has_action("ultimate"):
		InputMap.add_action("ultimate")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_R
		InputMap.action_add_event("ultimate", event)
	# Defer joystick lookup so the entire scene tree is ready first.
	call_deferred("_find_joystick")
	
	_build_reticle()
	_hide_from_minimap(self)
	
	if not PlayerData.active_species_changed.is_connected(_on_active_species_changed):
		PlayerData.active_species_changed.connect(_on_active_species_changed)
	_apply_species_form(PlayerData.active_species)

func _find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var result = _find_animation_player(child)
		if result != null:
			return result
	return null

func _on_active_species_changed(species_id: String) -> void:
	cancel_aiming_jump()
	_apply_species_form(species_id)

func _apply_species_form(species_id: String) -> void:
	var frog_form := get_node_or_null("Frog") as Node3D
	if species_id == "salamander" and not is_instance_valid(_salamander_form):
		_salamander_form = SALAMANDER_FORM_SCENE.instantiate() as Node3D
		add_child(_salamander_form)
		_hide_from_minimap(_salamander_form)
	if species_id == "water_monitor" and not is_instance_valid(_monitor_form):
		var scene := load("res://Models/Water Monitor Lizard/Water Monitor Lizard.glb") as PackedScene
		_monitor_form = scene.instantiate() as Node3D
		add_child(_monitor_form)
		_hide_from_minimap(_monitor_form)
	if frog_form: frog_form.visible = species_id == "frog"
	if is_instance_valid(_salamander_form): _salamander_form.visible = species_id == "salamander"
	if is_instance_valid(_monitor_form): _monitor_form.visible = species_id == "water_monitor"
	_configure_species_animations(species_id)

func _configure_species_animations(species_id: String) -> void:
	var form: Node = get_node_or_null("Frog")
	if species_id == "salamander": form = _salamander_form
	if species_id == "water_monitor": form = _monitor_form
	animation_player = _find_animation_player(form) if form else null
	if species_id != "frog":
		# The supplied Salamander model includes Walk and three attack clips, but
		# no idle clip. Leaving it paused while standing preserves its rest pose.
		anim_idle = ""
		anim_walk = _find_animation_name("walk")
		anim_jump = anim_walk
		_attack_animation = _find_animation_name("attack middle")
		if _attack_animation.is_empty():
			_attack_animation = _find_animation_name("attack")
	else:
		anim_idle = FROG_IDLE_ANIMATION
		anim_walk = FROG_WALK_ANIMATION
		anim_jump = FROG_JUMP_ANIMATION
		_attack_animation = FROG_ATTACK_ANIMATION

	if not is_instance_valid(animation_player):
		return
	var walk := animation_player.get_animation(anim_walk) if not anim_walk.is_empty() else null
	if walk:
		walk.loop_mode = Animation.LOOP_LINEAR
	var idle := animation_player.get_animation(anim_idle) if not anim_idle.is_empty() else null
	if idle:
		idle.loop_mode = Animation.LOOP_LINEAR
	var attack := animation_player.get_animation(_attack_animation) if not _attack_animation.is_empty() else null
	if attack:
		attack.loop_mode = Animation.LOOP_NONE

func _find_animation_name(keyword: String) -> String:
	if not is_instance_valid(animation_player):
		return ""
	for animation_name in animation_player.get_animation_list():
		if String(animation_name).to_lower().contains(keyword.to_lower()):
			return String(animation_name)
	return ""

func _hide_from_minimap(node: Node) -> void:
	if node is VisualInstance3D:
		node.layers = 524288
	for child in node.get_children():
		_hide_from_minimap(child)

func _build_reticle() -> void:
	_reticle = Decal.new()
	# The X and Z size is 5.0 (radius 2.5). The Y size is 4.0 (projection depth)
	_reticle.size = Vector3(5.0, 4.0, 5.0)
	
	# Generate a perfectly round circle texture using code
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.8, 0.85, 0.95])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.3),
		Color(1.0, 1.0, 1.0, 0.3),
		Color(1.0, 1.0, 1.0, 0.8),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 256
	tex.height = 256
	
	_reticle.texture_albedo = tex
	_reticle.modulate = Color(0.2, 0.6, 1.0, 1.0) # Blue by default
	
	_reticle.visible = false
	# Add to main scene so it ignores player rotation/scale
	call_deferred("_add_reticle_to_scene")

func _add_reticle_to_scene() -> void:
	get_tree().current_scene.add_child(_reticle)


func _find_joystick() -> void:
	var sticks := get_tree().get_nodes_in_group("joystick")
	if sticks.size() > 0:
		_joystick = sticks[0]


func _physics_process(delta: float) -> void:
	# ── Stamina recovery ─────────────────────────────────────────────────────
	PlayerData.recover_stamina(delta, float(PlayerData.AdaptationRules.SPECIES.get(PlayerData.active_species, {}).get("recovery", stamina_recovery_rate)) * PlayerData.get_stamina_recovery_multiplier() * PlayerData.ultimate_effect("stamina_recovery"))
	_adaptation.tick(delta)
	_basic_cooldown = maxf(0.0, _basic_cooldown - delta)
	_process_auto_heal(delta)
	if _skill1_cooldown_timer > 0.0:
		_skill1_cooldown_timer -= delta
	if damage_cooldown_timer > 0.0:
		damage_cooldown_timer -= delta

	# ── Gravity ──────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= gravity * delta

	# ── Fall Respawn ─────────────────────────────────────────────────────────
	if global_position.y < -20.0:
		global_position = _respawn_point
		velocity = Vector3.ZERO

	# ── Input direction (X-Z plane, top-down) ────────────────────────────────
	var raw_input: Vector2
	if input_locked:
		raw_input = Vector2.ZERO
	else:
		# Prefer joystick on mobile; fall back to keyboard in the editor / desktop.
		if _joystick != null and _joystick.get_vector().length_squared() > 0.0:
			raw_input = _joystick.get_vector()
		else:
			raw_input = Input.get_vector(
				"ui_left", "ui_right",   # A / Left  →  D / Right
				"ui_up",   "ui_down"	 # W / Up	→  S / Down
			)
	# Map 2-D input → 3-D world XZ direction.
	var direction := Vector3(raw_input.x, 0.0, raw_input.y).normalized()
	
	var cam = get_viewport().get_camera_3d()
	if cam and "view_mode" in cam and cam.view_mode == 1: # THIRD_PERSON
		direction = direction.rotated(Vector3.UP, cam.global_rotation.y)


	# Keep reticle attached to player as they walk
	if is_aiming_jump:
		jump_target_pos = global_position + _aim_offset
		jump_target_pos.y = global_position.y
		_reticle.global_position = jump_target_pos

	# ── Movement / Walking ────────────────────────────────────────────────────
	if direction != Vector3.ZERO:
		if is_on_floor():
			var current_speed := speed * PlayerData.get_ultimate_speed_multiplier()
			var current_accel := acceleration
			
			# Synchronize movement speed to the animation frame
			if PlayerData.active_species == "frog" and animation_player and animation_player.current_animation == anim_walk and animation_player.is_playing():
				var pos := animation_player.current_animation_position
				var length := animation_player.current_animation_length
				if length > 0.0:
					# Use a sine wave squared to make the player stop at the ends and move fast in the middle
					var phase := (pos / length) * PI
					current_speed = speed * PlayerData.get_ultimate_speed_multiplier() * pow(sin(phase), 2) * 2.0
					current_accel = acceleration * 2.0 # Track the curve faster
					
			# Walk on the ground
			velocity.x = move_toward(velocity.x, direction.x * current_speed, current_accel * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, current_accel * delta)
		else:
			# Frog jump: NO air control. Once you leap, you are committed to the ballistic arc.
			pass
	else:
		# Apply heavy friction to stick the landing instantly when releasing input
		var current_friction := friction * 5.0 if is_on_floor() else 0.0
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_friction * delta)

	# ── Visual Rotation ────────────────────────────────────────────────────────
	if Vector2(velocity.x, velocity.z).length() > 0.1:
		var target_angle := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)

	# ── Attacking ────────────────────────────────────────────────────────────
	if not input_locked:
		if Input.is_action_just_pressed("attack"):
			print("[ATTACK DEBUG] is_action_just_pressed(attack)=true")
			_attack()
		if Input.is_action_just_pressed("skill1"):
			_skill1()
		if Input.is_action_just_pressed("ultimate"):
			_activate_ultimate()

	_attack_debug_timer += delta
	if _attack_debug_timer > 1.0:
		_attack_debug_timer = 0.0
		print("[ATTACK DEBUG] tick — is_action_pressed(attack)=", Input.is_action_pressed("attack"),
			" current_animation=", (animation_player.current_animation if animation_player else "null"),
			" is_playing=", (animation_player.is_playing() if animation_player else "null"))

	var was_on_floor = is_on_floor()
	move_and_slide()
	var just_landed = is_on_floor() and not was_on_floor
	
	if just_landed and is_jumping:
		is_jumping = false
		_trigger_splashdown_aoe()

	# ── Animation state machine ──────────────────────────────────────────────
	_update_animation(direction)


# ── Combat ───────────────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if damage_cooldown_timer > 0.0:
		return
		
	damage_cooldown_timer = damage_cooldown_duration
	_time_since_combat = 0.0
	_heal_timer = 0.0
	var actual_damage := amount * (1.0 - PlayerData.get_ultimate_damage_reduction())
	PlayerData.take_damage(actual_damage)
	PlayerData.gain_ultimate_charge(minf(actual_damage, 30.0) * 0.5)
	
	# Apply brief flinch (red flash) without blocking movement
	var mesh = _find_mesh(self)
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "instance_shader_parameter/hit_flash", 1.0, 0.05)
		tween.tween_property(mesh, "instance_shader_parameter/hit_flash", 0.0, 0.2)
	
	_apply_hit_stop(0.05, 0.2)
	
	# Give some visual feedback when hit
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 1.5, 0))
			hud.show_float_text("-" + str(roundi(actual_damage)), scr, Color.RED)
	
	if PlayerData.health <= 0:
		PlayerData.end_ultimate()
		PlayerData.heal(PlayerData.max_health)
		
		var spawn_pos = _respawn_point
		if PlayerData.has_saved_position:
			spawn_pos = PlayerData.player_position
			
		global_position = spawn_pos
		velocity = Vector3.ZERO
		
		if hud and hud.has_method("show_float_text"):
			var cam := get_viewport().get_camera_3d()
			if cam:
				var scr := cam.unproject_position(global_position + Vector3(0, 1.5, 0))
				hud.show_float_text("RESPAWNED", scr, Color.RED)

func _process_auto_heal(delta: float) -> void:
	_time_since_combat += delta
	if _time_since_combat >= 5.0:
		_heal_timer += delta
		if _heal_timer >= 2.0:
			_heal_timer -= 2.0
			if PlayerData.health < PlayerData.max_health:
				var heal_amount := 5.0 * PlayerData.get_health_recovery_multiplier()
				PlayerData.heal(heal_amount)
				# Visual feedback for heal
				var hud := get_tree().get_first_node_in_group("hud")
				if hud and hud.has_method("show_float_text"):
					var cam := get_viewport().get_camera_3d()
					if cam:
						var scr := cam.unproject_position(global_position + Vector3(0, 1.5, 0))
						hud.show_float_text("+%d" % roundi(heal_amount), scr, Color.GREEN)

func _activate_ultimate() -> void:
	if _adaptation.activate():
		AudioManager.play_sfx("level_up")

func use_secondary_skill() -> bool:
	return _adaptation.use_skill2()

func _find_mesh(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var result = _find_mesh(child)
		if result != null:
			return result
	return null

# ── Splashdown Jump Mechanics ────────────────────────────────────────────────

func start_aiming_jump() -> void:
	if input_locked or PlayerData.active_species != "frog": return
	if not is_on_floor() or is_jumping: return
	
	if PlayerData.stamina < jump_stamina_cost * PlayerData.ultimate_effect("stamina_cost"):
		AudioManager.play_sfx("error", 1.0, 5.0)
		return
		
	is_aiming_jump = true
	_aim_offset = Vector3.ZERO
	_reticle.visible = true
	_reticle.modulate = Color(0.2, 0.6, 1.0, 1.0)
	_reticle.global_position = global_position
	jump_target_pos = global_position
	
func update_aim_jump(drag_vec: Vector2, is_cancelled: bool = false) -> void:
	if not is_aiming_jump: return
	var aim_range = 8.0
	var offset_dir := Vector3(drag_vec.x, 0, drag_vec.y)
	
	var cam = get_viewport().get_camera_3d()
	if cam and "view_mode" in cam and cam.view_mode == 1: # THIRD_PERSON
		offset_dir = offset_dir.rotated(Vector3.UP, cam.global_rotation.y)
		
	_aim_offset = offset_dir * aim_range
	jump_target_pos = global_position + _aim_offset
	jump_target_pos.y = global_position.y
	_reticle.global_position = jump_target_pos
	
	if is_cancelled:
		_reticle.modulate = Color(1.0, 0.2, 0.2, 1.0) # Turn red if cancelling
	else:
		_reticle.modulate = Color(0.2, 0.6, 1.0, 1.0) # Normal blue

func cancel_aiming_jump() -> void:
	if not is_aiming_jump: return
	is_aiming_jump = false
	_reticle.visible = false
	
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 1.5, 0))
			hud.show_float_text("CANCELLED", scr, Color(0.7, 0.7, 0.7))

func execute_splash_jump(is_quick_tap: bool) -> void:
	if not is_aiming_jump: return
	is_aiming_jump = false
	_reticle.visible = false
	
	if is_quick_tap:
		jump_target_pos = global_position
		
	# Instantly snap frog rotation to face the jump target
	var to_target = jump_target_pos - global_position
	to_target.y = 0
	if to_target.length() > 0.1:
		rotation.y = atan2(to_target.x, to_target.z)
	
	if not is_on_floor():
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_float_text"):
			var cam := get_viewport().get_camera_3d()
			if cam:
				var scr := cam.unproject_position(global_position + Vector3(0, 1.5, 0))
				hud.show_float_text("TOO LATE!", scr, Color.GRAY)
		return
		
	if not PlayerData.use_stamina(jump_stamina_cost * PlayerData.ultimate_effect("stamina_cost")):
		AudioManager.play_sfx("error", 1.0, 5.0)
		return
		
	is_jumping = true
	AudioManager.play_sfx("jump", randf_range(0.9, 1.1))
	
	if is_quick_tap:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = jump_velocity
	else:
		var dist = global_position.distance_to(jump_target_pos)
		var t = 0.8 # Fixed hang time
		velocity.y = (gravity * t) / 2.0
		
		var dir = global_position.direction_to(jump_target_pos)
		var h_speed = dist / t
		velocity.x = dir.x * h_speed
		velocity.z = dir.z * h_speed
		
		rotation.y = atan2(dir.x, dir.z)
		
	if animation_player:
		animation_player.stop()

func _trigger_splashdown_aoe() -> void:
	_time_since_combat = 0.0
	_heal_timer = 0.0
	var splash_radius = 4.5
	var splash_damage = PlayerData.attack_power * 1.8
	
	# Visual feedback
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 1.5, 0))
			hud.show_float_text("SPLASH!", scr, Color.CYAN)
			
	var hit_any = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("take_damage") and not enemy.get("is_dead"):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= splash_radius:
				enemy.take_damage(splash_damage * PlayerData.get_ultimate_damage_multiplier())
				_spawn_hit_particles(enemy.global_position, 1.5)
				hit_any = true
				
	if hit_any:
		_apply_hit_stop(0.08, 0.05)
		var cam = get_viewport().get_camera_3d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.6)
			
	# Cleanse Toxic Sludge
	for sludge in get_tree().get_nodes_in_group("toxic_sludge"):
		if sludge.has_method("cleanse"):
			var dist = global_position.distance_to(sludge.global_position)
			if dist <= splash_radius + 2.0: # slightly larger cleanse radius
				sludge.cleanse()

## Finds the closest valid target in a group. Cleanup targets are queried
## separately so a nearby rat cannot steal an attack intended for trash.
func _find_closest_target_in_group(group_name: String, attack_range: float) -> Node3D:
	var closest_target: Node3D = null
	var closest_distance := attack_range

	for candidate in get_tree().get_nodes_in_group(group_name):
		if not (candidate is Node3D):
			continue
		if not candidate.has_method("take_damage") or candidate.get("is_dead"):
			continue

		var distance := global_position.distance_to((candidate as Node3D).global_position)
		if distance < closest_distance:
			closest_target = candidate as Node3D
			closest_distance = distance

	return closest_target

func _find_attack_target(attack_range: float) -> Node3D:
	var trash_target := _find_closest_target_in_group("trash", attack_range)
	if trash_target:
		return trash_target
	return _find_closest_target_in_group("enemies", attack_range)

func _attack() -> void:
	if input_locked or get_tree().paused or _basic_cooldown > 0.0:
		return
	_basic_cooldown = 0.5 / PlayerData.ultimate_effect("attack_speed")
	print("[ATTACK DEBUG] _attack() entered. current_animation=", (animation_player.current_animation if animation_player else "null"),
		" is_playing=", (animation_player.is_playing() if animation_player else "null"),
		" loop_mode=", (animation_player.get_animation(_attack_animation).loop_mode if animation_player and not _attack_animation.is_empty() and animation_player.get_animation(_attack_animation) else "null"))
	if animation_player and not _attack_animation.is_empty() and animation_player.current_animation == _attack_animation and animation_player.is_playing():
		print("[ATTACK DEBUG] _attack() blocked — already playing")
		return

	_time_since_combat = 0.0
	_heal_timer = 0.0
	if animation_player:
		# Re-assert this every time rather than trusting the one-time _ready()
		# setup: this Animation resource is shared (loaded from the same .glb)
		# across every instance of the Frog model, so any other code touching
		# it — e.g. an NPC using the same model — can silently flip this back
		# to looping. See native_frog.gd for the actual case that caused this.
		var attack_anim = animation_player.get_animation(_attack_animation) if not _attack_animation.is_empty() else null
		if attack_anim:
			attack_anim.loop_mode = Animation.LOOP_NONE
			animation_player.play(_attack_animation, 0.1, 2.0 * PlayerData.ultimate_effect("attack_speed"))
			print("[ATTACK DEBUG] play() called for attack animation")
		
	AudioManager.play_sfx("lunge", randf_range(0.9, 1.1))
		
	# Show visual range
	var attack_range = 4.0
	_show_attack_range(attack_range, Color(1.0, 0.2, 0.2))
	
	# Cleanup objects take priority over enemies while the player is nearby.
	var damage = DamageCalculator.calculate_player_damage(PlayerData.attack_power * PlayerData.get_ultimate_damage_multiplier(), 1.0)
	var closest_enemy := _find_attack_target(attack_range)
	var closest_dist: float = attack_range
	if closest_enemy:
		closest_dist = global_position.distance_to(closest_enemy.global_position)
					
	
	if closest_enemy:
		# Auto-aim: Snap rotation to face the target
		var to_enemy = global_position.direction_to(closest_enemy.global_position)
		rotation.y = atan2(to_enemy.x, to_enemy.z)
		
		# Dash towards enemy if they are further away than 1.5 units
		if closest_dist > 1.5:
			var target_pos = closest_enemy.global_position - to_enemy * 1.5
			target_pos.y = global_position.y
			var dash_tween = create_tween()
			dash_tween.tween_property(self, "global_position", target_pos, 0.1)
		
		# Deal damage
		closest_enemy.take_damage(damage)
		_spawn_hit_particles(closest_enemy.global_position, 1.0)
		_apply_hit_stop(0.05, 0.1)
		var cam = get_viewport().get_camera_3d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.3)
	
	pass

func _skill1() -> void:
	if input_locked or get_tree().paused or _is_using_skill or _skill1_cooldown_timer > 0.0:
		return
		
	if PlayerData.active_species != "frog":
		_skill1_cooldown_timer = (12.0 if PlayerData.active_species == "salamander" else 5.0) * PlayerData.get_cooldown_multiplier()
		PlayerData.skill1_cooldown_started.emit(_skill1_cooldown_timer)
		_adaptation.use_skill1()
		return
	_is_using_skill = true
	_skill1_cooldown_timer = 3.0 * PlayerData.get_cooldown_multiplier()
	PlayerData.skill1_cooldown_started.emit(_skill1_cooldown_timer)
	
	_time_since_combat = 0.0
	_heal_timer = 0.0
	AudioManager.play_sfx("whip", randf_range(0.9, 1.1))
	
	var attack_range = 5.0
	_show_attack_range(attack_range, Color(0.2, 0.6, 1.0))
	
	# Sticky Tongue Whip also prioritizes nearby cleanup targets.
	var damage = DamageCalculator.calculate_player_damage(PlayerData.attack_power * PlayerData.get_ultimate_damage_multiplier(), 1.5)
	var closest_enemy := _find_attack_target(attack_range)
					
	if closest_enemy:
		# Auto-aim: Snap rotation to face the target
		var to_enemy = global_position.direction_to(closest_enemy.global_position)
		rotation.y = atan2(to_enemy.x, to_enemy.z)
		
		# Deal damage
		closest_enemy.take_damage(damage)
		_spawn_hit_particles(closest_enemy.global_position, 1.2)
		_apply_hit_stop(0.06, 0.1)
		var cam = get_viewport().get_camera_3d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.4)
		
		# Visual Tongue Animation
		_animate_tongue(closest_enemy.global_position)
	else:
		# If no enemy, just shoot tongue forward (+Z is character forward)
		var target_pos = global_position + global_transform.basis.z * 5.0
		_animate_tongue(target_pos)
	
	pass

func _animate_tongue(target_pos: Vector3) -> void:
	var tongue_pivot = Node3D.new()
	get_tree().current_scene.add_child(tongue_pivot)
	
	# Start slightly forward and up from the center to match the mouth
	var start_pos = global_position + Vector3(0, 0.5, 0) + global_transform.basis.z * 0.6
	target_pos.y += 0.5
	tongue_pivot.global_position = start_pos
	
	if start_pos.distance_to(target_pos) > 0.1:
		tongue_pivot.look_at(target_pos, Vector3.UP)
	
	var tongue_mesh = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.5) # Pink tongue
	mat.roughness = 0.2
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.15
	mesh.bottom_radius = 0.15
	mesh.height = 1.0
	tongue_mesh.mesh = mesh
	tongue_mesh.material_override = mat
	
	tongue_pivot.add_child(tongue_mesh)
	tongue_mesh.rotation.x = PI / 2.0
	tongue_mesh.position = Vector3(0, 0, -0.5)
	
	var dist = start_pos.distance_to(target_pos)
	tongue_pivot.scale.z = 0.01
	
	var tween = create_tween()
	# Extend
	tween.tween_property(tongue_pivot, "scale:z", dist, 0.1)
	# Retract
	tween.tween_property(tongue_pivot, "scale:z", 0.01, 0.1).set_delay(0.05)
	tween.finished.connect(func():
		tongue_pivot.queue_free()
		_is_using_skill = false
	)

func _show_attack_range(radius: float, color: Color) -> void:
	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.15
	torus.outer_radius = radius
	torus.rings = 32
	torus.ring_segments = 8
	mesh_inst.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	
	get_tree().current_scene.add_child(mesh_inst)
	mesh_inst.global_position = global_position + Vector3(0, 0.1, 0)
	
	# Animate expanding and fading out
	mesh_inst.scale = Vector3(0.1, 1.0, 0.1)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(mesh_inst, "scale", Vector3(1.0, 1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35).set_delay(0.05)
	
	tween.chain().tween_callback(mesh_inst.queue_free)


# ── Game Feel (Juice) ─────────────────────────────────────────────────────────

func _apply_hit_stop(duration: float = 0.05, time_scale: float = 0.1) -> void:
	Engine.time_scale = time_scale
	var timer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
	)

func _spawn_hit_particles(pos: Vector3, scale_mult: float = 1.0) -> void:
	var particles = GPUParticles3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.4) # Bright green slime
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.9, 0.4)
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	particles.draw_pass_1 = mesh
	particles.material_override = mat
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 90.0
	p_mat.initial_velocity_min = 3.0 * scale_mult
	p_mat.initial_velocity_max = 6.0 * scale_mult
	p_mat.scale_min = 0.5 * scale_mult
	p_mat.scale_max = 1.5 * scale_mult
	p_mat.gravity = Vector3(0, -9.8, 0)
	
	particles.process_material = p_mat
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = int(10 * scale_mult)
	particles.lifetime = 0.6
	
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	
	var timer = get_tree().create_timer(1.0, false)
	timer.timeout.connect(particles.queue_free)

# ── Animation ────────────────────────────────────────────────────────────────

func _update_animation(direction: Vector3) -> void:
	if animation_player == null:
		return

	if not _attack_animation.is_empty() and animation_player.current_animation == _attack_animation and animation_player.is_playing():
		return

	var target_anim: String

	if not is_on_floor():
		# In the air → play jump (holds on last frame until landing)
		target_anim = anim_jump
		if animation_player:
			var anim = animation_player.get_animation(target_anim)
			if anim: anim.loop_mode = Animation.LOOP_NONE
	elif direction != Vector3.ZERO:
		# Moving on the ground → walk cycle
		target_anim = anim_walk
		if animation_player:
			var anim = animation_player.get_animation(target_anim)
			if anim: anim.loop_mode = Animation.LOOP_LINEAR
	elif not anim_idle.is_empty():
		# Standing still → idle breathing
		target_anim = anim_idle
	else:
		# Salamander has no idle clip; preserve its imported rest pose.
		animation_player.pause()
		return

	# Only switch if the animation actually changed or if a ground animation stopped playing
	var should_play = animation_player.current_animation != target_anim
	if is_on_floor() and not animation_player.is_playing():
		should_play = true

	if should_play and not target_anim.is_empty() and animation_player.has_animation(target_anim):
		print("[ANIM DEBUG] _update_animation playing '", target_anim, "' (was '", animation_player.current_animation, "')")
		animation_player.play(target_anim, anim_blend_time)

	# ── Sync Animation Speed ──────────────────────────────────────────────────
	if not is_on_floor() and target_anim == anim_jump:
		# Scale the big jump animation to perfectly match the physical air time!
		if animation_player:
			var anim = animation_player.get_animation(target_anim)
			if anim:
				var air_time := (2.0 * jump_velocity) / gravity
				if air_time > 0.0:
					animation_player.speed_scale = anim.length / air_time
	elif target_anim == anim_walk:
		# Scale walking hop to movement speed, doubled for faster animation
		animation_player.speed_scale = clamp((speed / 2.5) * 1.2, 0.5, 4.0)
	else:
		# Idle
		animation_player.speed_scale = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Y:
			var frogs = get_tree().get_nodes_in_group("npc_frog")
			var generic_frogs = []
			for f in frogs:
				if "is_main_quest" in f and not f.is_main_quest:
					generic_frogs.append(f)
			
			if generic_frogs.size() > 1:
				for i in range(generic_frogs.size() - 1):
					generic_frogs[i].is_helped = true
					generic_frogs[i].visible = false
				
				PlayerData.total_frogs = frogs.size()
				PlayerData.frogs_helped = PlayerData.total_frogs - 1
				
				var hud = get_tree().get_first_node_in_group("hud")
				if hud and hud.has_method("show_subtitle"):
					hud.show_subtitle("DEBUG CHEAT ACTIVATED", "All frogs except ONE have been instantly found! Go find the last one!", 4.0)
