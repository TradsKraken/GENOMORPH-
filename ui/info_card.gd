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
	get_tree().paused = true
	
	if learn_more_btn:
		learn_more_btn.pressed.connect(_on_learn_more)
	if close_btn:
		close_btn.pressed.connect(_on_close)
		
	if panel:
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
	title_label.text = db_entry.get("title", "UNKNOWN DISCOVERY").to_upper()
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
		
	get_tree().paused = false
	closed.emit()
	queue_free()
