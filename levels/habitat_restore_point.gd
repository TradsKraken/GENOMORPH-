extends InteractableBase
class_name HabitatRestorePoint

## Q03's "critical damaged area" — one-shot interactable representing the
## Purification Module activation. Plays a small local visual (we don't have
## dirty/clean mesh variants to swap yet) and notifies Q03Director.

signal restored

var _is_restored: bool = false

func _ready() -> void:
	super._ready()
	interact_prompt = "Restore"

func _perform_interaction() -> void:
	if _is_restored:
		return
	_is_restored = true
	set_active(false)

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("exp_collect")

	_spawn_purify_effect()

	restored.emit()

func _spawn_purify_effect() -> void:
	var light = OmniLight3D.new()
	light.light_color = Color(0.6, 1.0, 0.8)
	light.light_energy = 0.0
	light.omni_range = 6.0
	get_parent().add_child(light)
	light.global_position = global_position

	var particles = GPUParticles3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 1.0, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 1.0, 0.6)
	mat.emission_energy_multiplier = 2.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES

	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.2, 0.2)
	mesh.material = mat
	particles.draw_pass_1 = mesh

	var process_mat = ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_mat.emission_sphere_radius = 2.0
	process_mat.direction = Vector3(0, 1, 0)
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 1.0
	process_mat.initial_velocity_max = 3.0
	process_mat.gravity = Vector3(0, 0.5, 0)
	process_mat.scale_min = 0.5
	process_mat.scale_max = 1.5
	particles.process_material = process_mat

	particles.amount = 60
	particles.lifetime = 2.0
	particles.explosiveness = 0.8
	particles.one_shot = true

	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true

	var tw = create_tween()
	tw.tween_property(light, "light_energy", 3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(light, "light_energy", 0.0, 1.2).set_delay(0.3)
	tw.tween_callback(func():
		light.queue_free()
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()
	)
