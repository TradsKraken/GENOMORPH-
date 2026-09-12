extends StaticBody3D
class_name TrashPile

signal destroyed

@export var max_health: float = 30.0
var health: float
var is_dead: bool = false
var _cleanup_enabled: bool = true

func _ready() -> void:
	health = max_health
	set_cleanup_enabled(_cleanup_enabled)
	# The source GLB is an asset collection: its rubbish-bin mesh is stored
	# several metres away from the imported scene root.  Without correcting
	# that, the visible pile, its collider, and the point the player attacks do
	# not agree.  Do this deferred so every imported mesh is in the scene tree.
	call_deferred("_align_visual_and_collision")
	
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		if PlayerData.is_object_destroyed(scene_path, node_path_str):
			queue_free()
			return
			
	_add_highlight_effect()

func _align_visual_and_collision() -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(self, meshes)
	var trash_mesh := _find_rubbish_mesh(meshes)
	if trash_mesh == null:
		push_warning("TrashPile could not find the rubbish-bin mesh to align its collision.")
		return

	# This GLB also contains decorative cattails, roots, and a rock.  They are
	# separate assets rather than part of the rubbish pile, so keep only the
	# actual bin mesh in this reusable cleanup prop.
	for mesh in meshes:
		mesh.visible = mesh == trash_mesh

	var bounds := _get_world_bounds(trash_mesh)
	if bounds.size == Vector3.ZERO:
		return

	# Place the centre of the bins above this node and sit their lowest point on
	# the ground.  The StaticBody3D root is now exactly where the player sees it.
	var desired_center := global_position + Vector3(0.0, bounds.size.y * 0.5, 0.0)
	trash_mesh.global_position += desired_center - bounds.get_center()
	bounds = _get_world_bounds(trash_mesh)
	_fit_collision_to_bounds(bounds)

func _collect_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		_collect_meshes(child, meshes)

func _find_rubbish_mesh(meshes: Array[MeshInstance3D]) -> MeshInstance3D:
	for mesh in meshes:
		var mesh_name := mesh.name.to_lower()
		if "rubbish" in mesh_name or "bin" in mesh_name or "trash" in mesh_name:
			return mesh
	return null

func _get_world_bounds(mesh: MeshInstance3D) -> AABB:
	var local_bounds := mesh.get_aabb()
	var first_corner := true
	var bounds := AABB()
	for x in [local_bounds.position.x, local_bounds.end.x]:
		for y in [local_bounds.position.y, local_bounds.end.y]:
			for z in [local_bounds.position.z, local_bounds.end.z]:
				var corner := mesh.global_transform * Vector3(x, y, z)
				if first_corner:
					bounds.position = corner
					first_corner = false
				else:
					bounds = bounds.expand(corner)
	return bounds

func _fit_collision_to_bounds(world_bounds: AABB) -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D:
		return

	# Each placed pile needs its own shape; otherwise resizing a shared scene
	# resource would make every pile inherit the last pile's dimensions.
	collision.shape = collision.shape.duplicate()
	var box := collision.shape as BoxShape3D
	box.size = world_bounds.size + Vector3(0.15, 0.05, 0.15)
	collision.global_position = world_bounds.get_center()

func _add_highlight_effect() -> void:
	# Add a pulsing light to draw attention
	var light = OmniLight3D.new()
	light.light_color = Color(0.8, 1.0, 0.4) # Sickly yellow-green
	light.light_energy = 0.5
	light.omni_range = 4.0
	light.position = Vector3(0, 1.5, 0)
	add_child(light)
	
	var tw = create_tween().set_loops()
	tw.tween_property(light, "light_energy", 1.5, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(light, "light_energy", 0.5, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func take_damage(amount: float, _knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead or not _cleanup_enabled:
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

## Used by HabitatRestorePoint to keep Q03's cleanup props intact until its
## restoration phase is active. Other TrashPile instances remain enabled.
func set_cleanup_enabled(enabled: bool) -> void:
	_cleanup_enabled = enabled
	if enabled:
		add_to_group("enemies")
		add_to_group("trash")
	else:
		remove_from_group("enemies")
		remove_from_group("trash")

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
