class_name GameHUD
extends CanvasLayer

## In-game HUD: health ring, stamina bar, level/XP display, jump button, menu.
## Spawned at runtime by camera_3d.gd — nothing baked into .tscn.

# ── Palette ───────────────────────────────────────────────────────────────────
const C_RED    := Color(1.00, 0.22, 0.33)
const C_GREEN  := Color(0.08, 0.90, 0.52)
const C_GOLD   := Color(1.00, 0.80, 0.08)
const C_BLUE   := Color(0.18, 0.46, 0.98)
const C_BG     := Color(0.04, 0.05, 0.12, 0.83)
const C_PANEL  := Color(0.04, 0.06, 0.16, 0.94)
const C_BORDER := Color(1.00, 1.00, 1.00, 0.15)
const C_TEXT   := Color(0.96, 0.96, 1.00, 1.00)
const C_DIM    := Color(0.70, 0.70, 0.82, 0.80)

# ── Node refs ─────────────────────────────────────────────────────────────────
var _root:      Control
var _hp_ring:   Control
var _hp_label:  Label
var _stam_bar:  ProgressBar
var _stam_val:  Label
var _lv_label:  Label
var _exp_bar:   ProgressBar
var _exp_label: Label
var _jump_btn:  Button
var _menu_btn:  Button
var _menu_panel: PanelContainer
var _menu_open: bool = false

# ── Inner: circular health ring ───────────────────────────────────────────────

class _HealthRing extends Control:
	const _FILL  := Color(1.00, 0.22, 0.33)
	const _GLOW  := Color(1.00, 0.30, 0.40, 0.20)
	const _TRACK := Color(0.28, 0.04, 0.08, 0.72)
	const _BASE  := Color(0.06, 0.01, 0.04, 0.92)
	var ratio: float = 1.0

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.40
		draw_circle(c, r, _BASE)
		draw_arc(c, r + 2.5, 0.0, TAU, 64, _GLOW, 14.0)
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU, 64, _TRACK, 7.0)
		if ratio > 0.002:
			var col := _FILL
			if ratio < 0.35:
				col = _FILL.lerp(Color(1.0, 0.75, 0.0), 1.0 - ratio / 0.35)
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * ratio, 64, col, 7.0, true)
		var font := ThemeDB.fallback_font
		draw_string(font, c + Vector2(-7.0, 8.0), "♥",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.85, 0.88, 0.90))

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 10
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("hud")

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_status_bar()
	_build_jump_btn()
	_build_menu_btn()
	_build_menu_panel()
	_connect_signals()

# ── Status bar ────────────────────────────────────────────────────────────────

func _build_status_bar() -> void:
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = C_BG
	bg.border_color = C_BORDER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(14)
	bg.content_margin_left   = 10.0
	bg.content_margin_right  = 10.0
	bg.content_margin_top    = 6.0
	bg.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", bg)
	panel.set_anchor(SIDE_LEFT,  0.0)
	panel.set_anchor(SIDE_RIGHT, 1.0)
	panel.set_anchor(SIDE_TOP,   0.0)
	panel.offset_top   = 6
	panel.offset_left  = 8
	panel.offset_right = -8
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	_build_health_section(hbox)
	_add_spacer(hbox)
	_build_stamina_section(hbox)
	_add_spacer(hbox)
	_build_level_section(hbox)


func _build_health_section(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vbox)

	_hp_ring = _HealthRing.new()
	_hp_ring.custom_minimum_size = Vector2(72, 72)
	_hp_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_hp_ring)

	_hp_label = _make_label("100/100", 10, C_DIM)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hp_label)


func _build_stamina_section(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vbox)

	var title := _make_label("⚡  STAMINA", 11, C_GREEN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_stam_bar = _make_bar(220, 18, C_GREEN, Color(0.03, 0.25, 0.15, 0.80))
	vbox.add_child(_stam_bar)

	_stam_val = _make_label("100 / 100", 10, C_DIM)
	_stam_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_stam_val)


func _build_level_section(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vbox)

	var lv_bg := StyleBoxFlat.new()
	lv_bg.bg_color = Color(0.15, 0.12, 0.01, 0.85)
	lv_bg.border_color = Color(0.9, 0.7, 0.05, 0.70)
	lv_bg.set_border_width_all(1)
	lv_bg.set_corner_radius_all(8)
	lv_bg.content_margin_left   = 8.0
	lv_bg.content_margin_right  = 8.0
	lv_bg.content_margin_top    = 3.0
	lv_bg.content_margin_bottom = 3.0
	var lv_panel := PanelContainer.new()
	lv_panel.add_theme_stylebox_override("panel", lv_bg)
	lv_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lv_panel)

	_lv_label = _make_label("LV 1", 15, C_GOLD)
	_lv_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lv_label.add_theme_constant_override("outline_size", 2)
	_lv_label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.0))
	lv_panel.add_child(_lv_label)

	_exp_bar = _make_bar(140, 10, C_GOLD, Color(0.15, 0.12, 0.01, 0.80))
	vbox.add_child(_exp_bar)

	_exp_label = _make_label("0 / 100 XP", 10, C_DIM)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_exp_label)

# ── Jump button (bottom-right) ────────────────────────────────────────────────

func _build_jump_btn() -> void:
	_jump_btn = Button.new()
	_jump_btn.text = "▲"
	_jump_btn.custom_minimum_size = Vector2(76, 76)
	_jump_btn.set_anchor(SIDE_RIGHT,  1.0)
	_jump_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_jump_btn.set_anchor(SIDE_LEFT,   1.0)
	_jump_btn.set_anchor(SIDE_TOP,    1.0)
	_jump_btn.offset_right  = -14
	_jump_btn.offset_bottom = -14
	_jump_btn.offset_left   = -14 - 76
	_jump_btn.offset_top    = -14 - 76

	var sn := _round_btn_style(Color(0.10, 0.22, 0.75, 0.88))
	var sp := _round_btn_style(Color(0.28, 0.55, 1.00, 0.96))
	_jump_btn.add_theme_stylebox_override("normal",  sn)
	_jump_btn.add_theme_stylebox_override("hover",   sn)
	_jump_btn.add_theme_stylebox_override("pressed", sp)
	_jump_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	_jump_btn.add_theme_font_size_override("font_size", 28)
	_jump_btn.add_theme_color_override("font_color",         Color.WHITE)
	_jump_btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.9, 1.0))
	_jump_btn.button_down.connect(func(): Input.action_press("ui_accept"))
	_jump_btn.button_up.connect(func():   Input.action_release("ui_accept"))
	_root.add_child(_jump_btn)

# ── Menu button (bottom-left) ─────────────────────────────────────────────────

func _build_menu_btn() -> void:
	_menu_btn = Button.new()
	_menu_btn.text = "☰"
	_menu_btn.custom_minimum_size = Vector2(58, 58)
	_menu_btn.set_anchor(SIDE_LEFT,   0.0)
	_menu_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_menu_btn.set_anchor(SIDE_RIGHT,  0.0)
	_menu_btn.set_anchor(SIDE_TOP,    1.0)
	_menu_btn.offset_left   = 14
	_menu_btn.offset_bottom = -14
	_menu_btn.offset_right  = 14 + 58
	_menu_btn.offset_top    = -14 - 58

	var sn := _round_btn_style(Color(0.08, 0.10, 0.22, 0.86))
	var sp := _round_btn_style(Color(0.18, 0.22, 0.50, 0.96))
	_menu_btn.add_theme_stylebox_override("normal",  sn)
	_menu_btn.add_theme_stylebox_override("hover",   sn)
	_menu_btn.add_theme_stylebox_override("pressed", sp)
	_menu_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	_menu_btn.add_theme_font_size_override("font_size", 22)
	_menu_btn.add_theme_color_override("font_color", Color.WHITE)
	_menu_btn.pressed.connect(_toggle_menu)
	_root.add_child(_menu_btn)

# ── Menu panel ────────────────────────────────────────────────────────────────

func _build_menu_panel() -> void:
	_menu_panel = PanelContainer.new()
	_menu_panel.visible = false
	_menu_panel.modulate.a = 0.0

	var bg := StyleBoxFlat.new()
	bg.bg_color = C_PANEL
	bg.border_color = C_BORDER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(16)
	bg.content_margin_left   = 16.0
	bg.content_margin_right  = 16.0
	bg.content_margin_top    = 14.0
	bg.content_margin_bottom = 14.0
	_menu_panel.add_theme_stylebox_override("panel", bg)

	_menu_panel.set_anchor(SIDE_LEFT,   0.0)
	_menu_panel.set_anchor(SIDE_BOTTOM, 1.0)
	_menu_panel.set_anchor(SIDE_RIGHT,  0.0)
	_menu_panel.set_anchor(SIDE_TOP,    1.0)
	_menu_panel.offset_left   = 10
	_menu_panel.offset_right  = 210
	_menu_panel.offset_bottom = -80
	_menu_panel.offset_top    = -80 - 185

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_menu_panel.add_child(vbox)

	var title := _make_label("  MENU  ", 18, C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = C_BORDER
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	var btn_resume := _panel_btn("▶  Resume")
	btn_resume.pressed.connect(_toggle_menu)
	vbox.add_child(btn_resume)

	var btn_quit := _panel_btn("⏏  Main Menu")
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
	# Set initial values
	var hr := _hp_ring as _HealthRing
	if hr:
		hr.ratio = pd.health / pd.max_health
		hr.queue_redraw()
	_hp_label.text  = "%d / %d" % [roundi(pd.health),  roundi(pd.max_health)]
	_stam_bar.max_value = pd.max_stamina
	_stam_bar.value     = pd.stamina
	_stam_val.text      = "%d / %d" % [roundi(pd.stamina), roundi(pd.max_stamina)]
	_exp_bar.max_value  = pd.exp_to_next
	_exp_bar.value      = pd.exp
	_exp_label.text     = "0 / %d XP" % roundi(pd.exp_to_next)
	_lv_label.text      = "LV %d" % pd.level


func _on_health(value: float, maximum: float) -> void:
	var hr := _hp_ring as _HealthRing
	if hr:
		hr.ratio = value / maximum
		hr.queue_redraw()
	_hp_label.text = "%d / %d" % [roundi(value), roundi(maximum)]
	var tw := create_tween()
	tw.tween_property(_hp_ring, "modulate", Color(2.0, 0.4, 0.5), 0.07)
	tw.tween_property(_hp_ring, "modulate", Color.WHITE, 0.28)


func _on_stamina(value: float, maximum: float) -> void:
	_stam_bar.max_value = maximum
	_stam_bar.value     = value
	_stam_val.text = "%d / %d" % [roundi(value), roundi(maximum)]


func _on_exp(value: float, needed: float) -> void:
	_exp_bar.max_value = needed
	_exp_bar.value     = value
	_exp_label.text = "%d / %d XP" % [roundi(value), roundi(needed)]


func _on_level(new_level: int) -> void:
	_lv_label.text = "LV %d" % new_level
	var tw := create_tween()
	tw.tween_property(_lv_label, "modulate", Color(2.5, 2.0, 0.3), 0.10)
	tw.tween_property(_lv_label, "modulate", Color.WHITE, 0.55)

# ── Menu toggle ───────────────────────────────────────────────────────────────

func _toggle_menu() -> void:
	_menu_open = !_menu_open
	if _menu_open:
		get_tree().paused = true
		_menu_panel.modulate.a = 0.0
		_menu_panel.visible = true
		var tw := create_tween()
		tw.tween_property(_menu_panel, "modulate:a", 1.0, 0.22)
	else:
		var tw := create_tween()
		tw.tween_property(_menu_panel, "modulate:a", 0.0, 0.18)
		tw.tween_callback(func():
			_menu_panel.visible = false
			get_tree().paused = false
		)

# ── Public: floating reward text (called by orbs) ─────────────────────────────

func show_float_text(text: String, screen_pos: Vector2, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.position = screen_pos + Vector2(-40.0, -20.0)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(lbl)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 75.0, 1.30)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.30).set_delay(0.25)
	tw.finished.connect(lbl.queue_free)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_bar(w: float, h: float, fill: Color, bg: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(w, h)
	bar.max_value    = 100.0
	bar.value        = 100.0
	bar.show_percentage = false
	var r := int(h / 2)
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = bg
	sbg.set_corner_radius_all(r)
	var sf := StyleBoxFlat.new()
	sf.bg_color = fill
	sf.set_corner_radius_all(r)
	bar.add_theme_stylebox_override("background", sbg)
	bar.add_theme_stylebox_override("fill", sf)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _round_btn_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = Color(1.0, 1.0, 1.0, 0.22)
	s.set_border_width_all(2)
	s.set_corner_radius_all(40)
	return s


func _panel_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.10, 0.12, 0.28, 0.90)
	sn.border_color = C_BORDER
	sn.set_border_width_all(1)
	sn.set_corner_radius_all(10)
	var sh := sn.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.18, 0.22, 0.52, 0.96)
	btn.add_theme_stylebox_override("normal",  sn)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sh)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", C_TEXT)
	return btn


func _add_spacer(parent: Control) -> void:
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sp)