extends Control

# ── Node refs ────────────────────────────────────────────────────────────────
@onready var _title_label: Label       = $Background/ContentAnchor/ContentBox/TitleLabel
@onready var _tagline_label: Label     = $Background/ContentAnchor/ContentBox/TaglineLabel
@onready var _start_btn: Button        = $Background/ContentAnchor/ContentBox/ButtonContainer/NewGameButton
@onready var _particle_layer: Control  = $Background/ParticleLayer
@onready var _scanlines: ColorRect     = $Background/Scanlines
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _background_root: Control = $Background
@onready var _version_label: Label     = $Background/VersionLabel

# ── Particle state ────────────────────────────────────────────────────────────
var _particles: Array[Dictionary] = []
var _time: float = 0.0
const PARTICLE_COUNT := 45

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	if AudioManager and AudioManager.has_method("fade_to_main_menu_bgm"):
		AudioManager.fade_to_main_menu_bgm()

	_title_label.add_theme_font_override("font", ThemeDB.fallback_font)
	_tagline_label.add_theme_font_override("font", ThemeDB.fallback_font)
	
	# Split layout: Title on the left, Buttons on the right
	var content_anchor = $Background/ContentAnchor
	content_anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var content_box = $Background/ContentAnchor/ContentBox
	if content_box is VBoxContainer:
		content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Reparent: Move title & tagline to the left side of the screen
	var title_container = VBoxContainer.new()
	title_container.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	title_container.offset_left = 60
	title_container.offset_right = 500
	title_container.offset_top = -80
	title_container.offset_bottom = 80
	title_container.add_theme_constant_override("separation", 8)
	_background_root.add_child(title_container)
	
	# Move the labels out of the original box and into the left container
	_title_label.get_parent().remove_child(_title_label)
	_tagline_label.get_parent().remove_child(_tagline_label)
	title_container.add_child(_title_label)
	title_container.add_child(_tagline_label)
	
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Move buttons to right side with more spacing from the edge
	var btn_container = $Background/ContentAnchor/ContentBox/ButtonContainer
	content_anchor.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	content_anchor.offset_left = -500
	content_anchor.offset_right = -200
	content_anchor.offset_top = -200
	content_anchor.offset_bottom = 200
	
	# Hide the spacers and divider that were between title and buttons
	for child in content_box.get_children():
		if child is HSeparator or (child is Control and child.name.begins_with("Spacer")):
			child.visible = false
	
	for child in btn_container.get_children():
		if child is Button:
			_apply_glass_button_style(child)
	
	# Dynamically show the version number from project settings
	var app_version = ProjectSettings.get_setting("application/config/version", "0.1.0")
	_version_label.text = "v" + str(app_version) + " — GENOMORPH"
	
	_spawn_background_world()
	
	_spawn_particles()
	_particle_layer.draw.connect(_on_particle_layer_draw)
	_anim_player.play("intro")
	_anim_player.animation_finished.connect(_on_intro_done)
	
	# Restore scanline effect but make it highly subtle
	if _scanlines:
		var mat = _scanlines.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("alpha_multiplier", 0.15)
			mat.set_shader_parameter("line_width", 0.002)
		_scanlines.modulate.a = 0.4
	
	_title_label.add_theme_font_size_override("font_size", 72)
	_tagline_label.add_theme_font_size_override("font_size", 20)

func _apply_glass_button_style(btn: Button) -> void:
	# Use the original green palette with a modernized glass feel
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.03, 0.08, 0.02, 0.7)
	sb_normal.border_color = Color(0.48, 0.72, 0.22, 0.6)
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(8)
	sb_normal.content_margin_left = 28
	sb_normal.content_margin_right = 28
	sb_normal.content_margin_top = 14
	sb_normal.content_margin_bottom = 14
	sb_normal.shadow_color = Color(0.2, 0.5, 0.05, 0.25)
	sb_normal.shadow_size = 4
	
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.06, 0.16, 0.03, 0.9)
	sb_hover.border_color = Color(0.78, 0.98, 0.35, 0.9)
	sb_hover.set_border_width_all(3)
	sb_hover.set_corner_radius_all(8)
	sb_hover.content_margin_left = 28
	sb_hover.content_margin_right = 28
	sb_hover.content_margin_top = 14
	sb_hover.content_margin_bottom = 14
	sb_hover.shadow_color = Color(0.35, 0.75, 0.1, 0.45)
	sb_hover.shadow_size = 12
	
	var sb_pressed = StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.12, 0.26, 0.06, 1.0)
	sb_pressed.border_color = Color(0.9, 1.0, 0.5, 1.0)
	sb_pressed.set_border_width_all(3)
	sb_pressed.set_corner_radius_all(8)
	sb_pressed.content_margin_left = 28
	sb_pressed.content_margin_right = 28
	sb_pressed.content_margin_top = 14
	sb_pressed.content_margin_bottom = 14
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_color_override("font_color", Color(0.88, 0.96, 0.78, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.88, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	btn.mouse_entered.connect(func():
		var tw = create_tween().set_parallel(true)
		tw.tween_property(btn, "custom_minimum_size:x", 340.0, 0.15).set_ease(Tween.EASE_OUT)
		if AudioManager and AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("tap_button", 1.2)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_parallel(true)
		tw.tween_property(btn, "custom_minimum_size:x", 300.0, 0.15).set_ease(Tween.EASE_OUT)
	)
	
	btn.custom_minimum_size.x = 300


func _on_intro_done(_anim_name: String) -> void:
	_start_btn.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)
	_particle_layer.queue_redraw()


# ── Background World Instantiation ───────────────────────────────────────────

func _spawn_background_world() -> void:
	# Create a SubViewportContainer and SubViewport to render the 3D scene
	var sub_viewport_container = SubViewportContainer.new()
	sub_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_viewport_container.stretch = true
	
	var sub_viewport = SubViewport.new()
	sub_viewport.handle_input_locally = false
	sub_viewport_container.add_child(sub_viewport)
	
	# Optionally pre-load the world scene in the background
	var world_scene = load("res://levels/main terrain.scn")
	var world = world_scene.instantiate()
	
	# Find the camera and set it to main menu mode
	var camera = world.get_node_or_null("Camera3D")
	if camera and "is_main_menu" in camera:
		camera.is_main_menu = true
		
	# Disable the player from moving if they somehow receive input
	var player = world.get_node_or_null("Frog Player")
	if player:
		player.set_process(false)
		player.set_physics_process(false)
		player.set_process_input(false)
		
	# Hide any gameplay HUDs (joysticks, buttons) that are in the level
	for child in world.get_children():
		if child is CanvasLayer:
			child.visible = false
		
	sub_viewport.add_child(world)
	
	# Create a blur shader overlay
	var blur_overlay = ColorRect.new()
	blur_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var blur_shader = Shader.new()
	blur_shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	COLOR = textureLod(screen_texture, SCREEN_UV, 3.5);
}
"""
	var blur_mat = ShaderMaterial.new()
	blur_mat.shader = blur_shader
	blur_overlay.material = blur_mat
	
	# Add the viewport behind everything else in the background
	_background_root.add_child(sub_viewport_container)
	_background_root.move_child(sub_viewport_container, 0)
	
	# Add the blur overlay directly on top of the viewport
	_background_root.add_child(blur_overlay)
	_background_root.move_child(blur_overlay, 1)


# ── Particles — warm firefly / spore effect ───────────────────────────────────

func _spawn_particles() -> void:
	var vp := get_viewport_rect().size
	for _i in PARTICLE_COUNT:
		_particles.append({
			"x":     randf_range(0.0, vp.x),
			"y":     randf_range(0.0, vp.y),
			"speed": randf_range(8.0, 32.0),
			"size":  randf_range(1.5, 4.5),
			"alpha": randf_range(0.15, 0.75),
			"drift": randf_range(-14.0, 14.0),
			"phase": randf_range(0.0, TAU),
		})


func _update_particles(delta: float) -> void:
	var vp := get_viewport_rect().size
	for p in _particles:
		p["y"] -= p["speed"] * delta
		p["x"] += sin(_time * 0.7 + p["phase"]) * p["drift"] * delta
		if p["y"] < -10.0:
			p["y"] = vp.y + 10.0
			p["x"] = randf_range(0.0, vp.x)


func _on_particle_layer_draw() -> void:
	for p in _particles:
		var flicker := 0.55 + 0.45 * sin(_time * 2.2 + p["phase"])
		# Warm amber-gold fireflies matching jungle/nature theme
		var col := Color(0.85, 0.78, 0.22, p["alpha"] * flicker)
		var s: float = p["size"]
		var pos := Vector2(p["x"], p["y"])
		_particle_layer.draw_circle(pos, s * 0.5, col)
		# Soft glow halo on larger fireflies
		if s > 3.0:
			_particle_layer.draw_circle(pos, s * 1.1, Color(col.r, col.g, col.b, col.a * 0.18))


# ── Button callbacks ──────────────────────────────────────────────────────────

func _on_new_game_pressed() -> void:
	var play_menu = preload("res://ui/play_menu.gd").new()
	play_menu.new_game.connect(func(slot: int):
		PlayerData.reset_data(slot)
		_anim_player.play("exit")
		await _anim_player.animation_finished
		get_node("/root/SceneLoader").load_scene("res://ui/prologue.tscn")
	)
	play_menu.load_game.connect(func(slot: int):
		print("DEBUG: load_game signal received for slot: ", slot)
		if PlayerData.has_save_file(slot):
			print("DEBUG: has_save_file is true")
			var ok = PlayerData.load_game(slot)
			print("DEBUG: PlayerData.load_game returned ", ok)
			print("DEBUG: current_scene_path is ", PlayerData.current_scene_path)
			_anim_player.play("exit")
			await _anim_player.animation_finished
			print("DEBUG: animation_finished")
			if AudioManager and AudioManager.has_method("play_game_bgm"):
				AudioManager.play_game_bgm()
			print("DEBUG: Calling SceneLoader...")
			get_node("/root/SceneLoader").load_scene(PlayerData.current_scene_path)
		else:
			print("DEBUG: has_save_file is false")
	)
	add_child(play_menu)


func _on_load_game_pressed() -> void:
	var settings = preload("res://ui/settings_menu.gd").new()
	add_child(settings)


func _on_credits_pressed() -> void:
	var credits = preload("res://ui/credits_menu.gd").new()
	add_child(credits)


func _on_quit_button_pressed() -> void:
	_anim_player.play("exit")
	await _anim_player.animation_finished
	get_tree().quit()
