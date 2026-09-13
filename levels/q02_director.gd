extends Node
class_name Q02Director

## Q02 — Invasive Rat (see files/GenoMorph_Quest_Flow.md, Step 6-7).
## Player gets a general-direction objective, finds burrows/tracks, scans them,
## a rat pack shows up. Clearing the pack ends this step.

const RatScene = preload("res://enemies/rat.tscn")

@export var rat_pack_size: int = 3
@export var spawn_distance: float = 6.0

signal completed

var _hud: Node = null

enum SequenceState {
	INIT,
	WAITING_FOR_SCAN,
	FIGHTING_RATS,
	DONE
}

var _state: SequenceState = SequenceState.INIT
var _living_rats: Array[Node] = []
var _scout_rat: Node3D = null
var _scout_fled: bool = false
var _clue: Node3D = null
var _clue_sighted: bool = false

func _ready() -> void:
	add_to_group("q02_director")
	# Do not replay completed encounters after loading a save.  Q03 reads the
	# persisted q02_completed checkpoint and will start itself when appropriate.
	if PlayerData.q02_completed:
		_state = SequenceState.DONE
		return

	_hud = get_tree().get_first_node_in_group("hud")

	for node in get_tree().get_nodes_in_group("knowledge_object"):
		var kid = node.get("knowledge_id")
		if kid == "q02_burrows" and node.has_signal("interaction_finished"):
			node.interaction_finished.connect(_on_burrows_scanned.bind(node))

	# Don't start until Q01 (the wake-up/mosquito sequence) actually finishes —
	# starting on our own fixed timer would race Q01's objective and dialogue.
	# PlayerData.q01_completed is checked first because it's a persistent
	# state flag, not a node lookup — relying on sibling _ready() order
	# happening to match creation order (director nodes were added to the
	# scene in the order their setup scripts were run) worked, but only by
	# luck, not by any actual guarantee.
	if PlayerData.q01_completed:
		_begin()
	else:
		var q01_nodes = get_tree().get_nodes_in_group("q01_director")
		if q01_nodes.size() > 0:
			var q01 = q01_nodes[0]
			q01.completed.connect(_begin)
		else:
			# No Q01Director in this scene (e.g. a test level) — just start.
			_begin()

func _process(delta: float) -> void:
	if _state == SequenceState.WAITING_FOR_SCAN and not _clue_sighted and is_instance_valid(_clue):
		var player = get_tree().get_first_node_in_group("player")
		if player and player is Node3D:
			if player.global_position.distance_to(_clue.global_position) < 10.0:
				_clue_sighted = true
				if _hud and _hud.has_method("show_subtitle"):
					_hud.show_subtitle("STERLING (RADIO)", "Hold on — burrow holes, fresh tracks. Something's nesting right there. Take a closer look.", 4.5)

	if _state == SequenceState.WAITING_FOR_SCAN and is_instance_valid(_scout_rat) and not _scout_fled:
		var player = get_tree().get_first_node_in_group("player")
		if player and player is Node3D:
			if player.global_position.distance_to(_scout_rat.global_position) < 15.0:
				_scout_fled = true
				_scout_rat.set_physics_process(false)
				var tw = create_tween()
				tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tw.tween_property(_scout_rat, "position:y", _scout_rat.position.y - 2.0, 0.6)
				tw.tween_callback(_scout_rat.queue_free)

func _begin() -> void:
	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "I'm picking up some strange readings up ahead. See if you can find the source.", 4.0)
		await _wait_for_dialogue()

	# Points the objective arrow straight at the actual clue. An earlier
	# version pointed at a separate "DisturbanceMarker" placed some distance
	# away (for a "general area, not exact path" feel) — but with no level
	# detail built yet to reward exploring around a vague area, that just read
	# as the marker doing nothing. One node to place, no risk of the marker
	# and the clue drifting apart. Revisit the vague-marker version once the
	# wetlands have real environmental detail to explore through.
	var clue = get_tree().current_scene.find_child("Clue_Burrows", true, false)
	PlayerData.set_objective(clue, "Investigate the disturbance", "Something else is out here. Find the source.")

	if clue:
		_clue = clue as Node3D
		_spawn_burrow_visual(clue as Node3D)

		_scout_rat = RatScene.instantiate()
		_scout_rat.position = clue.global_position + Vector3(0, 0, 1.5)
		get_tree().current_scene.add_child(_scout_rat)
		_scout_rat.global_position = clue.global_position + Vector3(0, 0, 1.5)
		# Temporarily disable its AI processing so it just stands idle
		_scout_rat.set_physics_process(false)

	_state = SequenceState.WAITING_FOR_SCAN

## Clue_Burrows has no matching art in the terrain (unlike Q01's clues, which
## get re-parented onto the level's existing dirty-water/dead-plant/trash
## meshes) — so without this, the clue was a completely invisible trigger.
## Builds a small dug-up mud mound with dark burrow holes, procedurally, since
## there's no imported "rat burrow" mesh asset to place instead.
func _spawn_burrow_visual(clue: Node3D) -> void:
	var mud_mat = StandardMaterial3D.new()
	mud_mat.albedo_color = Color(0.26, 0.18, 0.11)
	mud_mat.roughness = 1.0

	var mound = MeshInstance3D.new()
	var mound_mesh = CylinderMesh.new()
	mound_mesh.top_radius = 0.5
	mound_mesh.bottom_radius = 0.9
	mound_mesh.height = 0.35
	mound_mesh.radial_segments = 12
	mound.mesh = mound_mesh
	mound.material_override = mud_mat
	clue.add_child(mound)
	mound.owner = null
	mound.position = Vector3(0, 0.17, 0)

	var hole_mat = StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.02, 0.015, 0.015)
	hole_mat.roughness = 1.0

	var hole_offsets = [Vector2(0.18, 0.08), Vector2(-0.2, -0.12), Vector2(0.02, -0.24)]
	for offset in hole_offsets:
		var hole = MeshInstance3D.new()
		var hole_mesh = CylinderMesh.new()
		hole_mesh.top_radius = 0.13
		hole_mesh.bottom_radius = 0.13
		hole_mesh.height = 0.08
		hole_mesh.radial_segments = 8
		hole.mesh = hole_mesh
		hole.material_override = hole_mat
		mound.add_child(hole)
		hole.position = Vector3(offset.x, 0.18, offset.y)

	# Loose dirt clumps scattered around the base for a freshly-dug look.
	for i in range(6):
		var clump = MeshInstance3D.new()
		var clump_mesh = SphereMesh.new()
		var clump_radius = randf_range(0.08, 0.17)
		clump_mesh.radius = clump_radius
		clump_mesh.height = clump_radius * 1.6
		clump.mesh = clump_mesh
		clump.material_override = mud_mat
		clue.add_child(clump)
		var angle = randf() * TAU
		var r = randf_range(0.7, 1.15)
		clump.position = Vector3(cos(angle) * r, 0.05, sin(angle) * r)

func _on_burrows_scanned(clue_node: Node) -> void:
	if _state != SequenceState.WAITING_FOR_SCAN: return
	_state = SequenceState.FIGHTING_RATS

	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "Those burrows are fresh — and something's had the local wildlife running scared.", 4.0)

	# Wait for the player to tap through this line before the pack shows up —
	# same reasoning as Q01: let them read at their own pace instead of a
	# fixed timer that might land the pack before they've finished reading.
	await _wait_for_dialogue()

	_living_rats.clear()
	for i in range(rat_pack_size):
		var spawn_pos = _find_safe_spawn_point(clue_node as Node3D, spawn_distance)
		var rat = RatScene.instantiate()
		rat.position = spawn_pos
		rat.is_dynamic = true
		get_tree().current_scene.add_child(rat)
		rat.global_position = spawn_pos
		rat.tree_exited.connect(_on_rat_died)
		_living_rats.append(rat)

	PlayerData.set_objective(null, "Clear the invasive rats", "%d remaining" % _living_rats.size())

## Same approach as Q01Director._find_safe_spawn_point — anchor to the player
## (provably standing in open, non-colliding space) rather than the clue, and
## raycast down to find real ground height so nothing spawns embedded in
## terrain collision or right on top of the knowledge object.
func _find_safe_spawn_point(reference: Node3D, distance: float) -> Vector3:
	var anchor: Vector3 = reference.global_position
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player is Node3D:
		anchor = (player as Node3D).global_position

	var angle := randf() * TAU
	var spot := anchor + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)

	var space := reference.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		spot + Vector3(0, 10.0, 0),
		spot - Vector3(0, 20.0, 0)
	)
	var hit := space.intersect_ray(query)

	var ground_y: float = anchor.y
	if hit.has("position"):
		ground_y = (hit["position"] as Vector3).y

	return Vector3(spot.x, ground_y + 1.5, spot.z)

func _on_rat_died() -> void:
	_living_rats = _living_rats.filter(func(r): return is_instance_valid(r) and not r.is_queued_for_deletion())

	if _state != SequenceState.FIGHTING_RATS:
		return

	if _living_rats.size() > 0:
		PlayerData.set_objective(null, "Clear the invasive rats", "%d remaining" % _living_rats.size())
		return

	_state = SequenceState.DONE
	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "That's the last of them for now. But this disturbance goes deeper — keep moving.", 5.0)

	PlayerData.set_objective(null, "Explore deeper into the wetlands")

	PlayerData.q02_completed = true
	PlayerData.award_progression_reward("q02_complete", 40.0)
	completed.emit()

## Waits for the player to tap through the currently-shown subtitle before
## continuing — falls back to a fixed delay if there's no HUD to report a
## dismissal (e.g. a test scene), so this never hangs forever.
func _wait_for_dialogue() -> void:
	if _hud and _hud.has_signal("subtitle_dismissed"):
		await _hud.subtitle_dismissed
	else:
		await get_tree().create_timer(2.0).timeout
