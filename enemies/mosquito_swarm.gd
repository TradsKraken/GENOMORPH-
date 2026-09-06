class_name MosquitoSwarm
extends EnemyBase

@export var attack_damage: float = 10.0

func _ready() -> void:
	max_health = 100.0
	super._ready()
	
	# Flying enemies need Floating mode so they don't get stuck on terrain!
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	
	# Base class AI configuration
	uses_gravity = false
	speed = randf_range(3.0, 5.0)
	attack_range = 1.0
	detection_radius = 15.0
	recovery_time = 1.5
	patrol_radius = 10.0
	
	# Find and play the mosquito idle/fly animation
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

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

func _perform_attack() -> void:
	# Face the player during the attack
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		_face_direction(dir, 1.0) # Snap to face target
	
	# Visual Lunge: Move the mesh exactly to the player's position
	var visual = get_node_or_null("mosquito1")
	if visual and target and is_instance_valid(target):
		var orig_pos = visual.position
		
		# Find the exact local position of the player relative to the mosquito
		var global_target = target.global_position
		global_target.y += 0.3 # slightly above feet
		var local_target = to_local(global_target)
		
		var tween = create_tween()
		tween.tween_property(visual, "position", local_target, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "position", orig_pos, 0.25).set_delay(0.2)
	
	# Wind-up simulation (bite frame)
	await get_tree().create_timer(0.2).timeout
	
	if is_dead:
		return
		
	# Check if target is still valid and in range (small tolerance)
	if target and is_instance_valid(target):
		var dist_2d = Vector2(global_position.x, global_position.z).distance_to(Vector2(target.global_position.x, target.global_position.z))
		if dist_2d <= attack_range + 0.8:
			# Calculate damage via DamageCalculator
			var final_damage = DamageCalculator.calculate_enemy_damage(attack_damage)
			
			if target.has_method("take_damage"):
				target.take_damage(final_damage)
				
			# Play attack/bite sound
			AudioManager.play_sfx("hit", randf_range(1.2, 1.5))
	
	await get_tree().create_timer(0.2).timeout
	
	# Finish the attack to return to the RECOVER state
	_finish_attack()
