@tool
extends EditorScript

# ONE-TIME SETUP HELPER — not used at runtime.
#
# How to run:
# 1. In the Godot editor, open "res://levels/main terrain.scn" and make it the
#    active scene tab.
# 2. Open this file in the Script workspace.
# 3. File > Run (or Ctrl+Shift+X).
# 4. In the Scene dock you'll now see two new nodes under the scene root:
#      - Clue_Burrows — the interactable (burrows/tracks). Drag this onto real,
#        walkable ground somewhere deeper into the wetland than the Q01 clues
#        — this is BOTH the object you interact with AND where the objective
#        arrow points, so wherever you put it is exactly where the player ends
#        up. It's placed at a fixed default position (6, 0.5, -8) that has no
#        knowledge of your actual terrain shape there — you MUST move it onto
#        solid ground you can actually reach, or the rat fight will never
#        trigger.
#      - Q02Director — leave this wherever it lands, it has no transform that
#        matters.
# 5. Save the scene (Ctrl+S).
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
	else:
		print("Clue_Burrows already exists — left as-is.")

	if not root.has_node("Q02Director"):
		var director := Node.new()
		director.name = "Q02Director"
		director.set_script(Q02DirectorScript)
		root.add_child(director)
		director.owner = root
		print("Added Q02Director.")
	else:
		print("Q02Director already exists — left as-is.")

	print("Q02 setup done. Drag Clue_Burrows onto real, reachable ground deeper in the wetland, then save the scene.")
