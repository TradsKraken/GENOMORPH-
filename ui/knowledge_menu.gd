extends CanvasLayer

class_name KnowledgeMenu

signal closed

var _panel: PanelContainer
var _item_list: ItemList
var _details_title: Label
var _details_category: Label
var _details_desc: RichTextLabel
var _empty_label: Label

var _unlocked_keys: Array[String] = []

func _ready() -> void:
	layer = 100 # Ensure it's above other UI
	process_mode = PROCESS_MODE_ALWAYS
	
	# Full screen background
	var bg_rect := ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 0.75)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(800, 500)
	
	# Center it properly
	_panel.offset_left = -400
	_panel.offset_right = 400
	_panel.offset_top = -250
	_panel.offset_bottom = 250
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	sb.border_color = Color(0.8, 0.7, 0.3, 0.8) # A nice gold/bronze border for knowledge
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.8)
	sb.shadow_size = 24
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", sb)
	
	# Main VBox
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(main_vbox)
	
	# Header
	var header_hbox := HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var title := Label.new()
	title.text = "📖 KNOWLEDGE BASE"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 40)
	
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	btn_normal.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color(0.3, 0.3, 0.35, 0.9)
	close_btn.add_theme_stylebox_override("hover", btn_hover)
	
	close_btn.pressed.connect(_on_close)
	header_hbox.add_child(close_btn)
	
	var sep := HSeparator.new()
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
	_item_list.add_theme_font_size_override("font_size", 20)
	
	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	list_bg.set_corner_radius_all(8)
	_item_list.add_theme_stylebox_override("panel", list_bg)
	_item_list.add_theme_constant_override("v_separation", 8)
	
	_item_list.item_selected.connect(_on_item_selected)
	split_hbox.add_child(_item_list)
	
	var vsep := VSeparator.new()
	split_hbox.add_child(vsep)
	
	# Right: Details view
	var details_vbox := VBoxContainer.new()
	details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_vbox.add_theme_constant_override("separation", 12)
	split_hbox.add_child(details_vbox)
	
	_empty_label = Label.new()
	_empty_label.text = "Select an entry to read more."
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	details_vbox.add_child(_empty_label)
	
	_details_title = Label.new()
	_details_title.add_theme_font_size_override("font_size", 32)
	_details_title.add_theme_color_override("font_color", Color.WHITE)
	_details_title.visible = false
	details_vbox.add_child(_details_title)
	
	_details_category = Label.new()
	_details_category.add_theme_font_size_override("font_size", 18)
	_details_category.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_details_category.visible = false
	details_vbox.add_child(_details_category)
	
	_details_desc = RichTextLabel.new()
	_details_desc.bbcode_enabled = true
	_details_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_desc.add_theme_font_size_override("normal_font_size", 22)
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
		_item_list.add_item("No Knowledge Found")
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
