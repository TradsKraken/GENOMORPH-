extends Node3D

@export var tree_scene: PackedScene = null
@export var boss_scene: PackedScene = preload("res://enemies/boss_chimera.tscn")
@export var water_pool_scene: PackedScene = null # If exists, otherwise primitive

var boss_instance: Node3D

func _ready() -> void:
	call_deferred("_ensure_player_and_hud")
	_generate_arena()
	call_deferred("_spawn_boss")
	
func _ensure_player_and_hud() -> void:
	# Add player if missing
	if not get_tree().get_nodes_in_group("player"):
		var player_scene = load("res://player/player.tscn")
		if player_scene:
			var player = player_scene.instantiate()
			player.name = "Player"
			player.global_position = Vector3(0, 2, 8)
			add_child(player)
			
	# Add camera if missing
	var has_cam = false
	for cam in get_tree().get_nodes_in_group("camera"):
		has_cam = true
		break
	
	if not has_cam:
		var cam_scene = load("res://player/camera_3d.tscn")
		if not cam_scene:
			# Fallback if no dedicated camera scene
			var cam = Camera3D.new()
			var script = load("res://levels/camera_3d.gd")
			if script:
				cam.set_script(script)
			cam.global_position = Vector3(0, 15, 10)
			cam.rotation_degrees = Vector3(-45, 0, 0)
			cam.add_to_group("camera")
			add_child(cam)
		else:
			var cam = cam_scene.instantiate()
			add_child(cam)
			
	# Add HUD if missing
	if not get_tree().get_nodes_in_group("hud"):
		var hud_scene = load("res://ui/hud_head.tscn")
		if not hud_scene:
			hud_scene = load("res://ui/hud.tscn")
		if hud_scene:
			var hud = hud_scene.instantiate()
			add_child(hud)
			
	# Add lighting if missing
	var has_light = false
	for child in get_children():
		if child is DirectionalLight3D:
			has_light = true
			break
	if not has_light:
		var light = DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, 45, 0)
		light.light_color = Color(0.9, 0.85, 0.65)
		light.light_energy = 0.85
		light.shadow_enabled = true
		add_child(light)
		
	# Add WorldEnvironment if missing
	var has_env = false
	for child in get_children():
		if child is WorldEnvironment:
			has_env = true
			break
	if not has_env:
		var env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.3, 0.45, 0.35)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.65, 0.7, 0.8)
		env.ambient_light_energy = 0.8
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.glow_enabled = true
		env.glow_bloom = 0.1
		var world_env = WorldEnvironment.new()
		world_env.environment = env
		add_child(world_env)

	
func _generate_arena() -> void:
	# Generate precise trimesh collision for the arena floor (plane_002)
	var arena_model = get_node_or_null("ArenaModel")
	if arena_model:
		_generate_mesh_collision(arena_model)
		
	# Fallback flat floor just in case the mesh isn't found
	var floor_body = StaticBody3D.new()
	var floor_col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(200, 2, 200)
	floor_col.shape = box
	floor_body.add_child(floor_col)
	floor_body.global_position = Vector3(0, -2, 0) # Moved down to -2 so it doesn't clip with the real mesh floor
	add_child(floor_body)

	# Spawn water pools (healing zones)
	_spawn_water_pool(Vector3(-10, 0.1, -5))
	_spawn_water_pool(Vector3(10, 0.1, -5))
	_spawn_water_pool(Vector3(0, 0.1, 10))

	# Spawn logs for cover
	_spawn_log(Vector3(-5, 0, 5))
	_spawn_log(Vector3(5, 0, 5))

func _spawn_water_pool(pos: Vector3) -> void:
	var pool = Area3D.new()
	pool.add_to_group("healing_pools")
	
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 4.0
	shape.height = 0.5
	col.shape = shape
	pool.add_child(col)
	
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.0
	cyl.bottom_radius = 4.0
	cyl.height = 0.1
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.8, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cyl.material = mat
	mesh.mesh = cyl
	mesh.visible = false # Hide visual mesh, rely on the GLB arena model
	pool.add_child(mesh)
	
	add_child(pool)
	pool.global_position = pos
	
	pool.body_entered.connect(_on_water_entered)
	pool.body_exited.connect(_on_water_exited)
	
func _spawn_log(pos: Vector3) -> void:
	var log_body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 4.0
	col.shape = shape
	col.rotation.z = PI / 2.0
	log_body.add_child(col)
	
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 4.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.25, 0.1)
	cyl.material = mat
	mesh.mesh = cyl
	mesh.rotation.z = PI / 2.0
	mesh.visible = false # Hide visual mesh, rely on the GLB arena model
	log_body.add_child(mesh)
	
	add_child(log_body)
	log_body.global_position = pos
	log_body.rotation.y = randf() * PI

func _spawn_boss() -> void:
	# Check if the user manually placed the boss in the editor
	var existing_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in existing_enemies:
		if "boss" in enemy.name.to_lower() or "chimera" in enemy.name.to_lower():
			boss_instance = enemy
			return

	if boss_scene:
		boss_instance = boss_scene.instantiate()
		add_child(boss_instance)
		boss_instance.global_position = Vector3(0, 1.0, -15)

func _on_water_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# In a real setup, trigger a Cutaneous Respiration effect buff on the player
		pass
	elif body.is_in_group("enemies") and body == boss_instance:
		# Damage boss if it enters the pool (or maybe the pool just nullifies its nova)
		if body.has_method("take_damage"):
			body.take_damage(50.0)

func _on_water_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		pass

func on_boss_defeated() -> void:
	# Trigger wetland healing sequence or prepare level 2 transition
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("heal"):
		players[0].heal(100.0) # Full heal
		
	# The DNA fragment is dropped by the boss script. When the player picks it up, 
	# it will trigger PlayerData.unlock_genome("avian_form")

func _generate_mesh_collision(node: Node) -> void:
	if node is MeshInstance3D and "plane_002" in node.name.to_lower():
		node.create_trimesh_collision()
		
	for child in node.get_children():
		_generate_mesh_collision(child)
