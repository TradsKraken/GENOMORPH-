@tool
extends EditorScript

# DIAGNOSTIC — does not change anything. Lists every node in the scene that
# could independently produce a mosquito: any MosquitoSwarm already placed
# statically in the level, and any EnemySpawner whose enemy_scene is the
# mosquito scene. If Q01Director's count is fine but you still see 2 on
# screen, one of these is very likely the second source.
#
# How to run:
# 1. Open "res://levels/main terrain.scn" and make it the active scene tab.
# 2. Open this file, File > Run (or Ctrl+Shift+X).
# 3. Read the Output panel.

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open 'main terrain.scn' as the active scene tab first, then run this script.")
		return

	var found_anything := false
	found_anything = _scan(root) or found_anything

	var q01_count: Array = []
	_find_by_name(root, "Q01Director", q01_count)
	print("Q01Director count: ", q01_count.size())

	if not found_anything:
		print("No standalone mosquitoes or mosquito-spawning EnemySpawners found in the saved scene.")
		print("That means the second one is being created at RUNTIME, not placed in the scene file —")
		print("check if there's more than one script reacting to the same clue (e.g. something besides")
		print("Q01Director also listening for 'q01_' knowledge_object scans).")

func _scan(node: Node) -> bool:
	var any_found := false
	var script: Script = node.get_script()
	if script:
		var script_path: String = script.resource_path
		if script_path.ends_with("mosquito_swarm.gd"):
			print("STATIC MosquitoSwarm already placed in scene: ", node.get_path(), " at position ", node.position)
			any_found = true
		elif script_path.ends_with("enemy_spawner.gd"):
			var enemy_scene = node.get("enemy_scene")
			var scene_path := ""
			if enemy_scene:
				scene_path = enemy_scene.resource_path
			if scene_path.ends_with("mosquito_swarm.tscn"):
				print("EnemySpawner configured for mosquitoes: ", node.get_path(),
					" max_spawns=", node.get("max_spawns"),
					" spawn_asleep_initially=", node.get("spawn_asleep_initially"),
					" auto_wake=", node.get("auto_wake"))
				any_found = true

	for child in node.get_children():
		any_found = _scan(child) or any_found
	return any_found

func _find_by_name(node: Node, target_name: String, out_list: Array) -> void:
	if node.name == target_name:
		out_list.append(node)
	for child in node.get_children():
		_find_by_name(child, target_name, out_list)
