extends Node
class_name Q01Director

signal completed

const MosquitoScene = preload("res://enemies/mosquito_swarm.tscn")

@export var swarm_size: int = 3

var _hud: Node = null

enum SequenceState {
	INIT,
	WAITING_FOR_SCAN,
	FIGHTING_MOSQUITO,
	FIGHTING_SWARM,
	DONE
}

var _state: SequenceState = SequenceState.INIT
var _last_spawn_pos: Vector3 = Vector3.ZERO
var _living_swarm: Array[Node] = []

func _ready() -> void:
	add_to_group("q01_director")

	# Add a slight delay to let the scene fully load and HUD initialize
	await get_tree().create_timer(1.5).timeout

	_hud = get_tree().get_first_node_in_group("hud")

	# Find all Q01 clues
	for node in get_tree().get_nodes_in_group("knowledge_object"):
		var kid = node.get("knowledge_id")
		if typeof(kid) == TYPE_STRING and kid.begins_with("q01_"):
			if node.has_signal("interaction_finished"):
				node.interaction_finished.connect(_on_knowledge_scanned.bind(node, kid))
	
	_start_sequence()

func _start_sequence() -> void:
	# Sterling already says this over the radio subtitle during the wake-up
	# sequence (see prologue_manager.gd) — showing it again here as a popup
	# was a redundant repeat of the same line.
	PlayerData.set_objective(null, "Investigate your surroundings", "Something is wrong with this wetland. Look around and find out what happened.")

	_state = SequenceState.WAITING_FOR_SCAN

func _on_knowledge_scanned(clue_node: Node, kid: String) -> void:
	# All clues trigger Sterling flavor text
	if _hud and _hud.has_method("show_notification"):
		if kid == "q01_water":
			_hud.show_notification("STERLING (RADIO)", "That water shouldn't be that color. Test it if you can — I want that data.", 4.0)
		elif kid == "q01_plants":
			_hud.show_notification("STERLING (RADIO)", "This isn't natural die-off. Something's been sitting here a long time.", 4.0)
		elif kid == "q01_debris":
			_hud.show_notification("STERLING (RADIO)", "...Yeah. That tracks. This didn't happen by accident.", 4.0)
			
	# ONLY the FIRST clue scanned triggers the quest progression
	if _state != SequenceState.WAITING_FOR_SCAN: return
	
	_state = SequenceState.FIGHTING_MOSQUITO
	
	# Small delay so Sterling's flavor text plays before the warning
	await get_tree().create_timer(2.0).timeout
	
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("WARNING", "Invasive organism detected!", 3.0)
	
	# Spawn a mosquito slightly away from the clue
	var spawn_pos = clue_node.global_position + Vector3(2.0, 1.0, 2.0)
	
	var mosquito = MosquitoScene.instantiate()
	get_parent().add_child(mosquito)
	mosquito.global_position = spawn_pos
	_last_spawn_pos = spawn_pos

	# Connect to its death signal
	mosquito.tree_exited.connect(_on_mosquito_defeated)

	PlayerData.set_objective(null, "Defeat the invasive mosquito!")

func _on_mosquito_defeated() -> void:
	if _state != SequenceState.FIGHTING_MOSQUITO: return
	_state = SequenceState.FIGHTING_SWARM

	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "That wasn't the only one. More incoming — stay sharp.", 4.0)

	await get_tree().create_timer(2.0).timeout

	_living_swarm.clear()
	for i in range(swarm_size):
		var angle = (float(i) / swarm_size) * TAU
		var offset = Vector3(cos(angle), 0, sin(angle)) * 2.5
		var mosquito_2 = MosquitoScene.instantiate()
		get_parent().add_child(mosquito_2)
		mosquito_2.global_position = _last_spawn_pos + offset
		mosquito_2.tree_exited.connect(_on_swarm_mosquito_died)
		_living_swarm.append(mosquito_2)

	PlayerData.set_objective(null, "Clear the mosquito swarm!", "%d remaining" % _living_swarm.size())

func _on_swarm_mosquito_died() -> void:
	_living_swarm = _living_swarm.filter(func(m): return is_instance_valid(m) and not m.is_queued_for_deletion())

	if _state != SequenceState.FIGHTING_SWARM:
		return

	if _living_swarm.size() > 0:
		PlayerData.set_objective(null, "Clear the mosquito swarm!", "%d remaining" % _living_swarm.size())
		return

	_state = SequenceState.DONE

	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "Good job. Keep moving, we need to find the source of the corruption.", 5.0)

	PlayerData.set_objective(null, "Explore deeper into the wetlands")

	completed.emit()
