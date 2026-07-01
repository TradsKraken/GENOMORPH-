class_name EnemyBase
extends CharacterBody3D

@export var max_health: float = 50.0
@export var speed: float = 2.0
@export var exp_value: float = 10.0

var health: float
var is_dead: bool = false
var target: Node3D = null

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	
	# Find player target
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func take_damage(amount: float) -> void:
	if is_dead:
		return
	
	health -= amount
	_show_damage_text(amount)
	
	if health <= 0:
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	
	_spawn_exp_orb()
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Retarget if needed
	if target == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			
	_process_movement(delta)

# Virtual function to be overridden by subclasses
func _process_movement(_delta: float) -> void:
	pass

func _spawn_exp_orb() -> void:
	var exp_script = load("res://levels/exp_orb.gd")
	if exp_script:
		var orb = exp_script.new()
E 0:00:28:135   enemy_spawner.gd:26 @ _spawn_enemy(): Condition "!is_inside_tree()" is true. Returning: Transform3D()
  <C++ Source>  scene/3d/node_3d.cpp:649 @ get_global_transform()
  <Stack Trace> enemy_spawner.gd:26 @ _spawn_enemy()
		orb.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", orb)

func _show_damage_text(amount: float) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 1.0, 0))
			hud.show_float_text(str(round(amount)), scr, Color.WHITE)
