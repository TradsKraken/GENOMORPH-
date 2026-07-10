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
	bg_rect.color = Color(0, 0, 0, 0.75)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(750, 550)
	
	# Center it properly
	_panel.offset_left = -375
	_panel.offset_right = 375
	_panel.offset_top = -275
	_panel.offset_bottom = 275
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.12, 0.95)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 40
	sb.content_margin_bottom = 40
	_panel.add_theme_stylebox_override("panel", sb)
	
	var _scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(_scroll)
	
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 24)
	_scroll.add_child(_vbox)
	
	# Title
	_title = Label.new()
	_title.text = "Play Game"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 48)
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
	_title.text = "Play Game"
	
	# Buttons
	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.add_theme_font_size_override("font_size", 36)
	new_game_btn.custom_minimum_size = Vector2(0, 80)
	new_game_btn.pressed.connect(func():
		_show_slot_selection(false)
	)
	_vbox.add_child(new_game_btn)
	
	var load_game_btn := Button.new()
	load_game_btn.text = "Load Game"
	load_game_btn.add_theme_font_size_override("font_size", 36)
	load_game_btn.custom_minimum_size = Vector2(0, 80)
	
	# Check if ANY slot exists
	var any_save = false
	for i in range(1, 5):
		if PlayerData.has_save_file(i):
			any_save = true
			break
			
	if not any_save:
		load_game_btn.disabled = true
		load_game_btn.text = "Load Game (No saves found)"
	load_game_btn.pressed.connect(func():
		_show_slot_selection(true)
	)
	_vbox.add_child(load_game_btn)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_child(spacer)
	
	var close_btn := Button.new()
	close_btn.text = "Cancel"
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.custom_minimum_size = Vector2(0, 80)
	close_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	_vbox.add_child(close_btn)

func _show_slot_selection(is_loading: bool) -> void:
	_clear_vbox_items()
	_title.text = "Load Game" if is_loading else "New Game"
	
	for i in range(1, 5):
		var preview = PlayerData.get_save_preview(i)
		var slot_card = _create_save_slot(i, preview, is_loading)
		_vbox.add_child(slot_card)
		
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_vbox.add_child(spacer)
	
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.add_theme_font_size_override("font_size", 36)
	back_btn.custom_minimum_size = Vector2(0, 80)
	back_btn.pressed.connect(_show_main_actions)
	_vbox.add_child(back_btn)

func _create_save_slot(slot_idx: int, preview: Dictionary, is_loading: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 110)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var is_empty = preview.is_empty()
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	btn.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var header_hbox := HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_hbox)
	
	var file_lbl := Label.new()
	file_lbl.text = "Slot " + str(slot_idx)
	file_lbl.add_theme_font_size_override("font_size", 24)
	header_hbox.add_child(file_lbl)
	
	var date_lbl := Label.new()
	date_lbl.text = preview.get("timestamp", "") if not is_empty else ""
	date_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_lbl.add_theme_font_size_override("font_size", 20)
	date_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header_hbox.add_child(date_lbl)
	
	if is_empty:
		var empty_lbl := Label.new()
		empty_lbl.text = "Empty"
		empty_lbl.add_theme_font_size_override("font_size", 24)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(empty_lbl)
		
		if is_loading:
			btn.disabled = true
	else:
		var body_hbox := HBoxContainer.new()
		body_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(body_hbox)
		
		var form_lbl := Label.new()
		form_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		form_lbl.text = preview.get("active_form", "Unknown Form") + " - " + preview.get("biome_name", "Unknown Region")
		form_lbl.add_theme_font_size_override("font_size", 20)
		form_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		body_hbox.add_child(form_lbl)
		
		var level_lbl := Label.new()
		level_lbl.text = "Level " + str(preview.get("level", 1))
		level_lbl.add_theme_font_size_override("font_size", 20)
		body_hbox.add_child(level_lbl)
		
	btn.pressed.connect(func():
		if is_loading:
			load_game.emit(slot_idx)
		else:
			new_game.emit(slot_idx)
		queue_free()
	)
	return btn
