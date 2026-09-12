extends CanvasLayer
class_name CharacterMenu

signal closed
const Rules = preload("res://systems/adaptation_rules.gd")
var _panel: PanelContainer
var _tab_container: TabContainer
var _header: Label
var _summary: Label
var _stats: Label
var _inventory: Label
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
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.01, 0.025, 0.035, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 40
	_panel.offset_right = -40
	_panel.offset_top = 24
	_panel.offset_bottom = -24
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101f26")
	style.border_color = Color("50c99b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	_panel.add_child(body)
	var top := HBoxContainer.new()
	body.add_child(top)
	_header = _label("", 24)
	top.add_child(_header)
	var close := _button("CLOSE")
	close.name = "CLOSE"
	close.pressed.connect(_on_close)
	top.add_child(close)
	_summary = _label("", 18)
	_summary.modulate = Color("8fe7bd")
	body.add_child(_summary)
	_tab_container = TabContainer.new()
	_tab_container.name = "TabContainer"
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_font_size_override("font_size", 20)
	body.add_child(_tab_container)
	_stats = _label("", 20)
	_tab("STATS").add_child(_stats)
	var attributes := _tab("ATTRIBUTES")
	attributes.add_child(_label("Spend Attribute Points (AP). Every 5 upgrades in the same attribute earns 1 adaptation Genome for this species.", 18))
	for id in PlayerData.ATTRIBUTE_DEFINITIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		attributes.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var title := _label("", 21)
		info.add_child(title)
		var detail := _label("", 16)
		detail.modulate = Color("b4c9cd")
		info.add_child(detail)
		var upgrade := _button("")
		upgrade.name = "Upgrade_" + str(id)
		upgrade.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		upgrade.pressed.connect(_buy_attribute.bind(str(id)))
		row.add_child(upgrade)
		_attribute_rows[id] = {"title": title, "detail": detail, "button": upgrade}
	var ultimates := _tab("ULTIMATES")
	ultimates.add_child(_label("One path equipped per species. Unlock, upgrade or switch for 1 adaptation Genome. Switching retains the path's previous level. Fight to fill the shared meter, then tap ULT.", 18))
	for category in ["attack", "defense", "agility"]:
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 6)
		ultimates.add_child(card)
		var top_row := HBoxContainer.new()
		card.add_child(top_row)
		var title := _label("", 22)
		top_row.add_child(title)
		var develop := _button("")
		develop.name = "Develop_" + category
		develop.pressed.connect(_ask_ultimate.bind(category))
		top_row.add_child(develop)
		var detail := _label("", 16)
		card.add_child(detail)
		var effects := _label("", 16)
		effects.modulate = Color("8fe7bd")
		card.add_child(effects)
		_ultimate_rows[category] = {"title": title, "detail": detail, "effects": effects, "button": develop}
	_inventory = _label("", 20)
	_tab("INVENTORY").add_child(_inventory)
	_feedback = _label("Tap your level badge to return here. Change form using the circle at the top of the game screen.", 16)
	body.add_child(_feedback)
	_confirmation = ConfirmationDialog.new()
	_confirmation.title = "Develop Ultimate Adaptation"
	_confirmation.ok_button_text = "Spend 1 Genome"
	_confirmation.confirmed.connect(_confirm_ultimate)
	add_child(_confirmation)
	PlayerData.progression_changed.connect(_refresh)
	PlayerData.active_species_changed.connect(_refresh)
	PlayerData.skill_points_changed.connect(_on_points_changed)
	_refresh()
	if PlayerData.skill_points > 0:
		_tab_container.current_tab = 1

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 48)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_container.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	scroll.add_child(box)
	return box

func _refresh(_species_id: String = "") -> void:
	if not is_instance_valid(_header):
		return
	var data := PlayerData.get_current_species_data()
	var species := PlayerData.active_species
	var species_info: Dictionary = Rules.SPECIES.get(species, {})
	_header.text = "%s — ADAPTATION PROFILE" % str(species_info.get("name", species)).to_upper()
	_summary.text = "Level %d / 15  •  %d / %d XP  •  %d AP  •  %d adaptation Genomes  •  ULT %d%%" % [PlayerData.level, PlayerData.experience, PlayerData.exp_to_next, PlayerData.skill_points, data.genomes_available, PlayerData.ultimate_charge]
	_tab_container.set_tab_title(1, "ATTRIBUTES (!)" if PlayerData.skill_points > 0 else "ATTRIBUTES")
	_tab_container.set_tab_title(2, "ULTIMATES (!)" if int(data.genomes_available) > 0 else "ULTIMATES")
	var stat_lines: PackedStringArray = [str(species_info.get("role", "")), ""]
	for id in _attribute_rows:
		var definition: Dictionary = PlayerData.ATTRIBUTE_DEFINITIONS[id]
		var row: Dictionary = _attribute_rows[id]
		var count := PlayerData.get_attribute_upgrade_count(id)
		var cost := PlayerData.get_attribute_upgrade_cost(id)
		row.title.text = "%s   %s → %s" % [definition.name, PlayerData.attribute_value(id), PlayerData.attribute_value(id, 1)]
		row.detail.text = "%d upgrades  •  %d / 5 toward next Genome  •  %s" % [count, count % 5, definition.description]
		row.button.text = "+ Upgrade · %d AP" % cost
		row.button.disabled = PlayerData.skill_points < cost
		stat_lines.append("%s: %s" % [definition.name, PlayerData.attribute_value(id)])
	stat_lines.append("\nAbilities: " + " · ".join(species_info.get("skills", [])))
	stat_lines.append("\nEarn XP from quests, investigation, restoration and combat. Each level grants 2 AP. Progress belongs to this species.")
	_stats.text = "\n".join(stat_lines)
	for category in _ultimate_rows:
		var row: Dictionary = _ultimate_rows[category]
		var definition: Dictionary = Rules.ULTIMATES.get(species, {}).get(category, {})
		var rank := int(data.get(category + "_ultimate_level", 0))
		var equipped := str(data.equipped_ultimate_category) == str(category)
		var action := PlayerData.ultimate_purchase_action(category)
		row.title.text = "%s · %s  Lv%d%s" % [str(category).to_upper(), definition.get("name", "Undiscovered"), rank, "  [EQUIPPED]" if equipped else ""]
		row.detail.text = definition.get("description", "Recover this species first.")
		var lines: PackedStringArray = []
		for r in range(1, 4):
			lines.append("Lv%d%s: %s" % [r, " (current)" if r == rank else "", Rules.effect_summary(species, category, r)])
		row.effects.text = "\n".join(lines)
		row.button.text = action + (" · 1 Genome" if action != "Max level" else "")
		row.button.disabled = PlayerData.ultimate_active or int(data.genomes_available) < 1 or action in ["Max level", "Unavailable"]
	_inventory.text = "Suit fragments: %d / %d\n%s adaptation Genomes: %d available (%d earned, %d spent)\n\nSpecies discovery unlocks a form. Adaptation Genomes come from attributes and develop its Ultimates.\n\n%s" % [PlayerData.genome_fragments, PlayerData.max_genome_fragments, str(species_info.get("name", species)), data.genomes_available, data.genomes_earned, data.genomes_spent, "\n".join(PlayerData.inventory)]

func _on_points_changed(_points: int) -> void:
	_refresh()

func _buy_attribute(id: String) -> void:
	var genomes_before := int(PlayerData.get_current_species_data().genomes_available)
	if not PlayerData.upgrade_attribute(id):
		_feedback.text = "Not enough AP for this upgrade."
		return
	AudioManager.play_sfx("tap_button")
	_feedback.text = "%s upgraded to %s." % [PlayerData.ATTRIBUTE_DEFINITIONS[id].name, PlayerData.attribute_value(id)]
	if int(PlayerData.get_current_species_data().genomes_available) > genomes_before:
		_feedback.text += " Adaptation Genome earned! Open ULTIMATES to choose a path."

func _ask_ultimate(category: String) -> void:
	_pending_category = category
	_pending_species = PlayerData.active_species
	var data := PlayerData.get_current_species_data()
	var rank := int(data.get(category + "_ultimate_level", 0))
	var equipped := str(data.equipped_ultimate_category) == category
	var result_rank := rank + 1 if equipped else maxi(1, rank)
	var definition: Dictionary = Rules.ULTIMATES[_pending_species][category]
	_confirmation.dialog_text = "%s %s at Lv%d?\nCosts 1 %s adaptation Genome.\nOther path levels are retained.\n\n%s" % [PlayerData.ultimate_purchase_action(category), definition.name, result_rank, _pending_species.replace("_", " ").capitalize(), Rules.effect_summary(_pending_species, category, result_rank)]
	_confirmation.popup_centered(Vector2i(640, 250))

func _confirm_ultimate() -> void:
	if PlayerData.active_species != _pending_species or not PlayerData.develop_ultimate(_pending_category):
		_feedback.text = "Could not develop this path. Check your Genome balance and active Ultimate."
		return
	_feedback.text = "%s equipped. Fight to fill the shared meter, then tap ULT." % PlayerData.get_equipped_ultimate_definition().name
	AudioManager.play_sfx("level_up")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _confirmation.visible:
		get_viewport().set_input_as_handled()
		_on_close()

func _on_close() -> void:
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()
