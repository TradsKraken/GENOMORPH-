@tool
extends EditorScenePostImport

var log_file

func _post_import(scene):
	log_file = FileAccess.open("res://import_debug.txt", FileAccess.WRITE)
	log_file.store_line("STARTING IMPORT FOR: " + scene.name)
	_process_nodes(scene, scene)
	log_file.store_line("IMPORT FINISHED")
	log_file.close()
	return scene

func _process_nodes(node: Node, root: Node):
	if node is MeshInstance3D:
		var n = node.name.to_lower()
		log_file.store_line("Processing Mesh: " + n)
		# 1. Add collisions (ignore grass)
		if not ("grass" in n or "leaf" in n or "flower" in n):
			if node.mesh != null:
				if "rock" in n:
					node.create_convex_collision(true, true)
					log_file.store_line(" -> Created convex collision")
				else:
					node.create_trimesh_collision()
					log_file.store_line(" -> Created trimesh collision")
				
				# Fix owner for generated collision nodes so they get saved!
				var collision_count = 0
				for child in node.get_children():
					if child is CollisionObject3D:
						collision_count += 1
						child.owner = root
						for shape in child.get_children():
							shape.owner = root
				log_file.store_line(" -> Set owner for " + str(collision_count) + " collision nodes")
			else:
				log_file.store_line(" -> Skipping collision (mesh is null)")
		else:
			log_file.store_line(" -> Skipping collision (grass/leaf/flower)")
			
		# 3. Fix transparency and shadows
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if "grass" in n or "leaf" in n or "flower" in n:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
			
		# 2. Fix camera occlusion by enabling Distance Dither Fade
		if node.mesh != null:
			for i in range(node.mesh.get_surface_count()):
				var mat = node.mesh.surface_get_material(i)
				if mat is StandardMaterial3D:
					# Fix transparency to Alpha Scissor for shadows to work on leaves/grass
					if mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
						mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						mat.alpha_scissor_threshold = 0.5
						
					# Force the material to receive light and shadows (in case it exported from Blender as Unshaded)
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
					# Sometimes Blender exports diffuse as emission, which blows out shadows
					mat.emission_enabled = false 
					
					if not ("plane" in n or "terrain" in n or "ground" in n):
						# This makes objects dissolve into dots when the camera gets too close!
						mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
						mat.distance_fade_max_distance = 11.0 # Starts fading here
						mat.distance_fade_min_distance = 7.0  # Fully invisible here
						
	# 4. Remove any lights accidentally exported from Blender! They wash out our custom game lighting and shadows!
	if node is Light3D:
		node.queue_free()
		return # Don't process children of a deleted node
			
	for child in node.get_children():
		_process_nodes(child, root)
