class_name SuitTheme

const COLOR_ACCENT_YELLOW = Color("#f2c94c")
const COLOR_TEXT_INACTIVE = Color("#777777")
const COLOR_BG_TEAL = Color("#12201c")

## Returns the shared UI Theme for all suit HUD elements
static func get_theme() -> Theme:
	var theme = Theme.new()
	
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_TEAL
	style.bg_color.a = 0.9
	style.border_color = COLOR_ACCENT_YELLOW
	style.border_width_left = 3
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.set_corner_radius_all(0)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	
	theme.set_stylebox("panel", "PanelContainer", style)
	
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "Courier New", "monospace"])
	theme.default_font = font
	theme.default_font_size = 20
	
	return theme
