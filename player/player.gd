extends CharacterBody3D

## Capsule player – top-down movement (MOBA / ML style)
## Uses WASD / Arrow keys to move relative to the world's X-Z plane.

# ── Inspector exports ────────────────────────────────────────────────────────

## Movement speed in units per second.
@export var speed: float = 2.5

## How fast the player accelerates to full speed.
@export var acceleration: float = 20.0

## How fast the player decelerates when no input is pressed.
@export var friction: float = 20.0

## Gravity strength (keeps the player grounded on slopes).
@export var gravity: float = 20.0

## Upward velocity applied when jumping.
@export var jump_velocity: float = 10.0

## Whether the mesh rotates to face the movement direction.
@export var rotate_to_movement: bool = true

## Extra forward momentum added when jumping forward.
@export var jump_forward_boost: float = 2.5

## How fast the mesh rotates toward the movement direction (degrees/sec).
@export var rotation_speed: float = 720.0

## Maximum stamina available for actions.
@export var max_stamina: float = 100.0

## How much stamina is consumed per jump.
@export var jump_stamina_cost: float = 15.0

## How much stamina is recovered per second.
@export var stamina_recovery_rate: float = 5.0

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

## Reference to the on-screen virtual joystick (found at runtime via group).
var _joystick = null

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	# Defer joystick lookup so the entire scene tree is ready first.
	call_deferred("_find_joystick")
	
	if animation_player == null:
		animation_player = _find_animation_player(self)
		if animation_player:
			var walk = animation_player.get_animation(anim_walk)
			if walk: walk.loop_mode = Animation.LOOP_LINEAR
			var idle = animation_player.get_animation(anim_idle)
			if idle: idle.loop_mode = Animation.LOOP_LINEAR

func _find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var result = _find_animation_player(child)
		if result != null:
			return result
	return null


func _find_joystick() -> void:
	var sticks := get_tree().get_nodes_in_group("joystick")
	if sticks.size() > 0:
		_joystick = sticks[0]


func _physics_process(delta: float) -> void:
	# ── Stamina recovery ─────────────────────────────────────────────────────
	PlayerData.recover_stamina(delta, stamina_recovery_rate)

	# ── Gravity ──────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= gravity * delta

	# ── Input direction (X-Z plane, top-down) ────────────────────────────────
	# Prefer joystick on mobile; fall back to keyboard in the editor / desktop.
	var raw_input: Vector2
	if _joystick != null and _joystick.get_vector().length_squared() > 0.0:
		raw_input = _joystick.get_vector()
	else:
		raw_input = Input.get_vector(
			"ui_left", "ui_right",   # A / Left  →  D / Right
			"ui_up",   "ui_down"	 # W / Up	→  S / Down
		)
	# Map 2-D input → 3-D world XZ direction.
	var direction := Vector3(raw_input.x, 0.0, raw_input.y).normalized()

	# ── Movement / Walking ────────────────────────────────────────────────────
	if direction != Vector3.ZERO:
		if is_on_floor():
			var current_speed := speed
			var current_accel := acceleration
			
			# Synchronize movement speed to the animation frame
			if animation_player and animation_player.current_animation == anim_walk and animation_player.is_playing():
				var pos := animation_player.current_animation_position
				var length := animation_player.current_animation_length
				if length > 0.0:
					# Use a sine wave squared to make the player stop at the ends and move fast in the middle
					var phase := (pos / length) * PI
					current_speed = speed * pow(sin(phase), 2) * 2.0
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

	# ── Rotate whole player to face movement direction ────────────────────────
	if rotate_to_movement and direction != Vector3.ZERO:
		var target_angle := atan2(direction.x, direction.z)
		var current_angle: float = rotation.y
		var max_step := deg_to_rad(rotation_speed) * delta
		rotation.y = rotate_toward(current_angle, target_angle, max_step)

	# ── Jumping ──────────────────────────────────────────────────────────────
	if Input.is_action_pressed("ui_accept") and is_on_floor() and PlayerData.use_stamina(jump_stamina_cost):
		velocity.y = jump_velocity
		if direction != Vector3.ZERO:
			# Jump forward in the movement direction (true frog leap)
			velocity.x = direction.x * (speed * 2.0)
			velocity.z = direction.z * (speed * 2.0)
		else:
			# Jump straight up
			velocity.x = 0.0
			velocity.z = 0.0
			
		if animation_player:
			animation_player.stop() # Force the animation to restart from the beginning for the big leap

	# ── Attacking ────────────────────────────────────────────────────────────
	if Input.is_action_just_pressed("attack"):
		_attack()

	move_and_slide()

	# ── Animation state machine ──────────────────────────────────────────────
	_update_animation(direction)


# ── Combat ───────────────────────────────────────────────────────────────────

func _attack() -> void:
	if animation_player:
		animation_player.play("FrogArmature|Frog_Attack", 0.1)
	
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 1.5, 0))
			hud.show_float_text("PEWNG!", scr, Color(1.0, 0.3, 0.1))


# ── Animation ────────────────────────────────────────────────────────────────

func _update_animation(direction: Vector3) -> void:
	if animation_player == null:
		return

	if animation_player.current_animation == "FrogArmature|Frog_Attack" and animation_player.is_playing():
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
	else:
		# Standing still → idle breathing
		target_anim = anim_idle

	# Only switch if the animation actually changed or if a ground animation stopped playing
	var should_play = animation_player.current_animation != target_anim
	if is_on_floor() and not animation_player.is_playing():
		should_play = true

	if should_play:
		animation_player.play(target_anim, anim_blend_time)

	# Scale walk playback speed with the export speed instead of dynamic velocity
	if target_anim == anim_walk:
		animation_player.speed_scale = clamp(speed / 2.5, 0.5, 2.0)
	else:
		animation_player.speed_scale = 1.0
