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
@export var jump_forward_boost: float = 8.0

## How fast the mesh rotates toward the movement direction (degrees/sec).
@export var rotation_speed: float = 720.0

# ── Private ──────────────────────────────────────────────────────────────────

@onready var _mesh: MeshInstance3D = $MeshInstance3D

## Reference to the on-screen virtual joystick (found at runtime via group).
var _joystick = null

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Defer joystick lookup so the entire scene tree is ready first.
	call_deferred("_find_joystick")


func _find_joystick() -> void:
	var sticks := get_tree().get_nodes_in_group("joystick")
	if sticks.size() > 0:
		_joystick = sticks[0]


func _physics_process(delta: float) -> void:
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
			# Slight air control to allow adjusting trajectory while jumping
			velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * 0.2 * delta)
			velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * 0.2 * delta)
	else:
		# Apply friction to stop when no input
		var current_friction := friction if is_on_floor() else friction * 0.1
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_friction * delta)

	# ── Rotate whole player to face movement direction ────────────────────────
	if rotate_to_movement and direction != Vector3.ZERO:
		var target_angle := atan2(direction.x, direction.z)
		var current_angle: float = rotation.y
		var max_step := deg_to_rad(rotation_speed) * delta
		rotation.y = rotate_toward(current_angle, target_angle, max_step)

	# ── Jumping ──────────────────────────────────────────────────────────────
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		if direction != Vector3.ZERO:
			# Jump forward in the movement direction
			velocity.x = direction.x * (speed + jump_forward_boost)
			velocity.z = direction.z * (speed + jump_forward_boost)

	move_and_slide()
