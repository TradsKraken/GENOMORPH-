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
	
	add_child(_panel)


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
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	skills_tab.add_child(vbox)
	
	var sp_lbl = Label.new()
	sp_lbl.text = "Available Skill Points: " + str(PlayerData.skill_points)
	sp_lbl.add_theme_font_override("font", tech_font)
	sp_lbl.add_theme_font_size_override("font_size", 24)
	sp_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(sp_lbl)
	
	var create_upgrade = func(title: String, desc: String, action: Callable):
		var hbox = HBoxContainer.new()
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var t_lbl = Label.new()
		t_lbl.text = title
		t_lbl.add_theme_font_override("font", tech_font)
		t_lbl.add_theme_font_size_override("font_size", 22)
		t_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		info_vbox.add_child(t_lbl)
		
		var d_lbl = Label.new()
		d_lbl.text = desc
		d_lbl.add_theme_font_override("font", tech_font)
		d_lbl.add_theme_font_size_override("font_size", 16)
		d_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		info_vbox.add_child(d_lbl)
		
		hbox.add_child(info_vbox)
		
		var btn = Button.new()
		btn.text = "UPGRADE (1 SP)"
		btn.add_theme_font_override("font", tech_font)
		btn.custom_minimum_size = Vector2(140, 40)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.1, 0.2, 0.15, 0.8)
		normal.border_color = Color(0.3, 0.8, 0.4, 0.5)
		normal.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", normal)
		
		var hover = normal.duplicate()
		hover.bg_color = Color(0.2, 0.4, 0.25, 0.9)
		hover.border_color = Color(0.4, 1.0, 0.5, 1.0)
		btn.add_theme_stylebox_override("hover", hover)
		
		if PlayerData.skill_points <= 0:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
			
		btn.pressed.connect(func():
			if PlayerData.skill_points > 0:
				PlayerData.skill_points -= 1
				action.call()
				# Rebuild or update
				sp_lbl.text = "Available Skill Points: " + str(PlayerData.skill_points)
				if PlayerData.skill_points <= 0:
					for child in vbox.get_children():
						if child is HBoxContainer:
							var b = child.get_child(1) as Button
							if b: b.disabled = true; b.modulate = Color(0.5, 0.5, 0.5, 0.5)
		)
		hbox.add_child(btn)
		
		vbox.add_child(hbox)
		
	create_upgrade.call("Vitality Synthesis", "Increase Max Health by 20.", func():
		PlayerData.max_health += 20.0
		PlayerData.health += 20.0
		PlayerData.health_changed.emit(PlayerData.health, PlayerData.max_health)
	)
	create_upgrade.call("Endurance Weave", "Increase Max Stamina by 20.", func():
		PlayerData.max_stamina += 20.0
		PlayerData.stamina += 20.0
		PlayerData.stamina_changed.emit(PlayerData.stamina, PlayerData.max_stamina)
	)
	create_upgrade.call("Muscle Density", "Increase Attack Power by 5.", func():
		PlayerData.attack_power += 5.0
	)


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
