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

var _attack_btn: Button
var _skill1_btn: Button
var _jump_btn:   Button
var _skill3_btn: Button
var _cancel_zone: Label
var _menu_btn:   Button
var _menu_panel: PanelContainer
var _menu_open:  bool = false

var _tutorial_panel: PanelContainer
var _tutorial_title: Label
var _tutorial_desc:  Label

var _subtitle_panel: PanelContainer
var _subtitle_label: RichTextLabel
var _subtitle_tween: Tween

signal subtitle_dismissed

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
	_build_cancel_zone()
	_build_menu_panel()
	_build_tutorial_panel()
	_build_subtitle_panel()
	_connect_signals()

func _input(event: InputEvent) -> void:
	if _subtitle_panel and _subtitle_panel.visible and _subtitle_panel.modulate.a > 0.5:
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			if event.is_pressed():
				hide_subtitle()
				# Accept the event so it doesn't trigger jumping or attacking if they tap the subtitle area
				# Alternatively, let them attack/jump while dismissing. 
				# It's better to just dismiss and not block input if it's full screen, but let's leave it as non-blocking.


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
	# 1. Primary Attack Button (Webbed Lunge)
	# Largest button, outermost bottom-right
	_attack_btn = _make_circle_btn("🦵", 120, C_BTN_NORM)
	_attack_btn.add_theme_font_size_override("font_size", 64)
	_attack_btn.set_anchor(SIDE_RIGHT, 1.0)
	_attack_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_attack_btn.set_anchor(SIDE_LEFT, 1.0)
	_attack_btn.set_anchor(SIDE_TOP, 1.0)
	_attack_btn.offset_right  = -40
	_attack_btn.offset_bottom = -40
	_attack_btn.offset_left   = -160
	_attack_btn.offset_top    = -160
	_attack_btn.button_down.connect(func(): Input.action_press("attack"))
	_attack_btn.button_up.connect(func():   Input.action_release("attack"))
	_root.add_child(_attack_btn)

	# 2. Skill 1 Button (Sticky Tongue Whip)
	# Medium, directly to the left of Primary Attack
	_skill1_btn = _make_circle_btn("👅", 80, C_BTN_NORM)
	_skill1_btn.add_theme_font_size_override("font_size", 48)
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
	_root.add_child(_skill1_btn)

	# 3. Skill 2 Button (Splashdown Jump)
	# Medium, directly above Skill 1, forming the center of the UI arc
	_jump_btn = _make_circle_btn("🦘", 80, C_BTN_NORM)
	_jump_btn.add_theme_font_size_override("font_size", 48)
	_jump_btn.set_anchor(SIDE_RIGHT, 1.0)
	_jump_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_jump_btn.set_anchor(SIDE_LEFT, 1.0)
	_jump_btn.set_anchor(SIDE_TOP, 1.0)
	_jump_btn.offset_right  = -152
	_jump_btn.offset_bottom = -152
	_jump_btn.offset_left   = -232
	_jump_btn.offset_top    = -232
	_jump_btn.gui_input.connect(_on_jump_btn_input)
	_root.add_child(_jump_btn)

	# 4. Skill 3 Button (Cutaneous Respiration - Ultimate)
	# Medium, top of the curved arc (directly above Primary Attack)
	_skill3_btn = _make_circle_btn("☣️", 80, C_BTN_NORM)
	_skill3_btn.add_theme_font_size_override("font_size", 48)
	_skill3_btn.set_anchor(SIDE_RIGHT, 1.0)
	_skill3_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_skill3_btn.set_anchor(SIDE_LEFT, 1.0)
	_skill3_btn.set_anchor(SIDE_TOP, 1.0)
	_skill3_btn.offset_right  = -60
	_skill3_btn.offset_bottom = -190
	_skill3_btn.offset_left   = -140
	_skill3_btn.offset_top    = -270
	_skill3_btn.disabled = true
	_skill3_btn.modulate = Color(0.5, 0.5, 0.5, 0.5) # Locked visual state
	_root.add_child(_skill3_btn)


	# Menu Button (Top Right)
	_menu_btn = _make_circle_btn("", 56, C_BTN_NORM)
	_menu_btn.set_anchor(SIDE_RIGHT, 1.0)
	_menu_btn.set_anchor(SIDE_TOP, 0.0)
	_menu_btn.set_anchor(SIDE_LEFT, 1.0)
	_menu_btn.set_anchor(SIDE_BOTTOM, 0.0)
	_menu_btn.offset_right  = -24
	_menu_btn.offset_top    = 24
	_menu_btn.offset_left   = -24 - 56
	_menu_btn.offset_bottom = 24 + 56
	_menu_btn.pressed.connect(_toggle_menu)
	_menu_btn.draw.connect(_draw_pause_icon)
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

	var btn_settings := _panel_btn("Settings")
	btn_settings.pressed.connect(func():
		var settings = preload("res://ui/settings_menu.gd").new()
		_root.add_child(settings)
	)
	vbox.add_child(btn_settings)

	var btn_quit := _panel_btn("Main Menu", Color("#ff3b5c"))
	btn_quit.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
	vbox.add_child(btn_quit)

	_root.add_child(_menu_panel)


# ── Tutorial Panel ────────────────────────────────────────────────────────────

func _build_tutorial_panel() -> void:
	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.visible = false
	_tutorial_panel.modulate.a = 0.0
	
	_tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	_tutorial_panel.custom_minimum_size = Vector2(400, 0)
	_tutorial_panel.offset_left   = -200
	_tutorial_panel.offset_right  = 200
	_tutorial_panel.offset_top    = -150
	_tutorial_panel.offset_bottom = 150

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.08, 0.15, 0.95)
	bg.border_color = Color(0.3, 0.6, 1.0, 0.8)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(24)
	bg.shadow_color = Color(0, 0, 0, 0.6)
	bg.shadow_size = 20
	bg.content_margin_left   = 32.0
	bg.content_margin_right  = 32.0
	bg.content_margin_top    = 32.0
	bg.content_margin_bottom = 32.0
	_tutorial_panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	_tutorial_panel.add_child(vbox)

	_tutorial_title = _make_label("TUTORIAL", 28, Color(1.0, 0.8, 0.2))
	_tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_tutorial_title)

	_tutorial_desc = _make_label("Tutorial text goes here.", 18, Color.WHITE)
	_tutorial_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_tutorial_desc)

	var btn_got_it := _panel_btn("Got It!", Color(0.2, 0.8, 0.3))
	btn_got_it.pressed.connect(_hide_tutorial)
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
	var tw := create_tween()
	tw.tween_property(_tutorial_panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		_tutorial_panel.visible = false
		get_tree().paused = false
	)


# ── Subtitle System ───────────────────────────────────────────────────────────

func _build_subtitle_panel() -> void:
	_subtitle_panel = PanelContainer.new()
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
	_subtitle_panel.offset_top = -140
	
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.05, 0.75)
	bg.set_corner_radius_all(12)
	bg.border_color = Color(0.8, 0.8, 0.8, 0.5)
	bg.set_border_width_all(2)
	bg.content_margin_left   = 24.0
	bg.content_margin_right  = 24.0
	bg.content_margin_top    = 16.0
	bg.content_margin_bottom = 16.0
	_subtitle_panel.add_theme_stylebox_override("panel", bg)

	_subtitle_label = RichTextLabel.new()
	_subtitle_label.bbcode_enabled = true
	_subtitle_label.fit_content = true
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_label.add_theme_font_size_override("normal_font_size", 24)
	_subtitle_label.add_theme_font_size_override("bold_font_size", 26)
	_subtitle_panel.add_child(_subtitle_label)

	_root.add_child(_subtitle_panel)

func show_subtitle(speaker: String, text: String, _duration: float = 4.0) -> void:
	var color_hex = "40c0ff" # Default Sterling blue
	if speaker == "Lolo Palaka":
		color_hex = "40ff80" # Greenish for Palaka
		
	_subtitle_label.text = "[center][b][color=#" + color_hex + "]" + speaker + ":[/color][/b] " + text + "\n[font_size=16][color=#888888](Tap to continue)[/color][/font_size][/center]"
	
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
	
func reveal_jump() -> void:
	if _jump_btn and _jump_btn.modulate.a < 1.0:
		var tw = create_tween()
		tw.tween_property(_jump_btn, "modulate:a", 1.0, 1.0)
		
func reveal_attack() -> void:
	if _attack_btn and _attack_btn.modulate.a < 1.0:
		var tw = create_tween()
		tw.tween_property(_attack_btn, "modulate:a", 1.0, 1.0)
		
func flash_dodge() -> void:
	if _jump_btn:
		var tw = create_tween()
		for i in range(3):
			tw.tween_property(_jump_btn, "modulate", Color(1.0, 0.5, 0.5, 1.0), 0.15)
			tw.tween_property(_jump_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


# ── Cancel Zone ───────────────────────────────────────────────────────────────

func _build_cancel_zone() -> void:
	_cancel_zone = Label.new()
	_cancel_zone.text = "X\nCANCEL"
	_cancel_zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cancel_zone.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cancel_zone.add_theme_font_size_override("font_size", 14) # Smaller font prevents stretching
	
	_cancel_zone.custom_minimum_size = Vector2(80, 80)
	
	# Lock all 4 anchors to the top right to strictly enforce the 80x80 size
	_cancel_zone.set_anchor(SIDE_RIGHT, 1.0)
	_cancel_zone.set_anchor(SIDE_TOP, 0.0)
	_cancel_zone.set_anchor(SIDE_LEFT, 1.0)
	_cancel_zone.set_anchor(SIDE_BOTTOM, 0.0)
	
	_cancel_zone.offset_right = -152
	_cancel_zone.offset_left = -232 # perfectly aligned vertically with Skill 2
	_cancel_zone.offset_top = 100
	_cancel_zone.offset_bottom = 180 # exactly 80 tall
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.8, 0.1, 0.1, 0.6)
	bg.set_corner_radius_all(40) # Half of 80 = perfect circle
	bg.border_color = Color(1, 0.3, 0.3, 1)
	bg.set_border_width_all(3)
	_cancel_zone.add_theme_stylebox_override("normal", bg)
	
	_cancel_zone.visible = false
	_root.add_child(_cancel_zone)


# ── Action Button Logic ───────────────────────────────────────────────────────

var _is_aiming_jump: bool = false
var _jump_start_pos: Vector2

func _on_jump_btn_input(event: InputEvent) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.is_pressed():
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
	
	# Init
	_hp_bar.max_value   = pd.max_health
	_hp_bar.value       = pd.health
	_hp_lbl.text        = "%d / %d" % [roundi(pd.health), roundi(pd.max_health)]
	
	_stam_bar.max_value = pd.max_stamina
	_stam_bar.value     = pd.stamina
	
	_exp_bar.max_value  = pd.exp_to_next
	_exp_bar.value      = pd.experience
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
	return btn
