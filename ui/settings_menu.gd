extends CanvasLayer

class_name SettingsMenu

signal closed

var _panel: PanelContainer
var _vbox: VBoxContainer

func _ready() -> void:
	layer = 100 # Ensure it's above other UI
	
	# Full screen background
	var bg_rect := ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 0.6)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size = Vector2(700, 500)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.border_color = Color(0.3, 0.5, 0.8, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 16
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 40
	sb.content_margin_bottom = 40
	_panel.add_theme_stylebox_override("panel", sb)
	
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 32)
	_panel.add_child(_vbox)
	
	# Title
	var title := Label.new()
	title.text = "GRAPHICS SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_vbox.add_child(title)
	
	var sep := HSeparator.new()
	_vbox.add_child(sep)
	
	# Settings options
	_build_scale_option()
	_build_quality_option()
	_build_glow_toggle()
	_build_draw_distance_option()
	
	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_child(spacer)
	
	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.custom_minimum_size = Vector2(0, 80)
	close_btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	close_btn.pressed.connect(_on_close)
	_vbox.add_child(close_btn)
	
	add_child(_panel)

func _build_scale_option() -> void:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "3D Render Scale:"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 28)
	hbox.add_child(lbl)
	
	var opt := OptionButton.new()
	opt.add_theme_font_size_override("font_size", 24)
	opt.add_item("50% (Fast)", 0)
	opt.add_item("75% (Balanced)", 1)
	opt.add_item("100% (High Quality)", 2)
	
	# Find current setting
	var current = SettingsManager.resolution_scale
	if current <= 0.6: opt.selected = 0
	elif current <= 0.85: opt.selected = 1
	else: opt.selected = 2
	
	opt.item_selected.connect(func(index: int):
		if index == 0: SettingsManager.resolution_scale = 0.5
		elif index == 1: SettingsManager.resolution_scale = 0.75
		elif index == 2: SettingsManager.resolution_scale = 1.0
		SettingsManager.apply_settings()
	)
	hbox.add_child(opt)
	_vbox.add_child(hbox)

func _build_quality_option() -> void:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Graphics Quality:"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 28)
	hbox.add_child(lbl)
	
	var opt := OptionButton.new()
	opt.add_theme_font_size_override("font_size", 24)
	opt.add_item("Low (Fastest)", 0)
	opt.add_item("Medium (Balanced)", 1)
	opt.add_item("High (Beautiful)", 2)
	
	opt.selected = SettingsManager.graphics_quality
			
	opt.item_selected.connect(func(index: int):
		SettingsManager.graphics_quality = index
		SettingsManager.apply_settings()
	)
	hbox.add_child(opt)
	_vbox.add_child(hbox)

func _build_glow_toggle() -> void:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Environment Glow:"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 28)
	hbox.add_child(lbl)
	
	var check := CheckButton.new()
	check.button_pressed = SettingsManager.glow_enabled
	check.toggled.connect(func(toggled_on: bool):
		SettingsManager.glow_enabled = toggled_on
		SettingsManager.apply_settings()
	)
	hbox.add_child(check)
	_vbox.add_child(hbox)

func _build_draw_distance_option() -> void:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Draw Distance:"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 28)
	hbox.add_child(lbl)
	
	var opt := OptionButton.new()
	opt.add_theme_font_size_override("font_size", 24)
	opt.add_item("Low (35m)", 0)
	opt.add_item("Medium (60m)", 1)
	opt.add_item("High (100m)", 2)
	opt.add_item("Ultra (200m)", 3)
	
	var current = SettingsManager.draw_distance
	if current <= 35.0: opt.selected = 0
	elif current <= 60.0: opt.selected = 1
	elif current <= 100.0: opt.selected = 2
	else: opt.selected = 3
	
	opt.item_selected.connect(func(index: int):
		if index == 0: SettingsManager.draw_distance = 35.0
		elif index == 1: SettingsManager.draw_distance = 60.0
		elif index == 2: SettingsManager.draw_distance = 100.0
		elif index == 3: SettingsManager.draw_distance = 200.0
		SettingsManager.apply_settings()
	)
	hbox.add_child(opt)
	_vbox.add_child(hbox)

func _on_close() -> void:
	SettingsManager.save_settings()
	closed.emit()
	queue_free()
