@tool
extends EditorScript

# REFINED HELPER SCRIPT TO REPLACE TERRAIN SAFELY
#
# How to run:
# 1. Open "res://levels/main terrain.scn" in the Godot Editor.
# 2. Select the OLD terrain node in the Scene dock (the one you want to replace).
# 3. Open this file in the Script workspace.
# 4. Click File -> Run (or Ctrl+Shift+X).

const NEW_TERRAIN_PATH = "res://Models/NEW TERRAIN V2/terrainV2final.glb"
const TERRAIN_COLLIDER_SCRIPT = preload("res://levels/terrain_collider.gd")

func _run() -> void:
	var editor = get_editor_interface()
	var root = editor.get_edited_scene_root()
	
	if root == null:
		push_error("No scene open. Please open 'main terrain.scn' first.")
		return
		
	var selection = editor.get_selection().get_selected_nodes()
	if selection.size() != 1:
		push_error("Please select exactly ONE node in the Scene dock to replace.")
		return
		
	var old_node = selection[0]
	var parent = old_node.get_parent()
	
	if parent == null:
		push_error("Cannot replace the root node. Please select a child node.")
		return
	
	print("Replacing terrain...")
	
	# 1. Load the new terrain
	var new_scene = ResourceLoader.load(NEW_TERRAIN_PATH) as PackedScene
	if not new_scene:
		push_error("Failed to load new terrain from: " + NEW_TERRAIN_PATH)
		return
		
	var new_terrain = new_scene.instantiate()
	new_terrain.name = "TerrainV2"
	
	# 1.5 Sanitize the GLB to remove empty/corrupted meshes that cause rendering crashes!
	_sanitize_meshes(new_terrain)
	
	# 2. Attach collision script
	new_terrain.set_script(TERRAIN_COLLIDER_SCRIPT)
	
	# 3. Transfer transform position if applicable
	if new_terrain is Node3D and old_node is Node3D:
		new_terrain.transform = old_node.transform
		
	# 4. Transfer any children from the old node to the new one (so we don't lose them)
	var children_to_move = []
	for child in old_node.get_children():
		children_to_move.append(child)
		
	for child in children_to_move:
		old_node.remove_child(child)
		new_terrain.add_child(child)
		child.owner = root # Ensure children stay owned by the scene
	
	# 5. Add to scene tree at the exact same position
	var index = old_node.get_index()
	parent.add_child(new_terrain)
	parent.move_child(new_terrain, index)
	
	new_terrain.owner = root
	_set_owner_recursive(new_terrain, root)
	
	# 6. Delete old node IMMEDIATELY so it doesn't duplicate
	parent.remove_child(old_node)
	old_node.free()
	
	print("SUCCESS: Terrain replaced! Please save the scene (Ctrl+S) and check for floating objects.")

# Recursively check for and delete meshes that have 0 surfaces to prevent Godot index_buffer crashes
func _sanitize_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		if node.mesh == null or node.mesh.get_surface_count() == 0:
			print("WARNING: Found empty mesh in imported GLB: ", node.name, ". Deleting it to prevent crashes.")
			node.queue_free()
			return # Safe to use queue_free here because it hasn't entered the main tree yet
	
	for child in node.get_children():
		_sanitize_meshes(child)

func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	if node != new_owner and not node.is_queued_for_deletion():
		node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)
