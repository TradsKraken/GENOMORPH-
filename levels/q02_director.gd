extends Node
class_name Q02Director

## Q02 — Invasive Rat (see files/GenoMorph_Quest_Flow.md).
## Player finds fresh burrows/tracks, scans them, a small rat pack shows up.
## Clearing the pack ends this quest step and hands off toward Q03 (not built yet).

const RatScene = preload("res://enemies/rat.tscn")

@export var rat_pack_size: int = 3

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
	PlayerData.set_objective(null, "Investigate the disturbance", "Something else is out here. Find the source.")

	_state = SequenceState.WAITING_FOR_SCAN

func _on_burrows_scanned(clue_node: Node) -> void:
	if _state != SequenceState.WAITING_FOR_SCAN: return
	_state = SequenceState.FIGHTING_RATS

	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "Those burrows are fresh. Whatever's denning here, it isn't supposed to be.", 4.0)

	await get_tree().create_timer(2.0).timeout

	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("WARNING", "Invasive rat pack detected!", 3.0)

	_living_rats.clear()
	for i in range(rat_pack_size):
		var angle = (float(i) / rat_pack_size) * TAU
		var offset = Vector3(cos(angle), 0, sin(angle)) * 2.0
		var rat = RatScene.instantiate()
		get_parent().add_child(rat)
		rat.global_position = clue_node.global_position + offset + Vector3(2.0, 0.5, 2.0)
		rat.tree_exited.connect(_on_rat_died)
		_living_rats.append(rat)

	PlayerData.set_objective(null, "Clear the invasive rats", "%d remaining" % _living_rats.size())

func _on_rat_died() -> void:
	_living_rats = _living_rats.filter(func(r): return is_instance_valid(r) and not r.is_queued_for_deletion())

	if _state != SequenceState.FIGHTING_RATS:
		return

	if _living_rats.size() > 0:
		PlayerData.set_objective(null, "Clear the invasive rats", "%d remaining" % _living_rats.size())
		return

	_state = SequenceState.DONE
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "That's the last of them for now. But this disturbance goes deeper — keep moving.", 5.0)

	PlayerData.set_objective(null, "Explore deeper into the wetlands")
