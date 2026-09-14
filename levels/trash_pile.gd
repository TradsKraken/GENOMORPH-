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

func _align_visual_and_collision() -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(self, meshes)
	var trash_mesh := _find_rubbish_mesh(meshes)
	if trash_mesh == null:
		if meshes.size() > 0:
			trash_mesh = meshes[0]
		else:
			return

	# Hide decorative meshes (cattails, roots, rock) — keep only the trash bin
	for mesh in meshes:
		if mesh != trash_mesh:
			mesh.visible = false

	# Compute world-space bounding box of the trash mesh
	var aabb := trash_mesh.get_aabb()
	var wmin := Vector3(INF, INF, INF)
	var wmax := Vector3(-INF, -INF, -INF)
	for x in [aabb.position.x, aabb.end.x]:
		for y in [aabb.position.y, aabb.end.y]:
			for z in [aabb.position.z, aabb.end.z]:
				var wp := trash_mesh.global_transform * Vector3(x, y, z)
				wmin.x = minf(wmin.x, wp.x)
				wmin.y = minf(wmin.y, wp.y)
				wmin.z = minf(wmin.z, wp.z)
				wmax.x = maxf(wmax.x, wp.x)
				wmax.y = maxf(wmax.y, wp.y)
				wmax.z = maxf(wmax.z, wp.z)

	var mesh_size := wmax - wmin
	var mesh_bottom_center := Vector3((wmin.x + wmax.x) * 0.5, wmin.y, (wmin.z + wmax.z) * 0.5)

	# Save every child's world transform before we move the root
	var child_transforms: Array[Transform3D] = []
	for child in get_children():
		if child is Node3D:
			child_transforms.append((child as Node3D).global_transform)
		else:
			child_transforms.append(Transform3D.IDENTITY)

	# Move the StaticBody3D root to where the mesh actually is.
	# This fixes attack targeting which checks distance to self.global_position.
	global_position = mesh_bottom_center

	# Restore children to their original world positions so the mesh doesn't move
	for i in get_child_count():
		var child = get_child(i)
		if child is Node3D:
			(child as Node3D).global_transform = child_transforms[i]

	# Now place the collision shape locally — the root is at the mesh's feet
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision and collision.shape is BoxShape3D:
		collision.shape = collision.shape.duplicate()
		var box := collision.shape as BoxShape3D
		box.size = mesh_size + Vector3(0.3, 0.1, 0.3)
		collision.position = Vector3(0.0, mesh_size.y * 0.5, 0.0)

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

var _highlight_tween: Tween

func set_highlight(enabled: bool) -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(self, meshes)
	var trash_mesh := _find_rubbish_mesh(meshes)
	if trash_mesh == null:
		return
		
	if not enabled:
		trash_mesh.material_overlay = null
		if _highlight_tween:
			_highlight_tween.kill()
		return
		
	if trash_mesh.material_overlay != null:
		return # Already highlighted
		
	var mat = StandardMaterial3D.new()
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 1.0, 0.2, 0.0)
	trash_mesh.material_overlay = mat
	
	if _highlight_tween:
		_highlight_tween.kill()
		
	_highlight_tween = create_tween().set_loops()
	_highlight_tween.tween_property(mat, "albedo_color:a", 0.45, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_highlight_tween.tween_property(mat, "albedo_color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
