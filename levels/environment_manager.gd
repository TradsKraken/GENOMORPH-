extends WorldEnvironment

@export var max_fragments: int = 12

var _dir_light: DirectionalLight3D

# Toxic colors
var toxic_fog_color = Color(0.25, 0.45, 0.25) # richer murky green
var toxic_light_color = Color(0.85, 0.9, 0.6) # Brighter sickly sunlight for good contrast
var toxic_fog_density = 0.04

# Clean colors
var clean_fog_color = Color(0.6, 0.8, 1.0) # Clear sky blue
var clean_light_color = Color(1.0, 0.98, 0.92) # Warm natural sunlight
var clean_fog_density = 0.002

var _env_tween: Tween

func _ready() -> void:
	# ── MAKE LIGHTING APPEALING (Godot 4 Best Practices) ──
	if environment:
		# Cinematic colors
		environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		environment.tonemap_exposure = 1.0
		environment.tonemap_white = 1.0
		
		# Screen Space Ambient Occlusion (adds beautiful deep shadows in corners)
		environment.ssao_enabled = true
		environment.ssao_radius = 1.0
		environment.ssao_intensity = 2.0
		
		# Bloom / Glow
		environment.glow_enabled = true
		environment.glow_bloom = 0.1
		environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		
		# Volumetric Fog Tweaks
		environment.volumetric_fog_enabled = true
		environment.volumetric_fog_length = 64.0 # Keep it relatively close for performance
		environment.volumetric_fog_ambient_inject = 0.2

	# Find DirectionalLight3D and force Shadows ON
	if get_parent():
		for child in get_parent().get_children():
			if child is DirectionalLight3D:
				_dir_light = child
				
				# ── FORCE SHADOWS ON ──
				_dir_light.shadow_enabled = true
				_dir_light.light_energy = 1.5 # Boost brightness to create high contrast with shadows
				_dir_light.shadow_bias = 0.015
				_dir_light.shadow_blur = 1.5
				
				# Enable soft PCF3D shadows if supported
				_dir_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				_dir_light.directional_shadow_blend_splits = true
				break
	
	if get_tree().current_scene:
		_force_shadows(get_tree().current_scene)
		_force_collisions(get_tree().current_scene)
	
	PlayerData.genome_collected.connect(_on_genome_collected)
	
	# Set initial state (in case game loaded)
	_update_environment(PlayerData.genome_fragments, true)

func _force_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		# Ensure the mesh can cast and receive shadows
		if node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			
		var mat = node.material_override
		if mat == null and node.mesh:
			for i in range(node.mesh.get_surface_count()):
				mat = node.mesh.surface_get_material(i)
				_fix_material_for_shadows(mat, node.name)
		else:
			_fix_material_for_shadows(mat, node.name)
				
	for child in node.get_children():
		_force_shadows(child)

func _force_collisions(node: Node) -> void:
	if node is MeshInstance3D and "plane_002" in node.name.to_lower():
		var has_col = false
		for c in node.get_children():
			if c is CollisionObject3D:
				has_col = true
				break
		if not has_col:
			print("Runtime: Generating missing collision for Plane_002")
			node.create_trimesh_collision()
			
	for child in node.get_children():
		_force_collisions(child)

func _fix_material_for_shadows(mat: Material, node_name: String) -> void:
	if mat is StandardMaterial3D:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.emission_enabled = false
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		
		# If the soil/ground is too dark, shadows are invisible because the lit color is already black!
		# We force extremely dark colors to be slightly brighter so the shadow has room to appear.
		var c = mat.albedo_color
		if c.v < 0.35:
			mat.albedo_color = Color.from_hsv(c.h, c.s, 0.35, c.a)
			
		if "ground" in node_name.to_lower():
			mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED

func _on_genome_collected(current: int, _total: int) -> void:
	_update_environment(current, false)

func _update_environment(current: int, instant: bool) -> void:
	if not environment:
		return
		
	var progress = float(current) / float(max_fragments)
	progress = clamp(progress, 0.0, 1.0)
	
	var target_fog_color = toxic_fog_color.lerp(clean_fog_color, progress)
	var target_fog_density = lerpf(toxic_fog_density, clean_fog_density, progress)
	var target_light_color = toxic_light_color.lerp(clean_light_color, progress)
	
	environment.volumetric_fog_enabled = true
	
	if instant:
		environment.volumetric_fog_albedo = target_fog_color
		environment.volumetric_fog_density = target_fog_density
		if _dir_light:
			_dir_light.light_color = target_light_color
	else:
		if _env_tween and _env_tween.is_valid():
			_env_tween.kill()
		_env_tween = create_tween()
		_env_tween.set_parallel(true)
		_env_tween.tween_property(environment, "volumetric_fog_albedo", target_fog_color, 4.0).set_trans(Tween.TRANS_SINE)
		_env_tween.tween_property(environment, "volumetric_fog_density", target_fog_density, 4.0).set_trans(Tween.TRANS_SINE)
		if _dir_light:
			_env_tween.tween_property(_dir_light, "light_color", target_light_color, 4.0).set_trans(Tween.TRANS_SINE)
