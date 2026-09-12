class_name GameHUD
extends CanvasLayer

## Clean, modern game HUD.
## Sleek bars, circular badges, translucent backgrounds.

# ── Colors & Styling ──────────────────────────────────────────────────────────

const C_HP       := Color("#ff3b5c")
const C_STAM     := Color("#9400ff")
const C_EXP      := Color("#ffb31a")
const C_BG_DARK  := Color(0.04, 0.04, 0.06, 0.65)
const C_BTN_NORM := Color(0.12, 0.13, 0.18, 0.75)
const C_BTN_PRSS := Color(0.85, 0.88, 0.95, 0.90)

# ── Node refs ─────────────────────────────────────────────────────────────────

var _root:       Control
var _hp_bar:     ProgressBar
var _hp_lbl:     Label
var _stam_bar:   ProgressBar
var _stam_lbl:   Label
var _exp_bar:    Control
var _lvl_lbl:    Label
var _level_badge: Label
var _status_group: Control

# Top-centre transformation selector. The single visible circle keeps the HUD
# quiet; the full four-form picker opens only when the player taps it.
var _species_selector: PanelContainer
var _species_slot_buttons: Dictionary = {}
var _species_toggle: Button
var _species_toggle_portrait: TextureRect
var _species_toggle_symbol: Label
var _species_selector_expanded: bool = false
var _salamander_guide_active: bool = false
var _species_guide_tween: Tween

var _interact_btn: Button
var _current_interact_source: Node
var _interact_callback: Callable
var _interact_tween: Tween

var _attack_btn: Button
var _skill1_btn: Button
var _jump_btn:   Button
var _skill3_btn: Button
var _cancel_zone: Label
var _menu_btn:   Button
var _menu_panel: Control
var _menu_open:  bool = false
var _knowledge_btn: Button
var _knowledge_badge: Label

var _tutorial_panel: PanelContainer
var _tutorial_title: Label
var _tutorial_desc:  Label

var _subtitle_panel: PanelContainer
var _subtitle_label: RichTextLabel
var _subtitle_tween: Tween

var _objective_panel: HBoxContainer
var _objective_lbl: Label
var _subtitle_time_shown: float = 0.0

var _jump_highlight_tw: Tween
var _attack_highlight_tw: Tween

var _quest_header_lbl: Label
var _quest_accent_rect: ColorRect
var _quest_btn: Button
var _quest_hud_state: int = 0
var _quest_desc_panel: PanelContainer
var _quest_desc_lbl: Label
var _quest_hint_lbl: Label
var _quest_log_panel: PanelContainer
var _quest_panel: PanelContainer
var _genome_popup_panel: PanelContainer
var _genome_popup_label: RichTextLabel
var _genome_popup_tween: Tween

var _zone_status_panel: PanelContainer
var _zone_status_lbl: RichTextLabel
var _zone_status_tween: Tween

var _cleanup_progress_panel: PanelContainer
var _cleanup_progress_bar: ProgressBar
var _cleanup_progress_label: Label

var _frog_defense_panel: PanelContainer
var _frog_defense_bar: ProgressBar
var _frog_defense_label: Label

var _notification_panel: PanelContainer
var _notification_title: Label
var _notification_text: RichTextLabel
var _notification_tween: Tween

var _knowledge_toast_panel: PanelContainer
var _knowledge_toast_title: Label
var _knowledge_toast_label: Label
var _knowledge_toast_tween: Tween

var _walkthrough_steps: Array = []
var _current_step_index: int = 0
var _active_highlight_nodes: Array = []
var _active_highlight_tweens: Dictionary = {}

var _minimap_camera: Camera3D
var _minimap_viewport: SubViewport
var _minimap_panel: PanelContainer
var _is_minimap_expanded: bool = false
var _minimap_drag_active: bool = false
var _minimap_last_mouse_pos: Vector2
var _minimap_drag_distance: float = 0.0
var _minimap_cam_offset: Vector3 = Vector3.ZERO
var _minimap_original_rect: Rect2
var _minimap_original_zoom: float
var _minimap_tween: Tween
var _minimap_markers: Dictionary = {}
var _player_icon_container: CenterContainer
var _fog_manager: Node
var _current_objective_target: Node3D = null

signal subtitle_dismissed
signal tutorial_dismissed
signal tutorial_complete
signal player_moved_in_tutorial

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 10
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("hud")

	if has_node("Root"):
		_root = get_node("Root")
	else:
		_root = Control.new()
		_root.name = "Root"
		_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_root)

	_build_player_status()
	_build_species_selector()
	_build_action_buttons()
	_build_cancel_zone()
	_build_menu_panel()
	_build_tutorial_panel()
	_build_subtitle_panel()
	_build_objective_panel()
	_build_objective_arrow()
	_build_quest_log_panel()

	# Listen to QuestManager if it exists
	if get_tree().root.has_node("QuestManager"):
		var qm = get_tree().root.get_node("QuestManager")
		qm.objective_updated.connect(_on_objective_updated)
		_on_objective_updated(qm.current_objective)
	_build_genome_popup()
	_build_minimap()
	_build_zone_status()
	_build_frog_defense_status()
	_build_notification_panel()
	_build_knowledge_toast()

	_connect_signals()

func _set_owner_recursive(node: Node, r: Node) -> void:
	if node != r and node.owner == null:
		node.owner = r
	for child in node.get_children():
		_set_owner_recursive(child, r)

func _input(event: InputEvent) -> void:
	if _genome_popup_panel and _genome_popup_panel.visible and _genome_popup_panel.modulate.a > 0.5:
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			if event.is_pressed():
				_hide_genome_popup()
				
	if _subtitle_panel and _subtitle_panel.visible and _subtitle_panel.modulate.a > 0.5:
		# Allow tapping anywhere on the screen to dismiss the subtitle
		if event is InputEventScreenTouch and event.is_pressed() and _subtitle_time_shown > 1.0:
			hide_subtitle()

func add_minimap_marker(node: Node3D, color: Color = Color(0.2, 1.0, 0.4), hover: bool = true) -> void:
	if not is_instance_valid(_marker_layer): return
	if _minimap_markers.has(node): return
	var icon = Control.new()
	icon.custom_minimum_size = Vector2(10, 10)
	var script = GDScript.new()
	
	if hover:
		script.source_code = """extends Control
var color: Color = Color.WHITE
var time: float = 0.0
var offset_time: float = 0.0

func _ready():
	offset_time = randf() * 10.0

func _process(delta: float):
	time += delta * 4.0
	queue_redraw()

func _draw():
	var bounce = sin(time + offset_time) * 3.0
	var offset_vec = Vector2(0, bounce)
	var center = size / 2.0
	var points = PackedVector2Array([
		Vector2(0, 0) + offset_vec,
		Vector2(size.x, 0) + offset_vec,
		Vector2(center.x, size.y) + offset_vec
	])
	draw_polygon(points, PackedColorArray([color, color, color]))
"""
	else:
		script.source_code = """extends Control
var color: Color = Color.WHITE
func _draw():
	var center = size / 2.0
	var points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(center.x, size.y)
	])
	draw_polygon(points, PackedColorArray([color, color, color]))
"""
	script.reload()
	icon.set_script(script)
	icon.set("color", color)
	
	var icon_container = CenterContainer.new()
	icon_container.add_child(icon)
	_marker_layer.add_child(icon_container)
	_minimap_markers[node] = icon_container

func remove_minimap_marker(node: Node3D) -> void:
	if _minimap_markers.has(node):
		var icon_container = _minimap_markers[node]
		if is_instance_valid(icon_container):
			icon_container.queue_free()
		_minimap_markers.erase(node)

func _process(delta: float) -> void:
	_subtitle_time_shown += delta
	if is_instance_valid(_level_badge):
		_level_badge.visible = PlayerData.skill_points > 0
		_level_badge.text = str(PlayerData.skill_points)
		
	if is_instance_valid(_minimap_camera):
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player):
			if is_instance_valid(_fog_manager):
				_fog_manager.update_fog(player.global_position)
				
			# Follow player from above, plus any drag offset if expanded
			_minimap_camera.global_position = Vector3(player.global_position.x, 150.0, player.global_position.z) + _minimap_cam_offset
			
			# Update player icon offset
			var pixels_per_unit = _minimap_panel.size.y / _minimap_camera.size
			if is_instance_valid(_player_icon_container):
				var p_offset_x = -_minimap_cam_offset.x * pixels_per_unit
				var p_offset_y = -_minimap_cam_offset.z * pixels_per_unit
				_player_icon_container.position = _minimap_panel.size / 2.0 + Vector2(p_offset_x, p_offset_y) - _player_icon_container.size / 2.0
				
			# Update minimap markers
			for target in _minimap_markers.keys():
				var icon_container = _minimap_markers[target]
				if not is_instance_valid(target) or target.is_queued_for_deletion():
					if is_instance_valid(icon_container): icon_container.queue_free()
					_minimap_markers.erase(target)
					continue
					
				var world_offset = target.global_position - _minimap_camera.global_position
				var ui_x = world_offset.x * pixels_per_unit
				var ui_y = world_offset.z * pixels_per_unit
				
				var offset = Vector2(ui_x, ui_y)
				var max_radius = (min(_minimap_panel.size.x, _minimap_panel.size.y) / 2.0) - 10.0
				
				if abs(offset.x) > max_radius or abs(offset.y) > max_radius:
					var scale_x = max_radius / abs(offset.x) if abs(offset.x) > 0 else 1.0
					var scale_y = max_radius / abs(offset.y) if abs(offset.y) > 0 else 1.0
					var min_scale = min(scale_x, scale_y)
					offset *= min_scale
					
				icon_container.position = _minimap_panel.size / 2.0 + offset - icon_container.size / 2.0

# ── Zone Status (Top Center) ──────────────────────────────────────────────────

func _build_zone_status() -> void:
	if _root.has_node("ZoneStatusPanel"):
		_zone_status_panel = _root.find_child("ZoneStatusPanel", true, false)
		_zone_status_lbl = _zone_status_panel.get_child(0) as RichTextLabel
		return
		
	_zone_status_panel = PanelContainer.new()
	_zone_status_panel.name = "ZoneStatusPanel"
	_zone_status_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_zone_status_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_zone_status_panel.offset_top = 32
	_zone_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	style.border_color = Color(0.8, 0.8, 0.9, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_zone_status_panel.add_theme_stylebox_override("panel", style)
	
	_zone_status_lbl = RichTextLabel.new()
	_zone_status_lbl.name = "ZoneStatusLbl"
	_zone_status_lbl.bbcode_enabled = true
	_zone_status_lbl.fit_content = true
	_zone_status_lbl.scroll_active = false
	_zone_status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zone_status_lbl.add_theme_font_size_override("normal_font_size", 18)
	_zone_status_lbl.add_theme_font_size_override("bold_font_size", 18)
	_zone_status_lbl.custom_minimum_size = Vector2(250, 20)
	
	_zone_status_panel.add_child(_zone_status_lbl)
	_root.add_child(_zone_status_panel)
	
	_zone_status_panel.visible = false
	_zone_status_panel.modulate.a = 0.0

func show_zone_status(text: String) -> void:
	# Avoid redundant updates if text is same
	var formatted_text = "[center][b]" + text + "[/b][/center]"
	if _zone_status_lbl.text == formatted_text and _zone_status_panel.visible:
		return
		
	_zone_status_lbl.text = formatted_text
	_zone_status_panel.visible = true
	
	if _zone_status_tween and _zone_status_tween.is_valid():
		_zone_status_tween.kill()
	_zone_status_tween = create_tween()
	_zone_status_tween.tween_property(_zone_status_panel, "modulate:a", 1.0, 0.3)

func hide_zone_status() -> void:
	if not _zone_status_panel.visible or _zone_status_panel.modulate.a == 0.0:
		return
		
	if _zone_status_tween and _zone_status_tween.is_valid():
		_zone_status_tween.kill()
	_zone_status_tween = create_tween()
	_zone_status_tween.tween_property(_zone_status_panel, "modulate:a", 0.0, 0.3)
	_zone_status_tween.tween_callback(func(): _zone_status_panel.visible = false)

# ── Habitat Cleanup Progress (Top Center) ────────────────────────────────────

func show_cleanup_progress(cleared: int, total: int) -> void:
	if total <= 0:
		hide_cleanup_progress()
		return

	_build_cleanup_progress()
	_cleanup_progress_bar.max_value = total
	_cleanup_progress_bar.value = clampi(cleared, 0, total)
	_cleanup_progress_label.text = "HABITAT CLEANUP  %d / %d" % [cleared, total]
	_cleanup_progress_panel.visible = true

func hide_cleanup_progress() -> void:
	if _cleanup_progress_panel:
		_cleanup_progress_panel.visible = false

func _build_cleanup_progress() -> void:
	if _cleanup_progress_panel:
		return

	_cleanup_progress_panel = PanelContainer.new()
	_cleanup_progress_panel.name = "CleanupProgressPanel"
	_cleanup_progress_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_cleanup_progress_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_cleanup_progress_panel.offset_top = 92
	_cleanup_progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.10, 0.07, 0.90)
	panel_style.border_color = Color(0.30, 0.95, 0.60, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 10
	_cleanup_progress_panel.add_theme_stylebox_override("panel", panel_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_cleanup_progress_panel.add_child(box)

	_cleanup_progress_label = Label.new()
	_cleanup_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cleanup_progress_label.add_theme_font_size_override("font_size", 15)
	_cleanup_progress_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.84))
	box.add_child(_cleanup_progress_label)

	_cleanup_progress_bar = ProgressBar.new()
	_cleanup_progress_bar.custom_minimum_size = Vector2(270, 14)
	_cleanup_progress_bar.show_percentage = false
	_cleanup_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.01, 0.03, 0.02, 0.95)
	bar_bg.set_corner_radius_all(7)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.18, 0.92, 0.48)
	bar_fill.set_corner_radius_all(7)
	_cleanup_progress_bar.add_theme_stylebox_override("background", bar_bg)
	_cleanup_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	box.add_child(_cleanup_progress_bar)

	_root.add_child(_cleanup_progress_panel)
	_cleanup_progress_panel.visible = false

# ── Native Frog Defense (Q03) ───────────────────────────────────────────────

func _build_frog_defense_status() -> void:
	if is_instance_valid(_frog_defense_panel):
		return

	_frog_defense_panel = PanelContainer.new()
	_frog_defense_panel.name = "FrogDefensePanel"
	_frog_defense_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_frog_defense_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_frog_defense_panel.offset_top = 172.0
	_frog_defense_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.14, 0.035, 0.045, 0.91)
	panel_style.border_color = Color(1.0, 0.38, 0.46, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 7
	panel_style.content_margin_bottom = 9
	_frog_defense_panel.add_theme_stylebox_override("panel", panel_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_frog_defense_panel.add_child(box)
	_frog_defense_label = Label.new()
	_frog_defense_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frog_defense_label.add_theme_font_size_override("font_size", 14)
	_frog_defense_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.82))
	box.add_child(_frog_defense_label)
	_frog_defense_bar = ProgressBar.new()
	_frog_defense_bar.custom_minimum_size = Vector2(285, 13)
	_frog_defense_bar.show_percentage = false
	_frog_defense_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.01, 0.02, 0.95)
	bar_bg.set_corner_radius_all(7)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.98, 0.27, 0.34)
	bar_fill.set_corner_radius_all(7)
	_frog_defense_bar.add_theme_stylebox_override("background", bar_bg)
	_frog_defense_bar.add_theme_stylebox_override("fill", bar_fill)
	box.add_child(_frog_defense_bar)
	_root.add_child(_frog_defense_panel)
	_frog_defense_panel.visible = false

func show_frog_defense(current: float, maximum: float) -> void:
	_build_frog_defense_status()
	_frog_defense_bar.max_value = maximum
	_frog_defense_bar.value = clampf(current, 0.0, maximum)
	_frog_defense_label.text = "PROTECT NATIVE FROG  %d / %d" % [roundi(current), roundi(maximum)]
	_frog_defense_panel.visible = true

func hide_frog_defense() -> void:
	if is_instance_valid(_frog_defense_panel):
		_frog_defense_panel.visible = false

# ── Cinematic Notification Banner ─────────────────────────────────────────────

func _build_notification_panel() -> void:
	if _root.has_node("NotificationPanel"):
		_notification_panel = _root.find_child("NotificationPanel", true, false)
		return
		
	_notification_panel = PanelContainer.new()
	_notification_panel.name = "NotificationPanel"
	_notification_panel.set_anchors_preset(Control.PRESET_CENTER)
	_notification_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_notification_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_notification_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_panel.custom_minimum_size = Vector2(800, 150)
	
	var style = StyleBoxFlat.new()
	# Translucent dark gradient style strip across the middle
	style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	style.set_border_width_all(0)
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	_notification_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_notification_panel.add_child(vbox)
	
	_notification_title = Label.new()
	_notification_title.name = "NotifTitle"
	_notification_title.add_theme_font_size_override("font_size", 42)
	_notification_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2)) # Gold
	_notification_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_notification_title.add_theme_constant_override("shadow_offset_y", 2)
	_notification_title.add_theme_constant_override("shadow_outline_size", 4)
	_notification_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_title.text = "OBJECTIVE COMPLETE"
	vbox.add_child(_notification_title)
	
	_notification_text = RichTextLabel.new()
	_notification_text.name = "NotifText"
	_notification_text.bbcode_enabled = true
	_notification_text.fit_content = true
	_notification_text.scroll_active = false
	_notification_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_text.add_theme_font_size_override("normal_font_size", 20)
	_notification_text.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8))
	_notification_text.custom_minimum_size = Vector2(600, 30)
	vbox.add_child(_notification_text)
	
	_root.add_child(_notification_panel)
	
	_notification_panel.visible = false
	_notification_panel.modulate.a = 0.0

func show_notification(title: String, text: String, duration: float = 4.0) -> void:
	if not is_instance_valid(_notification_panel): return
	
	_notification_title.text = title.to_upper()
	_notification_text.text = "[center]" + text + "[/center]"
	_notification_panel.visible = true
	
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("palaka_convo") # Play a grander sound if available
	
	if _notification_tween and _notification_tween.is_valid():
		_notification_tween.kill()
		
	# Cinematic scale and fade in
	_notification_panel.scale = Vector2(1.2, 1.2)
	_notification_panel.modulate.a = 0.0
	_notification_panel.pivot_offset = _notification_panel.size / 2.0
	
	_notification_tween = create_tween()
	_notification_tween.set_parallel(true)
	
	# Scale down slightly and fade in
	_notification_tween.tween_property(_notification_panel, "scale", Vector2(1.0, 1.0), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_notification_tween.tween_property(_notification_panel, "modulate:a", 1.0, 0.8)
	
	_notification_tween.chain().tween_interval(duration)
	
	# Fade out smoothly
	_notification_tween.chain().tween_property(_notification_panel, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_notification_tween.chain().tween_callback(func(): _notification_panel.visible = false)

# ── Knowledge Unlocked Toast (flies into the Knowledge book button) ───────────

func _build_knowledge_toast() -> void:
	if _root.has_node("KnowledgeToast"):
		_knowledge_toast_panel = _root.find_child("KnowledgeToast", true, false)
		return

	_knowledge_toast_panel = PanelContainer.new()
	_knowledge_toast_panel.name = "KnowledgeToast"
	_knowledge_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var suit_theme = load("res://ui/suit_theme.gd")
	if suit_theme:
		_knowledge_toast_panel.theme = suit_theme.get_theme()

	# Same small dark backing as the quest expand panel — this is a brief,
	# self-contained pop-up moment (like the Investigation Card), not part of
	# the always-on resting HUD, so a light panel background is appropriate.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(18 / 255.0, 32 / 255.0, 28 / 255.0, 0.9)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_knowledge_toast_panel.add_theme_stylebox_override("panel", style)

	# Fixed top-left anchor for its entire lifecycle (resting AND flying) — the
	# resting position is computed manually in show_knowledge_unlocked() from
	# the panel's actual settled size each time, rather than relying on
	# anchor/grow-direction auto-recentering. That auto-recentering depends on
	# the container's size already reflecting the new title text at the moment
	# the anchor preset is (re)applied, which isn't guaranteed to have happened
	# yet in the same frame the text changes — causing an intermittent
	# off-center toast for titles of different lengths.
	_knowledge_toast_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_knowledge_toast_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_knowledge_toast_panel.grow_vertical = Control.GROW_DIRECTION_END

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	_knowledge_toast_panel.add_child(vbox)

	_knowledge_toast_title = Label.new()
	_knowledge_toast_title.text = "NEW KNOWLEDGE"
	_knowledge_toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_knowledge_toast_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_knowledge_toast_title.add_theme_font_size_override("font_size", 14)
	if suit_theme:
		_knowledge_toast_title.add_theme_color_override("font_color", suit_theme.COLOR_ACCENT_YELLOW)
	vbox.add_child(_knowledge_toast_title)

	_knowledge_toast_label = Label.new()
	_knowledge_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_knowledge_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_knowledge_toast_label.add_theme_font_size_override("font_size", 20)
	_knowledge_toast_label.add_theme_color_override("font_color", Color(0.95, 0.98, 0.95))
	vbox.add_child(_knowledge_toast_label)

	_root.add_child(_knowledge_toast_panel)
	_knowledge_toast_panel.visible = false
	_knowledge_toast_panel.modulate.a = 0.0

## Quiet pop-up for scanning a knowledge object — appears, holds briefly so the
## player can read it, then shrinks and flies into the Knowledge (book) button
## as if the entry is being physically filed away, instead of just fading out
## in place. This is deliberately smaller/quieter than show_notification()'s
## cinematic banner, which is reserved for bigger story/system beats.
func show_knowledge_unlocked(title: String) -> void:
	if not is_instance_valid(_knowledge_toast_panel) or not is_instance_valid(_knowledge_btn):
		return

	_knowledge_toast_label.text = title

	if _knowledge_toast_tween and _knowledge_toast_tween.is_valid():
		_knowledge_toast_tween.kill()

	_knowledge_toast_panel.scale = Vector2(0.85, 0.85)
	_knowledge_toast_panel.modulate.a = 0.0
	_knowledge_toast_panel.visible = true

	# Let the container fully re-measure itself for the NEW title text before
	# computing a centered position from its size — two frames to be safe,
	# since container re-layout is deferred and isn't guaranteed to finish
	# within a single frame.
	await get_tree().process_frame
	await get_tree().process_frame

	var rest_x = (_root.size.x - _knowledge_toast_panel.size.x) / 2.0
	_knowledge_toast_panel.position = Vector2(rest_x, 190)
	_knowledge_toast_panel.pivot_offset = _knowledge_toast_panel.size / 2.0

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("message")

	_knowledge_toast_tween = create_tween()

	# Pop in.
	_knowledge_toast_tween.set_parallel(true)
	_knowledge_toast_tween.tween_property(_knowledge_toast_panel, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_knowledge_toast_tween.tween_property(_knowledge_toast_panel, "modulate:a", 1.0, 0.25)
	_knowledge_toast_tween.set_parallel(false)

	# Hold so the player can actually read it.
	_knowledge_toast_tween.tween_interval(1.4)

	# Fly and shrink into the Knowledge book button, like the entry is being
	# filed away. The panel is top-left anchored for its whole lifecycle now,
	# so global_position can be tweened directly with no anchor swap needed.
	var target_pos: Vector2 = _knowledge_btn.get_global_rect().get_center()
	_knowledge_toast_tween.set_parallel(true)
	_knowledge_toast_tween.tween_property(_knowledge_toast_panel, "global_position", target_pos, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_knowledge_toast_tween.tween_property(_knowledge_toast_panel, "scale", Vector2(0.05, 0.05), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_knowledge_toast_tween.tween_property(_knowledge_toast_panel, "modulate:a", 0.0, 0.25).set_delay(0.25)
	_knowledge_toast_tween.set_parallel(false)

	_knowledge_toast_tween.tween_callback(func():
		_knowledge_toast_panel.visible = false
		_bounce_knowledge_button()
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("exp_collect")
	)

func _bounce_knowledge_button() -> void:
	if not is_instance_valid(_knowledge_btn): return
	_knowledge_btn.pivot_offset = _knowledge_btn.size / 2.0
	var tw = create_tween()
	tw.tween_property(_knowledge_btn, "scale", Vector2(1.25, 1.25), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(_knowledge_btn, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# ── Transformation Selector (Top Centre) ─────────────────────────────────────

func _build_species_selector() -> void:
	_build_species_toggle()
	if _root.has_node("SpeciesSelectorPanel"):
		_species_selector = _root.get_node("SpeciesSelectorPanel") as PanelContainer
		_refresh_species_selector()
		return

	_species_selector = PanelContainer.new()
	_species_selector.name = "SpeciesSelectorPanel"
	_species_selector.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_species_selector.offset_left = -151.0
	_species_selector.offset_top = 84.0
	_species_selector.offset_right = 151.0
	_species_selector.offset_bottom = 164.0
	# The picker has no background, so only its actual circle buttons should
	# capture input; empty space continues through to the game world.
	_species_selector.mouse_filter = Control.MOUSE_FILTER_PASS
	_species_selector.z_index = 5
	var selector_style := StyleBoxEmpty.new()
	_species_selector.add_theme_stylebox_override("panel", selector_style)
	_root.add_child(_species_selector)

	var slots := HBoxContainer.new()
	slots.name = "Slots"
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 13)
	slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_species_selector.add_child(slots)

	for slot_data in _get_species_selector_slots():
		var species_id := str(slot_data["id"])
		if species_id == PlayerData.active_species:
			continue
		var slot := VBoxContainer.new()
		slot.name = species_id.capitalize() + "Slot"
		slot.custom_minimum_size = Vector2(88, 78)
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_theme_constant_override("separation", -1)
		slots.add_child(slot)

		var button := Button.new()
		button.name = "SpeciesButton"
		button.custom_minimum_size = Vector2(64, 64)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_species_slot_pressed.bind(species_id))
		slot.add_child(button)

		var frog_portrait := TextureRect.new()
		frog_portrait.name = "FrogPortrait"
		frog_portrait.texture = load("res://assets/Geno_Icon.png")
		frog_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frog_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frog_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
		frog_portrait.offset_left = 6.0
		frog_portrait.offset_top = 6.0
		frog_portrait.offset_right = -6.0
		frog_portrait.offset_bottom = -6.0
		frog_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frog_portrait.visible = species_id == "frog"
		button.add_child(frog_portrait)

		var symbol := Label.new()
		symbol.name = "Symbol"
		symbol.set_anchors_preset(Control.PRESET_FULL_RECT)
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		symbol.add_theme_font_size_override("font_size", 19)
		symbol.add_theme_color_override("font_color", Color(0.68, 0.96, 0.82, 0.95))
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(symbol)

		var name_label := Label.new()
		name_label.name = "Name"
		name_label.custom_minimum_size = Vector2(88, 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(name_label)

		_species_slot_buttons[species_id] = button

	_species_selector.visible = _species_selector_expanded
	_refresh_species_selector()

func _build_species_toggle() -> void:
	if _root.has_node("SpeciesFormToggle"):
		_species_toggle = _root.get_node("SpeciesFormToggle") as Button
		_species_toggle_portrait = _species_toggle.get_node_or_null("FrogPortrait") as TextureRect
		_species_toggle_symbol = _species_toggle.get_node_or_null("Symbol") as Label
		return

	_species_toggle = Button.new()
	_species_toggle.name = "SpeciesFormToggle"
	_species_toggle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_species_toggle.offset_left = -34.0
	_species_toggle.offset_top = 14.0
	_species_toggle.offset_right = 34.0
	_species_toggle.offset_bottom = 82.0
	_species_toggle.focus_mode = Control.FOCUS_NONE
	_species_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_species_toggle.tooltip_text = "Choose transformation"
	_species_toggle.z_index = 6
	_species_toggle.pressed.connect(_toggle_species_selector)
	_root.add_child(_species_toggle)

	_species_toggle_portrait = TextureRect.new()
	_species_toggle_portrait.name = "FrogPortrait"
	_species_toggle_portrait.texture = load("res://assets/Geno_Icon.png")
	_species_toggle_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_species_toggle_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_species_toggle_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	_species_toggle_portrait.offset_left = 6.0
	_species_toggle_portrait.offset_top = 6.0
	_species_toggle_portrait.offset_right = -6.0
	_species_toggle_portrait.offset_bottom = -6.0
	_species_toggle_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_species_toggle.add_child(_species_toggle_portrait)

	_species_toggle_symbol = Label.new()
	_species_toggle_symbol.name = "Symbol"
	_species_toggle_symbol.set_anchors_preset(Control.PRESET_FULL_RECT)
	_species_toggle_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_species_toggle_symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_species_toggle_symbol.add_theme_font_size_override("font_size", 17)
	_species_toggle_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_species_toggle.add_child(_species_toggle_symbol)

func _get_species_selector_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = [{"id": "frog", "name": "Frog", "short_name": "FROG"}]
	for species_id in PlayerData.species_progression:
		if species_id == "frog":
			continue
		var display_name := str(species_id).replace("_", " ").capitalize()
		slots.append({
			"id": str(species_id),
			"name": display_name,
			"short_name": display_name.substr(0, 3).to_upper(),
		})
	while slots.size() < 4:
		slots.append({"id": "locked_%d" % slots.size(), "name": "Unknown", "short_name": "?"})
	if slots.size() > 4:
		slots.resize(4)
	return slots

func _rebuild_species_selector(_species_id: String = "") -> void:
	if is_instance_valid(_species_selector):
		_root.remove_child(_species_selector)
		_species_selector.queue_free()
	_species_selector = null
	_species_slot_buttons.clear()
	_build_species_selector()

func _toggle_species_selector() -> void:
	_set_species_selector_expanded(not _species_selector_expanded)

func _set_species_selector_expanded(expanded: bool) -> void:
	_species_selector_expanded = expanded
	if not is_instance_valid(_species_selector):
		return
	_species_selector.visible = expanded
	if expanded:
		_species_selector.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_species_selector, "modulate:a", 1.0, 0.12)
	if _salamander_guide_active:
		_update_species_guide_highlight()

func guide_salamander_transformation() -> void:
	_salamander_guide_active = PlayerData.active_species != "salamander"
	_update_species_guide_highlight()

func _update_species_guide_highlight() -> void:
	if _species_guide_tween and _species_guide_tween.is_valid():
		_species_guide_tween.kill()
	if is_instance_valid(_species_toggle):
		_species_toggle.self_modulate = Color.WHITE
	for button in _species_slot_buttons.values():
		if is_instance_valid(button):
			button.self_modulate = Color.WHITE
	if not _salamander_guide_active:
		return
	var target := _species_toggle
	if _species_selector_expanded:
		target = _species_slot_buttons.get("salamander") as Button
	if not is_instance_valid(target):
		return
	_species_guide_tween = create_tween().set_loops()
	_species_guide_tween.tween_property(target, "self_modulate", Color(1.5, 1.5, 0.8), 0.55)
	_species_guide_tween.tween_property(target, "self_modulate", Color.WHITE, 0.55)

func _refresh_species_selector() -> void:
	var active_slot: Dictionary = {"id": "frog", "name": "Frog", "short_name": "FROG"}
	for slot_data in _get_species_selector_slots():
		if str(slot_data["id"]) == PlayerData.active_species:
			active_slot = slot_data
	_refresh_species_toggle(active_slot)
	if not is_instance_valid(_species_selector):
		return

	for slot_data in _get_species_selector_slots():
		var species_id := str(slot_data["id"])
		var button := _species_slot_buttons.get(species_id) as Button
		if not is_instance_valid(button):
			continue
		var unlocked := PlayerData.is_species_unlocked(species_id)
		var active := unlocked and PlayerData.active_species == species_id
		button.disabled = not unlocked
		button.tooltip_text = "Select " + str(slot_data["name"]) + " transformation" if unlocked else "Genome data locked"

		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.07, 0.15, 0.15, 0.98) if unlocked else Color(0.035, 0.045, 0.06, 0.9)
		normal.border_color = Color(0.40, 1.0, 0.72, 1.0) if active else (Color(0.27, 0.62, 0.54, 0.72) if unlocked else Color(0.20, 0.25, 0.31, 0.82))
		normal.set_border_width_all(3 if active else 2)
		normal.set_corner_radius_all(32)
		normal.shadow_color = Color(0.1, 1.0, 0.65, 0.22) if active else Color(0, 0, 0, 0.32)
		normal.shadow_size = 6 if active else 3
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("disabled", normal)

		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.12, 0.28, 0.24, 1.0)
		hover.border_color = Color(0.66, 1.0, 0.84, 1.0)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)

		var frog_portrait := button.get_node_or_null("FrogPortrait") as TextureRect
		if is_instance_valid(frog_portrait):
			frog_portrait.visible = unlocked and species_id == "frog"
		var symbol := button.get_node_or_null("Symbol") as Label
		if is_instance_valid(symbol):
			symbol.visible = not (unlocked and species_id == "frog")
			symbol.text = str(slot_data["short_name"]) if unlocked else "?"
			symbol.add_theme_color_override("font_color", Color(0.68, 0.96, 0.82, 0.95) if unlocked else Color(0.36, 0.41, 0.48, 0.78))
		var name_label := button.get_parent().get_node_or_null("Name") as Label
		if is_instance_valid(name_label):
			name_label.text = ("ACTIVE" if active else str(slot_data["name"]).to_upper()) if unlocked else "LOCKED"
			name_label.add_theme_color_override("font_color", Color(0.54, 1.0, 0.74, 1.0) if active else (Color(0.75, 0.84, 0.84, 0.92) if unlocked else Color(0.38, 0.43, 0.49, 0.85)))

func _refresh_species_toggle(active_slot: Dictionary) -> void:
	if not is_instance_valid(_species_toggle):
		return
	var active_id := str(active_slot.get("id", "frog"))
	_species_toggle.tooltip_text = str(active_slot.get("name", "Frog")) + " form — tap to change"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.16, 0.15, 0.97)
	style.border_color = Color(0.40, 1.0, 0.72, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(34)
	style.shadow_color = Color(0.1, 1.0, 0.65, 0.22)
	style.shadow_size = 6
	_species_toggle.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.28, 0.24, 1.0)
	hover.border_color = Color(0.72, 1.0, 0.87, 1.0)
	_species_toggle.add_theme_stylebox_override("hover", hover)
	_species_toggle.add_theme_stylebox_override("pressed", hover)
	if is_instance_valid(_species_toggle_portrait):
		_species_toggle_portrait.visible = active_id == "frog"
	if is_instance_valid(_species_toggle_symbol):
		_species_toggle_symbol.visible = active_id != "frog"
		_species_toggle_symbol.text = str(active_slot.get("short_name", "?"))
		_species_toggle_symbol.add_theme_color_override("font_color", Color(0.68, 0.96, 0.82, 0.95))

func _on_species_slot_pressed(species_id: String) -> void:
	if PlayerData.set_active_species(species_id) and is_instance_valid(_notification_panel):
		var selected_name := species_id.capitalize()
		for slot_data in _get_species_selector_slots():
			if str(slot_data["id"]) == species_id:
				selected_name = str(slot_data["name"])
		show_notification(selected_name + " Form Active", "Transformation complete. Move around and try your attacks.", 3.5)
	_refresh_species_selector()
	_set_species_selector_expanded(false)

# ── Player Status (Top Left) ──────────────────────────────────────────────────

func _build_player_status() -> void:
	if _root.has_node("StatusGroup"):
		_status_group = _root.find_child("StatusGroup", true, false)
		var badge = _root.find_child("Badge", true, false)
		_hp_bar = _root.find_child("HpBar", true, false)
		_hp_lbl = _root.find_child("HpLbl", true, false)
		_stam_bar = _root.find_child("StamBar", true, false)
		_exp_bar = _root.find_child("ExpBar", true, false)
		_lvl_lbl = _root.find_child("LvlLbl", true, false)
		_level_badge = _root.find_child("LevelBadgeNotif", true, false)
		if not is_instance_valid(_level_badge) and badge:
			_level_badge = Label.new()
			_level_badge.name = "LevelBadgeNotif"
			_level_badge.add_theme_font_size_override("font_size", 14)
			_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_level_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var notif_style := StyleBoxFlat.new()
			notif_style.bg_color = Color(1.0, 0.2, 0.2, 1.0)
			notif_style.set_corner_radius_all(12)
			notif_style.content_margin_left = 6
			notif_style.content_margin_right = 6
			_level_badge.add_theme_stylebox_override("normal", notif_style)
			_level_badge.custom_minimum_size = Vector2(24, 24)
			_level_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			_level_badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			_level_badge.grow_vertical = Control.GROW_DIRECTION_END
			_level_badge.offset_right = 4
			_level_badge.offset_top = -4
			_level_badge.text = str(PlayerData.skill_points)
			_level_badge.visible = PlayerData.skill_points > 0
			var notif_wrapper = badge.get_node_or_null("LevelBadgeWrapper")
			if not notif_wrapper:
				notif_wrapper = Control.new()
				notif_wrapper.name = "LevelBadgeWrapper"
				notif_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
				badge.add_child(notif_wrapper)
			notif_wrapper.add_child(_level_badge)
		if badge and not badge.gui_input.is_connected(_on_badge_gui_input):
			badge.gui_input.connect(_on_badge_gui_input)
		return

	# Group container
	_status_group = Control.new()
	_status_group.name = "StatusGroup"
	_status_group.position = Vector2(24, 24)
	_status_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_status_group)

	# Level Badge (Circular)
	var badge := PanelContainer.new()
	badge.name = "Badge"
	badge.custom_minimum_size = Vector2(80, 80)
	badge.position = Vector2(0, 0)
	badge.z_index = 2
	
	var badge_bg := StyleBoxFlat.new()
	badge_bg.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	badge_bg.border_color = C_EXP
	badge_bg.set_border_width_all(2)
	badge_bg.set_corner_radius_all(40)
	badge_bg.shadow_color = Color(0, 0, 0, 0.3)
	badge_bg.shadow_size = 4
	badge.add_theme_stylebox_override("panel", badge_bg)
	badge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	badge.gui_input.connect(_on_badge_gui_input)
	_status_group.add_child(badge)
	
	_level_badge = Label.new()
	_level_badge.name = "LevelBadgeNotif"
	_level_badge.add_theme_font_size_override("font_size", 14)
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var notif_style := StyleBoxFlat.new()
	notif_style.bg_color = Color(1.0, 0.2, 0.2, 1.0)
	notif_style.set_corner_radius_all(12)
	notif_style.content_margin_left = 6
	notif_style.content_margin_right = 6
	_level_badge.add_theme_stylebox_override("normal", notif_style)
	_level_badge.custom_minimum_size = Vector2(24, 24)
	_level_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_level_badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_level_badge.grow_vertical = Control.GROW_DIRECTION_END
	_level_badge.offset_right = 4
	_level_badge.offset_top = -4
	_level_badge.text = str(PlayerData.skill_points)
	_level_badge.visible = PlayerData.skill_points > 0
	
	var notif_wrapper = Control.new()
	notif_wrapper.name = "LevelBadgeWrapper"
	notif_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(notif_wrapper)
	notif_wrapper.add_child(_level_badge)

	var lvl_vbox := VBoxContainer.new()
	lvl_vbox.name = "LvlVBox"
	lvl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lvl_vbox.add_theme_constant_override("separation", -4)
	badge.add_child(lvl_vbox)

	var lvl_title := _make_label("LVL", 12, Color(0.7, 0.7, 0.7))
	lvl_title.name = "LvlTitle"
	lvl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_vbox.add_child(lvl_title)

	_lvl_lbl = _make_label("1", 24, Color.WHITE)
	_lvl_lbl.name = "LvlLbl"
	_lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lvl_lbl.add_theme_font_override("font", ThemeDB.fallback_font)
	lvl_vbox.add_child(_lvl_lbl)

	# Bars Container (Offset to the right of the badge)
	var bars_vbox := VBoxContainer.new()
	bars_vbox.name = "BarsVBox"
	bars_vbox.position = Vector2(65, 12)
	bars_vbox.add_theme_constant_override("separation", 8)
	bars_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_vbox.z_index = 1
	_status_group.add_child(bars_vbox)

	# Health Bar
	var hp_box := Control.new()
	hp_box.name = "HpBox"
	hp_box.custom_minimum_size = Vector2(300, 24)
	_hp_bar = _make_bar(300, 24, C_HP)
	_hp_bar.name = "HpBar"
	_hp_lbl = _make_label("100 / 100", 14, Color.WHITE)
	_hp_lbl.name = "HpLbl"
	_hp_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_box.add_child(_hp_bar)
	hp_box.add_child(_hp_lbl)
	bars_vbox.add_child(hp_box)

	# Stamina Bar
	var stam_box := Control.new()
	stam_box.name = "StamBox"
	stam_box.custom_minimum_size = Vector2(220, 16)
	_stam_bar = _make_bar(220, 16, C_STAM)
	_stam_bar.name = "StamBar"
	stam_box.add_child(_stam_bar)
	bars_vbox.add_child(stam_box)

	# EXP Bar (Radial around badge)
	var exp_script = GDScript.new()
	exp_script.source_code = """extends Control
var max_value: float = 100.0:
	set(v):
		max_value = v
		queue_redraw()
var value: float = 0.0:
	set(v):
		value = v
		queue_redraw()
var color: Color = Color.WHITE

func _draw():
	var center = size / 2.0
	var radius = size.x / 2.0 + 3.0
	var start_angle = -PI / 2.0
	var progress = 0.0
	if max_value > 0:
		progress = clamp(value / max_value, 0.0, 1.0)
	var end_angle = start_angle + progress * PI * 2.0
	
	draw_arc(center, radius, 0, PI * 2.0, 64, Color(0.1, 0.1, 0.1, 0.8), 4.0, true)
	if progress > 0:
		draw_arc(center, radius, start_angle, end_angle, 64, color, 4.0, true)
"""
	exp_script.reload()
	
	_exp_bar = Control.new()
	_exp_bar.name = "ExpBar"
	_exp_bar.set_script(exp_script)
	_exp_bar.set("color", C_EXP)
	_exp_bar.custom_minimum_size = Vector2(80, 80)
	_exp_bar.position = badge.position
	_exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exp_bar.z_index = 1
	_status_group.add_child(_exp_bar)
	

var _marker_layer: Control

func _build_minimap() -> void:
	if _root.has_node("MinimapPanel"):
		var old = _root.get_node("MinimapPanel")
		old.queue_free()
		
	_minimap_panel = PanelContainer.new()
	_minimap_panel.name = "MinimapPanel"
	_minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap_panel.custom_minimum_size = Vector2(180, 180)
	_minimap_panel.offset_right = -24
	_minimap_panel.offset_top = 24
	_minimap_panel.offset_left = -204
	_minimap_panel.offset_bottom = 204
	_minimap_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_minimap_panel.gui_input.connect(_on_minimap_gui_input)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.08, 0.95)
	style.border_color = Color(0.1, 0.9, 0.7, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	_minimap_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	_minimap_panel.add_child(margin)
	
	var sub_container = SubViewportContainer.new()
	sub_container.stretch = true
	margin.add_child(sub_container)
	
	_minimap_viewport = SubViewport.new()
	# Share the main 3D world
	_minimap_viewport.world_3d = get_tree().root.get_viewport().world_3d
	_minimap_viewport.transparent_bg = false
	_minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_container.add_child(_minimap_viewport)
	
	_marker_layer = Control.new()
	_marker_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap_panel.add_child(_marker_layer)
	
	_minimap_camera = Camera3D.new()
	_minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_minimap_camera.size = 60.0 # Adjust to zoom in/out
	_minimap_camera.near = 0.1
	_minimap_camera.far = 400.0
	_minimap_camera.rotation_degrees = Vector3(-90, 0, 0)
	# Turn off environmental fog for a clear minimap view, but provide ambient light to fix PBR shader glitches
	var minimap_env = Environment.new()
	minimap_env.background_mode = Environment.BG_COLOR
	minimap_env.background_color = Color(0.1, 0.1, 0.1)
	minimap_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	minimap_env.ambient_light_color = Color(1.0, 1.0, 1.0)
	_minimap_camera.environment = minimap_env
	_minimap_viewport.add_child(_minimap_camera)
	
	# Add a small player icon directly inside the minimap UI center
	var icon = ColorRect.new()
	icon.color = Color(0.2, 0.8, 1.0, 1.0) # Cyan dot for player
	icon.custom_minimum_size = Vector2(6, 6)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	_player_icon_container = CenterContainer.new()
	_player_icon_container.add_child(icon)
	_marker_layer.add_child(_player_icon_container)
	
	_root.add_child(_minimap_panel)
	
	_minimap_camera.cull_mask = 524287 # 0xFFFFF ^ (1 << 19) to hide Layer 20
	
	# --- FOG OF WAR ---
	_fog_manager = load("res://ui/minimap_fog.gd").new()
	_fog_manager.name = "MinimapFog"
	_root.add_child(_fog_manager)
	
	if PlayerData.world_state.has(PlayerData.current_scene_path):
		var scene_state = PlayerData.world_state[PlayerData.current_scene_path]
		if scene_state.has("fog_map"):
			_fog_manager.set_fog_data(scene_state["fog_map"])
	
	var fog_plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(500, 500)
	fog_plane.mesh = plane_mesh
	fog_plane.position = Vector3(0, 140, 0)
	fog_plane.layers = 1024 # Layer 11
	
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, depth_draw_never;
uniform sampler2D fog_mask;
void fragment() {
	ALBEDO = vec3(0.02, 0.04, 0.08); // Dark fog color
	float mask = texture(fog_mask, UV).r;
	ALPHA = mask * 0.95; // Slight transparency even at max fog
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("fog_mask", _fog_manager.get_texture())
	fog_plane.material_override = mat
	
	_minimap_viewport.add_child(fog_plane)

func _on_minimap_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_minimap_drag_active = true
				_minimap_last_mouse_pos = event.position
				_minimap_drag_distance = 0.0
			else:
				_minimap_drag_active = false
				if _minimap_drag_distance < 10.0:
					_toggle_minimap_expanded()
	elif event is InputEventMouseMotion and _minimap_drag_active:
		var delta = event.position - _minimap_last_mouse_pos
		_minimap_last_mouse_pos = event.position
		_minimap_drag_distance += delta.length()
		
		if _is_minimap_expanded:
			var pixels_per_unit = _minimap_panel.size.y / _minimap_camera.size
			var world_delta_x = -delta.x / pixels_per_unit
			var world_delta_z = -delta.y / pixels_per_unit
			_minimap_cam_offset += Vector3(world_delta_x, 0, world_delta_z)

func _toggle_minimap_expanded() -> void:
	_is_minimap_expanded = not _is_minimap_expanded
	
	if _minimap_tween and _minimap_tween.is_valid():
		_minimap_tween.kill()
	_minimap_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_minimap_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	if _is_minimap_expanded:
		get_tree().paused = true
		_minimap_original_rect = Rect2(_minimap_panel.position, _minimap_panel.size)
		_minimap_original_zoom = _minimap_camera.size
		
		var vp_size = get_viewport().get_visible_rect().size
		var target_size = Vector2(min(600, vp_size.x * 0.8), min(600, vp_size.y * 0.8))
		var target_pos = (vp_size - target_size) / 2.0
		
		_minimap_tween.parallel().tween_property(_minimap_panel, "custom_minimum_size", target_size, 0.3)
		_minimap_tween.parallel().tween_property(_minimap_panel, "size", target_size, 0.3)
		_minimap_tween.parallel().tween_property(_minimap_panel, "position", target_pos, 0.3)
		_minimap_tween.parallel().tween_property(_minimap_camera, "size", _minimap_original_zoom * 2.0, 0.3)
	else:
		get_tree().paused = false
		_minimap_cam_offset = Vector3.ZERO
		
		_minimap_tween.parallel().tween_property(_minimap_panel, "custom_minimum_size", _minimap_original_rect.size, 0.3)
		_minimap_tween.parallel().tween_property(_minimap_panel, "size", _minimap_original_rect.size, 0.3)
		_minimap_tween.parallel().tween_property(_minimap_panel, "position", _minimap_original_rect.position, 0.3)
		_minimap_tween.parallel().tween_property(_minimap_camera, "size", _minimap_original_zoom, 0.3)

func _build_genome_popup() -> void:
	if _root.has_node("GenomePopupPanel"):
		_genome_popup_panel = _root.find_child("GenomePopupPanel", true, false)
		_genome_popup_label = _root.find_child("GenomePopupLabel", true, false)
		return

	_genome_popup_panel = PanelContainer.new()
	_genome_popup_panel.name = "GenomePopupPanel"
	_genome_popup_panel.visible = false
	_genome_popup_panel.modulate.a = 0.0
	
	_genome_popup_panel.set_anchors_preset(Control.PRESET_CENTER)
	_genome_popup_panel.custom_minimum_size = Vector2(600, 200)
	
	_genome_popup_panel.set_anchor(SIDE_LEFT, 0.5)
	_genome_popup_panel.set_anchor(SIDE_RIGHT, 0.5)
	_genome_popup_panel.set_anchor(SIDE_TOP, 0.5)
	_genome_popup_panel.set_anchor(SIDE_BOTTOM, 0.5)
	_genome_popup_panel.offset_left = -300
	_genome_popup_panel.offset_right = 300
	_genome_popup_panel.offset_top = -100
	_genome_popup_panel.offset_bottom = 100
	
	_genome_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.1, 0.05, 0.95)
	bg.border_color = Color(0.2, 1.0, 0.5, 0.8)
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(8)
	bg.content_margin_left   = 32.0
	bg.content_margin_right  = 32.0
	bg.content_margin_top    = 48.0
	bg.content_margin_bottom = 48.0
	_genome_popup_panel.add_theme_stylebox_override("panel", bg)
	
	_genome_popup_label = RichTextLabel.new()
	_genome_popup_label.name = "GenomePopupLabel"
	var tech_font := SystemFont.new()
	tech_font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "Courier New", "monospace"])
	_genome_popup_label.add_theme_font_override("normal_font", tech_font)
	_genome_popup_label.add_theme_font_override("bold_font", tech_font)
	_genome_popup_label.bbcode_enabled = true
	_genome_popup_label.fit_content = true
	_genome_popup_label.scroll_active = false
	_genome_popup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_genome_popup_label.add_theme_font_size_override("normal_font_size", 24)
	_genome_popup_label.add_theme_font_size_override("bold_font_size", 36)
	_genome_popup_panel.add_child(_genome_popup_label)
	
	_root.add_child(_genome_popup_panel)

func show_genome_popup(current: int, total: int) -> void:
	var percent = int((float(current) / float(total)) * 100.0)
	_genome_popup_label.text = "[center][b][color=#33ff88]GENOME FRAGMENT RECOVERED[/color][/b]\n\n[font_size=24]Suit Reconstruction: " + str(percent) + "%[/font_size]\n\n[font_size=16][color=#888888](Tap to continue)[/color][/font_size][/center]"
	
	if _genome_popup_tween and _genome_popup_tween.is_valid():
		_genome_popup_tween.kill()
		
	_genome_popup_panel.visible = true
	_genome_popup_tween = create_tween()
	_genome_popup_tween.tween_property(_genome_popup_panel, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)

func _hide_genome_popup() -> void:
	if _genome_popup_tween and _genome_popup_tween.is_valid():
		_genome_popup_tween.kill()
	_genome_popup_tween = create_tween()
	_genome_popup_tween.tween_property(_genome_popup_panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	_genome_popup_tween.tween_callback(func(): _genome_popup_panel.visible = false)

# ── Action Buttons (Right / Bottom Right) ────────────────────────────────────────────────────────────

func _build_action_buttons() -> void:
	# 1. Primary Attack Button (Webbed Lunge)
	# Largest button, outermost bottom-right
	var attack_is_new = not _root.has_node("AttackBtn")
	_attack_btn = _make_circle_btn("AttackBtn", "", 120, C_BTN_NORM)
	_attack_btn.icon = preload("res://assets/BASIC ATTACK.svg")
	_attack_btn.expand_icon = true
	_attack_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attack_btn.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.6))
	_attack_btn.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.8))
	_attack_btn.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 0.9))
	if attack_is_new:
		_attack_btn.set_anchor(SIDE_RIGHT, 1.0)
		_attack_btn.set_anchor(SIDE_BOTTOM, 1.0)
		_attack_btn.set_anchor(SIDE_LEFT, 1.0)
		_attack_btn.set_anchor(SIDE_TOP, 1.0)
		_attack_btn.offset_right  = -40
		_attack_btn.offset_bottom = -40
		_attack_btn.offset_left   = -160
		_attack_btn.offset_top    = -160
	_attack_btn.button_down.connect(func():
		stop_highlight_attack()
		Input.action_press("attack")
	)
	_attack_btn.button_up.connect(func():   Input.action_release("attack"))

	# 2. Skill 1 Button (Sticky Tongue Whip)
	# Medium, directly to the left of Primary Attack
	var skill1_is_new = not _root.has_node("Skill1Btn")
	_skill1_btn = _make_circle_btn("Skill1Btn", "", 80, C_BTN_NORM)
	_skill1_btn.icon = preload("res://assets/TONGUE ATTACK.svg")
	_skill1_btn.expand_icon = true
	_skill1_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill1_btn.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.6))
	_skill1_btn.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.8))
	_skill1_btn.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 0.9))
	if skill1_is_new:
		_skill1_btn.set_anchor(SIDE_RIGHT, 1.0)
		_skill1_btn.set_anchor(SIDE_BOTTOM, 1.0)
		_skill1_btn.set_anchor(SIDE_LEFT, 1.0)
		_skill1_btn.set_anchor(SIDE_TOP, 1.0)
		_skill1_btn.offset_right  = -190
		_skill1_btn.offset_bottom = -60
		_skill1_btn.offset_left   = -270
		_skill1_btn.offset_top    = -140
	_skill1_btn.button_down.connect(func(): Input.action_press("skill1"))
	_skill1_btn.button_up.connect(func():   Input.action_release("skill1"))

	# 3. Skill 2 Button (Splashdown Jump)
	# Medium, directly above Skill 1, forming the center of the UI arc
	var jump_is_new = not _root.has_node("JumpBtn")
	_jump_btn = _make_circle_btn("JumpBtn", "", 80, C_BTN_NORM)
	_jump_btn.icon = preload("res://assets/SPLASH BUTTON.svg")
	_jump_btn.expand_icon = true
	_jump_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_jump_btn.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.6))
	_jump_btn.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.8))
	_jump_btn.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 0.9))
	if jump_is_new:
		_jump_btn.set_anchor(SIDE_RIGHT, 1.0)
		_jump_btn.set_anchor(SIDE_BOTTOM, 1.0)
		_jump_btn.set_anchor(SIDE_LEFT, 1.0)
		_jump_btn.set_anchor(SIDE_TOP, 1.0)
		_jump_btn.offset_right  = -152
		_jump_btn.offset_bottom = -152
		_jump_btn.offset_left   = -232
		_jump_btn.offset_top    = -232
	_jump_btn.gui_input.connect(_on_jump_btn_input)

	# 4. Skill 3 Button (Cutaneous Respiration - Ultimate)
	# Medium, top of the curved arc (directly above Primary Attack)
	var skill3_is_new = not _root.has_node("Skill3Btn")
	_skill3_btn = _make_circle_btn("Skill3Btn", "", 80, C_BTN_NORM)
	_skill3_btn.icon = preload("res://assets/cutaneous respiration.svg")
	_skill3_btn.expand_icon = true
	_skill3_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill3_btn.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.6))
	_skill3_btn.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.8))
	_skill3_btn.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 0.9))
	if skill3_is_new:
		_skill3_btn.set_anchor(SIDE_RIGHT, 1.0)
		_skill3_btn.set_anchor(SIDE_BOTTOM, 1.0)
		_skill3_btn.set_anchor(SIDE_LEFT, 1.0)
		_skill3_btn.set_anchor(SIDE_TOP, 1.0)
		_skill3_btn.offset_right  = -60
		_skill3_btn.offset_bottom = -190
		_skill3_btn.offset_left   = -140
		_skill3_btn.offset_top    = -270
	if skill3_is_new:
		_skill3_btn.pressed.connect(func(): Input.action_press("ultimate"); Input.action_release("ultimate"))
	_refresh_ultimate_button()

	# 5. Interact Button
	var interact_is_new = not _root.has_node("InteractBtn")
	_interact_btn = _make_circle_btn("InteractBtn", "🖐️", 70, C_BTN_NORM)
	_interact_btn.add_theme_font_size_override("font_size", 32)
	if interact_is_new:
		_interact_btn.set_anchor(SIDE_RIGHT, 1.0)
		_interact_btn.set_anchor(SIDE_BOTTOM, 1.0)
		_interact_btn.set_anchor(SIDE_LEFT, 1.0)
		_interact_btn.set_anchor(SIDE_TOP, 1.0)
		_interact_btn.offset_right  = -40
		_interact_btn.offset_bottom = -300
		_interact_btn.offset_left   = -110
		_interact_btn.offset_top    = -370
	_interact_btn.visible = false
	_interact_btn.pressed.connect(func(): AudioManager.play_sfx("dialogue_button")); _interact_btn.pressed.connect(_on_interact_pressed)



	# Menu Button (Top Right)
	var menu_is_new = not _root.has_node("MenuBtn")
	_menu_btn = _make_circle_btn("MenuBtn", "", 56, C_BTN_NORM)
	_menu_btn.set_anchor(SIDE_RIGHT, 1.0)
	_menu_btn.set_anchor(SIDE_TOP, 0.0)
	_menu_btn.set_anchor(SIDE_LEFT, 1.0)
	_menu_btn.set_anchor(SIDE_BOTTOM, 0.0)
	_menu_btn.offset_right  = -220
	_menu_btn.offset_top    = 24
	_menu_btn.offset_left   = -276
	_menu_btn.offset_bottom = 80
	_menu_btn.pressed.connect(func(): AudioManager.play_sfx("pause_button")); _menu_btn.pressed.connect(_toggle_menu)
	_menu_btn.draw.connect(_draw_pause_icon)

	# Knowledge Button (Top Right, left of Menu Button)
	var knowledge_is_new = not _root.has_node("KnowledgeBtn")
	_knowledge_btn = _make_circle_btn("KnowledgeBtn", "📖", 56, C_BTN_NORM)
	_knowledge_btn.add_theme_font_size_override("font_size", 28)
	_knowledge_btn.set_anchor(SIDE_RIGHT, 1.0)
	_knowledge_btn.set_anchor(SIDE_TOP, 0.0)
	_knowledge_btn.set_anchor(SIDE_LEFT, 1.0)
	_knowledge_btn.set_anchor(SIDE_BOTTOM, 0.0)
	_knowledge_btn.offset_right  = -220
	_knowledge_btn.offset_top    = 96
	_knowledge_btn.offset_left   = -276
	_knowledge_btn.offset_bottom = 152
		
	_knowledge_badge = _root.find_child("NotificationBadge", true, false)
	if not is_instance_valid(_knowledge_badge):
		_knowledge_badge = Label.new()
		_knowledge_badge.name = "NotificationBadge"
		_knowledge_badge.add_theme_font_size_override("font_size", 14)
		_knowledge_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_knowledge_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var badge_style = StyleBoxFlat.new()
		badge_style.bg_color = Color(0.9, 0.2, 0.2)
		badge_style.corner_radius_top_left = 12
		badge_style.corner_radius_top_right = 12
		badge_style.corner_radius_bottom_left = 12
		badge_style.corner_radius_bottom_right = 12
		badge_style.content_margin_left = 6
		badge_style.content_margin_right = 6
		_knowledge_badge.add_theme_stylebox_override("normal", badge_style)
		_knowledge_badge.custom_minimum_size = Vector2(24, 24)
		_knowledge_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_knowledge_badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_knowledge_badge.grow_vertical = Control.GROW_DIRECTION_END
		_knowledge_badge.offset_right = 4
		_knowledge_badge.offset_top = -4
		_knowledge_badge.visible = false
		_knowledge_btn.add_child(_knowledge_badge)
		
	_knowledge_btn.pressed.connect(func(): AudioManager.play_sfx("knowledge_button")); _knowledge_btn.pressed.connect(_open_knowledge_menu)

	# Quest Button (Top Right, left of Knowledge Button)
	var quest_is_new = not _root.has_node("QuestBtn")
	_quest_btn = _make_circle_btn("QuestBtn", "💬", 56, C_BTN_NORM)
	_quest_btn.add_theme_font_size_override("font_size", 28)
	_quest_btn.set_anchor(SIDE_RIGHT, 1.0)
	_quest_btn.set_anchor(SIDE_TOP, 0.0)
	_quest_btn.set_anchor(SIDE_LEFT, 1.0)
	_quest_btn.set_anchor(SIDE_BOTTOM, 0.0)
	# Position it vertically below knowledge btn
	_quest_btn.offset_right  = -220
	_quest_btn.offset_top    = 168
	_quest_btn.offset_left   = -276
	_quest_btn.offset_bottom = 224
	_quest_btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	_quest_btn.pressed.connect(_open_quest_menu)

	# Camera Toggle Button (Top Right, below Quest Button)
	var cam_btn_is_new = not _root.has_node("CamToggleBtn")
	var _cam_toggle_btn = _make_circle_btn("CamToggleBtn", "🎥", 56, C_BTN_NORM)
	_cam_toggle_btn.add_theme_font_size_override("font_size", 28)
	_cam_toggle_btn.set_anchor(SIDE_RIGHT, 1.0)
	_cam_toggle_btn.set_anchor(SIDE_TOP, 0.0)
	_cam_toggle_btn.set_anchor(SIDE_LEFT, 1.0)
	_cam_toggle_btn.set_anchor(SIDE_BOTTOM, 0.0)
	_cam_toggle_btn.offset_right  = -220
	_cam_toggle_btn.offset_top    = 240
	_cam_toggle_btn.offset_left   = -276
	_cam_toggle_btn.offset_bottom = 296
	_cam_toggle_btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	_cam_toggle_btn.pressed.connect(func():
		var event = InputEventAction.new()
		event.action = "toggle_camera"
		event.pressed = true
		Input.parse_input_event(event)
	)



# ── Menu Panel (Centered) ─────────────────────────────────────────────────────

func _build_menu_panel() -> void:
	if _root.has_node("MenuPanel"):
		var old_menu = _root.get_node("MenuPanel")
		old_menu.name = "MenuPanel_Old"
		old_menu.queue_free()

	var tech_font := SystemFont.new()
	tech_font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "Courier New", "monospace"])

	_menu_panel = Control.new()
	_menu_panel.name = "MenuPanel"
	_menu_panel.visible = false
	_menu_panel.modulate.a = 0.0
	
	_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	_menu_panel.custom_minimum_size = Vector2(360, 440)
	_menu_panel.offset_left   = -180
	_menu_panel.offset_right  = 180
	_menu_panel.offset_top    = -220
	_menu_panel.offset_bottom = 220

	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0.02, 0.04, 0.08, 0.95)
	panel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_panel.add_child(panel_bg)
	
	var scanlines := ColorRect.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	var scan_mat := ShaderMaterial.new()
	scan_mat.shader = load("res://ui/scanlines.gdshader")
	scanlines.material = scan_mat
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_panel.add_child(scanlines)
	
	var borders := Control.new()
	borders.set_anchors_preset(Control.PRESET_FULL_RECT)
	borders.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b_script := GDScript.new()
	b_script.source_code = "extends Control\nfunc _draw():\n\tvar c = Color(0.1, 0.9, 0.7, 0.9)\n\tvar r = get_rect().size\n\tvar l = 16.0\n\tvar t = 2.0\n\tdraw_rect(Rect2(0,0,l,t), c); draw_rect(Rect2(0,0,t,l), c)\n\tdraw_rect(Rect2(r.x-l,0,l,t), c); draw_rect(Rect2(r.x-t,0,t,l), c)\n\tdraw_rect(Rect2(0,r.y-t,l,t), c); draw_rect(Rect2(0,r.y-l,t,l), c)\n\tdraw_rect(Rect2(r.x-l,r.y-t,l,t), c); draw_rect(Rect2(r.x-t,r.y-l,t,l), c)\n\tvar c2 = Color(0.1, 0.9, 0.7, 0.4)\n\tfor p in [Vector2(20,20), Vector2(r.x-20,20), Vector2(20,r.y-20), Vector2(r.x-20,r.y-20)]:\n\t\tdraw_line(p-Vector2(6,0), p+Vector2(6,0), c2, 1)\n\t\tdraw_line(p-Vector2(0,6), p+Vector2(0,6), c2, 1)"
	b_script.reload()
	borders.set_script(b_script)
	_menu_panel.add_child(borders)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_menu_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title := _make_label("PAUSED", 24, Color(0.1, 0.9, 0.7))
	title.add_theme_font_override("font", tech_font)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.1, 0.9, 0.7, 0.3)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	var style_btn = func(b: Button, color: Color = Color(0.8, 1.0, 0.9)):
		b.add_theme_font_override("font", tech_font)
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", color)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.08, 0.12, 0.9)
		sb.border_color = color * 0.4
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(0)
		b.add_theme_stylebox_override("normal", sb)
		var sb_h := sb.duplicate()
		sb_h.bg_color = Color(0.1, 0.3, 0.25, 0.9)
		sb_h.border_color = color
		b.add_theme_stylebox_override("hover", sb_h)
		b.add_theme_stylebox_override("pressed", sb_h)

	var btn_resume := _panel_btn("Resume Game")
	btn_resume.name = "BtnResume"
	btn_resume.pressed.connect(func(): AudioManager.play_sfx("resume_button")); btn_resume.pressed.connect(_toggle_menu)
	style_btn.call(btn_resume, Color(0.1, 0.9, 0.7))
	vbox.add_child(btn_resume)

	var btn_settings := _panel_btn("Settings")
	btn_settings.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	btn_settings.pressed.connect(func():
		var settings = preload("res://ui/settings_menu.gd").new()
		_root.add_child(settings)
	)
	style_btn.call(btn_settings)
	vbox.add_child(btn_settings)

	var btn_save := _panel_btn("Save Game")
	btn_save.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	btn_save.pressed.connect(func():
		PlayerData.save_game()
		btn_save.text = "Saved!"
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_instance_valid(btn_save):
				btn_save.text = "Save Game"
		)
	)
	style_btn.call(btn_save)
	vbox.add_child(btn_save)

	var btn_quit := _panel_btn("Main Menu", Color(1.0, 0.2, 0.3))
	btn_quit.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	btn_quit.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
	style_btn.call(btn_quit, Color(1.0, 0.2, 0.3))
	vbox.add_child(btn_quit)

	_root.add_child(_menu_panel)

func _build_quest_panel() -> void:
	if has_node("QuestPanel"):
		var old_quest = find_child("QuestPanel", true, false)
		if old_quest:
			old_quest.name = "QuestPanel_Old"
			old_quest.queue_free()
		
	_quest_panel = PanelContainer.new()
	_quest_panel.name = "QuestPanel"
	_quest_panel.visible = false
	
	_quest_panel.set_anchors_preset(Control.PRESET_CENTER)
	_quest_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_quest_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_quest_panel.custom_minimum_size = Vector2(500, 400)
	
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.05, 0.07, 0.95)
	bg.border_color = Color(0.1, 0.8, 0.9, 0.6)
	bg.set_border_width_all(1)
	bg.border_width_top = 4
	bg.set_corner_radius_all(12)
	bg.content_margin_left = 32
	bg.content_margin_right = 32
	bg.content_margin_top = 32
	bg.content_margin_bottom = 32
	_quest_panel.add_theme_stylebox_override("panel", bg)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_quest_panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "DIALOGUE LOG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	vbox.add_child(title)
	
	var desc := RichTextLabel.new()
	desc.name = "QuestDesc"
	desc.bbcode_enabled = true
	desc.fit_content = false
	desc.scroll_active = true
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("normal_font_size", 18)
	desc.text = ""
	vbox.add_child(desc)
	
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	close_btn.pressed.connect(func(): _quest_panel.visible = false)
	vbox.add_child(close_btn)
	
	add_child(_quest_panel)

func _open_quest_menu() -> void:
	if not _quest_panel:
		_build_quest_panel()
	
	var desc = _quest_panel.find_child("QuestDesc", true, false)
	if desc and desc is RichTextLabel:
		var full_text = ""
		for msg in PlayerData.message_log:
			full_text += msg + "\n\n"
			
		if full_text == "":
			full_text = "No dialogue yet."
			
		desc.text = full_text
		
	_quest_panel.visible = true
	
	if desc and desc is RichTextLabel:
		await get_tree().process_frame
		var scrollbar = desc.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value = scrollbar.max_value

# ── Tutorial / Subtitle Panels ────────────────────────────────────────────────────────────

func _build_tutorial_panel() -> void:
	if _root.has_node("TutorialPanel"):
		_tutorial_panel = _root.find_child("TutorialPanel", true, false)
		_tutorial_title = _root.find_child("TutorialTitle", true, false)
		_tutorial_desc = _root.find_child("TutorialDesc", true, false)
		var btn = _root.find_child("BtnGotIt", true, false)
		if btn and not btn.pressed.is_connected(_hide_tutorial):
			btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
			btn.pressed.connect(_hide_tutorial)
		return

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "TutorialPanel"
	_tutorial_panel.visible = false
	_tutorial_panel.modulate.a = 0.0
	
	_tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	_tutorial_panel.custom_minimum_size = Vector2(400, 0)
	_tutorial_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tutorial_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	bg.border_color = Color(0.1, 0.9, 0.7, 0.6)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(0)
	bg.shadow_color = Color(0, 0, 0, 0.6)
	bg.shadow_size = 20
	bg.content_margin_left   = 32.0
	bg.content_margin_right  = 32.0
	bg.content_margin_top    = 32.0
	bg.content_margin_bottom = 32.0
	_tutorial_panel.add_theme_stylebox_override("panel", bg)

	var tech_font := SystemFont.new()
	tech_font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "Courier New", "monospace"])

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 24)
	_tutorial_panel.add_child(vbox)

	_tutorial_title = _make_label("TUTORIAL", 24, Color(0.1, 0.9, 0.7))
	_tutorial_title.name = "TutorialTitle"
	_tutorial_title.add_theme_font_override("font", tech_font)
	_tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_tutorial_title)

	_tutorial_desc = _make_label("Tutorial text goes here.", 18, Color(0.8, 1.0, 0.9))
	_tutorial_desc.name = "TutorialDesc"
	_tutorial_desc.add_theme_font_override("font", tech_font)
	_tutorial_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_tutorial_desc)

	var btn_got_it := _panel_btn("ACKNOWLEDGE", Color(0.1, 0.9, 0.7))
	btn_got_it.name = "BtnGotIt"
	btn_got_it.add_theme_font_override("font", tech_font)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.12, 0.9)
	sb.border_color = Color(0.1, 0.9, 0.7, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	btn_got_it.add_theme_stylebox_override("normal", sb)
	
	var sb_h := sb.duplicate()
	sb_h.bg_color = Color(0.1, 0.3, 0.25, 0.9)
	sb_h.border_color = Color(0.1, 0.9, 0.7)
	btn_got_it.add_theme_stylebox_override("hover", sb_h)
	btn_got_it.add_theme_stylebox_override("pressed", sb_h)
	
	btn_got_it.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	btn_got_it.pressed.connect(_hide_tutorial)
	btn_got_it.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	vbox.add_child(btn_got_it)

	_root.add_child(_tutorial_panel)

func show_tutorial(title: String, text: String) -> void:
	_tutorial_title.text = title
	_tutorial_desc.text = text
	get_tree().paused = true
	_tutorial_panel.modulate.a = 0.0
	_tutorial_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_tutorial_panel, "modulate:a", 1.0, 0.2)

func _hide_tutorial() -> void:
	if _walkthrough_steps.size() > 0 and _current_step_index < _walkthrough_steps.size():
		_advance_walkthrough_step()
		return
		
	var tw := create_tween()
	tw.tween_property(_tutorial_panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		_tutorial_panel.visible = false
		get_tree().paused = false
		tutorial_dismissed.emit()
		tutorial_complete.emit()
	)


# \u2500\u2500 Interactive Spotlight Tutorial \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

var _tut_overlay: ColorRect = null
var _tut_panel: PanelContainer = null
var _tut_title_lbl: Label = null
var _tut_desc_lbl: RichTextLabel = null
var _tut_tap_hint: Label = null
var _tut_tap_overlay: Button = null   # Invisible tap catcher placed over the target
var _tut_active: bool = false

func start_tutorial() -> void:
	if PlayerData.has_seen_prologue:
		return
	_tut_active = true
	get_tree().paused = false
	
	# ── Build the dim overlay ──
	_tut_overlay = ColorRect.new()
	_tut_overlay.name = "TutOverlay"
	_tut_overlay.color = Color(0, 0, 0, 0)
	_tut_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tut_overlay.z_index = 50
	_tut_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_tut_overlay)

	# ── Build the floating tooltip ──
	_tut_panel = PanelContainer.new()
	_tut_panel.name = "TutTooltip"
	_tut_panel.z_index = 80
	_tut_panel.visible = false
	_tut_panel.custom_minimum_size = Vector2(320, 0)
	_tut_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tp_bg = StyleBoxFlat.new()
	tp_bg.bg_color = Color(0.02, 0.05, 0.08, 0.96)
	tp_bg.border_color = Color(0.1, 0.9, 0.7, 0.9)
	tp_bg.set_border_width_all(2)
	tp_bg.set_corner_radius_all(10)
	tp_bg.shadow_color = Color(0, 0, 0, 0.5)
	tp_bg.shadow_size = 12
	tp_bg.content_margin_left = 20
	tp_bg.content_margin_right = 20
	tp_bg.content_margin_top = 16
	tp_bg.content_margin_bottom = 16
	_tut_panel.add_theme_stylebox_override("panel", tp_bg)
	var tp_vbox = VBoxContainer.new()
	tp_vbox.add_theme_constant_override("separation", 8)
	tp_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_panel.add_child(tp_vbox)
	_tut_title_lbl = Label.new()
	_tut_title_lbl.add_theme_font_size_override("font_size", 20)
	_tut_title_lbl.add_theme_color_override("font_color", Color(0.1, 0.9, 0.7))
	_tut_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tp_vbox.add_child(_tut_title_lbl)
	var sep = HSeparator.new()
	var sep_s = StyleBoxLine.new()
	sep_s.color = Color(0.1, 0.9, 0.7, 0.3)
	sep.add_theme_stylebox_override("separator", sep_s)
	tp_vbox.add_child(sep)
	_tut_desc_lbl = RichTextLabel.new()
	_tut_desc_lbl.bbcode_enabled = true
	_tut_desc_lbl.fit_content = true
	_tut_desc_lbl.scroll_active = false
	_tut_desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_desc_lbl.add_theme_font_size_override("normal_font_size", 16)
	_tut_desc_lbl.custom_minimum_size = Vector2(280, 0)
	tp_vbox.add_child(_tut_desc_lbl)
	_tut_tap_hint = Label.new()
	_tut_tap_hint.add_theme_font_size_override("font_size", 14)
	_tut_tap_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_tut_tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tp_vbox.add_child(_tut_tap_hint)
	_root.add_child(_tut_panel)

	# Invisible tap catcher
	_tut_tap_overlay = Button.new()
	_tut_tap_overlay.name = "TutTapOverlay"
	_tut_tap_overlay.z_index = 70
	_tut_tap_overlay.visible = false
	_tut_tap_overlay.flat = true
	_tut_tap_overlay.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_tut_tap_overlay.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_tut_tap_overlay.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_tut_tap_overlay.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	_root.add_child(_tut_tap_overlay)

	# \u2500\u2500 Run all steps \u2500\u2500
	await _tut_welcome()
	var badge = _root.find_child("Badge", true, false)
	await _tut_spotlight(badge,
		"YOUR LEVEL BADGE",
		"This badge shows your [color=#ffcc00]Level[/color].\n\nThe golden ring is your [color=#ffcc00]EXP progress[/color] to the next level.\n\n[b]Tap it[/b] to explore your character stats!",
		"Tap the badge to continue")
	# After badge is tapped \u2192 open character menu sub-tutorial
	await _tut_character_menu()

	await _tut_spotlight(_hp_bar,
		"HEALTH BAR",
		"The [color=#ff3b5c]red bar[/color] is your [b]Health[/b].\nIf it reaches zero, you go down.\n\nKeep it above zero at all times.",
		"Tap the bar to continue")

	await _tut_spotlight(_stam_bar,
		"STAMINA BAR",
		"The [color=#9400ff]purple bar[/color] is your [b]Stamina[/b].\n\nJump and Tongue Whip both consume it. It regenerates automatically when you stop using abilities.",
		"Tap the bar to continue")

	await _tut_spotlight(_objective_panel,
		"CURRENT OBJECTIVE",
		"This shows your [b]current mission[/b].\n\nAlways check here if you're unsure of what to do next.",
		"Tap the objective to continue")

	await _tut_spotlight(_minimap_panel,
		"MINIMAP",
		"The [b]minimap[/b] shows a bird's-eye view.\n\n[b]Tap it[/b] to expand it to a full map.",
		"Tap the minimap to continue")

	var mm_event = InputEventMouseButton.new()
	mm_event.button_index = MOUSE_BUTTON_LEFT
	mm_event.pressed = true
	_on_minimap_gui_input(mm_event)
	mm_event.pressed = false
	_on_minimap_gui_input(mm_event)
	await get_tree().create_timer(0.4).timeout

	await _tut_spotlight_in_canvas(_minimap_panel, self, "FULL MAP", "Drag to pan around.\n\n[color=#00ccff]Cyan[/color] dot = you. [color=#ff3333]Red triangles[/color] = enemies.\n\n[b]Tap the map again[/b] to close it.", "Tap the map to close")
	
	mm_event.pressed = true
	_on_minimap_gui_input(mm_event)
	mm_event.pressed = false
	_on_minimap_gui_input(mm_event)
	await get_tree().create_timer(0.4).timeout

	await _tut_spotlight(_menu_btn,
		"PAUSE MENU",
		"Opens the system menu.\n\n[b]Tap it[/b] to view your options.",
		"Tap the pause button to continue")
		
	_toggle_menu()
	await get_tree().process_frame
	
	var resume_btn = _menu_panel.find_child("RESUME", true, false)
	if resume_btn:
		await _tut_spotlight_in_canvas(resume_btn, self, "SYSTEM OPTIONS", "\u2022 Adjust graphics quality\n\u2022 Save your progress\n\u2022 Return to Main Menu\n\n[b]Tap RESUME[/b] to close the menu.", "Tap RESUME to continue")
	
	if _menu_open:
		_toggle_menu()
	await get_tree().create_timer(0.2).timeout

	await _tut_spotlight(_knowledge_btn,
		"KNOWLEDGE LOG \ud83d\udcd6",
		"Collecting Genome Fragments unlocks entries about the world.\n\n[b]Tap the book[/b] to open the Knowledge Log.",
		"Tap the book to continue")
		
	_open_knowledge_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	
	var k_menu = _root.get_children().filter(func(c): return c is KnowledgeMenu)
	if not k_menu.is_empty():
		var k_menu_node = k_menu[0]
		var close_btn = k_menu_node.find_child("CLOSE", true, false)
		if not close_btn:
			for c in k_menu_node.get_children():
				var b = c.find_child("CLOSE", true, false)
				if b: close_btn = b; break
		if close_btn:
			await _tut_spotlight_in_canvas(close_btn, k_menu_node, "LORE & TRAITS", "Read about characters, locations, and enemy species here.\n\n[b]Tap CLOSE[/b] to return to the field.", "Tap CLOSE to continue")
		if is_instance_valid(k_menu_node) and k_menu_node.has_method("_on_close"):
			k_menu_node._on_close()
	await get_tree().process_frame

	await _tut_spotlight(_quest_btn,
		"DIALOGUE LOG \ud83d\udcac",
		"Review all past transmissions.\n\n[b]Tap the chat icon[/b] to open the log.",
		"Tap the chat icon to continue")
		
	_open_quest_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	
	if is_instance_valid(_quest_panel):
		var close_btn = _quest_panel.find_child("CLOSE", true, false)
		if not close_btn:
			for c in _quest_panel.get_children():
				var b = c.find_child("CLOSE", true, false)
				if b: close_btn = b; break
		if close_btn:
			await _tut_spotlight_in_canvas(close_btn, self, "TRANSMISSION HISTORY", "If you miss a message during gameplay, check here to catch up.\n\n[b]Tap CLOSE[/b] to return.", "Tap CLOSE to continue")
		if is_instance_valid(_quest_panel):
			_quest_panel.visible = false
	await get_tree().process_frame

	await _tut_spotlight(_jump_btn,
		"SPLASHDOWN JUMP \ud83e\uddb8",
		"[b]Tap[/b] for a quick hop.\n\n[b]Hold + drag[/b] to aim a directed jump, release to launch.\n\nDrag into the red [b]CANCEL ZONE[/b] that appears above to abort the jump safely.",
		"Tap the jump button to continue")

	await _tut_spotlight(_attack_btn,
		"PRIMARY ATTACK \ud83e\uddb5",
		"Performs a [b]Webbed Lunge[/b] \u2014 a powerful melee strike.\n\nDisrupts mosquito swarms and staggers ground enemies.\n\n[color=#00ff88]No stamina cost.[/color]",
		"Tap the attack button to continue")

	await _tut_spotlight(_skill1_btn,
		"TONGUE WHIP \ud83d\udc45",
		"A [b]ranged strike[/b] with longer reach than the lunge.\n\nConsumes [color=#9400ff]Stamina[/color]. The button dims when stamina is too low.\n\nWait for stamina to recover before using again.",
		"Tap the tongue button to continue")

	await _tut_spotlight(_skill3_btn,
		"ULTIMATE \u2014 LOCKED \u2620\ufe0f",
		"Your [b]Ultimate Ability[/b] is currently locked.\n\n[color=#33ff88]Genome Fragments[/color] help reconstruct your suit.\n\n[b]Species genomes[/b], like the Salamander genome, unlock new forms. Follow your objectives to discover them.",
		"Tap to acknowledge")

	await _tut_finish()

	# Clean up
	if is_instance_valid(_tut_overlay): _tut_overlay.queue_free()
	if is_instance_valid(_tut_panel): _tut_panel.queue_free()
	if is_instance_valid(_tut_tap_overlay): _tut_tap_overlay.queue_free()
	_tut_active = false
	PlayerData.has_seen_prologue = true
	tutorial_complete.emit()


func _tut_welcome() -> void:
	# Dim gently then show a welcome tooltip at screen center
	var tw = create_tween()
	tw.tween_property(_tut_overlay, "color:a", 0.75, 0.4)
	await tw.finished

	_tut_title_lbl.text = "HUD SYSTEM INITIALIZED"
	_tut_desc_lbl.text = "Your suit has booted. The heads-up display is now active.\n\n[b]Tap anywhere[/b] to begin the briefing."
	_tut_tap_hint.text = ""
	var vp = get_viewport().get_visible_rect().size
	await get_tree().process_frame
	_tut_panel.position = (vp - _tut_panel.size) / 2.0
	_tut_panel.visible = true
	_tut_panel.modulate.a = 0.0
	var tw2 = create_tween()
	tw2.tween_property(_tut_panel, "modulate:a", 1.0, 0.3)
	await tw2.finished

	# Full-screen tap catcher
	_tut_tap_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tut_tap_overlay.visible = true
	await _tut_tap_overlay.pressed

	_tut_tap_overlay.visible = false
	_tut_panel.visible = false


func _tut_spotlight(target: Control, title: String, desc: String, hint: String) -> void:
	if not is_instance_valid(target):
		return

	# Elevate target above dim overlay
	var old_z = target.z_index
	target.z_index = 65

	# Dim overlay if not already visible
	if _tut_overlay.color.a < 0.5:
		var tw = create_tween()
		tw.tween_property(_tut_overlay, "color:a", 0.75, 0.3)
		await tw.finished

	# Position tooltip: prefer below the target, but clamp to screen
	await get_tree().process_frame
	var vp = get_viewport().get_visible_rect().size
	var tr = target.get_global_rect()
	_tut_title_lbl.text = title
	_tut_desc_lbl.text = desc
	_tut_tap_hint.text = "\u25bc " + hint
	_tut_panel.visible = true
	_tut_panel.modulate.a = 0.0
	await get_tree().process_frame  # let it size itself
	var tp_size = _tut_panel.size
	var pos = Vector2(tr.position.x, tr.position.y + tr.size.y + 12)
	# Right-align if target is near right edge
	if pos.x + tp_size.x > vp.x - 10:
		pos.x = vp.x - tp_size.x - 10
	# If tooltip goes off bottom, put it above the target
	if pos.y + tp_size.y > vp.y - 10:
		pos.y = tr.position.y - tp_size.y - 12
	# Clamp
	pos.x = clamp(pos.x, 8, vp.x - tp_size.x - 8)
	pos.y = clamp(pos.y, 8, vp.y - tp_size.y - 8)
	_tut_panel.position = pos
	var tw2 = create_tween()
	tw2.tween_property(_tut_panel, "modulate:a", 1.0, 0.25)
	await tw2.finished

	# Pulsing highlight on target
	highlight_node(target)

	# Place invisible tap catcher exactly over the target
	_tut_tap_overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_tut_tap_overlay.position = tr.position
	_tut_tap_overlay.size = tr.size
	_tut_tap_overlay.visible = true
	await _tut_tap_overlay.pressed

	# Clean up this step
	stop_highlight_node(target)
	target.z_index = old_z
	_tut_tap_overlay.visible = false
	var tw3 = create_tween()
	tw3.tween_property(_tut_panel, "modulate:a", 0.0, 0.2)
	await tw3.finished
	_tut_panel.visible = false


func _tut_character_menu() -> void:
	# Open the character menu
	get_tree().paused = false
	_open_character_menu()
	# Wait one frame for the menu to be added to the tree
	await get_tree().process_frame
	await get_tree().process_frame

	var menu = _root.get_children().filter(func(c): return c is CharacterMenu)
	if menu.is_empty():
		return
	var char_menu: CharacterMenu = menu[0]
	var tab_container = char_menu.find_child("TabContainer", true, false) as TabContainer
	if not tab_container:
		return

	# Sub-tutorial: highlight each tab
	var tab_data = [
		["STATS TAB", "This tab shows your [b]character statistics[/b]:\n\n[color=#ffcc00]Level[/color], [color=#ff3b5c]Health[/color], [color=#9400ff]Stamina[/color], [color=#ff8833]Attack Power[/color], [color=#33aaff]Defense[/color], [color=#44ff44]Speed[/color].\n\n[b]Tap the STATS tab[/b] to view it."],
		["SKILLS TAB", "Here you can spend [color=#ffcc00]Skill Points[/color] earned from leveling up.\n\nUpgrade Vitality, Endurance, and Attack Power.\n\n[b]Tap the SKILLS tab[/b] to view it."],
		["INVENTORY TAB", "This shows everything you are carrying.\n\n[color=#33ff88]Genome Fragments[/color] collected will appear here.\n\n[b]Tap the INVENTORY tab[/b] to view it."],
	]
	for i in range(tab_data.size()):
		var tab_btn = _get_tab_button(tab_container, i)
		if tab_btn:
			await _tut_spotlight_in_canvas(tab_btn, char_menu, tab_data[i][0], tab_data[i][1], "Tap the tab to continue")
			tab_container.current_tab = i

	# Prompt to close
	var close_btn = char_menu.find_child("CLOSE", true, false) as Button
	if not close_btn:
		# find by text
		for c in char_menu.get_children():
			var b = c.find_child("CLOSE", true, false)
			if b: close_btn = b; break
	if close_btn:
		await _tut_spotlight_in_canvas(close_btn, char_menu, "CLOSE THE MENU", "Good! You now know how to read your character stats.\n\n[b]Tap CLOSE[/b] to return to the field.", "Tap CLOSE to continue")

	# Ensure menu is closed
	if is_instance_valid(char_menu):
		char_menu._on_close()
	await get_tree().process_frame


func _tut_spotlight_in_canvas(target: Control, canvas: Node, title: String, desc: String, hint: String) -> void:
	if not is_instance_valid(target): return

	var need_reparent = (canvas != self and canvas != _root)
	if need_reparent:
		if _tut_overlay.get_parent(): _tut_overlay.get_parent().remove_child(_tut_overlay)
		canvas.add_child(_tut_overlay)
		if _tut_panel.get_parent(): _tut_panel.get_parent().remove_child(_tut_panel)
		canvas.add_child(_tut_panel)
		if _tut_tap_overlay.get_parent(): _tut_tap_overlay.get_parent().remove_child(_tut_tap_overlay)
		canvas.add_child(_tut_tap_overlay)

	var old_z = target.z_index
	target.z_index = 65

	if _tut_overlay.color.a < 0.5:
		var tw = create_tween()
		tw.tween_property(_tut_overlay, "color:a", 0.75, 0.3)
		await tw.finished

	await get_tree().process_frame
	var vp = get_viewport().get_visible_rect().size
	var tr = target.get_global_rect()
	_tut_title_lbl.text = title
	_tut_desc_lbl.text = desc
	_tut_tap_hint.text = "\u25bc " + hint
	_tut_panel.visible = true
	_tut_panel.modulate.a = 0.0
	await get_tree().process_frame
	var tp_size = _tut_panel.size
	var pos = Vector2(tr.position.x, tr.position.y + tr.size.y + 12)
	if pos.x + tp_size.x > vp.x - 10: pos.x = vp.x - tp_size.x - 10
	if pos.y + tp_size.y > vp.y - 10: pos.y = tr.position.y - tp_size.y - 12
	pos.x = clamp(pos.x, 8, vp.x - tp_size.x - 8)
	pos.y = clamp(pos.y, 8, vp.y - tp_size.y - 8)
	_tut_panel.position = pos
	var tw2 = create_tween()
	tw2.tween_property(_tut_panel, "modulate:a", 1.0, 0.25)
	await tw2.finished

	highlight_node(target)

	_tut_tap_overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_tut_tap_overlay.position = tr.position
	_tut_tap_overlay.size = tr.size
	_tut_tap_overlay.visible = true
	await _tut_tap_overlay.pressed

	stop_highlight_node(target)
	target.z_index = old_z
	_tut_tap_overlay.visible = false
	var tw3 = create_tween()
	tw3.tween_property(_tut_panel, "modulate:a", 0.0, 0.2)
	await tw3.finished
	_tut_panel.visible = false

	if need_reparent and is_instance_valid(_root):
		if _tut_overlay.get_parent(): _tut_overlay.get_parent().remove_child(_tut_overlay)
		_root.add_child(_tut_overlay)
		if _tut_panel.get_parent(): _tut_panel.get_parent().remove_child(_tut_panel)
		_root.add_child(_tut_panel)
		if _tut_tap_overlay.get_parent(): _tut_tap_overlay.get_parent().remove_child(_tut_tap_overlay)
		_root.add_child(_tut_tap_overlay)


func _tut_finish() -> void:
	_tut_title_lbl.text = "FIELD BRIEFING COMPLETE"
	_tut_desc_lbl.text = "Your suit is ready, Volunteer. Sterling is standing by on comms.\n\nFollow your [color=#33ff88]current objective[/color] to help the wetland and search for lost genomes.\n\n[b]Fragments repair the suit. Species genomes unlock forms.[/b]"
	_tut_tap_hint.text = "\u25bc Tap anywhere to begin"
	var vp = get_viewport().get_visible_rect().size
	await get_tree().process_frame
	_tut_panel.position = (vp - _tut_panel.size) / 2.0
	_tut_panel.visible = true
	_tut_panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_tut_panel, "modulate:a", 1.0, 0.3)
	await tw.finished

	_tut_tap_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tut_tap_overlay.visible = true
	await _tut_tap_overlay.pressed
	_tut_tap_overlay.visible = false

	var tw2 = create_tween().set_parallel(true)
	tw2.tween_property(_tut_panel, "modulate:a", 0.0, 0.4)
	tw2.tween_property(_tut_overlay, "color:a", 0.0, 0.4)
	await tw2.finished
	_tut_panel.visible = false


func _get_tab_button(tab_container: TabContainer, index: int) -> Control:
	# TabContainer's tab bar is a child of type TabBar
	for child in tab_container.get_children():
		if child.get_class() == "TabBar":
			# Each tab is accessible via the tab bar
			return child
	# Fallback: return the tab container itself if tab bar not found
	return tab_container


# ── Subtitle System ───────────────────────────────────────────────────────────

func _build_subtitle_panel() -> void:
	if _root.has_node("SubtitlePanel"):
		_subtitle_panel = _root.find_child("SubtitlePanel", true, false)
		_subtitle_label = _root.find_child("SubtitleLabel", true, false)
		return

	_subtitle_panel = PanelContainer.new()
	_subtitle_panel.name = "SubtitlePanel"
	_subtitle_panel.visible = false
	_subtitle_panel.modulate.a = 0.0
	
	_subtitle_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle_panel.custom_minimum_size = Vector2(800, 100)
	
	_subtitle_panel.set_anchor(SIDE_LEFT, 0.5)
	_subtitle_panel.set_anchor(SIDE_RIGHT, 0.5)
	_subtitle_panel.set_anchor(SIDE_BOTTOM, 1.0)
	_subtitle_panel.offset_left = -400
	_subtitle_panel.offset_right = 400
	_subtitle_panel.offset_bottom = -40
	_subtitle_panel.offset_top = -40
	
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	bg.border_color = Color(0.1, 0.9, 0.7, 0.6)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(0)
	bg.content_margin_left   = 24.0
	bg.content_margin_right  = 24.0
	bg.content_margin_top    = 24.0
	bg.content_margin_bottom = 32.0
	_subtitle_panel.add_theme_stylebox_override("panel", bg)

	_subtitle_label = RichTextLabel.new()
	_subtitle_label.name = "SubtitleLabel"
	var tech_font := SystemFont.new()
	tech_font.font_names = PackedStringArray(["Rajdhani", "Orbitron", "Consolas", "Courier New", "monospace"])
	_subtitle_label.add_theme_font_override("normal_font", tech_font)
	_subtitle_label.add_theme_font_override("bold_font", tech_font)
	_subtitle_label.bbcode_enabled = true
	_subtitle_label.fit_content = true
	_subtitle_label.scroll_active = false
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_label.add_theme_font_size_override("normal_font_size", 24)
	_subtitle_label.add_theme_font_size_override("bold_font_size", 26)
	_subtitle_panel.add_child(_subtitle_label)

	_root.add_child(_subtitle_panel)
	
func _build_objective_panel() -> void:
	if _root.has_node("ObjectivePanel"):
		_objective_panel = _root.find_child("ObjectivePanel", true, false)
		_objective_lbl = _root.find_child("ObjectiveLabel", true, false)
		return
		
	_objective_panel = HBoxContainer.new()
	_objective_panel.name = "ObjectivePanel"
	_objective_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_objective_panel.gui_input.connect(_on_objective_gui_input)
	_objective_panel.add_theme_constant_override("separation", 8)

	# Same technical sans-serif family as the Investigation Card / Quest Log —
	# this only sets the default font (HBoxContainer has no "panel" stylebox
	# slot), so it can't accidentally add a background to the resting banner.
	var panel_suit_theme = load("res://ui/suit_theme.gd")
	if panel_suit_theme:
		_objective_panel.theme = panel_suit_theme.get_theme()

	_objective_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective_panel.position = Vector2(16, 160) # Below status/badges, slight indent

	_quest_accent_rect = ColorRect.new()
	_quest_accent_rect.custom_minimum_size = Vector2(3, 0)
	_quest_accent_rect.size_flags_vertical = Control.SIZE_FILL
	_objective_panel.add_child(_quest_accent_rect)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", -2)
	_objective_panel.add_child(vbox)
	
	var suit_theme = load("res://ui/suit_theme.gd")
	
	_quest_header_lbl = Label.new()
	_quest_header_lbl.text = "Quests"
	_quest_header_lbl.add_theme_font_size_override("font_size", 14)
	_quest_header_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_quest_header_lbl.add_theme_constant_override("shadow_offset_x", 0)
	_quest_header_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_quest_header_lbl.add_theme_constant_override("shadow_outline_size", 6)
	if suit_theme:
		_quest_header_lbl.add_theme_color_override("font_color", suit_theme.COLOR_TEXT_INACTIVE)
		_quest_accent_rect.color = suit_theme.COLOR_TEXT_INACTIVE
	vbox.add_child(_quest_header_lbl)
	
	_objective_lbl = Label.new()
	_objective_lbl.name = "ObjectiveLabel"
	_objective_lbl.text = ""
	_objective_lbl.add_theme_font_size_override("font_size", 20)
	_objective_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 0.95))
	_objective_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_objective_lbl.add_theme_constant_override("shadow_offset_x", 0)
	_objective_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_objective_lbl.add_theme_constant_override("shadow_outline_size", 6)
	vbox.add_child(_objective_lbl)
	
	_quest_desc_panel = PanelContainer.new()
	_quest_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var desc_style = StyleBoxFlat.new()
	desc_style.bg_color = Color(18/255.0, 32/255.0, 28/255.0, 0.75)
	desc_style.set_corner_radius_all(0)
	desc_style.corner_radius_top_right = 8
	desc_style.corner_radius_bottom_right = 8
	desc_style.content_margin_left = 12
	desc_style.content_margin_right = 12
	desc_style.content_margin_top = 8
	desc_style.content_margin_bottom = 8
	_quest_desc_panel.add_theme_stylebox_override("panel", desc_style)
	_quest_desc_panel.hide()
	
	var desc_vbox = VBoxContainer.new()
	_quest_desc_panel.add_child(desc_vbox)
	
	_quest_desc_lbl = Label.new()
	_quest_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_desc_lbl.custom_minimum_size = Vector2(250, 0)
	_quest_desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_vbox.add_child(_quest_desc_lbl)
	
	_quest_hint_lbl = Label.new()
	_quest_hint_lbl.text = "Tap again for quest log →"
	_quest_hint_lbl.add_theme_font_size_override("font_size", 12)
	if suit_theme:
		_quest_hint_lbl.add_theme_color_override("font_color", suit_theme.COLOR_ACCENT_YELLOW)
	desc_vbox.add_child(_quest_hint_lbl)
	
	vbox.add_child(_quest_desc_panel)
	
	_root.add_child(_objective_panel)

func _on_objective_updated(text: String) -> void:
	if not is_instance_valid(_objective_lbl) or not is_instance_valid(_quest_header_lbl) or not is_instance_valid(_quest_accent_rect): return
	
	var suit_theme = load("res://ui/suit_theme.gd")
	var color_active = suit_theme.COLOR_ACCENT_YELLOW if suit_theme else Color("#f2c94c")
	var color_inactive = suit_theme.COLOR_TEXT_INACTIVE if suit_theme else Color("#777777")
	
	if text.is_empty():
		_quest_header_lbl.text = "Quests"
		_quest_header_lbl.add_theme_color_override("font_color", color_inactive)
		_quest_accent_rect.color = color_inactive
		_objective_lbl.text = ""
		_objective_lbl.hide()
		if _quest_hud_state != 0: _set_quest_hud_state(0)
	else:
		_quest_header_lbl.text = "Quests ▾" if _quest_hud_state == 0 else "Quests ▴"
		_quest_header_lbl.add_theme_color_override("font_color", color_active)
		_quest_accent_rect.color = color_active
		_objective_lbl.text = text
		_objective_lbl.show()
		
	if PlayerData.current_objective_desc != "":
		_quest_desc_lbl.text = PlayerData.current_objective_desc
	else:
		_quest_desc_lbl.text = "No additional details."
	
	_subtitle_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

func _on_objective_gui_input(event: InputEvent) -> void:
	# Only InputEventScreenTouch is handled here — project.godot has
	# pointing/emulate_touch_from_mouse=true, so every mouse click ALSO
	# generates a synthetic touch event. Handling both meant a single tap
	# fired this twice in the same frame (state 0→1, then immediately 1→0
	# plus opening the Quest Log), skipping the in-place expand entirely.
	if event is InputEventScreenTouch:
		if event.is_pressed() and PlayerData.current_objective_text != "":
			AudioManager.play_sfx("tap_button")
			if _quest_hud_state == 0:
				_set_quest_hud_state(1)
			else:
				_set_quest_hud_state(0)
				_open_quest_log()

func _set_quest_hud_state(state: int) -> void:
	_quest_hud_state = state
	if state == 0:
		if PlayerData.current_objective_text != "":
			_quest_header_lbl.text = "Quests ▾"
		_quest_desc_panel.hide()
	else:
		_quest_header_lbl.text = "Quests ▴"
		_quest_desc_panel.show()

func _unhandled_input(event: InputEvent) -> void:
	# Same reasoning as _on_objective_gui_input — only handle the touch event,
	# since mouse clicks are also synthesized into touch events project-wide.
	if event is InputEventScreenTouch:
		if event.is_pressed() and _quest_hud_state == 1:
			var rect = _objective_panel.get_global_rect()
			if not rect.has_point(event.position):
				_set_quest_hud_state(0)
	
func _build_objective_arrow() -> void:
	if _root.has_node("ObjectiveArrow"):
		var arrow = _root.find_child("ObjectiveArrow", true, false)
		var update_arrow = func(target):
			if is_instance_valid(arrow):
				arrow.set("target_node", target)
		PlayerData.objective_changed.connect(update_arrow)
		arrow.tree_exited.connect(func(): 
			if PlayerData.objective_changed.is_connected(update_arrow):
				PlayerData.objective_changed.disconnect(update_arrow)
		)
		arrow.set("target_node", PlayerData.current_objective)
		return

	var arrow_script = GDScript.new()
	arrow_script.source_code = """extends Control
var target_node: Node3D = null

func _process(delta: float) -> void:
	if not is_instance_valid(target_node):
		visible = false
		return
		
	var cam = get_viewport().get_camera_3d()
	if not cam:
		visible = false
		return
		
	visible = true
	var center = get_viewport_rect().size / 2.0
	
	var actual_target: Node3D = target_node
	if "enemy_scene" in actual_target and actual_target.has_method("_activate_next_enemy"):
		var enemies = actual_target.get("_living_enemies")
		if enemies != null and enemies.size() > 0:
			var best = null
			for e in enemies:
				if is_instance_valid(e) and not e.is_queued_for_deletion():
					if "is_active" in e and e.is_active:
						best = e
						break
			if best == null:
				for e in enemies:
					if is_instance_valid(e) and not e.is_queued_for_deletion():
						best = e
						break
			if best != null:
				actual_target = best

	# Try to find screen pos
	var is_behind = cam.is_position_behind(actual_target.global_position)
	var screen_pos = cam.unproject_position(actual_target.global_position)
	
	var dir: Vector2
	var radius = 200.0
	
	if is_behind:
		# If behind, push the arrow to the edge of the screen opposite the target
		dir = (center - screen_pos).normalized()
	else:
		dir = (screen_pos - center).normalized()
		var dist = center.distance_to(screen_pos)
		# Bring the arrow closer if the target is near the center, up to a max of 200px
		radius = min(200.0, max(20.0, dist - 25.0))
		
	# Place arrow in a circle around center or closer to the target
	position = center + dir * radius
	rotation = dir.angle() + PI/2.0
	queue_redraw()

func _draw() -> void:
	# Draw a sleek triangle pointing UP (which means towards dir since we rotated by dir.angle() + PI/2)
	var points = PackedVector2Array([
		Vector2(0, -20),
		Vector2(-15, 15),
		Vector2(0, 5),
		Vector2(15, 15)
	])
	var colors = PackedColorArray([Color(0.2, 0.9, 0.3, 0.8), Color(0.1, 0.7, 0.2, 0.8), Color(0.1, 0.7, 0.2, 0.8), Color(0.1, 0.7, 0.2, 0.8)])
	draw_polygon(points, colors)
	
	points.append(Vector2(0, -20))
	draw_polyline(points, Color.BLACK, 2.0, true)
"""
	arrow_script.reload()
	
	var arrow = Control.new()
	arrow.name = "ObjectiveArrow"
	arrow.set_script(arrow_script)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(arrow)
	
	var update_arrow = func(target):
		if is_instance_valid(arrow):
			arrow.set("target_node", target)
			
	PlayerData.objective_changed.connect(update_arrow)
	arrow.tree_exited.connect(func(): 
		if PlayerData.objective_changed.is_connected(update_arrow):
			PlayerData.objective_changed.disconnect(update_arrow)
	)
	arrow.set("target_node", PlayerData.current_objective)


func show_subtitle(speaker: String, text: String, _duration: float = 4.0) -> void:
	var color_hex = "40c0ff" # Default Sterling blue
	if speaker == "Lolo Palaka" or "frog" in speaker.to_lower() or speaker == "PLAYER":
		color_hex = "40ff80" # Greenish for the frog conversation (Player included, so the whole exchange shares one sound cue)
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("palaka_convo")
	elif "sterling" in speaker.to_lower():
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("message")
			
	PlayerData.add_message(speaker, text, color_hex)
		
	_subtitle_label.text = "[center][b][color=#" + color_hex + "]" + speaker + ":[/color][/b] " + text + "\n[font_size=16][color=#888888](Tap to continue)[/color][/font_size][/center]"
	_subtitle_time_shown = 0.0
	
	if _subtitle_tween and _subtitle_tween.is_valid():
		_subtitle_tween.kill()
		
	_subtitle_panel.visible = true
	_subtitle_tween = create_tween()
	_subtitle_tween.tween_property(_subtitle_panel, "modulate:a", 1.0, 0.3)
	
func hide_subtitle() -> void:
	if _subtitle_tween and _subtitle_tween.is_valid():
		_subtitle_tween.kill()
	_subtitle_tween = create_tween()
	_subtitle_tween.tween_property(_subtitle_panel, "modulate:a", 0.0, 0.2)
	_subtitle_tween.tween_callback(func(): 
		_subtitle_panel.visible = false
		subtitle_dismissed.emit()
	)

# ── Tutorial UI Controls ──────────────────────────────────────────────────────

func hide_action_buttons() -> void:
	if _attack_btn: _attack_btn.modulate.a = 0.0
	if _jump_btn:   _jump_btn.modulate.a = 0.0
	if _skill1_btn: _skill1_btn.modulate.a = 0.0
	if _skill3_btn: _skill3_btn.modulate.a = 0.0
	
func start_ui_walkthrough(steps: Array) -> void:
	_walkthrough_steps = steps
	_current_step_index = 0
	_advance_walkthrough_step()

func _advance_walkthrough_step() -> void:
	for node in _active_highlight_nodes:
		stop_highlight_node(node)
	_active_highlight_nodes.clear()
	
	if _current_step_index >= _walkthrough_steps.size():
		_hide_tutorial()
		return
		
	var step = _walkthrough_steps[_current_step_index]
	_current_step_index += 1
	
	if step.has("nodes"):
		for node_name in step.nodes:
			var node = get(node_name)
			if node and node is Control:
				_active_highlight_nodes.append(node)
				highlight_node(node)
				if node.modulate.a < 1.0:
					var tw = create_tween()
					tw.tween_property(node, "modulate:a", 1.0, 1.0)
				
	show_tutorial(step.get("title", "TUTORIAL"), step.get("text", ""))

func highlight_node(node: Control) -> void:
	if not node: return
	
	node.pivot_offset = node.size / 2.0
	if _active_highlight_tweens.has(node) and _active_highlight_tweens[node].is_valid():
		_active_highlight_tweens[node].kill()
		
	var tw = create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(node, "modulate", Color(1.2, 1.5, 2.0, 1.0), 0.4)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	
	_active_highlight_tweens[node] = tw

func stop_highlight_node(node: Control) -> void:
	if not node: return
	
	if _active_highlight_tweens.has(node):
		var tw = _active_highlight_tweens[node]
		if tw and tw.is_valid():
			tw.kill()
		_active_highlight_tweens.erase(node)
		
	var rtw = create_tween()
	rtw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.1)
	rtw.parallel().tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

	
func reveal_jump() -> void:
	if _jump_btn:
		if _jump_btn.modulate.a < 1.0:
			var tw = create_tween()
			tw.tween_property(_jump_btn, "modulate:a", 1.0, 1.0)
		highlight_node(_jump_btn)
		
func reveal_attack() -> void:
	if _attack_btn:
		if _attack_btn.modulate.a < 1.0:
			var tw = create_tween()
			tw.tween_property(_attack_btn, "modulate:a", 1.0, 1.0)
		highlight_node(_attack_btn)
		
func highlight_jump() -> void:
	highlight_node(_jump_btn)

func stop_highlight_jump() -> void:
	stop_highlight_node(_jump_btn)

func highlight_attack() -> void:
	highlight_node(_attack_btn)

func stop_highlight_attack() -> void:
	stop_highlight_node(_attack_btn)
		
func flash_dodge() -> void:
	if _jump_btn:
		var tw = create_tween()
		for i in range(3):
			tw.tween_property(_jump_btn, "modulate", Color(1.0, 0.5, 0.5, 1.0), 0.15)
			tw.tween_property(_jump_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


# ── Cancel Zone ───────────────────────────────────────────────────────────────

func _build_cancel_zone() -> void:
	if _root.has_node("CancelZone"):
		_cancel_zone = _root.find_child("CancelZone", true, false)
		return

	_cancel_zone = Label.new()
	_cancel_zone.name = "CancelZone"
	_cancel_zone.text = "X\nCANCEL"
	_cancel_zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cancel_zone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cancel_zone.add_theme_font_size_override("font_size", 14) # Smaller font prevents stretching
	
	_cancel_zone.custom_minimum_size = Vector2(80, 80)
	
	# Lock all 4 anchors to the bottom right
	_cancel_zone.set_anchor(SIDE_RIGHT, 1.0)
	_cancel_zone.set_anchor(SIDE_BOTTOM, 1.0)
	_cancel_zone.set_anchor(SIDE_LEFT, 1.0)
	_cancel_zone.set_anchor(SIDE_TOP, 1.0)
	
	_cancel_zone.offset_right = -152
	_cancel_zone.offset_left = -232 # perfectly aligned vertically with Skill 2
	_cancel_zone.offset_bottom = -350
	_cancel_zone.offset_top = -430 # exactly 80 tall and placed above the jump button
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.8, 0.1, 0.1, 0.6)
	bg.set_corner_radius_all(40) # Half of 80 = perfect circle
	bg.border_color = Color(1, 0.3, 0.3, 1)
	bg.set_border_width_all(3)
	_cancel_zone.add_theme_stylebox_override("normal", bg)
	
	_cancel_zone.visible = false
	_root.add_child(_cancel_zone)

# ── Interact API ──────────────────────────────────────────────────────────────

func show_interact(text: String, callback: Callable, source: Node) -> void:
	_current_interact_source = source
	_interact_callback = callback
	_interact_btn.visible = true
	_interact_btn.pivot_offset = _interact_btn.size / 2.0
	
	if _interact_tween and _interact_tween.is_valid():
		_interact_tween.kill()
	_interact_tween = create_tween().set_loops()
	_interact_tween.tween_property(_interact_btn, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_interact_tween.tween_property(_interact_btn, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# if text != "": _interact_btn.text = text

func hide_interact(source: Node) -> void:
	if _current_interact_source == source:
		if _interact_tween and _interact_tween.is_valid():
			_interact_tween.kill()
		_interact_btn.scale = Vector2.ONE
		_interact_btn.visible = false
		_current_interact_source = null
		_interact_callback = Callable()

func _on_interact_pressed() -> void:
	if _interact_callback.is_valid():
		_interact_callback.call()



# ── Action Button Logic ───────────────────────────────────────────────────────

var _is_aiming_jump: bool = false
var _jump_start_pos: Vector2

func _on_jump_btn_input(event: InputEvent) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.is_pressed():
			stop_highlight_jump()
			_is_aiming_jump = true
			_jump_start_pos = event.position
			if _cancel_zone: _cancel_zone.visible = true
			if player.has_method("start_aiming_jump"):
				player.start_aiming_jump()
		else:
			if _is_aiming_jump:
				_is_aiming_jump = false
				if _cancel_zone: _cancel_zone.visible = false
				
				# Check visual cancel zone intersection
				var is_cancelled = false
				var global_touch_pos = _jump_btn.get_global_position() + event.position
				if _cancel_zone and _cancel_zone.get_global_rect().has_point(global_touch_pos):
					is_cancelled = true
				
				if is_cancelled:
					if player.has_method("cancel_aiming_jump"):
						player.cancel_aiming_jump()
				else:
					var drag_dist = event.position.distance_to(_jump_start_pos)
					var is_quick_tap = drag_dist < 20.0
					if player.has_method("execute_splash_jump"):
						player.execute_splash_jump(is_quick_tap)
					
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and _is_aiming_jump):
		if _is_aiming_jump:
			var is_cancelled = false
			var global_touch_pos = _jump_btn.get_global_position() + event.position
			if _cancel_zone and _cancel_zone.get_global_rect().has_point(global_touch_pos):
				is_cancelled = true
				
			# Highlight cancel zone when hovering
			if _cancel_zone:
				var bg = _cancel_zone.get_theme_stylebox("normal") as StyleBoxFlat
				if is_cancelled:
					bg.bg_color = Color(1.0, 0.2, 0.2, 0.95)
					bg.set_border_width_all(6)
				else:
					bg.bg_color = Color(0.8, 0.1, 0.1, 0.6)
					bg.set_border_width_all(3)
			
			var max_drag = 80.0
			var drag_vec = (event.position - _jump_start_pos) / max_drag
			if drag_vec.length() > 1.0:
				drag_vec = drag_vec.normalized()
				
			var mapped_vec = Vector2(drag_vec.x, drag_vec.y)
			if player.has_method("update_aim_jump"):
				player.update_aim_jump(mapped_vec, is_cancelled)

# ── Signals ───────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	var pd = PlayerData
	pd.health_changed.connect(_on_health)
	pd.stamina_changed.connect(_on_stamina)
	pd.exp_changed.connect(_on_exp)
	pd.level_changed.connect(_on_level)
	if pd.has_signal("skill_points_changed"):
		pd.skill_points_changed.connect(_on_skill_points_changed)
	if pd.has_signal("active_species_changed"):
		pd.active_species_changed.connect(_on_active_species_changed)
	if pd.has_signal("species_unlocked"):
		pd.species_unlocked.connect(_rebuild_species_selector)
	if pd.has_signal("progression_changed"):
		pd.progression_changed.connect(func(_species_id: String): _refresh_ultimate_button())
	if pd.has_signal("ultimate_state_changed"):
		pd.ultimate_state_changed.connect(_on_ultimate_state_changed)
	PlayerData.knowledge_unlocked.connect(_on_knowledge_unlocked)
	if PlayerData.has_signal("knowledge_read"):
		PlayerData.knowledge_read.connect(_on_knowledge_read)
	PlayerData.genome_collected.connect(show_genome_popup)
	PlayerData.objective_changed.connect(_on_objective_changed)
	if is_instance_valid(PlayerData.current_objective):
		_on_objective_changed(PlayerData.current_objective)
	else:
		_on_objective_changed(null)
		
	if pd.has_signal("skill1_cooldown_started"):
		pd.skill1_cooldown_started.connect(_on_skill1_cooldown)
	
	# Initial states
	_hp_bar.max_value   = pd.max_health
	_hp_bar.value       = pd.health
	_hp_lbl.text        = "%d / %d" % [roundi(pd.health), roundi(pd.max_health)]
	
	_stam_bar.max_value = pd.max_stamina
	_stam_bar.value     = pd.stamina
	
	_exp_bar.max_value  = pd.exp_to_next
	_exp_bar.value      = pd.experience
	_lvl_lbl.text       = str(pd.level)
	_refresh_species_selector()
	_refresh_ultimate_button()

func _on_active_species_changed(_species_id: String) -> void:
	if _species_id == "salamander":
		_salamander_guide_active = false
	_update_species_guide_highlight()
	_rebuild_species_selector()
	_refresh_ultimate_button()

func _refresh_ultimate_button() -> void:
	if not is_instance_valid(_skill3_btn):
		return
	var definition := PlayerData.get_equipped_ultimate_definition()
	var level := PlayerData.get_equipped_ultimate_level()
	var unlocked := level > 0
	_skill3_btn.disabled = not unlocked or PlayerData.ultimate_active
	_skill3_btn.modulate = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5, 0.5)
	_skill3_btn.tooltip_text = "%s Lv%d" % [str(definition.get("name", "Ultimate locked")), level] if unlocked else "Develop an Ultimate in Character Telemetry"

func _on_ultimate_state_changed(active: bool, remaining: float) -> void:
	_refresh_ultimate_button()
	if active and is_instance_valid(_skill3_btn):
		_skill3_btn.tooltip_text = "Ultimate active: %ds" % ceili(remaining)

func _on_skill1_cooldown(duration: float) -> void:
	if not is_instance_valid(_skill1_btn): return
	
	var overlay = _skill1_btn.get_node_or_null("CooldownOverlay")
	if not overlay:
		overlay = TextureProgressBar.new()
		overlay.name = "CooldownOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.offset_left = 3
		overlay.offset_top = 3
		overlay.offset_right = -3
		overlay.offset_bottom = -3
		overlay.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		overlay.step = 0.01
		
		# Radial sweep requires a perfectly circular texture
		var grad = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.99, 1.0])
		grad.colors = PackedColorArray([Color(0,0,0, 0.7), Color(0,0,0, 0.7), Color(0,0,0, 0.0)])
		var tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 74
		tex.height = 74
		
		overlay.texture_progress = tex
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_skill1_btn.add_child(overlay)
		
	overlay.max_value = duration
	overlay.value = duration
	overlay.visible = true
	
	var tw = create_tween()
	tw.tween_property(overlay, "value", 0.0, duration)
	tw.finished.connect(func(): overlay.visible = false)


func _on_health(value: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	var tw := create_tween()
	tw.tween_property(_hp_bar, "value", value, 0.15).set_trans(Tween.TRANS_SINE)
	_hp_lbl.text = "%d / %d" % [roundi(value), roundi(maximum)]


func _on_stamina(value: float, maximum: float) -> void:
	_stam_bar.max_value = maximum
	_stam_bar.value = value
	
	if _skill1_btn:
		if value < 25.0:
			_skill1_btn.modulate = Color(0.3, 0.3, 0.3, 0.8)
		else:
			_skill1_btn.modulate = Color.WHITE
			
	if _jump_btn:
		if value < 30.0:
			_jump_btn.modulate = Color(0.3, 0.3, 0.3, 0.8)
		else:
			_jump_btn.modulate = Color.WHITE


func _on_exp(value: float, needed: float) -> void:
	_exp_bar.max_value = needed
	var tw := create_tween()
	tw.tween_property(_exp_bar, "value", value, 0.25).set_trans(Tween.TRANS_SINE)


func _on_level(new_level: int) -> void:
	_lvl_lbl.text = str(new_level)
	var tw := create_tween()
	tw.tween_property(_lvl_lbl, "modulate", C_EXP, 0.1)
	tw.tween_property(_lvl_lbl, "modulate", Color.WHITE, 0.5)
	
	var screen_pos = Vector2(get_viewport().size.x / 2.0, 200)
	show_float_text("LEVEL UP! +1 Skill Point", screen_pos, Color(1.0, 0.8, 0.2))

func _on_skill_points_changed(points: int) -> void:
	if is_instance_valid(_level_badge):
		_level_badge.text = str(points)
		_level_badge.visible = points > 0

func _toggle_menu() -> void:
	_menu_open = !_menu_open
	if _menu_open:
		get_tree().paused = true
		_menu_panel.modulate.a = 0.0
		_menu_panel.visible = true
		var tw := create_tween()
		tw.tween_property(_menu_panel, "modulate:a", 1.0, 0.15)
	else:
		var tw := create_tween()
		tw.tween_property(_menu_panel, "modulate:a", 0.0, 0.1)
		tw.tween_callback(func():
			_menu_panel.visible = false
			get_tree().paused = false
		)

func _open_knowledge_menu() -> void:
	get_tree().paused = true
	var menu = load("res://ui/knowledge_menu.gd").new()
	_root.add_child(menu)
	
func _on_badge_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_open_character_menu()

func _open_character_menu() -> void:
	get_tree().paused = true
	var menu = load("res://ui/character_menu.gd").new()
	_root.add_child(menu)
	
func _on_knowledge_unlocked(id: String) -> void:
	if id in PlayerData.KNOWLEDGE_DB:
		var data = PlayerData.KNOWLEDGE_DB[id]
		var title = data.get("title", "Unknown")
		var icon = data.get("icon", "")
		var screen_pos = Vector2(get_viewport().size.x / 2.0, 150) # top center
		show_float_text("NEW KNOWLEDGE: " + icon + " " + title, screen_pos, Color(0.9, 0.8, 0.4))
		
		_update_knowledge_badge()

func _on_knowledge_read(_id: String) -> void:
	_update_knowledge_badge()

func _update_knowledge_badge() -> void:
	if is_instance_valid(_knowledge_badge):
		var count = PlayerData.unread_knowledge.size()
		if count > 0:
			_knowledge_badge.text = str(count)
			_knowledge_badge.visible = true
		else:
			_knowledge_badge.visible = false

func _on_objective_changed(target: Node3D) -> void:
	if is_instance_valid(_current_objective_target) and _current_objective_target != target:
		remove_minimap_marker(_current_objective_target)
		
	_current_objective_target = target
	
	if is_instance_valid(target):
		if not _minimap_markers.has(target):
			add_minimap_marker(target, Color(1.0, 0.8, 0.2), true) # Gold objective marker
		else:
			# If it already has a marker, we can try to turn it gold
			var icon_container = _minimap_markers[target]
			if icon_container.get_child_count() > 0:
				var icon = icon_container.get_child(0)
				icon.set("color", Color(1.0, 0.8, 0.2))
				if icon.has_method("queue_redraw"): icon.queue_redraw()

	var txt = PlayerData.current_objective_text
	_on_objective_updated(txt)

# ── Notifications / Menus ──────────────────────────────────────────────────────────

func show_float_text(text: String, screen_pos: Vector2, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("outline_size", 4)
	
	# Add a slight random offset so simultaneous damage numbers don't perfectly overlap
	var offset_x = randf_range(-20.0, 20.0)
	var offset_y = randf_range(-15.0, 15.0)
	lbl.position = screen_pos + Vector2(-30 + offset_x, -20 + offset_y)
	
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(lbl)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 60.0, 1.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.2).set_delay(0.3)
	tw.finished.connect(lbl.queue_free)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _make_bar(w: float, h: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(w, h)
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var r := int(h / 2.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = C_BG_DARK
	bg.set_corner_radius_all(r)
	
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(r)
	
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _make_circle_btn(name: String, text: String, size: float, bg_col: Color) -> Button:
	var btn: Button
	var is_new = false
	if _root.has_node(name):
		btn = _root.find_child(name, true, false) as Button
	else:
		btn = Button.new()
		btn.name = name
		is_new = true
		
	btn.text = text
		
	btn.custom_minimum_size = Vector2(size, size)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.07, 0.15, 0.50)
	normal.set_corner_radius_all(int(size / 2.0))
	normal.border_color = Color(0.55, 0.78, 1.0, 0.40)
	normal.set_border_width_all(3)
	normal.shadow_color = Color(0, 0, 0, 0.4)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 4)
	normal.anti_aliasing = true
	
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.18, 0.42, 0.90, 0.90)
	pressed.border_color = Color(0.70, 0.88, 1.0, 0.60)
	pressed.shadow_size = 2
	pressed.shadow_offset = Vector2(0, 1)
	
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.1)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	if is_new:
		_root.add_child(btn)
		
	return btn

func _draw_attack_icon() -> void:
	var center = _attack_btn.size / 2.0
	var col = Color(1, 1, 1, 0.85)
	if _attack_btn.is_pressed() or _attack_btn.is_hovered():
		col = Color.WHITE
		
	var thick = 8.0
	# Sword handle
	_attack_btn.draw_line(center + Vector2(-15, 15), center + Vector2(-30, 30), col, thick, true)
	# Sword crossguard
	_attack_btn.draw_line(center + Vector2(-25, 10), center + Vector2(-10, 25), col, thick, true)
	# Sword blade
	_attack_btn.draw_line(center + Vector2(-15, 15), center + Vector2(25, -25), col, thick + 2.0, true)

func _draw_jump_icon() -> void:
	var center = _jump_btn.size / 2.0
	var col = Color(1, 1, 1, 0.85)
	if _jump_btn.is_pressed() or _jump_btn.is_hovered():
		col = Color.WHITE
		
	var thick = 6.0
	var pts = PackedVector2Array([
		center + Vector2(-14, 5),
		center + Vector2(0, -9),
		center + Vector2(14, 5)
	])
	_jump_btn.draw_polyline(pts, col, thick, true)

func _draw_pause_icon() -> void:
	var center = _menu_btn.size / 2.0
	var col = Color(1, 1, 1, 0.85)
	if _menu_btn.is_pressed() or _menu_btn.is_hovered():
		col = Color.WHITE
		
	var w = 6.0
	var h = 20.0
	var spacing = 14.0
	var r1 = Rect2(center.x - spacing/2.0 - w/2.0, center.y - h/2.0, w, h)
	var r2 = Rect2(center.x + spacing/2.0 - w/2.0, center.y - h/2.0, w, h)
	
	# Draw rounded rectangles for the pause icon
	var style = StyleBoxFlat.new()
	style.bg_color = col
	style.set_corner_radius_all(3)
	style.anti_aliasing = true
	style.draw(_menu_btn.get_canvas_item(), r1)
	style.draw(_menu_btn.get_canvas_item(), r2)


func _panel_btn(text: String, col: Color = Color.WHITE) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 48)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.12, 0.16, 0.8)
	normal.set_corner_radius_all(8)
	
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.18, 0.24, 0.9)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", col)
	btn.pressed.connect(func(): AudioManager.play_sfx("tap_button"))
	return btn

# ── Prologue Sequence ─────────────────────────────────────────────────────────

func play_boot_sequence() -> void:
	var boot_overlay = ColorRect.new()
	boot_overlay.color = Color.BLACK
	boot_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	boot_overlay.z_index = 100
	_root.add_child(boot_overlay)
	
	for child in _root.get_children():
		if child is CanvasItem and child != boot_overlay and child != _subtitle_panel:
			child.modulate.a = 0.0
			
	var tw = create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(boot_overlay, "color:a", 0.0, 0.8)
	
	tw.tween_callback(func():
		var hud_tw = create_tween()
		for child in _root.get_children():
			if child is CanvasItem and child != boot_overlay and child != _subtitle_panel and child != _menu_panel and child != _tutorial_panel:
				hud_tw.tween_property(child, "modulate:a", 1.0, 0.5)
				hud_tw.tween_interval(0.2)
	).set_delay(0.25)
	
	tw.tween_callback(boot_overlay.queue_free).set_delay(0.25)

func get_fog_data() -> String:
	if _fog_manager and _fog_manager.has_method("get_fog_data"):
		return _fog_manager.get_fog_data()
	return ""

func _build_quest_log_panel() -> void:
	if _root.has_node("QuestLogPanel"):
		_quest_log_panel = _root.get_node("QuestLogPanel")
		return
		
	_quest_log_panel = PanelContainer.new()
	_quest_log_panel.name = "QuestLogPanel"
	var suit_theme = load("res://ui/suit_theme.gd")
	if suit_theme:
		_quest_log_panel.theme = suit_theme.get_theme()
		
	# Center it. PRESET_CENTER alone only anchors the panel's top-left corner to
	# screen-center (offsets default to 0) — without also setting both grow
	# directions, the panel expands toward the bottom-right instead of being
	# centered around that point.
	_quest_log_panel.set_anchors_preset(Control.PRESET_CENTER)
	_quest_log_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_quest_log_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_quest_log_panel.custom_minimum_size = Vector2(800, 450)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_quest_log_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "ACTIVE"
	header.add_theme_font_size_override("font_size", 28)
	if suit_theme:
		header.add_theme_color_override("font_color", suit_theme.COLOR_ACCENT_YELLOW)
	vbox.add_child(header)
	
	var active_quest_lbl = Label.new()
	active_quest_lbl.name = "ActiveQuestLbl"
	active_quest_lbl.add_theme_font_size_override("font_size", 24)
	vbox.add_child(active_quest_lbl)
	
	var active_desc_lbl = Label.new()
	active_desc_lbl.name = "ActiveDescLbl"
	active_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_desc_lbl.add_theme_font_size_override("font_size", 18)
	if suit_theme:
		active_desc_lbl.add_theme_color_override("font_color", suit_theme.COLOR_TEXT_INACTIVE)
	vbox.add_child(active_desc_lbl)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	if suit_theme:
		divider.color = suit_theme.COLOR_TEXT_INACTIVE
	divider.color.a = 0.3
	vbox.add_child(divider)
	
	var completed_lbl = Label.new()
	completed_lbl.text = "No completed quests yet."
	completed_lbl.add_theme_font_size_override("font_size", 18)
	if suit_theme:
		completed_lbl.add_theme_color_override("font_color", suit_theme.COLOR_TEXT_INACTIVE)
	vbox.add_child(completed_lbl)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		AudioManager.play_sfx("tap_button")
		_quest_log_panel.hide()
		get_tree().paused = false
	)
	vbox.add_child(close_btn)
	
	_quest_log_panel.hide()
	_root.add_child(_quest_log_panel)

func _open_quest_log() -> void:
	if not is_instance_valid(_quest_log_panel): return
	
	var active_quest_lbl = _quest_log_panel.find_child("ActiveQuestLbl", true, false)
	var active_desc_lbl = _quest_log_panel.find_child("ActiveDescLbl", true, false)
	
	if PlayerData.current_objective_text != "":
		active_quest_lbl.text = PlayerData.current_objective_text
		active_desc_lbl.text = PlayerData.current_objective_desc if PlayerData.current_objective_desc != "" else "No additional details available."
	else:
		active_quest_lbl.text = "No active quests."
		active_desc_lbl.text = ""
		
	_quest_log_panel.show()
	get_tree().paused = true
