extends Control

# ── Node refs ────────────────────────────────────────────────────────────────
@onready var _title_label: Label       = $Background/ContentAnchor/ContentBox/TitleLabel
@onready var _tagline_label: Label     = $Background/ContentAnchor/ContentBox/TaglineLabel
@onready var _start_btn: Button        = $Background/ContentAnchor/ContentBox/ButtonContainer/NewGameButton
@onready var _particle_layer: Control  = $Background/ParticleLayer
@onready var _scanlines: ColorRect     = $Background/Scanlines
@onready var _anim_player: AnimationPlayer = $AnimationPlayer

# ── Particle state ────────────────────────────────────────────────────────────
var _particles: Array[Dictionary] = []
var _time: float = 0.0
const PARTICLE_COUNT := 45

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_title_label.add_theme_font_override("font", ThemeDB.fallback_font)
	_tagline_label.add_theme_font_override("font", ThemeDB.fallback_font)
	
	_spawn_particles()
	_particle_layer.draw.connect(_on_particle_layer_draw)
	_anim_player.play("intro")
	_anim_player.animation_finished.connect(_on_intro_done)


func _on_intro_done(_anim_name: String) -> void:
	_start_btn.grab_focus()


func _process(delta: float) -> void:
	_time += delta

	# Scroll scanlines
	var mat := _scanlines.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("scroll_offset", fmod(_time * 0.04, 1.0))

	_update_particles(delta)
	_particle_layer.queue_redraw()


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
		_anim_player.play("exit")
		await _anim_player.animation_finished
		get_tree().change_scene_to_file("res://levels/node_3d.tscn")
	)
	play_menu.load_game.connect(func():
		print("Load Game — not yet implemented")
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
