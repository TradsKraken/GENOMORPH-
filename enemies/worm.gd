class_name Worm
extends EnemyBase

@export var heal_amount: float = 25.0

func _ready() -> void:
	is_dynamic = true
	# Default stats for the worm
	max_health = 10.0
	speed = 0.5
	exp_value = 5.0
	base_scale = 3.0 
	
	super._ready()
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	# Randomize starting rotation
	rotation.y = randf() * TAU

func _process_movement(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
		
	var dist = global_position.distance_to(target.global_position)
	
	# If player gets close, wiggle away slowly
	if dist < 15.0:
		var flee_dir = (global_position - target.global_position)
		flee_dir.y = 0
		if flee_dir.length() > 0.1:
			flee_dir = flee_dir.normalized()
			
			var target_angle = atan2(flee_dir.x, flee_dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)
			
			velocity = flee_dir * speed
	else:
		velocity = Vector3.ZERO
		
	if not is_on_floor():
		velocity.y -= 20.0 * delta
		
	move_and_slide()

func die() -> void:
	if is_dead: return
	
	# Heal player
	PlayerData.heal(heal_amount)
	AudioManager.play_sfx("stamina_collect", randf_range(0.8, 1.0), -5.0) # Play a satisfying sound
	
	# Show heal text
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam = get_viewport().get_camera_3d()
		if cam:
			var scr = cam.unproject_position(global_position + Vector3(0, 1.0, 0))
			hud.show_float_text("+%d HP" % int(heal_amount), scr, Color(0.2, 1.0, 0.2))
			
	super.die()
