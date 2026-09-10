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

func _ready() -> void:
	add_to_group("q02_director")

	_hud = get_tree().get_first_node_in_group("hud")

	for node in get_tree().get_nodes_in_group("knowledge_object"):
		var kid = node.get("knowledge_id")
		if kid == "q02_burrows" and node.has_signal("interaction_finished"):
			node.interaction_finished.connect(_on_burrows_scanned.bind(node))

	# Don't start until Q01 (the wake-up/mosquito sequence) actually finishes —
	# starting on our own fixed timer would race Q01's objective and dialogue.
	var q01_nodes = get_tree().get_nodes_in_group("q01_director")
	if q01_nodes.size() > 0:
		var q01 = q01_nodes[0]
		if "_state" in q01 and q01._state == Q01Director.SequenceState.DONE:
			_begin()
		else:
			q01.completed.connect(_begin)
	else:
		# No Q01Director in this scene (e.g. a test level) — just start.
		_begin()

func _begin() -> void:
	# "DisturbanceMarker" is a plain Node3D placed a distance away from the
	# actual Clue_Burrows — this is the "marker points to a general area, not
	# an exact path" step. If it's missing, fall back to text-only.
	var marker = get_tree().current_scene.find_child("DisturbanceMarker", true, false)
	PlayerData.set_objective(marker, "Investigate the disturbance", "Something else is out here. Find the source.")

	_state = SequenceState.WAITING_FOR_SCAN

func _on_burrows_scanned(clue_node: Node) -> void:
	if _state != SequenceState.WAITING_FOR_SCAN: return
	_state = SequenceState.FIGHTING_RATS

	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "Those burrows are fresh — and something's had the local wildlife running scared.", 4.0)

	# Breathing room before the fight starts, same reasoning as Q01: give the
	# player time to read the line instead of the pack landing on top of it.
	await get_tree().create_timer(4.0).timeout

	_living_rats.clear()
	for i in range(rat_pack_size):
		var spawn_pos = _find_safe_spawn_point(clue_node as Node3D, spawn_distance)
		var rat = RatScene.instantiate()
		rat.position = spawn_pos
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

	completed.emit()
