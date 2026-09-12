class_name Rat
extends EnemyBase

@export var bite_damage: float = 6.0

var _anim_player: AnimationPlayer
var _idle_anim: String = ""
var _walk_anim: String = ""
var _attack_anim: String = ""
var is_spawning: bool = false
var _defense_target: Node3D = null

func _ready() -> void:
	max_health = 25.0
	super._ready()

	speed = 3.5
	attack_range = 1.3
	detection_radius = 10.0
	recovery_time = 0.8
	patrol_radius = 4.0

	_anim_player = _find_animation_player(self)
	if _anim_player:
		var anims = _anim_player.get_animation_list()
		for a in anims:
			var a_lower = a.to_lower()
			if "idle" in a_lower:
				_idle_anim = a
			elif "walk" in a_lower or "run" in a_lower:
				_walk_anim = a
			elif "attack" in a_lower or "bite" in a_lower:
				_attack_anim = a

		# Set loops if found
		if _idle_anim != "":
			_anim_player.get_animation(_idle_anim).loop_mode = Animation.LOOP_LINEAR
		if _walk_anim != "":
			_anim_player.get_animation(_walk_anim).loop_mode = Animation.LOOP_LINEAR
		if _attack_anim != "":
			_anim_player.get_animation(_attack_anim).loop_mode = Animation.LOOP_NONE

		if _idle_anim != "":
			_anim_player.play(_idle_anim)
		elif anims.size() > 0:
			_anim_player.play(anims[0])

	if is_dynamic:
		_play_spawn_animation()

func _physics_process(delta: float) -> void:
	if is_spawning:
		return
	super._physics_process(delta)

func _process(_delta: float) -> void:
	# Simple animation state machine
	if is_dead:
		return
	if velocity.length_squared() > 0.1 and _walk_anim != "":
		if _anim_player and _anim_player.current_animation != _walk_anim and _anim_player.current_animation != _attack_anim:
			_anim_player.play(_walk_anim)
	elif _idle_anim != "":
		if _anim_player and _anim_player.current_animation != _idle_anim and _anim_player.current_animation != _attack_anim:
			_anim_player.play(_idle_anim)

func _play_spawn_animation() -> void:
	# Freeze AI state machine and physics until fully spawned
	is_spawning = true
	current_state = AIState.IDLE
	
	uses_gravity = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	var nutria = get_node_or_null("Nutria")
	if nutria:
		nutria.visible = false
	
	# Small random delay so they don't all pop up at the exact same time
	await get_tree().create_timer(randf_range(0.2, 0.5)).timeout

	# Trigger Mud Particles (burrowing animation)
	var mud = get_node_or_null("MudParticles")
	if mud:
		mud.one_shot = true
		mud.emitting = true

	# Wait for the particles to fly up before popping the rat in
	await get_tree().create_timer(0.6).timeout
	
	# Rat instantly appears after the mud animation
	if nutria:
		nutria.visible = true
	
	uses_gravity = true
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	is_spawning = false

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

## Q03's rats begin by attacking the threatened native frog. The first hit
## from the player pulls their attention away, making protection an active
## combat choice instead of a passive countdown.
func set_defense_target(defense_target: Node3D) -> void:
	_defense_target = defense_target
	target = defense_target
	current_state = AIState.CHASE

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	super.take_damage(amount, knockback)
	if is_dead or target != _defense_target:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if is_instance_valid(player):
		target = player
		current_state = AIState.CHASE

func _perform_attack() -> void:
	if _anim_player and _attack_anim != "":
		_anim_player.play(_attack_anim)

	if not target or not is_instance_valid(target):
		_finish_attack()
		return

	var final_damage = DamageCalculator.calculate_enemy_damage(bite_damage)
	if target.has_method("take_damage"):
		target.take_damage(final_damage)
	AudioManager.play_sfx("hit", randf_range(1.3, 1.6))

	await get_tree().create_timer(0.15).timeout
	if is_dead:
		return

	_finish_attack()
