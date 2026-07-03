extends CanvasLayer

class_name KnowledgeMenu

signal closed

var _panel: Control
var _item_list: ItemList
var _details_title: Label
var _details_category: Label
var _details_desc: RichTextLabel
var _empty_label: Label

var _unlocked_keys: Array[String] = []

func _ready() -> void:
	layer = 100 # Ensure it's above other UI
	process_mode = PROCESS_MODE_ALWAYS
	
	# Tech Font
	var tech_font := SystemFont.new()
	tech_font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "Courier New", "monospace"])

	# Full screen frosted glass background
	var bg_rect := ColorRect.new()
	var blur_mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;\nvoid fragment(){\n\tCOLOR = mix(textureLod(screen_texture, SCREEN_UV, 2.5), vec4(0.02, 0.04, 0.08, 1.0), 0.65);\n}"
	blur_mat.shader = shader
	bg_rect.material = blur_mat
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	# Center panel
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(800, 500)
	
	# Center it properly
	_panel.offset_left = -400
	_panel.offset_right = 400
	_panel.offset_top = -250
	_panel.offset_bottom = 250
	
	# Tech Panel Background
	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0.04, 0.08, 0.12, 0.9)
	panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(panel_bg)
	
	# Scanlines
	var scanlines := ColorRect.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	var scan_mat := ShaderMaterial.new()
	scan_mat.shader = load("res://ui/scanlines.gdshader")
	scanlines.material = scan_mat
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(scanlines)
	
	# Mechanical Borders Overlay
	var borders := Control.new()
	borders.set_anchors_preset(Control.PRESET_FULL_RECT)
	borders.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b_script := GDScript.new()
	b_script.source_code = "extends Control\nfunc _draw():\n\tvar c = Color(0.1, 0.9, 0.7, 0.9)\n\tvar r = get_rect().size\n\tvar l = 24.0\n\tvar t = 2.0\n\tdraw_rect(Rect2(0,0,l,t), c); draw_rect(Rect2(0,0,t,l), c)\n\tdraw_rect(Rect2(r.x-l,0,l,t), c); draw_rect(Rect2(r.x-t,0,t,l), c)\n\tdraw_rect(Rect2(0,r.y-t,l,t), c); draw_rect(Rect2(0,r.y-l,t,l), c)\n\tdraw_rect(Rect2(r.x-l,r.y-t,l,t), c); draw_rect(Rect2(r.x-t,r.y-l,t,l), c)\n\tvar c2 = Color(0.1, 0.9, 0.7, 0.4)\n\tfor p in [Vector2(40,40), Vector2(r.x-40,40), Vector2(40,r.y-40), Vector2(r.x-40,r.y-40)]:\n\t\tdraw_line(p-Vector2(8,0), p+Vector2(8,0), c2, 1)\n\t\tdraw_line(p-Vector2(0,8), p+Vector2(0,8), c2, 1)"
	b_script.reload()
	borders.set_script(b_script)
	_panel.add_child(borders)
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)
	
	# Main VBox
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(main_vbox)
	
	# Header
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var title := Label.new()
	title.text = "GENOME DATABASE"
	title.add_theme_font_override("font", tech_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.9))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.add_theme_font_override("font", tech_font)
	close_btn.custom_minimum_size = Vector2(100, 40)
	
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.05, 0.1, 0.15, 0.8)
	btn_normal.border_color = Color(0.1, 0.9, 0.7, 0.5)
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(0)
	close_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color(0.1, 0.3, 0.25, 0.9)
	btn_hover.border_color = Color(0.1, 0.9, 0.7, 1.0)
	close_btn.add_theme_stylebox_override("hover", btn_hover)
	
	close_btn.pressed.connect(_on_close)
	header_hbox.add_child(close_btn)
	
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.1, 0.9, 0.7, 0.3)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	main_vbox.add_child(sep)
	
	# Split Layout
	var split_hbox := HBoxContainer.new()
	split_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hbox.add_theme_constant_override("separation", 24)
	main_vbox.add_child(split_hbox)
	
	# Left: List of unlocked items
	_item_list = ItemList.new()
	_item_list.custom_minimum_size = Vector2(250, 0)
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.add_theme_font_override("font", tech_font)
	_item_list.add_theme_font_size_override("font_size", 18)
	_item_list.add_theme_color_override("font_color", Color(0.7, 0.9, 0.8))
	
	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.02, 0.04, 0.06, 0.6)
	list_bg.border_color = Color(0.1, 0.9, 0.7, 0.2)
	list_bg.set_border_width_all(1)
	list_bg.set_corner_radius_all(0)
	_item_list.add_theme_stylebox_override("panel", list_bg)
	_item_list.add_theme_constant_override("v_separation", 8)
	
	_item_list.item_selected.connect(_on_item_selected)
	split_hbox.add_child(_item_list)
	
	var vsep := VSeparator.new()
	var vsep_style := StyleBoxLine.new()
	vsep_style.color = Color(0.1, 0.9, 0.7, 0.3)
	vsep_style.thickness = 1
	vsep_style.vertical = true
	vsep.add_theme_stylebox_override("separator", vsep_style)
	split_hbox.add_child(vsep)
	
	# Right: Details view
	var details_vbox := VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_vbox.add_theme_constant_override("separation", 12)
	split_hbox.add_child(details_vbox)
	
	_empty_label = Label.new()
	_empty_label.text = "Select a biological entry to display telemetry."
	_empty_label.add_theme_font_override("font", tech_font)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.5))
	details_vbox.add_child(_empty_label)
	
	_details_title = Label.new()
	_details_title.add_theme_font_override("font", tech_font)
	_details_title.add_theme_font_size_override("font_size", 32)
	_details_title.add_theme_color_override("font_color", Color(0.1, 0.9, 0.7))
	_details_title.visible = false
	details_vbox.add_child(_details_title)
	
	_details_category = Label.new()
	_details_category.add_theme_font_override("font", tech_font)
	_details_category.add_theme_font_size_override("font_size", 18)
	_details_category.add_theme_color_override("font_color", Color(0.5, 0.8, 0.7))
	_details_category.visible = false
	details_vbox.add_child(_details_category)
	
	_details_desc = RichTextLabel.new()
	_details_desc.bbcode_enabled = true
	_details_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_desc.add_theme_font_override("normal_font", tech_font)
	_details_desc.add_theme_font_size_override("normal_font_size", 20)
	_details_desc.add_theme_color_override("default_color", Color(0.8, 0.9, 0.85))
	_details_desc.visible = false
	details_vbox.add_child(_details_desc)
	
	add_child(_panel)
	
	_populate_list()

func _populate_list() -> void:
	_item_list.clear()
	_unlocked_keys.clear()
	
	for key in PlayerData.unlocked_knowledge:
		if key in PlayerData.KNOWLEDGE_DB:
			var data = PlayerData.KNOWLEDGE_DB[key]
			var display_text = data.get("icon", "") + " " + data.get("title", "Unknown")
			_item_list.add_item(display_text)
			_unlocked_keys.append(key)
			
	if _item_list.item_count == 0:
		_item_list.add_item("DATA CORRUPTED")
		_item_list.set_item_disabled(0, true)

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _unlocked_keys.size(): return
	
	var key = _unlocked_keys[index]
	var data = PlayerData.KNOWLEDGE_DB[key]
	
	_empty_label.visible = false
	
	_details_title.visible = true
	_details_title.text = data.get("title", "")
	
	_details_category.visible = true
	_details_category.text = "Category: " + data.get("category", "")
	
	_details_desc.visible = true
	_details_desc.text = data.get("desc", "")

func _on_close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
