extends Node3D

## Spawns stamina and EXP orbs randomly across the level at runtime.
## Respawns each type automatically after a delay when collected.

# ── Exports ───────────────────────────────────────────────────────────────────
@export var stamina_orb_count: int   = 25
@export var exp_orb_count: int       = 20
@export var spawn_radius: float      = 70.0
@export var clear_radius: float      = 6.0
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
	
	# Wait for physics to sync so raycasts work
	await get_tree().physics_frame
	
	for _i in stamina_orb_count:
		_spawn_orb(false)
	for _i in exp_orb_count:
		_spawn_orb(true)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _spawn_orb(is_exp: bool) -> void:
	var pos := _random_position()
	var orb = _exp_script.new() if is_exp else _stamina_script.new()
	
	var final_y = orb_height
	var space_state = get_world_3d().direct_space_state
	if space_state:
		var origin = Vector3(pos.x, 200.0, pos.y)
		var target = Vector3(pos.x, -100.0, pos.y)
		var params = PhysicsRayQueryParameters3D.create(origin, target)
		var result = space_state.intersect_ray(params)
		if result.has("position"):
			final_y = result.position.y + orb_height
			
	orb.position = Vector3(pos.x, final_y, pos.y)
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
