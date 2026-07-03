extends CanvasLayer

signal new_game(slot: int)
signal load_game(slot: int)
signal closed

var _panel: PanelContainer
var _vbox: VBoxContainer
var _title: Label

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
	_panel.custom_minimum_size = Vector2(700, 500)
	
	# Center it properly
	_panel.offset_left = -350
	_panel.offset_right = 350
	_panel.offset_top = -250
	_panel.offset_bottom = 250
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.95)
	sb.border_color = Color(0.15, 0.85, 0.65, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 24
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", sb)
	
	var _scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(_scroll)
	
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 16)
	_scroll.add_child(_vbox)
	
	# Title
	_title = Label.new()
	_title.text = "PLAY GAME"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_vbox.add_child(_title)
	
	var sep := HSeparator.new()
	_vbox.add_child(sep)
	
	_show_main_actions()
	add_child(_panel)

func _clear_vbox_items() -> void:
	for child in _vbox.get_children():
		if child != _title and not child is HSeparator:
			child.queue_free()

func _show_main_actions() -> void:
	_clear_vbox_items()
	_title.text = "PLAY GAME"
	
	# Buttons
	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.custom_minimum_size = Vector2(0, 50)
	new_game_btn.pressed.connect(func():
		_show_slot_selection(false)
	)
	_vbox.add_child(new_game_btn)
	
	var load_game_btn := Button.new()
	load_game_btn.text = "Load Game"
	load_game_btn.custom_minimum_size = Vector2(0, 50)
	
	# Check if ANY slot exists
	var any_save = false
	for i in range(1, 5):
		if PlayerData.has_save_file(i):
			any_save = true
			break
			
	if not any_save:
		load_game_btn.disabled = true
		load_game_btn.text = "Load Game (No saves)"
	load_game_btn.pressed.connect(func():
		_show_slot_selection(true)
	)
	_vbox.add_child(load_game_btn)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_child(spacer)
	
	var close_btn := Button.new()
	close_btn.text = "Cancel"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	_vbox.add_child(close_btn)

func _show_slot_selection(is_loading: bool) -> void:
	_clear_vbox_items()
	_title.text = "LOAD SLOT" if is_loading else "NEW GAME (OVERWRITE)"
	
	for i in range(1, 5):
		var preview = PlayerData.get_save_preview(i)
		var slot_card = _create_save_slot(i, preview, is_loading)
		_vbox.add_child(slot_card)
		
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_vbox.add_child(spacer)
	
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 50)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.12, 0.16, 0.8)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.18, 0.24, 0.9)
	
	back_btn.add_theme_stylebox_override("normal", normal)
	back_btn.add_theme_stylebox_override("hover", hover)
	back_btn.add_theme_stylebox_override("pressed", hover)
	back_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	back_btn.pressed.connect(_show_main_actions)
	_vbox.add_child(back_btn)

func _create_save_slot(slot_idx: int, preview: Dictionary, is_loading: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 110)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var is_empty = preview.is_empty()
	
	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.08, 0.1, 0.14, 0.8)
	normal_sb.border_color = Color(0.2, 0.4, 0.6, 0.3)
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(8)
	normal_sb.content_margin_left = 16
	normal_sb.content_margin_right = 16
	normal_sb.content_margin_top = 12
	normal_sb.content_margin_bottom = 12
	
	var hover_sb := normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = Color(0.1, 0.25, 0.2, 0.85)
	hover_sb.border_color = Color(0.2, 0.9, 0.6, 0.8)
	hover_sb.set_border_width_all(2)
	
	var disabled_sb := normal_sb.duplicate() as StyleBoxFlat
	disabled_sb.bg_color = Color(0.05, 0.05, 0.06, 0.6)
	disabled_sb.border_color = Color(0.1, 0.1, 0.1, 0.2)
	
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var tech_font := SystemFont.new()
	tech_font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "monospace"])
	
	var outer_hbox := HBoxContainer.new()
	outer_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(outer_hbox)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_hbox.add_child(left_vbox)
	
	var header_hbox := HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(header_hbox)
	
	var file_lbl := Label.new()
	file_lbl.text = "Volunteer Record 0" + str(slot_idx)
	file_lbl.add_theme_font_override("font", tech_font)
	file_lbl.add_theme_font_size_override("font_size", 20)
	file_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0) if not is_empty else Color(0.4, 0.4, 0.4))
	header_hbox.add_child(file_lbl)
	
	var date_lbl := Label.new()
	date_lbl.text = preview.get("timestamp", "--/--/---- --:--") if not is_empty else ""
	date_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_lbl.add_theme_font_override("font", tech_font)
	date_lbl.add_theme_font_size_override("font_size", 14)
	date_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	header_hbox.add_child(date_lbl)
	
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.2, 0.4, 0.6, 0.3)
	sep.add_theme_stylebox_override("separator", sep_style)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.add_child(sep)
	
	if is_empty:
		var empty_lbl := Label.new()
		empty_lbl.text = "NO DATA ASSIMILATED"
		empty_lbl.add_theme_font_override("font", tech_font)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		left_vbox.add_child(empty_lbl)
		
		if is_loading:
			btn.disabled = true
	else:
		var body_hbox := HBoxContainer.new()
		body_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_vbox.add_child(body_hbox)
		
		var icon_lbl := Label.new()
		icon_lbl.text = "🐸" # Sleek vector text icon
		icon_lbl.add_theme_font_size_override("font_size", 36)
		body_hbox.add_child(icon_lbl)
		
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vbox.add_theme_constant_override("separation", -2)
		body_hbox.add_child(info_vbox)
		
		var form_lbl := Label.new()
		form_lbl.text = " " + preview.get("active_form", "Unknown Form")
		form_lbl.add_theme_font_override("font", tech_font)
		form_lbl.add_theme_font_size_override("font_size", 16)
		form_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		info_vbox.add_child(form_lbl)
		
		var biome_lbl := Label.new()
		biome_lbl.text = " " + preview.get("biome_name", "Unknown Region")
		biome_lbl.add_theme_font_override("font", tech_font)
		biome_lbl.add_theme_font_size_override("font_size", 14)
		biome_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6))
		info_vbox.add_child(biome_lbl)
		
		var right_vbox := VBoxContainer.new()
		right_vbox.custom_minimum_size = Vector2(140, 0)
		right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		right_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body_hbox.add_child(right_vbox)
		
		var level_lbl := Label.new()
		level_lbl.text = "Bio-Data Level: " + str(preview.get("level", 1))
		level_lbl.add_theme_font_override("font", tech_font)
		level_lbl.add_theme_font_size_override("font_size", 14)
		level_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
		level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_vbox.add_child(level_lbl)
		
		var genome_lbl := Label.new()
		genome_lbl.text = "Genomes: " + str(preview.get("genome_fragments", 0)) + "/" + str(preview.get("max_genome_fragments", 4))
		genome_lbl.add_theme_font_override("font", tech_font)
		genome_lbl.add_theme_font_size_override("font_size", 14)
		genome_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
		genome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_vbox.add_child(genome_lbl)
		
	btn.pressed.connect(func():
		if is_loading:
			load_game.emit(slot_idx)
		else:
			new_game.emit(slot_idx)
		queue_free()
	)
	return btn
