class_name EnemySpawner
extends Node3D

@export var enemy_scene: PackedScene
@export var respawn_delay: float = 3.0

## Set to 0 for infinite spawns. Set to a positive number (e.g. 3) to clear a nest after 3 kills.
@export var max_spawns: int = 0

var _spawn_count: int = 0
var _current_enemy: Node3D = null

func _ready() -> void:
	_spawn_enemy()

func _spawn_enemy() -> void:
	if not is_inside_tree() or enemy_scene == null:
		return
		
	# Check if we reached the maximum spawn limit for this nest
	if max_spawns > 0 and _spawn_count >= max_spawns:
		_on_nest_cleared()
		return
		
	_current_enemy = enemy_scene.instantiate()
	_current_enemy.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", _current_enemy)
	
	_spawn_count += 1
	
	# Listen for when the enemy is destroyed (killed)
	_current_enemy.tree_exited.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	# If the level is reloading, the spawner is not in the tree anymore, so ignore it
	if not is_inside_tree():
		return
		
	var tree = get_tree()
	if tree == null:
		return
		
	# Start respawn timer
	var timer = tree.create_timer(respawn_delay)
	timer.timeout.connect(_spawn_enemy)

func _on_nest_cleared() -> void:
	# Give the player visual feedback that the nest is completely destroyed
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 2.0, 0))
			hud.show_float_text("NEST CLEARED!", scr, Color.GREEN)
	
	# The nest is dead, remove the spawner
	queue_free()
