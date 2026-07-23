extends Area3D
class_name ToxicSpit

@export var speed: float = 8.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.ZERO
var _age: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
		
	# Move in a straight line
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies"):
		return # Don't hit other enemies
		
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		
	# Spawn a small splash effect or sound if desired
	queue_free()
