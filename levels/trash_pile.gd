extends StaticBody3D
class_name TrashPile

signal destroyed

@export var max_health: float = 30.0
var health: float
var is_dead: bool = false

func _ready() -> void:
	health = max_health
	# Must be in the "enemies" group for the player's basic attack to find and hit it
	add_to_group("enemies")
	add_to_group("trash")
	
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		if PlayerData.is_object_destroyed(scene_path, node_path_str):
			queue_free()
			return

func take_damage(amount: float, _knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
		
	health -= amount
	AudioManager.play_sfx("hit", randf_range(0.8, 1.2))
	
	# Small visual feedback (shake or scale pop)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.1, 1.1, 1.1), 0.05)
	tw.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.05)
	
	if health <= 0:
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		PlayerData.mark_object_destroyed(scene_path, node_path_str)
	
	_spawn_destruction_particles()
	AudioManager.play_sfx("exp_collect", 0.8) # Play a satisfying break sound
	
	destroyed.emit()
	queue_free()

func _spawn_destruction_particles() -> void:
	var particles = GPUParticles3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2) # Brownish trash color
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.3, 0.2)
	mat.emission_energy_multiplier = 0.5
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.2, 0.2)
	mesh.material = mat
	particles.draw_pass_1 = mesh
	
	var process_mat = ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_mat.emission_sphere_radius = 1.0
	process_mat.direction = Vector3(0, 1, 0)
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 2.0
	process_mat.initial_velocity_max = 5.0
	process_mat.gravity = Vector3(0, -9.8, 0)
	process_mat.scale_min = 0.5
	process_mat.scale_max = 1.5
	particles.process_material = process_mat
	
	particles.amount = 20
	particles.lifetime = 1.5
	particles.explosiveness = 0.9
	particles.one_shot = true
	
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	
	# Cleanup particles
	get_tree().create_timer(2.0).timeout.connect(particles.queue_free)
