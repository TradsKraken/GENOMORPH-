class_name MosquitoSwarm
extends EnemyBase

@export var attack_damage: float = 10.0

func _ready() -> void:
	max_health = 100.0
	super._ready()

	# ── Flying mode ─────────────────────────────────────────────────────────
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	uses_gravity = false

	# ── AI tuning ────────────────────────────────────────────────────────────
	speed            = 4.0
	attack_range     = 1.2   # must be within 1.2 m to bite
	detection_radius = 15.0
	recovery_time    = 1.2
	patrol_radius    = 8.0

	# ── Play looping animation ───────────────────────────────────────────────
	var anim_player = _find_animation_player(self)
	if anim_player:
		var anims = anim_player.get_animation_list()
		if anims.size() > 0:
			var anim = anim_player.get_animation(anims[0])
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.play(anims[0])
			
	# Add 3D audio for flying sound
	if AudioManager.sounds.has("mosquito_fly") and AudioManager.sounds["mosquito_fly"] != null:
		var fly_sfx = AudioStreamPlayer3D.new()
		fly_sfx.stream = AudioManager.sounds["mosquito_fly"]
		fly_sfx.autoplay = true
		fly_sfx.unit_size = 5.0
		fly_sfx.max_distance = 40.0
		fly_sfx.volume_db = 12.0
		fly_sfx.bus = "Master"
		add_child(fly_sfx)
		fly_sfx.play()

# ── Helpers ──────────────────────────────────────────────────────────────────

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

# ── Attack ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		_finish_attack()
		return

	# Direction from mosquito to frog (full 3D direction so it dives)
	var lunge_target = target.global_position
	lunge_target.y += 0.4  # aim at frog body center
	
	var to_frog = lunge_target - global_position
	var lunge_dir = to_frog.normalized()

	# ── Lunge IN: fast 3D burst toward the frog ─────────────────────────────
	velocity = lunge_dir * 18.0

	await get_tree().create_timer(0.12).timeout

	if is_dead:
		return

	# ── Bite: stop and deal damage ───────────────────────────────────────────
	velocity = Vector3.ZERO

	var final_damage = DamageCalculator.calculate_enemy_damage(attack_damage)
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(final_damage)
	AudioManager.play_sfx("hit", randf_range(1.2, 1.5))

	# Brief pause so the hit registers visually
	await get_tree().create_timer(0.1).timeout

	if is_dead:
		return

	# ── Retreat: short hop backwards ─────────────────────────────────────────
	velocity = -lunge_dir * 8.0

	await get_tree().create_timer(0.2).timeout

	velocity = Vector3.ZERO

	_finish_attack()
