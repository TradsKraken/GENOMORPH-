@tool
extends EditorScript

# ONE-TIME CLEANUP — removes duplicate Q01Director nodes (the cause of the
# mosquito spawning twice: each director independently spawns its own
# mosquito when a clue is scanned). Safe to run more than once.
#
# How to run:
# 1. Open "res://levels/main terrain.scn" and make it the active scene tab.
# 2. Open this file, then File > Run (or Ctrl+Shift+X).
# 3. Check the Output panel for what it found/removed.
# 4. Save the scene (Ctrl+S).

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open 'main terrain.scn' as the active scene tab first, then run this script.")
		return

	var directors: Array = []
	_find_by_name(root, "Q01Director", directors)

	if directors.size() <= 1:
		print("Found %d Q01Director node(s) — no duplicates. Nothing to do." % directors.size())
	else:
		print("Found %d Q01Director nodes — keeping the first (%s), removing the rest." % [directors.size(), str(directors[0].get_path())])
		for i in range(1, directors.size()):
			var dup: Node = directors[i]
			print("Removing duplicate: ", dup.get_path())
			dup.get_parent().remove_child(dup)
			dup.free()
		print("Cleanup done. Save the scene now (Ctrl+S).")

	# Informational only — report (don't touch) any clues sharing a knowledge_id,
	# since that's a separate thing worth knowing about but not what caused this bug.
	var clues_by_id: Dictionary = {}
	_collect_knowledge_objects(root, clues_by_id)
	for kid in clues_by_id.keys():
		var paths: Array = clues_by_id[kid]
		if paths.size() > 1:
			print("NOTE: knowledge_id '%s' appears on %d nodes: %s" % [kid, paths.size(), str(paths)])

func _find_by_name(node: Node, target_name: String, out_list: Array) -> void:
	if node.name == target_name:
		out_list.append(node)
	for child in node.get_children():
		_find_by_name(child, target_name, out_list)

func _collect_knowledge_objects(node: Node, out_map: Dictionary) -> void:
	if "knowledge_id" in node:
		var kid = node.get("knowledge_id")
		if typeof(kid) == TYPE_STRING and kid != "":
			if not out_map.has(kid):
				out_map[kid] = []
			out_map[kid].append(str(node.get_path()))
	for child in node.get_children():
		_collect_knowledge_objects(child, out_map)
