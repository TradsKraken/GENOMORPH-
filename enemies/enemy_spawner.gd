class_name EnemySpawner
extends Node3D

@export var enemy_scene: PackedScene
@export var respawn_delay: float = 3.0

## Set to 0 for infinite spawns. Set to a positive number (e.g. 3) to clear a nest after 3 kills.
@export var max_spawns: int = 3

## If true, the very first enemy spawned will have is_active = false. It must be woken up by a script or trigger zone. Subsequent respawns will always be active.
@export var spawn_asleep_initially: bool = false

## Radius to spread out spawned enemies so they don't overlap exactly
@export var spawn_radius: float = 2.0

## If >= 0, overrides the spawned enemy's damage_per_second
@export var enemy_damage_override: float = -1.0

var _living_enemies: Array[Node3D] = []
var _is_nest_cleared: bool = false

func _ready() -> void:
	if not is_inside_tree() or enemy_scene == null:
		return
		
	if max_spawns <= 0:
		max_spawns = 1
		
	# Spawn all enemies at once
	for i in range(max_spawns):
		_spawn_enemy(i)
		
	if not spawn_asleep_initially:
		_activate_next_enemy()

func _spawn_enemy(index: int) -> void:
	var enemy = enemy_scene.instantiate()
	
	# Position in a circle around the spawner
	var angle = (float(index) / max_spawns) * TAU
	var offset = Vector3(cos(angle), 0, sin(angle)) * spawn_radius
	enemy.global_position = global_position + offset
	
	if "is_active" in enemy:
		enemy.is_active = false # Always start asleep, activate sequentially
		
	if enemy_damage_override >= 0.0 and "damage_per_second" in enemy:
		enemy.damage_per_second = enemy_damage_override
		
	get_tree().current_scene.call_deferred("add_child", enemy)
	
	_living_enemies.append(enemy)
	enemy.tree_exited.connect(func(): _on_enemy_died(enemy))

func activate() -> void:
	_activate_next_enemy()

func _activate_next_enemy() -> void:
	# Filter out any that were deleted externally or didn't exist
	_living_enemies = _living_enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	# Wake up the first alive one
	if _living_enemies.size() > 0:
		var next_enemy = _living_enemies[0]
		if "is_active" in next_enemy:
			next_enemy.is_active = true

func _on_enemy_died(enemy: Node3D) -> void:
	_living_enemies.erase(enemy)
	
	if not is_inside_tree() or _is_nest_cleared:
		return
		
	var tree = get_tree()
	if tree == null:
		return
		
	if _living_enemies.size() > 0:
		var timer = tree.create_timer(respawn_delay)
		timer.timeout.connect(_activate_next_enemy)
	else:
		_on_nest_cleared()

func _on_nest_cleared() -> void:
	_is_nest_cleared = true
	# Give the player visual feedback that the nest is completely destroyed
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 2.0, 0))
			hud.show_float_text("NEST CLEARED!", scr, Color.GREEN)
	
	# The nest is dead, remove the spawner
	queue_free()
