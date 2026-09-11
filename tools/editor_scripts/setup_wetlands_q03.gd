@tool
extends EditorScript

# ONE-TIME SETUP HELPER — not used at runtime.
#
# How to run:
# 1. Open "res://levels/main terrain.scn" and make it the active scene tab.
# 2. Open this file, File > Run (or Ctrl+Shift+X).
# 3. In the Scene dock you'll see three new nodes under the scene root, all at
#    arbitrary default positions that know nothing about your actual terrain —
#    reposition every one of them onto real, walkable ground:
#      - NativeFrog — the frog in danger. Place it somewhere deeper into the
#        wetland than Q02's rat fight. It carries its own ambush-trigger area
#        (built in code, no separate node to place) — walking near it is what
#        starts the second rat fight. Adjust its "Ambush Radius" export in the
#        Inspector if you want a bigger/smaller trigger radius (default 6m).
#      - HabitatRestorePoint — the interactable "critical damaged area."
#        Place it near NativeFrog, somewhere that reads as visibly damaged.
#      - SafeSpot — where NativeFrog hops to once the habitat is restored.
#        Place it somewhere nearby that reads as safe/healthier.
#      - Q03Director — leave this wherever it lands, it has no transform that
#        matters.
# 4. Save the scene (Ctrl+S).
#
# If you ran an earlier version of this script, it also removes the old
# standalone "AmbushZone" node — that's no longer used now that the trigger
# lives on NativeFrog itself.
#
# Safe to run more than once — it skips any node that already exists by name.

const HabitatRestorePointScene = preload("res://levels/habitat_restore_point.tscn")
const NativeFrogScript = preload("res://levels/native_frog.gd")
const Q03DirectorScript = preload("res://levels/q03_director.gd")

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open 'main terrain.scn' as the active scene tab first, then run this script.")
		return

	if root.has_node("AmbushZone"):
		var old_zone = root.get_node("AmbushZone")
		old_zone.get_parent().remove_child(old_zone)
		old_zone.free()
		print("Removed the old standalone AmbushZone node (superseded by NativeFrog's own trigger).")

	if not root.has_node("NativeFrog"):
		var frog := Node3D.new()
		frog.name = "NativeFrog"
		frog.set_script(NativeFrogScript)
		root.add_child(frog)
		frog.owner = root
		frog.position = Vector3(-6, 0.5, -20)
		print("Added NativeFrog.")
	else:
		print("NativeFrog already exists — left as-is.")

	if not root.has_node("HabitatRestorePoint"):
		var restore := HabitatRestorePointScene.instantiate()
		restore.name = "HabitatRestorePoint"
		root.add_child(restore)
		restore.owner = root
		restore.position = Vector3(-4, 0.5, -22)
		print("Added HabitatRestorePoint.")
	else:
		print("HabitatRestorePoint already exists — left as-is.")

	if not root.has_node("SafeSpot"):
		var safe_spot := Node3D.new()
		safe_spot.name = "SafeSpot"
		root.add_child(safe_spot)
		safe_spot.owner = root
		safe_spot.position = Vector3(-8, 0.5, -24)
		print("Added SafeSpot.")
	else:
		print("SafeSpot already exists — left as-is.")

	if not root.has_node("Q03Director"):
		var director := Node.new()
		director.name = "Q03Director"
		director.set_script(Q03DirectorScript)
		root.add_child(director)
		director.owner = root
		print("Added Q03Director.")
	else:
		print("Q03Director already exists — left as-is.")

	print("Q03 setup done. Reposition NativeFrog, HabitatRestorePoint, and SafeSpot per the comments above, then save the scene.")
