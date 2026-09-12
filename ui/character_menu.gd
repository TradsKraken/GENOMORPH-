extends CanvasLayer
class_name CharacterMenu

signal closed
const Rules = preload("res://systems/adaptation_rules.gd")

# ── Theme colors ──────────────────────────────────────────────────────────────
const C_BG        := Color("0b1820")
const C_CARD      := Color(0.06, 0.11, 0.15, 0.92)
const C_BORDER    := Color("3aa87a")
const C_ACCENT    := Color("50e8a8")
const C_TEXT      := Color("d6eae0")
const C_DIM       := Color("7a9e94")
const C_HP        := Color("#ff3b5c")
const C_STAM      := Color("#9400ff")
const C_ATK       := Color("#ff8833")
const C_CDR       := Color("#33aaff")
const C_HEAL      := Color("#44ff88")
const C_BTN_BG    := Color(0.14, 0.26, 0.22, 0.85)
const C_BTN_HOVER := Color(0.18, 0.38, 0.30, 0.95)
const C_GOLD      := Color("ffd666")
const C_GENOME    := Color("66ffbb")

const ATTR_COLORS := {
	"health": Color("#ff3b5c"),
	"attack": Color("#ff8833"),
	"stamina": Color("#9400ff"),
	"stamina_recovery": Color("#b366ff"),
	"cooldown": Color("#33aaff"),
	"health_recovery": Color("#44ff88"),
}
const ATTR_ICONS := {
	"health": "♥", "attack": "⚔", "stamina": "⚡",
	"stamina_recovery": "↻", "cooldown": "◎", "health_recovery": "✚",
}
const ULT_ICONS := {"attack": "⚔", "defense": "🛡", "agility": "💨"}

var _panel: PanelContainer
var _backdrop: ColorRect
var _tab_container: TabContainer
var _header: Label
var _summary: RichTextLabel
var _stats: RichTextLabel
var _inventory: RichTextLabel
var _feedback: Label
var _attribute_rows: Dictionary = {}
var _ultimate_rows: Dictionary = {}
var _confirmation: ConfirmationDialog
var _pending_category := ""
var _pending_species := ""
var _was_paused := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	add_to_group("progression_menu")

	# ── Backdrop ──
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.01, 0.02, 0.03, 0.0)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var blur_shader := Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
	uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;
	void fragment() {
		vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);
		COLOR = mix(blurred, COLOR, COLOR.a);
	}
	"""
	var blur_mat := ShaderMaterial.new()
	blur_mat.shader = blur_shader
	blur_mat.set_shader_parameter("blur_amount", 0.0)
	_backdrop.material = blur_mat
	add_child(_backdrop)

	# ── Main panel ──
	var center_container := CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(800, 560)
	var style := StyleBoxFlat.new()
	style.bg_color = C_BG
	style.border_color = C_BORDER
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", style)
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.95, 0.95)
	_panel.pivot_offset = Vector2(400, 280) # Half of 800x560
	center_container.add_child(_panel)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	_panel.add_child(body)

	# ── Header row ──
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	body.add_child(top)
	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 20)
	_header.add_theme_color_override("font_color", C_ACCENT)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_header)
	var close := _styled_button("✕", 44, 36)
	close.name = "CLOSE"
	close.pressed.connect(_on_close)
	top.add_child(close)

	# ── Summary ──
	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.scroll_active = false
	_summary.add_theme_font_size_override("normal_font_size", 14)
	_summary.add_theme_color_override("default_color", C_DIM)
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_summary)

	# ── Separator ──
	var sep := ColorRect.new()
	sep.color = Color(C_BORDER, 0.3)
	sep.custom_minimum_size = Vector2(0, 1)
	body.add_child(sep)

	# ── Tab container ──
	_tab_container = TabContainer.new()
	_tab_container.name = "TabContainer"
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_font_size_override("font_size", 16)
	_tab_container.add_theme_color_override("font_selected_color", C_ACCENT)
	_tab_container.add_theme_color_override("font_unselected_color", C_DIM)
	body.add_child(_tab_container)

	# ── STATS tab ──
	_stats = RichTextLabel.new()
	_stats.bbcode_enabled = true
	_stats.fit_content = true
	_stats.scroll_active = false
	_stats.add_theme_font_size_override("normal_font_size", 16)
	_stats.add_theme_color_override("default_color", C_TEXT)
	_tab("STATS").add_child(_stats)

	# ── ATTRIBUTES tab ──
	var attributes := _tab("ATTR")
	for id in PlayerData.ATTRIBUTE_DEFINITIONS:
		var card := _card_panel()
		attributes.add_child(card)
		var card_body := card.get_child(0) as VBoxContainer
		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 8)
		card_body.add_child(top_row)
		# Icon
		var icon_lbl := Label.new()
		icon_lbl.text = ATTR_ICONS.get(id, "•")
		icon_lbl.add_theme_font_size_override("font_size", 20)
		icon_lbl.add_theme_color_override("font_color", ATTR_COLORS.get(id, C_ACCENT))
		top_row.add_child(icon_lbl)
		# Title
		var title := Label.new()
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", C_TEXT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(title)
		# Button
		var upgrade := _styled_button("", 100, 34)
		upgrade.name = "Upgrade_" + str(id)
		upgrade.pressed.connect(_buy_attribute.bind(str(id)))
		top_row.add_child(upgrade)
		# Progress bar row
		var progress_row := HBoxContainer.new()
		progress_row.add_theme_constant_override("separation", 6)
		card_body.add_child(progress_row)
		var dots_lbl := Label.new()
		dots_lbl.add_theme_font_size_override("font_size", 14)
		dots_lbl.add_theme_color_override("font_color", C_DIM)
		dots_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_row.add_child(dots_lbl)
		_attribute_rows[id] = {"title": title, "detail": dots_lbl, "button": upgrade, "card": card}

	# ── ULTIMATES tab ──
	var ultimates := _tab("ULT")
	for category in ["attack", "defense", "agility"]:
		var card := _card_panel()
		ultimates.add_child(card)
		var card_body := card.get_child(0) as VBoxContainer
		# Header row
		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 8)
		card_body.add_child(top_row)
		var icon_lbl := Label.new()
		icon_lbl.text = ULT_ICONS.get(category, "✦")
		icon_lbl.add_theme_font_size_override("font_size", 20)
		top_row.add_child(icon_lbl)
		var title := Label.new()
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", C_TEXT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(title)
		var develop := _styled_button("", 110, 34)
		develop.name = "Develop_" + category
		develop.pressed.connect(_ask_ultimate.bind(category))
		top_row.add_child(develop)
		# Description
		var detail := Label.new()
		detail.add_theme_font_size_override("font_size", 13)
		detail.add_theme_color_override("font_color", C_DIM)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_body.add_child(detail)
		# Effects
		var effects := Label.new()
		effects.add_theme_font_size_override("font_size", 13)
		effects.add_theme_color_override("font_color", C_GENOME)
		effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_body.add_child(effects)
		_ultimate_rows[category] = {"title": title, "detail": detail, "effects": effects, "button": develop, "icon": icon_lbl, "card": card}

	# ── INVENTORY tab ──
	_inventory = RichTextLabel.new()
	_inventory.bbcode_enabled = true
	_inventory.fit_content = true
	_inventory.scroll_active = false
	_inventory.add_theme_font_size_override("normal_font_size", 16)
	_inventory.add_theme_color_override("default_color", C_TEXT)
	_tab("ITEMS").add_child(_inventory)

	# ── Feedback ──
	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 14)
	_feedback.add_theme_color_override("font_color", C_DIM)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_feedback)

	# ── Confirmation dialog ──
	_confirmation = ConfirmationDialog.new()
	_confirmation.title = "Develop Ultimate"
	_confirmation.ok_button_text = "Spend 1 Genome"
	_confirmation.confirmed.connect(_confirm_ultimate)
	add_child(_confirmation)

	PlayerData.progression_changed.connect(_refresh)
	PlayerData.active_species_changed.connect(_refresh)
	PlayerData.skill_points_changed.connect(_on_points_changed)
	_refresh()
	if PlayerData.skill_points > 0:
		_tab_container.current_tab = 1

	# ── Open animation ──
	_animate_open()


# ── UI Builders ───────────────────────────────────────────────────────────────

func _styled_button(text: String, w: float, h: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(w, h)
	btn.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = C_BTN_BG
	normal.set_corner_radius_all(8)
	normal.border_color = Color(C_BORDER, 0.4)
	normal.set_border_width_all(1)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = C_BTN_HOVER
	hover.border_color = C_ACCENT
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.08, 0.10, 0.12, 0.6)
	disabled.border_color = Color(0.2, 0.25, 0.3, 0.3)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.5, 0.5))
	return btn

func _card_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_CARD
	s.set_corner_radius_all(10)
	s.border_color = Color(C_BORDER, 0.2)
	s.set_border_width_all(1)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", s)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	return panel

func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_container.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	return box

func _genome_dots(count: int) -> String:
	var progress := count % 5
	var filled := ""
	var empty := ""
	for i in range(progress):
		filled += "●"
	for i in range(5 - progress):
		empty += "○"
	return filled + empty


# ── Animations ────────────────────────────────────────────────────────────────

func _animate_open() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_backdrop, "color:a", 0.65, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_backdrop.material, "shader_parameter/blur_amount", 2.2, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Stagger attribute cards
	var delay := 0.15
	for id in _attribute_rows:
		var card: PanelContainer = _attribute_rows[id]["card"]
		card.modulate.a = 0.0
		card.position.y += 12
		var ctw := create_tween().set_parallel(true)
		ctw.tween_property(card, "modulate:a", 1.0, 0.2).set_delay(delay).set_trans(Tween.TRANS_SINE)
		ctw.tween_property(card, "position:y", card.position.y - 12, 0.25).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		delay += 0.04
	for cat in _ultimate_rows:
		var card: PanelContainer = _ultimate_rows[cat]["card"]
		card.modulate.a = 0.0
		card.position.y += 12
		var ctw := create_tween().set_parallel(true)
		ctw.tween_property(card, "modulate:a", 1.0, 0.2).set_delay(delay).set_trans(Tween.TRANS_SINE)
		ctw.tween_property(card, "position:y", card.position.y - 12, 0.25).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		delay += 0.04

func _animate_close() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_backdrop, "color:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_backdrop.material, "shader_parameter/blur_amount", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_panel, "scale", Vector2(0.97, 0.97), 0.15).set_trans(Tween.TRANS_SINE)
	await tw.finished
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()

func _flash_feedback(text: String, color: Color = C_ACCENT) -> void:
	_feedback.text = text
	_feedback.add_theme_color_override("font_color", color)
	_feedback.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_feedback, "modulate:a", 1.0, 0.15)
	tw.tween_property(_feedback, "modulate:a", 0.6, 1.5).set_delay(1.0)


# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh(_species_id: String = "") -> void:
	if not is_instance_valid(_header):
		return
	var data := PlayerData.get_current_species_data()
	var species := PlayerData.active_species
	var species_info: Dictionary = Rules.SPECIES.get(species, {})
	_header.text = str(species_info.get("name", species)).to_upper()
	_summary.text = "[color=#8fe7bd]LV %d[/color]  ·  %d/%d XP  ·  [color=#ffd666]%d AP[/color]  ·  [color=#66ffbb]%d Genomes[/color]" % [PlayerData.level, PlayerData.experience, PlayerData.exp_to_next, PlayerData.skill_points, data.genomes_available]
	_tab_container.set_tab_title(1, "ATTR (!)" if PlayerData.skill_points > 0 else "ATTR")
	_tab_container.set_tab_title(2, "ULT (!)" if int(data.genomes_available) > 0 else "ULT")

	# ── Stats ──
	var role_text := str(species_info.get("role", ""))
	var skills_text := " · ".join(species_info.get("skills", []))
	var stat_parts: PackedStringArray = ["[color=#8fe7bd]%s[/color]\n" % role_text]
	for id in _attribute_rows:
		var def: Dictionary = PlayerData.ATTRIBUTE_DEFINITIONS[id]
		var c: Color = ATTR_COLORS.get(id, C_TEXT)
		stat_parts.append("%s [color=#%s]%s[/color]: %s" % [ATTR_ICONS.get(id, ""), c.to_html(false), def.name, PlayerData.attribute_value(id)])
	stat_parts.append("\n[color=#8fe7bd]Abilities:[/color] %s" % skills_text)
	_stats.text = "\n".join(stat_parts)

	# ── Attributes ──
	for id in _attribute_rows:
		var def: Dictionary = PlayerData.ATTRIBUTE_DEFINITIONS[id]
		var row: Dictionary = _attribute_rows[id]
		var count := PlayerData.get_attribute_upgrade_count(id)
		var cost := PlayerData.get_attribute_upgrade_cost(id)
		row.title.text = "%s  %s → %s" % [def.name, PlayerData.attribute_value(id), PlayerData.attribute_value(id, 1)]
		var dots := _genome_dots(count)
		var dots_colored := dots.replace("●", "[color=#66ffbb]●[/color]") if false else dots
		row.detail.text = "Lv%d  %s" % [count, dots]
		row.detail.add_theme_color_override("font_color", C_GENOME if count % 5 == 0 and count > 0 else C_DIM)
		row.button.text = "+1 · %dAP" % cost
		row.button.disabled = PlayerData.skill_points < cost

	# ── Ultimates ──
	for category in _ultimate_rows:
		var row: Dictionary = _ultimate_rows[category]
		var definition: Dictionary = Rules.ULTIMATES.get(species, {}).get(category, {})
		var rank := int(data.get(category + "_ultimate_level", 0))
		var equipped := str(data.equipped_ultimate_category) == str(category)
		var action := PlayerData.ultimate_purchase_action(category)
		var tag := "  ✦ ACTIVE" if equipped else ""
		row.title.text = "%s Lv%d%s" % [definition.get("name", "Locked"), rank, tag]
		row.title.add_theme_color_override("font_color", C_ACCENT if equipped else C_TEXT)
		row.icon.add_theme_color_override("font_color", C_GOLD if equipped else C_DIM)
		row.detail.text = definition.get("description", "Recover this species first.")
		var effect_lines: PackedStringArray = []
		if rank > 0:
			effect_lines.append("Now: %s" % Rules.effect_summary(species, category, rank))
		if rank < 3:
			effect_lines.append("Next: %s" % Rules.effect_summary(species, category, rank + 1))
		row.effects.text = "\n".join(effect_lines)
		row.button.text = ("%s · 1G" % action) if action != "Max level" else "MAX"
		row.button.disabled = PlayerData.ultimate_active or int(data.genomes_available) < 1 or action in ["Max level", "Unavailable"]
		# Highlight active card border
		var card_style := (row.card as PanelContainer).get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		card_style.border_color = Color(C_GOLD, 0.6) if equipped else Color(C_BORDER, 0.2)
		card_style.set_border_width_all(2 if equipped else 1)
		row.card.add_theme_stylebox_override("panel", card_style)

	# ── Inventory ──
	var inv_parts: PackedStringArray = [
		"[color=#66ffbb]Suit fragments:[/color] %d / %d" % [PlayerData.genome_fragments, PlayerData.max_genome_fragments],
		"[color=#66ffbb]%s Genomes:[/color] %d  (%d earned, %d spent)" % [str(species_info.get("name", species)), data.genomes_available, data.genomes_earned, data.genomes_spent],
	]
	if PlayerData.inventory.size() > 0:
		inv_parts.append("")
		inv_parts.append_array(PlayerData.inventory)
	_inventory.text = "\n".join(inv_parts)

func _on_points_changed(_points: int) -> void:
	_refresh()

func _buy_attribute(id: String) -> void:
	var genomes_before := int(PlayerData.get_current_species_data().genomes_available)
	if not PlayerData.upgrade_attribute(id):
		_flash_feedback("Not enough AP.", C_HP)
		return
	AudioManager.play_sfx("tap_button")
	# Animate the card
	var card: PanelContainer = _attribute_rows[id]["card"]
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2(1.02, 1.02), 0.08).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)
	_flash_feedback("%s → %s" % [PlayerData.ATTRIBUTE_DEFINITIONS[id].name, PlayerData.attribute_value(id)])
	if int(PlayerData.get_current_species_data().genomes_available) > genomes_before:
		_flash_feedback("Genome earned!", C_GOLD)

func _ask_ultimate(category: String) -> void:
	_pending_category = category
	_pending_species = PlayerData.active_species
	var data := PlayerData.get_current_species_data()
	var rank := int(data.get(category + "_ultimate_level", 0))
	var equipped := str(data.equipped_ultimate_category) == category
	var result_rank := rank + 1 if equipped else maxi(1, rank)
	var definition: Dictionary = Rules.ULTIMATES[_pending_species][category]
	_confirmation.dialog_text = "%s %s Lv%d?\n\nCost: 1 Genome\n%s" % [PlayerData.ultimate_purchase_action(category), definition.name, result_rank, Rules.effect_summary(_pending_species, category, result_rank)]
	_confirmation.popup_centered(Vector2i(480, 180))

func _confirm_ultimate() -> void:
	if PlayerData.active_species != _pending_species or not PlayerData.develop_ultimate(_pending_category):
		_flash_feedback("Cannot develop — check Genomes.", C_HP)
		return
	_flash_feedback("%s equipped!" % PlayerData.get_equipped_ultimate_definition().name, C_GOLD)
	AudioManager.play_sfx("level_up")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _confirmation.visible:
		get_viewport().set_input_as_handled()
		_on_close()

func _on_close() -> void:
	_animate_close()
