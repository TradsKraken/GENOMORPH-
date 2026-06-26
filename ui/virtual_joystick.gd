extends Control

## Virtual on-screen joystick for mobile play.
## Draws itself via the canvas API — no textures required.
## Registers in the "joystick" group so player.gd can locate it automatically.

# ── Inspector exports ────────────────────────────────────────────────────────

## Radius of the outer (background) ring in pixels.
@export var radius: float = 130.0

## Radius of the draggable knob in pixels.
@export var knob_radius: float = 50.0

## Fraction of radius below which input is ignored (prevents drift).
@export var dead_zone: float = 0.12

# ── Private ──────────────────────────────────────────────────────────────────

var _touch_index: int = -1
var _center: Vector2
var _knob_pos: Vector2
var _value: Vector2 = Vector2.ZERO

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("joystick")
	_center  = size * 0.5
	_knob_pos = _center


## Returns the joystick direction as a Vector2 in the range [-1, 1] per axis.
func get_vector() -> Vector2:
	return _value

# ── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var local := event.position - global_position
	if event.pressed:
		if _touch_index == -1 and local.distance_to(_center) <= radius:
			_touch_index = event.index
			_move_knob(local)
	else:
		if event.index == _touch_index:
			_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _touch_index:
		_move_knob(event.position - global_position)

# ── Helpers ──────────────────────────────────────────────────────────────────

func _move_knob(local: Vector2) -> void:
	var offset := local - _center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_knob_pos = _center + offset
	var raw := offset / radius
	_value    = raw if raw.length() >= dead_zone else Vector2.ZERO
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_knob_pos    = _center
	_value       = Vector2.ZERO
	queue_redraw()

# ── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	# ── Outer ring background ─────────────────────────────────────────────
	draw_circle(_center, radius, Color(0.05, 0.07, 0.15, 0.50))
	draw_arc(_center, radius, 0.0, TAU, 80, Color(0.55, 0.78, 1.0, 0.40), 2.5, true)

	# ── Subtle cross-hair lines ───────────────────────────────────────────
	var lc := Color(1.0, 1.0, 1.0, 0.07)
	draw_line(_center + Vector2(-radius, 0), _center + Vector2(radius, 0), lc, 1.0)
	draw_line(_center + Vector2(0, -radius), _center + Vector2(0, radius), lc, 1.0)

	# ── Inner dead-zone indicator (tiny ring) ─────────────────────────────
	draw_arc(_center, radius * dead_zone, 0.0, TAU, 32,
			Color(1.0, 1.0, 1.0, 0.08), 1.0, true)

	# ── Knob glow ─────────────────────────────────────────────────────────
	draw_circle(_knob_pos, knob_radius + 10.0, Color(0.30, 0.60, 1.0, 0.15))
	draw_circle(_knob_pos, knob_radius + 5.0,  Color(0.30, 0.60, 1.0, 0.20))

	# ── Knob body ─────────────────────────────────────────────────────────
	draw_circle(_knob_pos, knob_radius, Color(0.18, 0.42, 0.90, 0.90))

	# ── Knob rim ─────────────────────────────────────────────────────────
	draw_arc(_knob_pos, knob_radius, 0.0, TAU, 48,
			Color(0.70, 0.88, 1.0, 0.60), 1.8, true)

	# ── Knob shine (top-left highlight) ──────────────────────────────────
	draw_circle(_knob_pos + Vector2(-knob_radius * 0.28, -knob_radius * 0.28),
			knob_radius * 0.32, Color(1.0, 1.0, 1.0, 0.22))
