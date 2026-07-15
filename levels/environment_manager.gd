extends WorldEnvironment
class_name EnvironmentManager

@export var max_fragments: int = 12

var _dir_light: DirectionalLight3D

# Toxic colors
var toxic_fog_color = Color(0.2, 0.4, 0.2) # Murky green
var toxic_light_color = Color(0.6, 0.7, 0.4) # Sickly yellow-green
var toxic_fog_density = 0.05

# Clean colors
var clean_fog_color = Color(0.5, 0.7, 0.8) # Clear blue/white
var clean_light_color = Color(1.0, 1.0, 0.9) # Bright sunlight
var clean_fog_density = 0.005

var _env_tween: Tween

func _ready() -> void:
	# Find DirectionalLight3D
	if get_parent():
		for child in get_parent().get_children():
			if child is DirectionalLight3D:
				_dir_light = child
				break
	
	PlayerData.genome_collected.connect(_on_genome_collected)
	
	# Set initial state (in case game loaded)
	_update_environment(PlayerData.genome_fragments, true)

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
