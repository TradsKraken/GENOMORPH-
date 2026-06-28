extends MeshInstance3D

func _ready() -> void:
	# Automatically generate a perfect static collision mesh based on the visual mesh!
	create_trimesh_collision()
