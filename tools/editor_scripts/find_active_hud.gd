@tool
extends EditorScript

# DIAGNOSTIC — does not change anything. Finds whatever node is in the "hud"
# group inside the saved scene and reports its script, so we know for certain
# whether ui/hud.gd or ui/hud_head.gd is the one actually live in gameplay.
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

	_scan(root)
	print("Scan complete.")

func _scan(node: Node) -> void:
	# Godot's "group" membership only exists at runtime (added via add_to_group()
	# in _ready()), so in the editor we instead look for any node whose script
	# is literally hud.gd or hud_head.gd, wherever it sits in the tree.
	var script: Script = node.get_script()
	if script:
		var path: String = script.resource_path
		if path.ends_with("hud.gd") or path.ends_with("hud_head.gd"):
			print("FOUND HUD NODE: ", node.get_path(), "  script=", path, "  node_type=", node.get_class())

	for child in node.get_children():
		_scan(child)
