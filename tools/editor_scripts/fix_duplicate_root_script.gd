@tool
extends EditorScript

# ONE-TIME FIX — the scene ROOT node ("main terrain") somehow ended up with
# q01_director.gd attached directly to it, completely separately from the
# proper child node named "Q01Director". Both were independently running the
# full Q01 sequence, which is why scanning a clue spawned two mosquitoes.
# This removes the script from the ROOT ONLY. The child "Q01Director" node is
# untouched and keeps working exactly as before.
#
# How to run:
# 1. Open "res://levels/main terrain.scn" and make it the active scene tab.
# 2. Open this file, then File > Run (or Ctrl+Shift+X).
# 3. Check the Output panel.
# 4. Save the scene (Ctrl+S).

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open 'main terrain.scn' as the active scene tab first, then run this script.")
		return

	var root_script: Script = root.get_script()
	if root_script == null:
		print("Root has no script attached. Nothing to fix here.")
		return

	var root_script_path: String = root_script.resource_path
	if not root_script_path.ends_with("q01_director.gd"):
		print("Root's script is '", root_script_path, "', not q01_director.gd — leaving it alone.")
		print("(If duplicates are still happening, the second copy may be a different script — tell me what this printed.)")
		return

	print("Root node '", root.name, "' has q01_director.gd attached directly to it. Removing it.")
	root.set_script(null)
	print("Done. The child 'Q01Director' node (if present) is untouched. Save the scene now (Ctrl+S).")
