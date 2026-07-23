class_name EnemyBase
extends CharacterBody3D

@export var max_health: float = 50.0
@export var speed: float = 0.3
@export var exp_value: float = 10.0
@export var enemy_level: int = 1

var health: float
var is_dead: bool = false
var target: Node3D = null

var _hp_bg: Sprite3D
var _hp_fg: Sprite3D
var _level_label: Label3D

func _ready() -> void:
	_apply_level_scaling()
	
	health = max_health
	add_to_group("enemies")
	
	_create_health_bar()
	
	# Find player target
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		
func _apply_level_scaling() -> void:
	# Keep baseline stats for level 1, then scale up
	var level_multiplier = float(maxi(1, enemy_level)) - 1.0
	
	# +15% Health per level
	max_health += (max_health * 0.15) * level_multiplier
	
	# +20% EXP per level
	exp_value += (exp_value * 0.20) * level_multiplier
	
	# +5% Size per level
	var size_boost = 1.0 + (0.05 * level_multiplier)
	scale = Vector3(size_boost, size_boost, size_boost)

func _update_level_label_color() -> void:
	if not _level_label:
		return
		
	var diff = enemy_level - PlayerData.level
	if diff <= -1:
		_level_label.modulate = Color(0.6, 0.6, 0.6) # Gray (Easy)
	elif diff == 0:
		_level_label.modulate = Color(1.0, 1.0, 1.0) # White (Normal)
	elif diff <= 2:
		_level_label.modulate = Color(1.0, 0.6, 0.1) # Orange (Hard)
	else:
		_level_label.modulate = Color(1.0, 0.2, 0.2) # Red (Deadly)
		
func show_on_minimap() -> void:
	var tree = get_tree()
	if not tree: return
	var hud = tree.get_first_node_in_group("hud")
	if hud and hud.has_method("add_minimap_marker"):
		hud.add_minimap_marker(self, Color(1.0, 0.1, 0.1), false)

func hide_from_minimap() -> void:
	var tree = get_tree()
	if not tree: return
	var hud = tree.get_first_node_in_group("hud")
	if hud and hud.has_method("remove_minimap_marker"):
		hud.remove_minimap_marker(self)

func _create_health_bar() -> void:
	# Background
	var bg_grad = Gradient.new()
	bg_grad.set_color(0, Color(0.1, 0.1, 0.1, 0.8))
	bg_grad.set_color(1, Color(0.1, 0.1, 0.1, 0.8))
	var bg_tex = GradientTexture2D.new()
	bg_tex.gradient = bg_grad
	bg_tex.width = 150
	bg_tex.height = 15
	
	_hp_bg = Sprite3D.new()
	_hp_bg.texture = bg_tex
	_hp_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_bg.no_depth_test = true
	_hp_bg.position = Vector3(0, 1.4, 0)
	_hp_bg.pixel_size = 0.01
	_hp_bg.visible = false
	add_child(_hp_bg)
	
	# Foreground
	var fg_grad = Gradient.new()
	fg_grad.set_color(0, Color(0.9, 0.2, 0.2, 1.0))
	fg_grad.set_color(1, Color(0.9, 0.2, 0.2, 1.0))
	var fg_tex = GradientTexture2D.new()
	fg_tex.gradient = fg_grad
	fg_tex.width = 150
	fg_tex.height = 15
	
	_hp_fg = Sprite3D.new()
	_hp_fg.texture = fg_tex
	_hp_fg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_fg.no_depth_test = true
	_hp_fg.centered = false
	_hp_fg.offset = Vector2(-75, -7.5)
	_hp_fg.position = Vector3(0, 1.4, 0.001)
	_hp_fg.pixel_size = 0.01
	_hp_fg.visible = false
	add_child(_hp_fg)
	
	# Level Label
	_level_label = Label3D.new()
	_level_label.text = "Lv. %d" % enemy_level
	_level_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_level_label.no_depth_test = true
	_level_label.position = Vector3(0, 1.8, 0) # Moved slightly higher because it is bigger
	_level_label.pixel_size = 0.002 # crisp resolution
	_level_label.outline_render_priority = 0
	_level_label.outline_size = 16
	_level_label.font_size = 256
	add_child(_level_label)
	
	_update_level_label_color()

func take_damage(amount: float) -> void:
	if is_dead or not visible:
		return
	
	health -= amount
	AudioManager.play_sfx("hit", randf_range(0.8, 1.2))
	# _show_damage_text(amount) # Removed to avoid spam overlapping the health bar
	
	if health < max_health:
		_hp_bg.visible = true
		_hp_fg.visible = true
		var ratio = maxf(0.001, health / max_health)
		_hp_fg.scale.x = ratio
		# Dynamically shift the offset so the left edge remains perfectly anchored at -75
		_hp_fg.offset.x = -75.0 / ratio
	
	if health <= 0:
		if _level_label:
			_level_label.visible = false
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	
	_spawn_exp_orb()
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Retarget if needed
	if target == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
			
	_process_movement(delta)

# Virtual function to be overridden by subclasses
func _process_movement(_delta: float) -> void:
	pass

func _spawn_exp_orb() -> void:
	var exp_script = load("res://levels/exp_orb.gd")
	if exp_script:
		AudioManager.play_sfx("exp_drop", randf_range(0.9, 1.1))
		var orb_count := randi_range(5, 10)
		for i in range(orb_count):
			var orb = exp_script.new()
			orb.global_position = global_position
			if "exp_grant" in orb:
				orb.exp_grant = 2.0
			if "velocity" in orb:
				var angle = randf() * TAU
				var spd = randf_range(3.0, 7.0)
				orb.velocity = Vector3(cos(angle) * spd, randf_range(4.0, 8.0), sin(angle) * spd)
			get_tree().current_scene.call_deferred("add_child", orb)

func _show_damage_text(amount: float) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 1.0, 0))
			hud.show_float_text(str(round(amount)), scr, Color.WHITE)
