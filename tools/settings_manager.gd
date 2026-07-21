extends Node

const SAVE_PATH = "user://settings.cfg"

signal settings_changed

var resolution_scale: float = 1.0
var graphics_quality: int = 1 # 0: Low, 1: Medium, 2: High
var glow_enabled: bool = true
var draw_distance: float = 60.0

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
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		resolution_scale = config.get_value("graphics", "resolution_scale", 1.0)
		graphics_quality = config.get_value("graphics", "graphics_quality", 1)
		glow_enabled = config.get_value("graphics", "glow", true)
		draw_distance = config.get_value("graphics", "draw_distance", 60.0)

func apply_settings() -> void:
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_scale = resolution_scale
		# Disabled MSAA completely for better performance
		vp.msaa_3d = Viewport.MSAA_DISABLED
	
	# Apply glow to WorldEnvironment if present
	_apply_glow_to_tree(get_tree().root)
	
	var meshes = get_tree().get_nodes_in_group("cullable_meshes")
	for m in meshes:
		if m is MeshInstance3D:
			m.visibility_range_end = draw_distance
			
	settings_changed.emit()

func _apply_glow_to_tree(node: Node) -> void:
	if node is WorldEnvironment and node.environment != null:
		node.environment.glow_enabled = glow_enabled
	for child in node.get_children():
		_apply_glow_to_tree(child)
