extends Node

const SAVE_PATH = "user://settings.cfg"

signal settings_changed

var resolution_scale: float = 1.0
var graphics_quality: int = 1 # 0: Low, 1: Medium, 2: High
var glow_enabled: bool = true
var draw_distance: float = 60.0
var shadows_enabled: bool = true
var foliage_enabled: bool = true

var camera_fov: float = 75.0
var camera_zoom: float = 3.5
var camera_sensitivity: float = 0.003

func _ready() -> void:
	load_settings()
	# Apply once at startup
	call_deferred("apply_settings")

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "resolution_scale", resolution_scale)
	config.set_value("graphics", "graphics_quality", graphics_quality)
	config.set_value("graphics", "glow", glow_enabled)
	config.set_value("graphics", "draw_distance", draw_distance)
	config.set_value("graphics", "shadows", shadows_enabled)
	config.set_value("graphics", "foliage", foliage_enabled)
	config.set_value("perspective", "camera_fov", camera_fov)
	config.set_value("perspective", "camera_zoom", camera_zoom)
	config.set_value("perspective", "camera_sensitivity", camera_sensitivity)
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		resolution_scale = config.get_value("graphics", "resolution_scale", 1.0)
		graphics_quality = config.get_value("graphics", "graphics_quality", 1)
		glow_enabled = config.get_value("graphics", "glow", true)
		draw_distance = config.get_value("graphics", "draw_distance", 60.0)
		shadows_enabled = config.get_value("graphics", "shadows", true)
		foliage_enabled = config.get_value("graphics", "foliage", true)
		camera_fov = config.get_value("perspective", "camera_fov", 75.0)
		camera_zoom = config.get_value("perspective", "camera_zoom", 3.5)
		camera_sensitivity = config.get_value("perspective", "camera_sensitivity", 0.003)

func apply_settings() -> void:
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_scale = resolution_scale
		# Disabled MSAA completely for better performance
		vp.msaa_3d = Viewport.MSAA_DISABLED
	
	# Apply glow to WorldEnvironment if present
	_apply_glow_to_tree(get_tree().root)
	
	_apply_draw_distance()
			
	_apply_shadows_to_tree(get_tree().root)
	
	var foliage = get_tree().get_nodes_in_group("foliage_detail")
	for f in foliage:
		if f is Node3D:
			f.visible = foliage_enabled
			
	# Update camera settings if we have a current camera
	var cam = get_viewport().get_camera_3d()
	if cam:
		cam.fov = camera_fov
		if "tp_distance_back" in cam:
			cam.tp_distance_back = camera_zoom
			
	settings_changed.emit()

func _apply_draw_distance() -> void:
	# Camera3D's far plane is the reliable global draw-distance control. Godot's
	# renderer then performs its native frustum culling for every visible 3D
	# object before issuing draw calls. Do not hide gameplay nodes manually:
	# they must continue simulating even when their visuals are out of view.
	var camera := get_viewport().get_camera_3d()
	if camera:
		camera.far = maxf(10.0, draw_distance)

	# Some detailed props can opt into an earlier mesh-level cutoff through this
	# existing group. Mesh-level ranges avoid rendering small decorations at the
	# edge of the camera far plane while keeping large terrain uninterrupted.
	for mesh in get_tree().get_nodes_in_group("cullable_meshes"):
		if mesh is GeometryInstance3D:
			mesh.visibility_range_end = draw_distance
			mesh.visibility_range_end_margin = minf(8.0, draw_distance * 0.1)

func _apply_glow_to_tree(node: Node) -> void:
	if node is WorldEnvironment and node.environment != null:
		node.environment.glow_enabled = glow_enabled
	for child in node.get_children():
		_apply_glow_to_tree(child)

func _apply_shadows_to_tree(node: Node) -> void:
	if node is DirectionalLight3D or node is OmniLight3D or node is SpotLight3D:
		node.shadow_enabled = shadows_enabled
	for child in node.get_children():
		_apply_shadows_to_tree(child)
