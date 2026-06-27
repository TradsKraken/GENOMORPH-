extends CanvasLayer

## Performance HUD overlay.
## Displays FPS, memory, and objects in a semi-transparent panel.

@export var show_hud: bool = true :
	set(value):
		show_hud = value
		if is_inside_tree() and _panel != null:
			_panel.visible = value

var _panel: PanelContainer
var _lbl: Label

func _ready() -> void:
	layer = 128
	
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = show_hud
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.5)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", sb)
	
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 16
	_panel.offset_top = 16
	
	_lbl = Label.new()
	_lbl.add_theme_font_size_override("font_size", 14)
	_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_lbl.add_theme_constant_override("outline_size", 4)
	_lbl.add_theme_font_override("font", ThemeDB.fallback_font)
	
	_panel.add_child(_lbl)
	add_child(_panel)

func _process(_delta: float) -> void:
	if not show_hud:
		return
		
	var fps := Engine.get_frames_per_second()
	var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var objs := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	
	_lbl.text = "FPS: %d\nMem: %.1f MB\nNodes: %d\nDraws: %d" % [fps, mem, objs, draws]
