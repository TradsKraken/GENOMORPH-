extends Node

const Field = preload("res://combat/adaptation_field.gd")
const Poison = preload("res://combat/adaptation_poison.gd")
var player: CharacterBody3D
var skin_remaining := 0.0
var skill2_cooldown := 0.0
var _trail_tick := 0.0
var _last_trail := Vector3.INF
var _aura: MeshInstance3D
var _maul_running := false

func _ready() -> void:
	player = get_parent() as CharacterBody3D
	PlayerData.active_species_changed.connect(_on_species_changed)

func _on_species_changed(_species: String) -> void:
	skin_remaining = 0.0
	# Keep cooldowns on switching to prevent free ability resets.

func _exit_tree() -> void:
	PlayerData.end_ultimate()

func tick(delta: float) -> void:
	skill2_cooldown = maxf(0.0, skill2_cooldown - delta)
	PlayerData.update_ultimate(delta)
	if skin_remaining > 0.0:
		var heal_time := minf(skin_remaining, delta)
		skin_remaining -= delta
		PlayerData.heal(6.0 * heal_time * PlayerData.get_health_recovery_multiplier() * PlayerData.ultimate_effect("healing"))
	if not PlayerData.ultimate_active:
		if is_instance_valid(_aura):
			_aura.queue_free()
			_aura = null
		return
	var healing := PlayerData.ultimate_effect("heal_per_second", 0.0)
	if healing > 0.0:
		PlayerData.heal(healing * delta * PlayerData.get_health_recovery_multiplier())
	if PlayerData.active_species == "frog" and PlayerData.ultimate_effect("poison", 0.0) > 0.0:
		_trail_tick -= delta
		if _trail_tick <= 0.0:
			_trail_tick = 1.0
			for enemy in _nearby(3.0):
				Poison.apply(enemy, PlayerData.ultimate_effect("poison"))
			if _last_trail.distance_to(player.global_position) >= 1.0:
				_spawn_field(1.6, PlayerData.ultimate_effect("trail_duration", 4.0), PlayerData.ultimate_effect("poison"))
				_last_trail = player.global_position

func activate() -> bool:
	if player.get("input_locked") or get_tree().paused or _maul_running:
		return false
	# An aimed slam requires a target; do not consume charge for a miss.
	var target: Node3D = null
	if PlayerData.active_species == "water_monitor" and str(PlayerData.get_current_species_data().equipped_ultimate_category) == "attack":
		target = player._find_closest_target_in_group("enemies", 5.0)
		if target == null:
			return false
	if not PlayerData.activate_ultimate():
		return false
	_trail_tick = 0.0
	_last_trail = Vector3.INF
	_create_aura()
	if target:
		_maul(target)
	return true

func use_skill1() -> void:
	if PlayerData.active_species == "salamander":
		skin_remaining = 5.0
	elif PlayerData.active_species == "water_monitor":
		player._show_attack_range(4.5, Color(0.8, 0.6, 0.2))
		for enemy in _nearby(4.5):
			enemy.take_damage(PlayerData.attack_power * 1.5)
			_stagger(enemy, 0.4, 6.0)

func use_skill2() -> bool:
	if player.get("input_locked") or skill2_cooldown > 0.0 or get_tree().paused:
		return false
	var target: Node3D = null
	if PlayerData.active_species == "water_monitor":
		target = player._find_closest_target_in_group("enemies", 4.0)
		if target == null:
			return false
	var cost := 30.0 * PlayerData.ultimate_effect("stamina_cost")
	if not PlayerData.use_stamina(cost):
		return false
	skill2_cooldown = 8.0 * PlayerData.get_cooldown_multiplier()
	PlayerData.skill2_cooldown_started.emit(skill2_cooldown)
	if PlayerData.active_species == "salamander":
		_spawn_field(3.5, 6.0, 4.0 * PlayerData.ultimate_effect("poison_multiplier"), 0.6 if PlayerData.ultimate_active else 1.0)
	elif target:
		target.take_damage(PlayerData.attack_power * 2.5)
		_stagger(target, 0.7, 1.0)
	return true

func _spawn_field(radius: float, duration: float, damage: float, interval: float = 1.0) -> void:
	var field := Field.new()
	field.radius = radius
	field.remaining = duration
	field.poison_damage = damage
	field.application_interval = interval
	get_tree().current_scene.add_child(field)
	field.global_position = player.global_position

func _nearby(radius: float) -> Array[Node3D]:
	var enemies: Array[Node3D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and enemy.has_method("take_damage") and not enemy.get("is_dead"):
			if player.global_position.distance_to(enemy.global_position) <= radius:
				enemies.append(enemy)
	return enemies

func _stagger(enemy: Node, duration: float, force: float) -> void:
	if "stagger_remaining" in enemy:
		enemy.stagger_remaining = maxf(enemy.stagger_remaining, duration)
	if "knockback_velocity" in enemy:
		enemy.knockback_velocity = player.global_position.direction_to(enemy.global_position) * force

func _maul(target: Node3D) -> void:
	_maul_running = true
	var damage := PlayerData.attack_power * PlayerData.ultimate_effect("slam")
	var splash := PlayerData.attack_power * PlayerData.ultimate_effect("splash")
	# Boss script/group and large meshes are never lifted.
	var can_lift := not (target.is_in_group("boss") or target.has_method("_start_phase") or "boss" in str(target.get_script().resource_path).to_lower() or target.scale.length() > 3.5)
	var start := target.global_position
	_stagger(target, 1.1, 0.0)
	if can_lift:
		var lift := create_tween()
		lift.tween_property(target, "global_position", start + Vector3.UP * 1.6, 0.35)
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(target) and not target.get("is_dead"):
		if can_lift:
			target.global_position = start
		target.take_damage(damage)
		_stagger(target, 1.2, 0.0)
		for enemy in _nearby(5.0):
			if enemy != target:
				enemy.take_damage(splash)
				_stagger(enemy, 0.8, 9.0)
		player._show_attack_range(5.0, Color(1.0, 0.65, 0.2))
	_maul_running = false

func _create_aura() -> void:
	if is_instance_valid(_aura):
		_aura.queue_free()
	_aura = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.2
	mesh.height = 2.4
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var category := str(PlayerData.get_current_species_data().equipped_ultimate_category)
	material.albedo_color = Color(0.25, 0.7, 1.0, 0.22) if category == "defense" else Color(0.2, 1.0, 0.4, 0.18)
	mesh.material = material
	_aura.mesh = mesh
	_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player.add_child(_aura)
