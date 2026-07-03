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
	_title_label.add_theme_font_override("font", ThemeDB.fallback_font)
	_tagline_label.add_theme_font_override("font", ThemeDB.fallback_font)
	
	# Dynamically show the version number from project settings
	var app_version = ProjectSettings.get_setting("application/config/version", "0.1.0")
	_version_label.text = "v" + str(app_version) + " — GENOMORPH"
	
	_spawn_background_world()
	
	_spawn_particles()
	_particle_layer.draw.connect(_on_particle_layer_draw)
	_anim_player.play("intro")
	_anim_player.animation_finished.connect(_on_intro_done)
	
	# Remove the scanline effect entirely so it doesn't look like stripes
	if _scanlines:
		_scanlines.queue_free()


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
	
	# Load the 3D world
	var world_scene = load("res://levels/node_3d.tscn")
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
	play_menu.new_game.connect(func():
		PlayerData.reset_data()
		_anim_player.play("exit")
		await _anim_player.animation_finished
		get_tree().change_scene_to_file("res://levels/node_3d.tscn")
	)
	play_menu.load_game.connect(func():
		if PlayerData.has_save_file():
			PlayerData.load_game()
			_anim_player.play("exit")
			await _anim_player.animation_finished
			get_tree().change_scene_to_file(PlayerData.current_scene_path)
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
