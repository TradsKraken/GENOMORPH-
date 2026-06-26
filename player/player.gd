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
@export var jump_velocity: float = 8.0

## Whether the mesh rotates to face the movement direction.
@export var rotate_to_movement: bool = true

## Extra forward momentum added when jumping forward.
@export var jump_forward_boost: float = 8.0

## How fast the mesh rotates toward the movement direction (degrees/sec).
@export var rotation_speed: float = 720.0

## Maximum stamina available for actions.
@export var max_stamina: float = 100.0

## How much stamina is consumed per jump.
@export var jump_stamina_cost: float = 15.0

## How much stamina is recovered per second.
@export var stamina_recovery_rate: float = 5.0

# ── Private ──────────────────────────────────────────────────────────────────

@onready var _mesh: Node3D = $MeshInstance3D

## AnimationPlayer from the imported frog .glb (child of the mesh node).
## Set this in the Inspector once you have imported the frog model.
@export var animation_player: AnimationPlayer = null

## Name of the idle animation track (must match the name in the .glb).
@export var anim_idle: String = "idle"

## Name of the walk animation track.
@export var anim_walk: String = "walk"

## Name of the jump animation track.
@export var anim_jump: String = "jump"

## Speed at which animations blend/transition.
@export var anim_blend_time: float = 0.15

## Reference to the on-screen virtual joystick (found at runtime via group).
var _joystick = null

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("player")
	# Defer joystick lookup so the entire scene tree is ready first.
	call_deferred("_find_joystick")


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
			"ui_up",   "ui_down"     # W / Up    →  S / Down
		)
	# Map 2-D input → 3-D world XZ direction.
	var direction := Vector3(raw_input.x, 0.0, raw_input.y).normalized()

	# ── Movement / Walking ────────────────────────────────────────────────────
	if direction != Vector3.ZERO:
		if is_on_floor():
			# Walk on the ground
			velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
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
			velocity.x = direction.x * (speed + jump_forward_boost)
			velocity.z = direction.z * (speed + jump_forward_boost)
		else:
			# Jump straight up
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()

	# ── Animation state machine ──────────────────────────────────────────────
	_update_animation(direction)


# ── Animation ────────────────────────────────────────────────────────────────

func _update_animation(direction: Vector3) -> void:
	if animation_player == null:
		return

	var target_anim: String

	if not is_on_floor():
		# In the air → play jump (holds on last frame until landing)
		target_anim = anim_jump
	elif direction != Vector3.ZERO:
		# Moving on the ground → walk cycle
		target_anim = anim_walk
	else:
		# Standing still → idle breathing
		target_anim = anim_idle

	# Only switch if the animation actually changed
	if animation_player.current_animation != target_anim:
		animation_player.play(target_anim, anim_blend_time)

	# Scale walk playback speed with actual movement speed
	if target_anim == anim_walk:
		var h_speed := Vector2(velocity.x, velocity.z).length()
		animation_player.speed_scale = clamp(h_speed / speed, 0.5, 2.0)
	else:
		animation_player.speed_scale = 1.0
