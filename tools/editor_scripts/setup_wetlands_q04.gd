@tool
extends EditorScript

# ONE-TIME SETUP HELPER — not used at runtime.
#
# How to run:
# 1. In the Godot editor, open "res://levels/main terrain.scn" and make it the
#    active scene tab.
# 2. Open this file in the Script workspace.
# 3. File > Run (or Ctrl+Shift+X).
# 4. In the Scene dock you'll now see Q04Director under the scene root. It will
#    have a child Area3D named Q04Trigger with a CollisionShape3D.
# 5. Move the Q04Trigger slightly PAST the Salamander Genome signal so the player
#    hits it after transforming.
# 6. Save the scene (Ctrl+S).

const Q04DirectorScript = preload("res://levels/q04_director.gd")

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open 'main terrain.scn' as the active scene tab first, then run this script.")
		return
		
	var director: Node = null
	
	# Create Q04Director
	if not root.has_node("Q04Director"):
		director = Node.new()
		director.name = "Q04Director"
		director.set_script(Q04DirectorScript)
		root.add_child(director)
		director.owner = root
		print("Added Q04Director.")
	else:
		director = root.get_node("Q04Director")
		print("Q04Director already exists.")
		
	# Create Q04Trigger
	if not director.has_node("Q04Trigger"):
		var trigger := Area3D.new()
		trigger.name = "Q04Trigger"
		director.add_child(trigger)
		trigger.owner = root
		
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(8, 4, 8)
		col.shape = box
		trigger.add_child(col)
		col.owner = root
		
		# Try to place it near the SalamanderGenomeSite
		var site = root.find_child("SalamanderGenomeSite", true, false)
		if site and site is Node3D:
			# Place it slightly offset from the site
			trigger.global_position = site.global_position + Vector3(5, 0, 0)
		
		print("Added Q04Trigger Area3D with BoxShape3D.")
	else:
		print("Q04Trigger already exists.")
		
	print("Q04 setup done. Please position Q04Trigger slightly past the Salamander Genome Site, then save the scene.")
