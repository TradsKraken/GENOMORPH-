extends Node3D

const Poison = preload("res://combat/adaptation_poison.gd")
var remaining := 4.0
var radius := 2.0
var poison_damage := 3.0
var application_interval := 1.0
var _tick := 0.0

func _ready() -> void:
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.06
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.2, 0.9, 0.3, 0.32)
	mesh.material = material
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.position.y = 0.12
	add_child(visual)

func _physics_process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = application_interval
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and enemy.has_method("take_damage") and not enemy.get("is_dead"):
			if global_position.distance_to(enemy.global_position) <= radius:
				Poison.apply(enemy, poison_damage)
