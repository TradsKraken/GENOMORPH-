extends Node3D

func _ready() -> void:
	_generate_collisions(self)

func _generate_collisions(node: Node) -> void:
	if node is MeshInstance3D:
		var is_grass = node.name.to_lower().contains("grass")
		
		# Apply smooth culling to ALL meshes
		node.add_to_group("cullable_meshes")
		node.visibility_range_end = SettingsManager.draw_distance
		node.visibility_range_end_margin = 10.0
		node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		
		if is_grass:
			# Grass optimizations: no shadows
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			# Terrain optimizations: cast shadows, build collision
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			var has_collision := false
			for child in node.get_children():
				if child is CollisionObject3D:
					has_collision = true
					break
			# Import already bakes collision (see terrain_post_import.gd). Regenerating
			# it here on every scene load is a slow trimesh rebake per mesh and leaves
			# duplicate overlapping colliders behind — only fill in what's missing.
			if not has_collision:
				node.create_trimesh_collision()
			
		if node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var mat = node.mesh.surface_get_material(i)
				if mat and mat is BaseMaterial3D:
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
					# Disable receiving shadows on grass to save performance
					mat.disable_receive_shadows = is_grass
						
	for child in node.get_children():
		_generate_collisions(child)
