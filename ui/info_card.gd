extends CanvasLayer
class_name InfoCard

signal closed

@onready var panel = $Panel
@onready var icon_label: Label = $Panel/VBoxContainer/HeaderHBox/IconLabel
@onready var title_label: Label = $Panel/VBoxContainer/HeaderHBox/TitleLabel
@onready var summary_label: RichTextLabel = $Panel/VBoxContainer/SummaryLabel
@onready var category_label: Label = $Panel/VBoxContainer/CategoryLabel

@onready var expand_container: VBoxContainer = $Panel/VBoxContainer/ExpandContainer
@onready var facts_label: RichTextLabel = $Panel/VBoxContainer/ExpandContainer/FactsLabel

@onready var learn_more_btn: Button = $Panel/VBoxContainer/HBoxButtons/LearnMoreBtn
@onready var close_btn: Button = $Panel/VBoxContainer/HBoxButtons/CloseBtn

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	# Lets the HUD wait for this card's close animation before opening a tutorial.
	add_to_group("knowledge_popup")
	# No longer pausing the game to keep world live
	
	if learn_more_btn:
		learn_more_btn.pressed.connect(_on_learn_more)
	if close_btn:
		close_btn.pressed.connect(_on_close)
		
	if panel:
		panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#12201C")
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color("#8FD9B8")
		style.border_blend = true
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.content_margin_left = 20
		style.content_margin_top = 20
		style.content_margin_right = 20
		style.content_margin_bottom = 20
		panel.add_theme_stylebox_override("panel", style)
		
		if icon_label: icon_label.add_theme_color_override("font_color", Color("#8FD9B8"))
		if title_label: title_label.add_theme_color_override("font_color", Color("#8FD9B8"))
		if summary_label: summary_label.add_theme_color_override("default_color", Color("#8FD9B8"))
		if category_label: category_label.add_theme_color_override("font_color", Color("#8FD9B8"))
		if facts_label: facts_label.add_theme_color_override("default_color", Color("#8FD9B8"))
		
		panel.scale = Vector2(0.8, 0.8)
		panel.modulate.a = 0.0
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(panel, "modulate:a", 1.0, 0.2)

func set_info(knowledge_id: String, db_entry: Dictionary) -> void:
	if not is_inside_tree():
		await ready
		
	icon_label.text = db_entry.get("icon", "🔹")
	# Title in sentence case, not all-caps
	title_label.text = db_entry.get("title", "Unknown Discovery")
	summary_label.text = db_entry.get("summary", "")
	
	var cat = db_entry.get("category", "")
	var subcat = db_entry.get("subcategory", "")
	if subcat != "":
		category_label.text = cat.to_upper() + "\n" + subcat
	else:
		category_label.text = cat.to_upper()
		
	var facts = db_entry.get("facts", [])
	if facts.size() > 0:
		var facts_text = ""
		for fact in facts:
			facts_text += "• " + fact + "\n"
		facts_label.text = facts_text.strip_edges()
	else:
		learn_more_btn.hide()

func _on_learn_more() -> void:
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("tap_button")
	
	learn_more_btn.hide()
	expand_container.show()
	
	if panel:
		var tw = create_tween()
		var start_y = panel.size.y
		panel.custom_minimum_size.y = start_y
		tw.tween_property(panel, "custom_minimum_size:y", start_y + 200, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_close() -> void:
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("tap_button")
	
	if panel:
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tw.tween_property(panel, "modulate:a", 0.0, 0.15)
		await tw.finished
		
	closed.emit()
	queue_free()
