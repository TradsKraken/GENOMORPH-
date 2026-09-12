extends CanvasLayer

class_name CharacterMenu

signal closed

var _panel: Control
var _tab_container: TabContainer
var tech_font: SystemFont

func _ready() -> void:
	layer = 100 # Ensure it's above other UI
	process_mode = PROCESS_MODE_ALWAYS
	
	tech_font = SystemFont.new()
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
	b_script.source_code = "extends Control\nfunc _draw():\n\tvar c = Color(0.9, 0.7, 0.1, 0.9)\n\tvar r = get_rect().size\n\tvar l = 24.0\n\tvar t = 2.0\n\tdraw_rect(Rect2(0,0,l,t), c); draw_rect(Rect2(0,0,t,l), c)\n\tdraw_rect(Rect2(r.x-l,0,l,t), c); draw_rect(Rect2(r.x-t,0,t,l), c)\n\tdraw_rect(Rect2(0,r.y-t,l,t), c); draw_rect(Rect2(0,r.y-l,t,l), c)\n\tdraw_rect(Rect2(r.x-l,r.y-t,l,t), c); draw_rect(Rect2(r.x-t,r.y-l,t,l), c)\n\tvar c2 = Color(0.9, 0.7, 0.1, 0.4)\n\tfor p in [Vector2(40,40), Vector2(r.x-40,40), Vector2(40,r.y-40), Vector2(r.x-40,r.y-40)]:\n\t\tdraw_line(p-Vector2(8,0), p+Vector2(8,0), c2, 1)\n\t\tdraw_line(p-Vector2(0,8), p+Vector2(0,8), c2, 1)"
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
	
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(main_vbox)
	
	# Header
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var title := Label.new()
	title.text = "CHARACTER TELEMETRY"
	title.add_theme_font_override("font", tech_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.add_theme_font_override("font", tech_font)
	close_btn.custom_minimum_size = Vector2(100, 40)
	
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.05, 0.1, 0.15, 0.8)
	btn_normal.border_color = Color(0.9, 0.7, 0.1, 0.5)
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(0)
	close_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color(0.3, 0.2, 0.1, 0.9)
	btn_hover.border_color = Color(0.9, 0.8, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("hover", btn_hover)
	
	close_btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	close_btn.pressed.connect(_on_close)
	header_hbox.add_child(close_btn)
	
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.9, 0.7, 0.1, 0.3)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	main_vbox.add_child(sep)
	
	# TabContainer
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_font_override("font", tech_font)
	_tab_container.add_theme_font_size_override("font_size", 18)
	
	var tab_bg := StyleBoxFlat.new()
	tab_bg.bg_color = Color(0.02, 0.04, 0.06, 0.6)
	tab_bg.border_color = Color(0.9, 0.7, 0.1, 0.2)
	tab_bg.set_border_width_all(1)
	_tab_container.add_theme_stylebox_override("panel", tab_bg)
	_tab_container.add_theme_stylebox_override("tab_selected", btn_hover)
	_tab_container.add_theme_stylebox_override("tab_unselected", btn_normal)
	
	main_vbox.add_child(_tab_container)
	
	_build_stats_tab()
	_build_skills_tab()
	_build_inventory_tab()
	
	_update_skills_tab_title(PlayerData.skill_points)
	if PlayerData.has_signal("skill_points_changed"):
		PlayerData.skill_points_changed.connect(_update_skills_tab_title)
		
	if PlayerData.skill_points > 0:
		_tab_container.current_tab = 1
	
	add_child(_panel)

func _update_skills_tab_title(points: int) -> void:
	if is_instance_valid(_tab_container) and _tab_container.get_tab_count() > 1:
		if points > 0:
			_tab_container.set_tab_title(1, "SKILLS (!)")
		else:
			_tab_container.set_tab_title(1, "SKILLS")


func _build_stats_tab() -> void:
	var stats_tab = MarginContainer.new()
	stats_tab.name = "STATS"
	stats_tab.add_theme_constant_override("margin_left", 24)
	stats_tab.add_theme_constant_override("margin_right", 24)
	stats_tab.add_theme_constant_override("margin_top", 24)
	stats_tab.add_theme_constant_override("margin_bottom", 24)
	_tab_container.add_child(stats_tab)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 64)
	grid.add_theme_constant_override("v_separation", 16)
	stats_tab.add_child(grid)
	
	var add_stat = func(label: String, value: String, color: Color):
		var lbl_name = Label.new()
		lbl_name.text = label
		lbl_name.add_theme_font_override("font", tech_font)
		lbl_name.add_theme_font_size_override("font_size", 24)
		lbl_name.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		grid.add_child(lbl_name)
		
		var lbl_val = Label.new()
		lbl_val.text = value
		lbl_val.add_theme_font_override("font", tech_font)
		lbl_val.add_theme_font_size_override("font_size", 24)
		lbl_val.add_theme_color_override("font_color", color)
		grid.add_child(lbl_val)
	
	add_stat.call("Level", str(PlayerData.level), Color(0.9, 0.8, 0.3))
	add_stat.call("Experience", "%d / %d" % [int(PlayerData.experience), int(PlayerData.exp_to_next)], Color(1.0, 0.8, 0.1))
	add_stat.call("Max Health", str(PlayerData.max_health), Color(1.0, 0.3, 0.4))
	add_stat.call("Max Stamina", str(PlayerData.max_stamina), Color(0.6, 0.3, 1.0))
	add_stat.call("Attack Power", str(PlayerData.attack_power), Color(0.9, 0.5, 0.2))
	add_stat.call("Defense", str(PlayerData.defense), Color(0.3, 0.8, 0.9))
	add_stat.call("Speed", str(PlayerData.speed), Color(0.4, 0.9, 0.3))


func _build_skills_tab() -> void:
	var skills_tab = MarginContainer.new()
	skills_tab.name = "SKILLS"
	skills_tab.add_theme_constant_override("margin_left", 24)
	skills_tab.add_theme_constant_override("margin_right", 24)
	skills_tab.add_theme_constant_override("margin_top", 24)
	skills_tab.add_theme_constant_override("margin_bottom", 24)
	_tab_container.add_child(skills_tab)
	
	_populate_skills_tab(skills_tab)

func _populate_skills_tab(skills_tab: MarginContainer) -> void:
	for child in skills_tab.get_children():
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skills_tab.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)
	var profile := PlayerData.get_current_species_data()
	var header := Label.new()
	header.text = "%s ADAPTATION PROFILE  •  %d AP  •  %d GENOME" % [PlayerData.active_species.to_upper(), PlayerData.skill_points, int(profile.get("genomes_available", 0))]
	header.add_theme_font_override("font", tech_font)
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(header)
	var section := Label.new()
	section.text = "BIOLOGICAL ATTRIBUTES"
	section.add_theme_font_override("font", tech_font)
	section.add_theme_font_size_override("font_size", 16)
	section.add_theme_color_override("font_color", Color(0.45, 0.9, 0.72))
	vbox.add_child(section)
	for attribute_id in PlayerData.ATTRIBUTE_DEFINITIONS:
		var definition: Dictionary = PlayerData.ATTRIBUTE_DEFINITIONS[attribute_id]
		var count := PlayerData.get_attribute_upgrade_count(attribute_id)
		var cost := PlayerData.get_attribute_upgrade_cost(attribute_id)
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_override("font", tech_font)
		label.text = "%s  Lv%d  —  %s" % [definition["name"], count, definition["description"]]
		row.add_child(label)
		var button := Button.new()
		button.text = "+  (%d AP)" % cost
		button.disabled = PlayerData.skill_points < cost
		button.pressed.connect(func():
			if PlayerData.upgrade_attribute(attribute_id):
				AudioManager.play_sfx("level_up")
				_populate_skills_tab(skills_tab)
		)
		row.add_child(button)
		vbox.add_child(row)
	var ultimate_header := Label.new()
	ultimate_header.text = "ULTIMATE ADAPTATION  •  Spend 1 Genome to develop or equip a path"
	ultimate_header.add_theme_font_override("font", tech_font)
	ultimate_header.add_theme_font_size_override("font_size", 16)
	ultimate_header.add_theme_color_override("font_color", Color(0.45, 0.9, 0.72))
	vbox.add_child(ultimate_header)
	for category in ["attack", "defense", "agility"]:
		var ultimate: Dictionary = PlayerData.ULTIMATE_DEFINITIONS.get(PlayerData.active_species, {}).get(category, {})
		var level := int(profile.get(category + "_ultimate_level", 0))
		var equipped: bool = str(profile.get("equipped_ultimate_category", "")) == category
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_override("font", tech_font)
		label.text = "%s%s  Lv%d — %s" % [category.to_upper() + ": ", str(ultimate.get("name", "Unknown")), level, "EQUIPPED" if equipped else str(ultimate.get("description", ""))]
		row.add_child(label)
		var button := Button.new()
		button.text = "MAX" if level >= 3 else "DEVELOP"
		button.disabled = level >= 3 or int(profile.get("genomes_available", 0)) < 1
		button.pressed.connect(func():
			if PlayerData.develop_ultimate(category):
				AudioManager.play_sfx("level_up")
				_populate_skills_tab(skills_tab)
		)
		row.add_child(button)
		vbox.add_child(row)


func _build_inventory_tab() -> void:
	var inv_tab = MarginContainer.new()
	inv_tab.name = "INVENTORY"
	inv_tab.add_theme_constant_override("margin_left", 24)
	inv_tab.add_theme_constant_override("margin_right", 24)
	inv_tab.add_theme_constant_override("margin_top", 24)
	inv_tab.add_theme_constant_override("margin_bottom", 24)
	_tab_container.add_child(inv_tab)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	inv_tab.add_child(vbox)
	
	var list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_override("font", tech_font)
	list.add_theme_font_size_override("font_size", 20)
	
	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.02, 0.04, 0.06, 0.6)
	list_bg.border_color = Color(0.1, 0.9, 0.7, 0.2)
	list_bg.set_border_width_all(1)
	list.add_theme_stylebox_override("panel", list_bg)
	list.add_theme_constant_override("v_separation", 8)
	
	# Add Genome Fragments
	if PlayerData.genome_fragments > 0:
		list.add_item("Genome Fragments (x%d)" % PlayerData.genome_fragments)
	
	for item in PlayerData.inventory:
		list.add_item(str(item))
		
	if list.item_count == 0:
		list.add_item("-- Empty --")
		list.set_item_disabled(0, true)
		
	vbox.add_child(list)


func _on_close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
