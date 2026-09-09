@tool
extends EditorScript

# ONE-TIME SETUP HELPER — not used at runtime.
#
# How to run:
# 1. In the Godot editor, open "res://levels/main terrain.scn" and make it the
#    active scene tab.
# 2. Open this file in the Script workspace.
# 3. File > Run (or Ctrl+Shift+X).
# 4. In the Scene dock you'll now see Clue_Water, Clue_Plants, Clue_Debris and
#    Q01Director under the scene root. Drag each Clue_* node so it sits on/near
#    the matching terrain feature (dirty water / dead plants / trash), ideally
#    re-parenting it onto that feature's own mesh node so the scan highlight
#    outlines the right object. Then save the scene (Ctrl+S).
#
# Safe to run more than once — it skips any node that already exists by name.

const KnowledgeObjectScene = preload("res://levels/knowledge_object.tscn")
const Q01DirectorScript = preload("res://levels/q01_director.gd")

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open 'main terrain.scn' as the active scene tab first, then run this script.")
		return

	_add_clue(root, "Clue_Water", "q01_water", Vector3(3, 0.5, 3))
	_add_clue(root, "Clue_Plants", "q01_plants", Vector3(-3, 0.5, 4))
	_add_clue(root, "Clue_Debris", "q01_debris", Vector3(0, 0.5, -4))

	if not root.has_node("Q01Director"):
		var director := Node.new()
		director.name = "Q01Director"
		director.set_script(Q01DirectorScript)
		root.add_child(director)
		director.owner = root
		print("Added Q01Director.")

	print("Q01 setup done. Reposition the three Clue_* markers onto the dirty water, dead plants, and trash, then save the scene.")

func _add_clue(root: Node, node_name: String, knowledge_id: String, pos: Vector3) -> void:
	if root.has_node(node_name):
		return
	var clue := KnowledgeObjectScene.instantiate()
	clue.name = node_name
	clue.knowledge_id = knowledge_id
	root.add_child(clue)
	clue.owner = root
	clue.position = pos
	print("Added ", node_name, " at ", pos)
