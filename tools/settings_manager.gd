extends Node

const SAVE_PATH = "user://settings.cfg"

var resolution_scale: float = 1.0
var msaa: int = Viewport.MSAA_DISABLED
var glow_enabled: bool = true

func _ready() -> void:
	load_settings()
	# Apply once at startup
	call_deferred("apply_settings")

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "resolution_scale", resolution_scale)
	config.set_value("graphics", "msaa", msaa)
	config.set_value("graphics", "glow", glow_enabled)
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		resolution_scale = config.get_value("graphics", "resolution_scale", 1.0)
		msaa = config.get_value("graphics", "msaa", Viewport.MSAA_DISABLED)
		glow_enabled = config.get_value("graphics", "glow", true)

func apply_settings() -> void:
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_scale = resolution_scale
		vp.msaa_3d = msaa
	
	# Apply glow to WorldEnvironment if present
	_apply_glow_to_tree(get_tree().root)

func _apply_glow_to_tree(node: Node) -> void:
	if node is WorldEnvironment and node.environment != null:
		node.environment.glow_enabled = glow_enabled
	for child in node.get_children():
		_apply_glow_to_tree(child)
