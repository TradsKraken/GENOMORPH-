extends CanvasLayer

class_name KnowledgeMenu

signal closed

# â”€â”€ Node refs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
var _panel: Control
var _item_list: ItemList
var _detail_panel: ScrollContainer
var _empty_label: Label
var _detail_content: VBoxContainer
var _filter_btns: Dictionary = {}
var _current_filter: String = "All"
var _unlocked_keys: Array[String] = []
var _tech_font: SystemFont

# â”€â”€ Threat Level Colors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const THREAT_COLORS: Dictionary = {
	"CRITICAL": Color(1.0, 0.2, 0.2),
	"HIGH":     Color(1.0, 0.55, 0.1),
	"MODERATE": Color(1.0, 0.9, 0.2),
	"LOW":      Color(0.3, 1.0, 0.5),
	"ALLY":     Color(0.1, 0.9, 0.7),
	"ASSET":    Color(0.4, 0.7, 1.0),
	"UNKNOWN":  Color(0.6, 0.6, 0.6),
}

# â”€â”€ Category Colors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const CATEGORY_COLORS: Dictionary = {
	"All":         Color(0.1, 0.9, 0.7),
	"Species":     Color(0.4, 1.0, 0.5),
	"Environment": Color(0.9, 0.7, 0.2),
	"Characters":  Color(0.7, 0.5, 1.0),
	"Technology":  Color(0.3, 0.8, 1.0),
	"History":     Color(1.0, 0.5, 0.3),
}

# â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func _ready() -> void:
	layer = 100
	process_mode = PROCESS_MODE_ALWAYS

	_tech_font = SystemFont.new()
	_tech_font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "Courier New", "monospace"])

	_build_background()
	_build_panel()
	add_child(_panel)
	_populate_list()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close()

# â”€â”€ Build UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func _build_background() -> void:
	var bg_rect := ColorRect.new()
	var blur_mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;\nvoid fragment(){\n\tCOLOR = mix(textureLod(screen_texture, SCREEN_UV, 2.5), vec4(0.02, 0.04, 0.08, 1.0), 0.70);\n}"
	blur_mat.shader = shader
	bg_rect.material = blur_mat
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

func _build_panel() -> void:
	# â”€â”€ Outer panel (wider for more content) â”€â”€
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(960, 620)
	_panel.offset_left   = -480
	_panel.offset_right  = 480
	_panel.offset_top    = -310
	_panel.offset_bottom = 310

	# Dark tech background
	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0.03, 0.06, 0.10, 0.95)
	panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(panel_bg)

	# Scanlines overlay
	var scanlines := ColorRect.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	var scan_mat := ShaderMaterial.new()
	scan_mat.shader = load("res://ui/scanlines.gdshader")
	scanlines.material = scan_mat
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(scanlines)

	# Corner brackets
	var borders := Control.new()
	borders.set_anchors_preset(Control.PRESET_FULL_RECT)
	borders.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b_script := GDScript.new()
	b_script.source_code = "extends Control\nfunc _draw():\n\tvar c = Color(0.1, 0.9, 0.7, 0.9)\n\tvar r = get_rect().size\n\tvar l = 28.0\n\tvar t = 2.0\n\tdraw_rect(Rect2(0,0,l,t), c); draw_rect(Rect2(0,0,t,l), c)\n\tdraw_rect(Rect2(r.x-l,0,l,t), c); draw_rect(Rect2(r.x-t,0,t,l), c)\n\tdraw_rect(Rect2(0,r.y-t,l,t), c); draw_rect(Rect2(0,r.y-l,t,l), c)\n\tdraw_rect(Rect2(r.x-l,r.y-t,l,t), c); draw_rect(Rect2(r.x-t,r.y-l,t,l), c)\n\tvar c2 = Color(0.1, 0.9, 0.7, 0.35)\n\tfor p in [Vector2(50,50), Vector2(r.x-50,50), Vector2(50,r.y-50), Vector2(r.x-50,r.y-50)]:\n\t\tdraw_line(p-Vector2(10,0), p+Vector2(10,0), c2, 1)\n\t\tdraw_line(p-Vector2(0,10), p+Vector2(0,10), c2, 1)"
	b_script.reload()
	borders.set_script(b_script)
	_panel.add_child(borders)

	# Main margin
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_panel.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(main_vbox)

	_build_header(main_vbox)
	_build_separator(main_vbox)
	_build_category_filters(main_vbox)
	_build_separator(main_vbox)
	_build_split_layout(main_vbox)

func _build_header(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	# Icon + Title block
	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(title_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "â—ˆ GENOME DATABASE"
	title_lbl.add_theme_font_override("font", _tech_font)
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.92))
	title_vbox.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "BIOLOGICAL & ECOLOGICAL FIELD RECORDS"
	subtitle_lbl.add_theme_font_override("font", _tech_font)
	subtitle_lbl.add_theme_font_size_override("font_size", 13)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.1, 0.9, 0.7, 0.6))
	title_vbox.add_child(subtitle_lbl)

	var close_btn := _make_button("âœ•  CLOSE", _on_close)
	close_btn.custom_minimum_size = Vector2(110, 44)
	hbox.add_child(close_btn)

func _build_category_filters(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	parent.add_child(hbox)

	var filter_lbl := Label.new()
	filter_lbl.text = "FILTER:"
	filter_lbl.add_theme_font_override("font", _tech_font)
	filter_lbl.add_theme_font_size_override("font_size", 14)
	filter_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.55))
	hbox.add_child(filter_lbl)

	for cat in ["All", "Species", "Environment", "Characters", "Technology", "History"]:
		var btn := _make_filter_button(cat)
		hbox.add_child(btn)
		_filter_btns[cat] = btn

	_set_filter_active("All")

func _make_filter_button(cat: String) -> Button:
	var btn := Button.new()
	btn.text = cat.to_upper()
	btn.add_theme_font_override("font", _tech_font)
	btn.add_theme_font_size_override("font_size", 13)
	btn.custom_minimum_size = Vector2(0, 30)
	btn.toggle_mode = false
	_style_filter_btn(btn, cat, false)
	btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	btn.pressed.connect(func(): _on_filter_pressed(cat))
	return btn

func _style_filter_btn(btn: Button, cat: String, active: bool) -> void:
	var col: Color = CATEGORY_COLORS.get(cat, Color(0.1, 0.9, 0.7))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(col.r, col.g, col.b, 0.12) if active else Color(0.05, 0.08, 0.10, 0.7)
	normal.border_color = Color(col.r, col.g, col.b, 0.9) if active else Color(col.r, col.g, col.b, 0.35)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.content_margin_left  = 12
	normal.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.9) if active else Color(col.r, col.g, col.b, 0.55))
	btn.add_theme_color_override("font_hover_color", col)
	var hover := normal.duplicate()
	hover.bg_color = Color(col.r, col.g, col.b, 0.20)
	hover.border_color = col
	btn.add_theme_stylebox_override("hover", hover)

func _build_split_layout(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 20)
	parent.add_child(hbox)

	# â”€â”€ LEFT: entry list â”€â”€
	var list_vbox := VBoxContainer.new()
	list_vbox.custom_minimum_size = Vector2(240, 0)
	list_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(list_vbox)

	var count_lbl := Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.add_theme_font_override("font", _tech_font)
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", Color(0.3, 0.6, 0.5))
	list_vbox.add_child(count_lbl)

	_item_list = ItemList.new()
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.add_theme_font_override("font", _tech_font)
	_item_list.add_theme_font_size_override("font_size", 16)
	_item_list.add_theme_color_override("font_color", Color(0.7, 0.9, 0.8))
	_item_list.add_theme_color_override("font_selected_color", Color(0.1, 1.0, 0.75))

	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.02, 0.04, 0.06, 0.5)
	list_bg.border_color = Color(0.1, 0.9, 0.7, 0.15)
	list_bg.set_border_width_all(1)
	_item_list.add_theme_stylebox_override("panel", list_bg)

	var list_sel := StyleBoxFlat.new()
	list_sel.bg_color = Color(0.05, 0.25, 0.2, 0.8)
	list_sel.border_color = Color(0.1, 0.9, 0.7, 0.6)
	list_sel.set_border_width_all(1)
	_item_list.add_theme_stylebox_override("selected", list_sel)
	_item_list.add_theme_stylebox_override("selected_focus", list_sel)
	_item_list.add_theme_constant_override("v_separation", 10)

	_item_list.item_selected.connect(_on_item_selected)
	list_vbox.add_child(_item_list)

	# â”€â”€ VSEP â”€â”€
	var vsep := VSeparator.new()
	var vsep_style := StyleBoxLine.new()
	vsep_style.color = Color(0.1, 0.9, 0.7, 0.2)
	vsep_style.thickness = 1
	vsep_style.vertical = true
	vsep.add_theme_stylebox_override("separator", vsep_style)
	hbox.add_child(vsep)

	# â”€â”€ RIGHT: detail scroll â”€â”€
	_detail_panel = ScrollContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hbox.add_child(_detail_panel)

	_detail_content = VBoxContainer.new()
	_detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_content.add_theme_constant_override("separation", 16)
	_detail_panel.add_child(_detail_content)

	# Empty state prompt
	_empty_label = Label.new()
	_empty_label.text = "â€” Select an entry to view its biological telemetry â€”"
	_empty_label.add_theme_font_override("font", _tech_font)
	_empty_label.add_theme_font_size_override("font_size", 16)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.add_theme_color_override("font_color", Color(0.3, 0.5, 0.45))
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_content.add_child(_empty_label)

func _build_separator(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.1, 0.9, 0.7, 0.2)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	parent.add_child(sep)

# â”€â”€ List Population â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func _populate_list() -> void:
	_item_list.clear()
	_unlocked_keys.clear()

	for key in PlayerData.unlocked_knowledge:
		if key in PlayerData.KNOWLEDGE_DB:
			var data: Dictionary = PlayerData.KNOWLEDGE_DB[key]
			var cat: String = data.get("category", "")
			if _current_filter != "All" and cat != _current_filter:
				continue
			var icon: String = data.get("icon", "")
			var title: String = data.get("title", "Unknown")
			var subcat: String = data.get("subcategory", cat)
			_item_list.add_item(icon + "  " + title + "\n     [" + subcat + "]")
			_unlocked_keys.append(key)

	# Update count label
	var count_lbl: Label = _panel.find_child("CountLabel", true, false) as Label
	if count_lbl:
		var total: int = PlayerData.unlocked_knowledge.size()
		count_lbl.text = "%d / %d ENTRIES DISCOVERED" % [_unlocked_keys.size(), total]

	if _item_list.item_count == 0:
		_item_list.add_item("  â€” NO ENTRIES â€”")
		_item_list.set_item_disabled(0, true)

# â”€â”€ Detail View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _unlocked_keys.size():
		return
	var key: String = _unlocked_keys[index]
	var data: Dictionary = PlayerData.KNOWLEDGE_DB[key]
	_show_detail(data)

func _show_detail(data: Dictionary) -> void:
	# Clear previous content (keep empty label, hide it)
	for child in _detail_content.get_children():
		if child != _empty_label:
			child.queue_free()
	_empty_label.visible = false
	await get_tree().process_frame

	# â”€â”€ 1. Title row â”€â”€
	var title_hbox := HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 12)
	_detail_content.add_child(title_hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = data.get("icon", "â—ˆ")
	icon_lbl.add_theme_font_override("font", _tech_font)
	icon_lbl.add_theme_font_size_override("font_size", 44)
	icon_lbl.add_theme_color_override("font_color", Color(0.1, 0.9, 0.7))
	title_hbox.add_child(icon_lbl)

	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override("separation", 2)
	title_hbox.add_child(title_block)

	var title_lbl := Label.new()
	title_lbl.text = data.get("title", "Unknown")
	title_lbl.add_theme_font_override("font", _tech_font)
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.95))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_block.add_child(title_lbl)

	var sci_name := Label.new()
	sci_name.text = data.get("classification", "")
	sci_name.add_theme_font_override("font", _tech_font)
	sci_name.add_theme_font_size_override("font_size", 14)
	sci_name.add_theme_color_override("font_color", Color(0.1, 0.9, 0.7, 0.7))
	title_block.add_child(sci_name)

	# â”€â”€ 2. Category + Threat row â”€â”€
	var meta_hbox := HBoxContainer.new()
	meta_hbox.add_theme_constant_override("separation", 10)
	_detail_content.add_child(meta_hbox)

	var cat_str: String = data.get("category", "") + "  Â·  " + data.get("subcategory", "")
	var cat_color: Color = CATEGORY_COLORS.get(data.get("category", ""), Color(0.1, 0.9, 0.7))
	var cat_badge := _make_badge(
		cat_str,
		cat_color,
		14
	)
	meta_hbox.add_child(cat_badge)

	var threat: String = data.get("threat_level", "UNKNOWN")
	var threat_col: Color = THREAT_COLORS.get(threat, Color(0.6, 0.6, 0.6))
	var threat_badge := _make_badge("âš  THREAT: " + threat, threat_col, 14)
	meta_hbox.add_child(threat_badge)

	# â”€â”€ 3. Separator â”€â”€
	_detail_content.add_child(_make_thin_sep())

	# â”€â”€ 4. Summary â”€â”€
	var summary_label := _make_section_header("OVERVIEW")
	_detail_content.add_child(summary_label)

	var summary_text: String = data.get("summary", "")
	var summary_rtl := _make_rtl(summary_text, 16)
	_detail_content.add_child(summary_rtl)

	# â”€â”€ 5. Key Facts â”€â”€
	var facts_raw: Array = data.get("facts", [])
	if facts_raw.size() > 0:
		_detail_content.add_child(_make_thin_sep())
		_detail_content.add_child(_make_section_header("â¬¡ BIOLOGICAL FIELD NOTES"))

		for fact_entry in facts_raw:
			var fact_hbox := HBoxContainer.new()
			fact_hbox.add_theme_constant_override("separation", 10)
			_detail_content.add_child(fact_hbox)

			var bullet := Label.new()
			bullet.text = "â–¸"
			bullet.add_theme_font_override("font", _tech_font)
			bullet.add_theme_font_size_override("font_size", 14)
			bullet.add_theme_color_override("font_color", Color(0.1, 0.9, 0.7, 0.8))
			bullet.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			fact_hbox.add_child(bullet)

			var fact_lbl := Label.new()
			fact_lbl.text = str(fact_entry)
			fact_lbl.add_theme_font_override("font", _tech_font)
			fact_lbl.add_theme_font_size_override("font_size", 15)
			fact_lbl.add_theme_color_override("font_color", Color(0.78, 0.92, 0.86))
			fact_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			fact_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fact_hbox.add_child(fact_lbl)

	# â”€â”€ 6. Field Guide Tip â”€â”€
	var tip: String = data.get("guide_tip", "")
	if tip != "":
		_detail_content.add_child(_make_thin_sep())
		var tip_container := PanelContainer.new()
		var tip_style := StyleBoxFlat.new()
		tip_style.bg_color = Color(0.03, 0.15, 0.12, 0.8)
		tip_style.border_color = Color(0.1, 0.9, 0.7, 0.5)
		tip_style.border_width_left = 3
		tip_style.border_width_right = 0
		tip_style.border_width_top = 0
		tip_style.border_width_bottom = 0
		tip_style.content_margin_left   = 14
		tip_style.content_margin_right  = 14
		tip_style.content_margin_top    = 10
		tip_style.content_margin_bottom = 10
		tip_container.add_theme_stylebox_override("panel", tip_style)
		_detail_content.add_child(tip_container)
		var tip_rtl := _make_rtl(tip, 15)
		tip_container.add_child(tip_rtl)

# â”€â”€ Filter Logic â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func _on_filter_pressed(cat: String) -> void:
	_current_filter = cat
	_set_filter_active(cat)
	_populate_list()
	# Clear detail view
	for child in _detail_content.get_children():
		if child != _empty_label:
			child.queue_free()
	_empty_label.visible = true

func _set_filter_active(active_cat: String) -> void:
	for cat in _filter_btns:
		_style_filter_btn(_filter_btns[cat], cat, cat == active_cat)

# â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func _make_section_header(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_override("font", _tech_font)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.1, 0.9, 0.7, 0.75))
	return lbl

func _make_rtl(txt: String, font_size: int) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.text = txt
	rtl.fit_content = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.scroll_active = false
	rtl.add_theme_font_override("normal_font", _tech_font)
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_color_override("default_color", Color(0.8, 0.92, 0.88))
	return rtl

func _make_badge(txt: String, col: Color, font_size: int) -> PanelContainer:
	var pc := PanelContainer.new()
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(col.r, col.g, col.b, 0.12)
	sty.border_color = Color(col.r, col.g, col.b, 0.7)
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(3)
	sty.content_margin_left   = 10
	sty.content_margin_right  = 10
	sty.content_margin_top    = 4
	sty.content_margin_bottom = 4
	pc.add_theme_stylebox_override("panel", sty)

	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_override("font", _tech_font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", col)
	pc.add_child(lbl)
	return pc

func _make_thin_sep() -> HSeparator:
	var sep := HSeparator.new()
	var sty := StyleBoxLine.new()
	sty.color = Color(0.1, 0.9, 0.7, 0.15)
	sty.thickness = 1
	sep.add_theme_stylebox_override("separator", sty)
	return sep

func _make_button(txt: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.add_theme_font_override("font", _tech_font)
	btn.add_theme_font_size_override("font_size", 15)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.10, 0.15, 0.85)
	normal.border_color = Color(0.1, 0.9, 0.7, 0.5)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_color_override("font_color", Color(0.7, 0.9, 0.85))

	var hover := normal.duplicate()
	hover.bg_color = Color(0.08, 0.28, 0.22, 0.95)
	hover.border_color = Color(0.1, 0.9, 0.7, 1.0)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_hover_color", Color(0.1, 1.0, 0.75))

	btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	btn.pressed.connect(callback)
	return btn

# â”€â”€ Close â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func _on_close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
