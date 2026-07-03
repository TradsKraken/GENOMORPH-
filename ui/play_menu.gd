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
	_panel.custom_minimum_size = Vector2(400, 250)
	
	# Center it properly
	_panel.offset_left = -200
	_panel.offset_right = 200
	_panel.offset_top = -125
	_panel.offset_bottom = 125
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.border_color = Color(0.3, 0.5, 0.8, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 16
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", sb)
	
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(_vbox)
	
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
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(0, 50)
		var preview = PlayerData.get_save_preview(i)
		
		if preview.is_empty():
			slot_btn.text = "Slot " + str(i) + " - Empty"
			if is_loading:
				slot_btn.disabled = true
		else:
			slot_btn.text = "Slot " + str(i) + " - Level " + str(preview.get("level", 1))
			
		slot_btn.pressed.connect(func():
			if is_loading:
				load_game.emit(i)
			else:
				new_game.emit(i)
			queue_free()
		)
		_vbox.add_child(slot_btn)
		
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_child(spacer)
	
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 40)
	back_btn.pressed.connect(_show_main_actions)
	_vbox.add_child(back_btn)
