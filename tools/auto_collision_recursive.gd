extends Node3D

func _ready() -> void:
	_generate_collisions(self)

func _generate_collisions(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var mat = node.mesh.surface_get_material(i)
				if mat and mat is BaseMaterial3D:
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
					mat.disable_receive_shadows = false
					
		if not node.name.to_lower().contains("grass"):
			node.create_trimesh_collision()
	for child in node.get_children():
		_generate_collisions(child)
