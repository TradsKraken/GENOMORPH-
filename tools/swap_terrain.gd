@tool
extends EditorScript

func _run():
	var root = get_editor_interface().get_edited_scene_root()
	if not root:
		print("ERROR: Please open the scene you want to edit first!")
		return
		
	print("--- Running Terrain Swap on ", root.name, " ---")
	
	# Load the new terrain
	var terrain_path = "res://Models/FINAL TERRAIN LEVEL 1.glb"
	var terrain_scene = load(terrain_path)
	if not terrain_scene:
		print("ERROR: Could not load ", terrain_path)
		return
		
	# Create an instance
	var terrain_instance = terrain_scene.instantiate()
	terrain_instance.name = "LevelTerrain"
	
	# Add it to the scene
	root.add_child(terrain_instance)
	
	# Setting the owner is REQUIRED so it saves with the scene
	terrain_instance.owner = root
	
	print("SUCCESS: Added new LevelTerrain to the scene!")
	
	# Try to find the old ground and remove or hide it
	for child in root.get_children():
		if child != terrain_instance:
			var n = child.name.to_lower()
			if n.contains("ground") or n.contains("terrain") or n.contains("planemesh"):
				child.queue_free()
				print("Removed old ground node: ", child.name)
	
	print("Done! Don't forget to save your scene (Ctrl+S).")
