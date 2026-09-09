extends Node
class_name TerrainCollider

# This script automatically generates collisions for the terrain and trees
# but ignores grass so the player can walk straight through it.

func _ready() -> void:
	_generate_collisions(self)

func _generate_collisions(node: Node) -> void:
	if node is MeshInstance3D:
		var node_name = node.name.to_lower()
		
		# Skip objects we want the player to pass through
		if "grass" in node_name or "weed" in node_name or "flower" in node_name or "plant" in node_name:
			pass
		else:
			# Create a static collision mesh for ground, trees, rocks, etc.
			if node.mesh != null and node.mesh.get_surface_count() > 0:
				node.create_trimesh_collision()
			
	# Recursively check all children
	for child in node.get_children():
		_generate_collisions(child)
