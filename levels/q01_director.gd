extends Node
class_name Q01Director

const MosquitoScene = preload("res://enemies/mosquito_swarm.tscn")

var _hud: Node = null
var _quest_manager: Node = null

enum SequenceState {
	INIT,
	WAITING_FOR_SCAN,
	FIGHTING_MOSQUITO,
	DONE
}

var _state: SequenceState = SequenceState.INIT

func _ready() -> void:
	# Add a slight delay to let the scene fully load and HUD initialize
	await get_tree().create_timer(1.5).timeout
	
	_hud = get_tree().get_first_node_in_group("hud")
	if get_tree().root.has_node("QuestManager"):
		_quest_manager = get_tree().root.get_node("QuestManager")
	
	# Find all Q01 clues
	for node in get_tree().get_nodes_in_group("knowledge_object"):
		var kid = node.get("knowledge_id")
		if typeof(kid) == TYPE_STRING and kid.begins_with("q01_"):
			if node.has_signal("interaction_finished"):
				node.interaction_finished.connect(_on_knowledge_scanned.bind(node, kid))
	
	_start_sequence()

func _start_sequence() -> void:
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "Your suit is locked to Frog form for now. Go carefully, Volunteer. Whatever is out there — it isn't ordinary anymore.", 8.0)
	
	await get_tree().create_timer(6.0).timeout
	
	if _quest_manager:
		_quest_manager.set_objective("Investigate your surroundings")
		
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
	
	# Connect to its death signal
	mosquito.tree_exited.connect(_on_mosquito_defeated)
	
	if _quest_manager:
		_quest_manager.set_objective("Defeat the invasive mosquito!")

func _on_mosquito_defeated() -> void:
	if _state != SequenceState.FIGHTING_MOSQUITO: return
	_state = SequenceState.DONE
	
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "Good job. Keep moving, we need to find the source of the corruption.", 5.0)
		
	if _quest_manager:
		_quest_manager.set_objective("Explore deeper into the wetlands")
