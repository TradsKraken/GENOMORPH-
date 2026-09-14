class_name MosquitoSwarm
extends EnemyBase

@export var attack_damage: float = 10.0

# Q01's large swarm uses these fields to limit how many mosquitoes can make a
# damaging dive at once. The rest still circle/chase, so the swarm looks large
# without delivering ten simultaneous hits.
var _attack_slot_group: StringName
var _attack_slot_limit: int = 0
var _has_attack_slot: bool = false

func _ready() -> void:
	max_health = 100.0
	debug_ai = false # TEMPORARY — remove once the "won't chase" bug is confirmed fixed.
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
		print("[MOSQUITO] Creating fly_sfx AudioStreamPlayer")
		var fly_sfx = AudioStreamPlayer.new()
		fly_sfx.stream = AudioManager.sounds["mosquito_fly"]
		fly_sfx.autoplay = true
		fly_sfx.volume_db = 12.0
		fly_sfx.bus = "Master"
		add_child(fly_sfx)
		fly_sfx.play()
		print("[MOSQUITO] Playing fly_sfx: ", fly_sfx.playing, " at volume: ", fly_sfx.volume_db)
	else:
		print("[MOSQUITO] No mosquito_fly sound found in AudioManager!")

# ── Helpers ──────────────────────────────────────────────────────────────────

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

func configure_attack_slots(group_name: StringName, max_attackers: int) -> void:
	if not _attack_slot_group.is_empty():
		remove_from_group(_attack_slot_group)
	_attack_slot_group = group_name
	_attack_slot_limit = maxi(0, max_attackers)
	if not _attack_slot_group.is_empty() and _attack_slot_limit > 0:
		add_to_group(_attack_slot_group)

func _try_claim_attack_slot() -> bool:
	if _attack_slot_limit <= 0 or _attack_slot_group.is_empty():
		return true
	var active_attackers := 0
	for mosquito in get_tree().get_nodes_in_group(_attack_slot_group):
		if mosquito is MosquitoSwarm and mosquito._has_attack_slot:
			active_attackers += 1
	if active_attackers >= _attack_slot_limit:
		return false
	_has_attack_slot = true
	return true

func _release_attack_slot() -> void:
	_has_attack_slot = false

func _exit_tree() -> void:
	_release_attack_slot()

# ── Attack ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		_finish_attack()
		return
	if not _has_attack_slot and not _try_claim_attack_slot():
		# Another pair is already diving. Return to the normal chase/recovery
		# loop and try again shortly instead of stacking damage on the player.
		_finish_attack()
		return

	# Direction from mosquito to frog (full 3D direction so it dives)
	var lunge_target = target.global_position
	lunge_target.y += 0.4  # aim at frog body center
	
	var to_frog = lunge_target - global_position
	var lunge_dir = to_frog.normalized()

	# ── Lunge IN: quick burst toward the frog ───────────────────────────────
	# (Kept small on purpose: attack_range is 1.2m, so anything much faster than
	# this overshoots straight through the player before the 0.12s timer ends.)
	velocity = lunge_dir * 5.0

	await get_tree().create_timer(0.12).timeout

	if is_dead:
		_release_attack_slot()
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
		_release_attack_slot()
		return

	# ── Retreat: short hop backwards ─────────────────────────────────────────
	velocity = -lunge_dir * 3.0

	await get_tree().create_timer(0.2).timeout

	velocity = Vector3.ZERO

	_release_attack_slot()
	_finish_attack()
