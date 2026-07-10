extends Node3D

func _ready() -> void:
	_generate_collisions(self)

func _generate_collisions(node: Node) -> void:
	if node is MeshInstance3D:
		node.create_trimesh_collision()
	for child in node.get_children():
		_generate_collisions(child)
