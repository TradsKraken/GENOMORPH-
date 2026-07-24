class_name Worm
extends EnemyBase

@export var heal_amount: float = 25.0

var _segments: Array[MeshInstance3D] = []
var _wiggle_time: float = 0.0

func _ready() -> void:
	is_dynamic = true
	# Default stats for the worm
	max_health = 10.0
	speed = 0.8
	exp_value = 5.0
	base_scale = 1.5 # Moderately sized, highly visible procedural worm
	
	super._ready()
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	
	_build_procedural_model()
	
	# Randomize starting rotation
	rotation.y = randf() * TAU
	_wiggle_time = randf() * 10.0

func _build_procedural_model() -> void:
	var visuals = get_node_or_null("Visuals")
	if not visuals:
		return
		
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.45, 0.55) # Bright fleshy pink/red
	mat.roughness = 0.3
	mat.metallic = 0.1
	
	# Create 12 body segments for a smooth, continuous worm
	var num_segments = 12
	var current_z = 0.0
	
	for i in range(num_segments):
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		
		# Head is biggest, tail is smallest
		var radius = 0.16 - (i * 0.01)
		sphere.radius = radius
		sphere.height = radius * 2.0
		
		mesh_inst.mesh = sphere
		mesh_inst.material_override = mat
		
		# Calculate Z position to ensure they heavily overlap without gaps!
		if i > 0:
			var prev_radius = 0.16 - ((i - 1) * 0.01)
			current_z += (prev_radius + radius) * 0.45 # 45% overlap factor
		
		mesh_inst.position.z = current_z
		mesh_inst.position.y = radius
		
		visuals.add_child(mesh_inst)
		_segments.append(mesh_inst)

func _process(delta: float) -> void:
	if is_dead:
		return
		
	# Animate the worm wiggling procedurally
	var move_speed = velocity.length()
	var wiggle_speed = 3.0
	
	# If moving, wiggle significantly faster
	if move_speed > 0.1:
		wiggle_speed = 15.0
		
	_wiggle_time += delta * wiggle_speed
	
	for i in range(_segments.size()):
		var seg = _segments[i]
		# Sine wave offset based on segment index to create a slithering motion
		var wave = sin(_wiggle_time - i * 0.8) # Tighter wave frequency for more segments
		
		# Offset X (side to side slithering)
		seg.position.x = wave * 0.10
		
		# Offset Y (inching up and down)
		var base_y = 0.16 - (i * 0.01)
		seg.position.y = base_y + max(0.0, cos(_wiggle_time - i * 0.8)) * 0.10
		
		# Squish/stretch scale effect
		var stretch = 1.0 + (wave * 0.1)
		seg.scale = Vector3(1.0, 1.0 / stretch, stretch)

func _process_movement(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
		
	var dist = global_position.distance_to(target.global_position)
	
	# If player gets close, wiggle away
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
