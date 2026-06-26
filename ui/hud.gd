class_name GameHUD
extends CanvasLayer

## Clean, modern game HUD.
## Sleek bars, circular badges, translucent backgrounds.

# ── Colors & Styling ──────────────────────────────────────────────────────────

const C_HP       := Color("#ff3b5c")
const C_STAM     := Color("#26d97c")
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
var _exp_bar:    ProgressBar
var _lvl_lbl:    Label

var _jump_btn:   Button
var _menu_btn:   Button
var _menu_panel: PanelContainer
var _menu_open:  bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 10
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("hud")

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_player_status()
	_build_action_buttons()
	_build_menu_panel()
	_connect_signals()


# ── Player Status (Top Left) ──────────────────────────────────────────────────

func _build_player_status() -> void:
	# Group container
	var status_group := Control.new()
	status_group.position = Vector2(24, 24)
	status_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(status_group)

	# Level Badge (Circular)
	var badge := PanelContainer.new()
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
	status_group.add_child(badge)

	var lvl_vbox := VBoxContainer.new()
	lvl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lvl_vbox.add_theme_constant_override("separation", -4)
	badge.add_child(lvl_vbox)

	var lvl_title := _make_label("LVL", 12, Color(0.7, 0.7, 0.7))
	lvl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_vbox.add_child(lvl_title)

	_lvl_lbl = _make_label("1", 24, Color.WHITE)
	_lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lvl_lbl.add_theme_font_override("font", ThemeDB.fallback_font)
	lvl_vbox.add_child(_lvl_lbl)

	# Bars Container (Offset to the right of the badge)
	var bars_vbox := VBoxContainer.new()
	bars_vbox.position = Vector2(65, 12)
	bars_vbox.add_theme_constant_override("separation", 8)
	bars_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_vbox.z_index = 1
	status_group.add_child(bars_vbox)

	# Health Bar
	var hp_box := Control.new()
	hp_box.custom_minimum_size = Vector2(300, 24)
	_hp_bar = _make_bar(300, 24, C_HP)
	_hp_lbl = _make_label("100 / 100", 14, Color.WHITE)
	_hp_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_box.add_child(_hp_bar)
	hp_box.add_child(_hp_lbl)
	bars_vbox.add_child(hp_box)

	# Stamina Bar
	var stam_box := Control.new()
	stam_box.custom_minimum_size = Vector2(220, 16)
	_stam_bar = _make_bar(220, 16, C_STAM)
	stam_box.add_child(_stam_bar)
	bars_vbox.add_child(stam_box)

	# EXP Bar (Very thin)
	var exp_box := Control.new()
	exp_box.custom_minimum_size = Vector2(220, 6)
	_exp_bar = _make_bar(220, 6, C_EXP)
	exp_box.add_child(_exp_bar)
	bars_vbox.add_child(exp_box)


# ── Action Buttons ────────────────────────────────────────────────────────────

func _build_action_buttons() -> void:
	# Jump Button (Bottom Right)
	_jump_btn = _make_circle_btn("▲", 100, C_BTN_NORM)
	_jump_btn.set_anchor(SIDE_RIGHT, 1.0)
	_jump_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_jump_btn.set_anchor(SIDE_LEFT, 1.0)
	_jump_btn.set_anchor(SIDE_TOP, 1.0)
	_jump_btn.offset_right  = -40
	_jump_btn.offset_bottom = -40
	_jump_btn.offset_left   = -40 - 100
	_jump_btn.offset_top    = -40 - 100
	_jump_btn.add_theme_font_size_override("font_size", 36)
	_jump_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_jump_btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.1, 0.1, 0.9))
	_jump_btn.button_down.connect(func(): Input.action_press("ui_accept"))
	_jump_btn.button_up.connect(func():   Input.action_release("ui_accept"))
	_root.add_child(_jump_btn)

	# Menu Button (Top Right)
	_menu_btn = _make_circle_btn("⏸", 56, C_BTN_NORM)
	_menu_btn.set_anchor(SIDE_RIGHT, 1.0)
	_menu_btn.set_anchor(SIDE_TOP, 0.0)
	_menu_btn.set_anchor(SIDE_LEFT, 1.0)
	_menu_btn.set_anchor(SIDE_BOTTOM, 0.0)
	_menu_btn.offset_right  = -24
	_menu_btn.offset_top    = 24
	_menu_btn.offset_left   = -24 - 56
	_menu_btn.offset_bottom = 24 + 56
	_menu_btn.add_theme_font_size_override("font_size", 20)
	_menu_btn.pressed.connect(_toggle_menu)
	_root.add_child(_menu_btn)


# ── Menu Panel (Centered) ─────────────────────────────────────────────────────

func _build_menu_panel() -> void:
	_menu_panel = PanelContainer.new()
	_menu_panel.visible = false
	_menu_panel.modulate.a = 0.0
	
	_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	_menu_panel.custom_minimum_size = Vector2(280, 0)
	# Center it manually
	_menu_panel.offset_left   = -140
	_menu_panel.offset_right  = 140
	_menu_panel.offset_top    = -100
	_menu_panel.offset_bottom = 100

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	bg.border_color = Color(1, 1, 1, 0.1)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(16)
	bg.shadow_color = Color(0, 0, 0, 0.5)
	bg.shadow_size = 20
	bg.content_margin_left   = 24.0
	bg.content_margin_right  = 24.0
	bg.content_margin_top    = 24.0
	bg.content_margin_bottom = 24.0
	_menu_panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_menu_panel.add_child(vbox)

	var title := _make_label("PAUSED", 18, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_resume := _panel_btn("Resume Game")
	btn_resume.pressed.connect(_toggle_menu)
	vbox.add_child(btn_resume)

	var btn_quit := _panel_btn("Main Menu", Color("#ff3b5c"))
	btn_quit.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
	vbox.add_child(btn_quit)

	_root.add_child(_menu_panel)


# ── Signals ───────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	var pd = PlayerData
	pd.health_changed.connect(_on_health)
	pd.stamina_changed.connect(_on_stamina)
	pd.exp_changed.connect(_on_exp)
	pd.level_changed.connect(_on_level)
	
	# Init
	_hp_bar.max_value   = pd.max_health
	_hp_bar.value       = pd.health
	_hp_lbl.text        = "%d / %d" % [roundi(pd.health), roundi(pd.max_health)]
	
	_stam_bar.max_value = pd.max_stamina
	_stam_bar.value     = pd.stamina
	
	_exp_bar.max_value  = pd.exp_to_next
	_exp_bar.value      = pd.exp
	_lvl_lbl.text       = str(pd.level)


func _on_health(value: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	var tw := create_tween()
	tw.tween_property(_hp_bar, "value", value, 0.15).set_trans(Tween.TRANS_SINE)
	_hp_lbl.text = "%d / %d" % [roundi(value), roundi(maximum)]


func _on_stamina(value: float, maximum: float) -> void:
	_stam_bar.max_value = maximum
	_stam_bar.value = value


func _on_exp(value: float, needed: float) -> void:
	_exp_bar.max_value = needed
	var tw := create_tween()
	tw.tween_property(_exp_bar, "value", value, 0.25).set_trans(Tween.TRANS_SINE)


func _on_level(new_level: int) -> void:
	_lvl_lbl.text = str(new_level)
	var tw := create_tween()
	tw.tween_property(_lvl_lbl, "modulate", C_EXP, 0.1)
	tw.tween_property(_lvl_lbl, "modulate", Color.WHITE, 0.5)


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


# ── Floating Rewards ──────────────────────────────────────────────────────────

func show_float_text(text: String, screen_pos: Vector2, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = screen_pos + Vector2(-30, -20)
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


func _make_circle_btn(text: String, size: float, bg_col: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(size, size)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_col
	normal.set_corner_radius_all(int(size / 2.0))
	normal.border_color = Color(1, 1, 1, 0.1)
	normal.set_border_width_all(1)
	
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = C_BTN_PRSS
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn


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
	return btn
