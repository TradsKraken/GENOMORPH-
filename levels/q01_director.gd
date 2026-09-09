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
	print("[Q01 DEBUG] _ready() called on instance ", get_instance_id(), " path=", get_path())

	# Add a slight delay to let the scene fully load and HUD initialize
	await get_tree().create_timer(1.5).timeout

	_hud = get_tree().get_first_node_in_group("hud")
	if get_tree().root.has_node("QuestManager"):
		_quest_manager = get_tree().root.get_node("QuestManager")
	
	# Find all Q01 clues
	var connected_count := 0
	for node in get_tree().get_nodes_in_group("knowledge_object"):
		var kid = node.get("knowledge_id")
		if typeof(kid) == TYPE_STRING and kid.begins_with("q01_"):
			if node.has_signal("interaction_finished"):
				print("[Q01 DEBUG] connecting to clue node=", node.get_path(), " knowledge_id=", kid)
				node.interaction_finished.connect(_on_knowledge_scanned.bind(node, kid))
				connected_count += 1
	print("[Q01 DEBUG] total clue connections made: ", connected_count)

	_start_sequence()

func _start_sequence() -> void:
	print("[Q01 DEBUG] _start_sequence() called on instance ", get_instance_id())
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "Your suit is locked to Frog form for now. Go carefully, Volunteer. Whatever is out there — it isn't ordinary anymore.", 8.0)
	
	await get_tree().create_timer(6.0).timeout
	
	if _quest_manager:
		# First quest logic
		_quest_manager.set_objective("Investigate your surroundings", "Something is wrong with this wetland. Look around and find out what happened.")
		
	_state = SequenceState.WAITING_FOR_SCAN

func _on_knowledge_scanned(clue_node: Node, kid: String) -> void:
	print("[Q01 DEBUG] _on_knowledge_scanned called — clue=", clue_node.get_path(), " kid=", kid, " current _state=", _state, " director instance=", get_instance_id())
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
	
	# Spawn in verified-open air near the player.
	# Order matters: the position is set BEFORE add_child(), because add_child()
	# runs _ready() immediately — a CharacterBody3D that exists even briefly at the
	# scene root's origin (which is under the terrain here) ends up embedded in the
	# terrain's trimesh collision, and Jolt then ejects it or drops it through.
	var spawn_pos = _find_safe_spawn_point(clue_node as Node3D)
	print("[Q01 DEBUG] SPAWNING MOSQUITO — clue=", clue_node.get_path(), " director instance=", get_instance_id(), " at ", spawn_pos)

	var mosquito = MosquitoScene.instantiate()
	mosquito.position = spawn_pos
	get_tree().current_scene.add_child(mosquito)
	mosquito.global_position = spawn_pos

	# Connect to its death signal
	mosquito.tree_exited.connect(_on_mosquito_defeated)
	
	if _quest_manager:
		_quest_manager.set_objective("Defeat the invasive mosquito!")

## Picks a spot a few metres from the player, then raycasts down to find the real
## ground height there and returns a point hovering above it. Anchoring to the
## player matters: the player is provably standing in open, non-colliding space,
## whereas a fixed offset from the clue can land inside a tree/rock collider.
func _find_safe_spawn_point(clue_node: Node3D) -> Vector3:
	var anchor: Vector3 = clue_node.global_position
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player is Node3D:
		anchor = (player as Node3D).global_position

	var angle := randf() * TAU
	var spot := anchor + Vector3(cos(angle) * 3.0, 0.0, sin(angle) * 3.0)

	var space := clue_node.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		spot + Vector3(0, 10.0, 0),
		spot - Vector3(0, 20.0, 0)
	)
	var hit := space.intersect_ray(query)

	var ground_y: float = anchor.y
	if hit.has("position"):
		ground_y = (hit["position"] as Vector3).y

	return Vector3(spot.x, ground_y + 1.5, spot.z)

func _on_mosquito_defeated() -> void:
	if _state != SequenceState.FIGHTING_MOSQUITO: return
	_state = SequenceState.DONE
	
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("STERLING (RADIO)", "Good job. Keep moving, we need to find the source of the corruption.", 5.0)
		
	if _quest_manager:
		_quest_manager.set_objective("Explore deeper into the wetlands")
