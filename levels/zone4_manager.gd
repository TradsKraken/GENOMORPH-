extends Node3D

@export var tree_scene: PackedScene = null
@export var boss_scene: PackedScene = preload("res://enemies/boss_chimera.tscn")
@export var water_pool_scene: PackedScene = null # If exists, otherwise primitive

var boss_instance: Node3D

func _ready() -> void:
	_generate_arena()
	call_deferred("_spawn_boss")
	
func _generate_arena() -> void:
	# Semi-circular arena bounded by trees/reeds
	var center = Vector3(0, 0, 0)
	var radius = 25.0
	
	if tree_scene:
		# Draw a semi-circle of trees
		for i in range(30):
			var angle = PI + (PI * i / 29.0) # PI to 2PI (bottom half)
			var pos = center + Vector3(cos(angle)*radius, 0, sin(angle)*radius)
			var tree = tree_scene.instantiate()
			add_child(tree)
			tree.global_position = pos
			tree.rotation.y = randf() * TAU
			tree.scale = Vector3.ONE * randf_range(1.5, 2.5)
	else:
		# Procedural primitive trees
		for i in range(30):
			var angle = PI + (PI * i / 29.0)
			var pos = center + Vector3(cos(angle)*radius, 0, sin(angle)*radius)
			_spawn_primitive_tree(pos)

func _spawn_primitive_tree(pos: Vector3) -> void:
	var tree_body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 10.0
	col.shape = shape
	col.position.y = 5.0
	tree_body.add_child(col)
	
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 10.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.15, 0.05)
	cyl.material = mat
	mesh.mesh = cyl
	mesh.position.y = 5.0
	tree_body.add_child(mesh)
	
	add_child(tree_body)
	tree_body.global_position = pos

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
	log_body.add_child(mesh)
	
	add_child(log_body)
	log_body.global_position = pos
	log_body.rotation.y = randf() * PI

func _spawn_boss() -> void:
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
