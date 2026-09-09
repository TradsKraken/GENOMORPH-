@tool
extends EditorScript

# ONE-TIME SETUP HELPER — not used at runtime.
#
# How to run:
# 1. In the Godot editor, open "res://levels/main terrain.scn" and make it the
#    active scene tab.
# 2. Open this file in the Script workspace.
# 3. File > Run (or Ctrl+Shift+X).
# 4. In the Scene dock you'll now see Clue_Burrows and Q02Director under the
#    scene root. Drag Clue_Burrows to a spot deeper into the wetland than the
#    Q01 clues (burrows/tracks, away from the starting mud patch) so it reads
#    as "further in." Then save the scene (Ctrl+S).
#
# Safe to run more than once — it skips any node that already exists by name.

const KnowledgeObjectScene = preload("res://levels/knowledge_object.tscn")
const Q02DirectorScript = preload("res://levels/q02_director.gd")

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open 'main terrain.scn' as the active scene tab first, then run this script.")
		return

	if not root.has_node("Clue_Burrows"):
		var clue := KnowledgeObjectScene.instantiate()
		clue.name = "Clue_Burrows"
		clue.knowledge_id = "q02_burrows"
		root.add_child(clue)
		clue.owner = root
		clue.position = Vector3(6, 0.5, -8)
		print("Added Clue_Burrows.")

	if not root.has_node("Q02Director"):
		var director := Node.new()
		director.name = "Q02Director"
		director.set_script(Q02DirectorScript)
		root.add_child(director)
		director.owner = root
		print("Added Q02Director.")

	print("Q02 setup done. Reposition Clue_Burrows deeper into the wetland, then save the scene.")
