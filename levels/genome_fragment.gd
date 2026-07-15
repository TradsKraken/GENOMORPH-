extends Area3D

var _bob_time: float = 0.0

func _ready() -> void:
	# Create a visual representation
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.5)
	mat.emission_energy_multiplier = 2.0
	box.material = mat
	
	mesh.mesh = box
	add_child(mesh)
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.0
	collision.shape = sphere
	add_child(collision)
	
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_time += delta * 2.0
	position.y += sin(_bob_time) * delta * 0.5
	rotation.y += delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		PlayerData.add_genome_fragment()
		queue_free()
