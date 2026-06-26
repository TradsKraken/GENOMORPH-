extends Camera3D

## Top-down follow camera (MOBA / ML-style)
## Attach this script to a Camera3D node.
## The camera will look down at the player from a fixed height and angle,
## smoothly following their movement.

# ── Inspector exports ────────────────────────────────────────────────────────

## Path to the player node (CharacterBody3D / Node3D).
@export var player_path: NodePath = NodePath("../Player")

## Height above the player (Y axis).
@export var height: float = 15.0

## How far behind the player the camera sits (Z axis in world space).
## Positive = further back; adjust to taste.
@export var distance_back: float = 0.0

## Horizontal offset (X axis) – useful for slight off-centre framing.
@export var horizontal_offset: float = 0.0

## Camera tilt in degrees (0 = straight down, higher = more angled like ML).
@export_range(0.0, 89.0) var tilt_degrees: float = 35.0

## Smooth-follow speed. Lower = lazier follow, higher = snappier.
@export var follow_speed: float = 8.0

# ── Private ──────────────────────────────────────────────────────────────────

var _player: Node3D = null
var _last_ground_y: float = 0.0
var _target_ground_y: float = 0.0

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Resolve the player node from the exported path.
	if not player_path.is_empty():
		_player = get_node_or_null(player_path)

	if _player == null:
		# Fallback: search the whole scene tree for the first node in the
		# "player" group (add the player to that group in the editor).
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Node3D

	if _player == null:
		push_warning("Camera3D: No player found. Set 'player_path' or add the player to the 'player' group.")
		return

	_last_ground_y = _player.global_position.y
	_target_ground_y = _player.global_position.y

	# Snap to position immediately on the first frame.
	_apply_position(1.0)

	# ── Spawn game systems at runtime (avoids UID-less .tscn references) ──────
	var hud_script := load("res://ui/hud.gd") as GDScript
	if hud_script:
		var hud: CanvasLayer = hud_script.new()
		hud.name = "GameHUD"
		get_parent().call_deferred("add_child", hud)

	var spawner_script := load("res://levels/orb_spawner.gd") as GDScript
	if spawner_script:
		var spawner: Node3D = spawner_script.new()
		spawner.name = "OrbSpawner"
		get_parent().call_deferred("add_child", spawner)


func _process(delta: float) -> void:
	if _player == null:
		return

	if _player is CharacterBody3D:
		if _player.is_on_floor():
			_target_ground_y = _player.global_position.y
		elif _player.global_position.y < _target_ground_y:
			_target_ground_y = _player.global_position.y
	else:
		_target_ground_y = _player.global_position.y

	_last_ground_y = lerp(_last_ground_y, _target_ground_y, 10.0 * delta)

	_apply_position(follow_speed * delta)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _apply_position(weight: float) -> void:
	# With a tilted camera the player ends up below screen-center unless we
	# compensate. By positioning the camera directly above + behind and then
	# calling look_at() on the player, the player is always exactly centered.
	var tilt_rad := deg_to_rad(tilt_degrees)
	var z_offset := height * tan(tilt_rad) + distance_back

	var ground_pos := _player.global_position
	ground_pos.y = _last_ground_y

	var offset := Vector3(
		horizontal_offset,
		height,
		z_offset
	)
	var target_pos := ground_pos + offset

	global_position = global_position.lerp(target_pos, clampf(weight, 0.0, 1.0))

	# To prevent the camera from swiveling/tilting when the player moves,
	# we look at a point relative to the camera's CURRENT position.
	# This keeps the camera angle completely rigid while it slides into place.
	look_at(global_position - offset, Vector3.UP)
