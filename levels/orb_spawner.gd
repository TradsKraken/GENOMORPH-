extends Node3D

## Spawns stamina and EXP orbs randomly across the level at runtime.
## Respawns each type automatically after a delay when collected.

# ── Exports ───────────────────────────────────────────────────────────────────
@export var stamina_orb_count: int   = 6
@export var exp_orb_count: int       = 5
@export var spawn_radius: float      = 19.0
@export var clear_radius: float      = 4.0
@export var orb_height: float        = 1.1
@export var respawn_delay: float     = 10.0

# ── Private ───────────────────────────────────────────────────────────────────
const _STAMINA_PATH := "res://levels/stamina_orb.gd"
const _EXP_PATH     := "res://levels/exp_orb.gd"

var _rng:            RandomNumberGenerator = RandomNumberGenerator.new()
var _stamina_script: GDScript
var _exp_script:     GDScript

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_rng.randomize()
	_stamina_script = load(_STAMINA_PATH)
	_exp_script     = load(_EXP_PATH)
	for _i in stamina_orb_count:
		_spawn_orb(false)
	for _i in exp_orb_count:
		_spawn_orb(true)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _spawn_orb(is_exp: bool) -> void:
	var pos := _random_position()
	var orb := Area3D.new()
	orb.set_script(_exp_script if is_exp else _stamina_script)
	orb.position = Vector3(pos.x, orb_height, pos.y)
	add_child(orb)
	orb.tree_exited.connect(_on_orb_collected.bind(is_exp))


func _on_orb_collected(is_exp: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(respawn_delay).timeout
	if is_inside_tree():
		_spawn_orb(is_exp)


func _random_position() -> Vector2:
	for _attempt in 200:
		var x := _rng.randf_range(-spawn_radius, spawn_radius)
		var z := _rng.randf_range(-spawn_radius, spawn_radius)
		if Vector2(x, z).length() >= clear_radius:
			return Vector2(x, z)
	return Vector2(_rng.randf_range(clear_radius, spawn_radius), 0.0)
