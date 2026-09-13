extends Node
class_name Q01Director

signal completed

const MosquitoScene = preload("res://enemies/mosquito_swarm.tscn")

@export var swarm_size: int = 3
@export var spawn_distance: float = 12.0 # Increased from 6.0 so they don't spawn right on top of the player

var _hud: Node = null

enum SequenceState {
	INIT,
	WAITING_FOR_SCAN,
	FIGHTING_MOSQUITO,
	FIGHTING_SWARM,
	DONE
}

var _state: SequenceState = SequenceState.INIT
var _living_swarm: Array[Node] = []

func _ready() -> void:
	add_to_group("q01_director")
	# This quest has already been completed in the loaded save.  Leaving the
	# director dormant prevents its opening objective and enemy encounters from
	# overwriting the player's later progress.
	if PlayerData.q01_completed:
		_state = SequenceState.DONE
		return

	# Add a slight delay to let the scene fully load and HUD initialize
	await get_tree().create_timer(1.5).timeout

	_hud = get_tree().get_first_node_in_group("hud")

	# Find all Q01 clues
	for node in get_tree().get_nodes_in_group("knowledge_object"):
		var kid = node.get("knowledge_id")
		if typeof(kid) == TYPE_STRING and kid.begins_with("q01_"):
			if node.has_signal("interaction_finished"):
				node.interaction_finished.connect(_on_knowledge_scanned.bind(node, kid))

	# Don't set the first objective until Sterling's wake-up conversation is
	# actually over (see prologue_manager.gd) — starting on our own timer
	# would race that dialogue. PlayerData.has_seen_prologue is checked first
	# because the prologue node emits its signal and frees itself immediately
	# when the prologue was already seen, which could otherwise race against
	# us connecting to it.
	if PlayerData.has_seen_prologue:
		_start_sequence()
	else:
		var prologue_nodes = get_tree().get_nodes_in_group("prologue_manager")
		if prologue_nodes.size() > 0:
			prologue_nodes[0].finished.connect(_start_sequence)
		else:
			# No prologue in this scene (e.g. a test level) — just start.
			_start_sequence()

func _start_sequence() -> void:
	# A brief beat lets the player regain their bearings before the objective.
	await get_tree().create_timer(0.5).timeout

	# The HUD's quest display reads from PlayerData.current_objective_text/desc
	# (see hud.gd) — not from the separate QuestManager autoload, which
	# nothing in the live HUD actually listens to.
	PlayerData.set_objective(null, "Investigate your surroundings", "Something is wrong with this wetland. Look around and find out what happened.")

	_state = SequenceState.WAITING_FOR_SCAN

func _on_knowledge_scanned(clue_node: Node, kid: String) -> void:
	# All clues trigger Sterling flavor text — lightweight subtitle bar, not
	# the big centered popup (that's reserved for achievement-style toasts
	# like "NEW KNOWLEDGE" / "OBJECTIVE COMPLETE", not conversational lines).
	if _hud and _hud.has_method("show_subtitle"):
		if kid == "q01_water":
			_hud.show_subtitle("STERLING (RADIO)", "That water shouldn't be that color. Test it if you can — I want that data.", 4.0)
		elif kid == "q01_plants":
			_hud.show_subtitle("STERLING (RADIO)", "This isn't natural die-off. Something's been sitting here a long time.", 4.0)
		elif kid == "q01_debris":
			_hud.show_subtitle("STERLING (RADIO)", "...Yeah. That tracks. This didn't happen by accident.", 4.0)

	# ONLY the FIRST clue scanned triggers the quest progression
	if _state != SequenceState.WAITING_FOR_SCAN: return

	_state = SequenceState.FIGHTING_MOSQUITO

	# Wait for the player to actually tap through Sterling's line before the
	# mosquito shows up, instead of a fixed timer — they read at their own
	# pace. No separate "WARNING" system alert here on purpose — that
	# treatment reads as an emergency-level alarm, which is overselling a
	# single mosquito. Sterling's line above already carries the "something's
	# wrong" beat; the mosquito's buzzing sound and it flying into view do
	# the rest.
	await _wait_for_dialogue()

	var spawn_pos = _find_safe_spawn_point(clue_node as Node3D, spawn_distance)

	var mosquito = MosquitoScene.instantiate()
	mosquito.position = spawn_pos
	get_tree().current_scene.add_child(mosquito)
	mosquito.global_position = spawn_pos

	# Connect to its death signal
	mosquito.tree_exited.connect(_on_mosquito_defeated)

	PlayerData.set_objective(null, "Defeat the invasive mosquito!")

## Picks a spot `distance` metres from the player in a random direction, then
## raycasts down to find the real ground height there and returns a point
## hovering above it. Anchoring to the player (not the clue/reference) matters:
## the player is provably standing in open, non-colliding space, whereas a
## fixed offset from the clue can land inside a tree/rock collider — and it
## also keeps the spawn from appearing right on top of the knowledge object.
## `reference` only supplies world-space context (get_world_3d()) and is used
## as the anchor solely as a fallback if no player can be found.
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

func _on_mosquito_defeated() -> void:
	if _state != SequenceState.FIGHTING_MOSQUITO: return
	_state = SequenceState.FIGHTING_SWARM

	# Lightweight subtitle bar instead of the big centered popup — that heavy
	# "pop-up moment" treatment is meant for deliberate interruptions (like the
	# Investigation Card), not routine combat asides.
	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "That wasn't the only one. More incoming — stay sharp.", 4.0)

	# Wait for the player to tap through this line — plenty of time to see the
	# first mosquito's XP orbs land and actually read Sterling's line, instead
	# of a fixed beat before the next fight starts regardless of whether
	# they've finished reading.
	await _wait_for_dialogue()

	var player = get_tree().get_first_node_in_group("player")
	if not (player and player is Node3D):
		_finish_sequence()
		return

	_living_swarm.clear()
	for i in range(swarm_size):
		var spawn_pos = _find_safe_spawn_point(player as Node3D, spawn_distance)
		var mosquito = MosquitoScene.instantiate()
		mosquito.position = spawn_pos
		get_tree().current_scene.add_child(mosquito)
		mosquito.global_position = spawn_pos
		mosquito.tree_exited.connect(_on_swarm_mosquito_died)
		_living_swarm.append(mosquito)

	PlayerData.set_objective(null, "Clear the mosquito swarm!", "%d remaining" % _living_swarm.size())

func _on_swarm_mosquito_died() -> void:
	_living_swarm = _living_swarm.filter(func(m): return is_instance_valid(m) and not m.is_queued_for_deletion())

	if _state != SequenceState.FIGHTING_SWARM:
		return

	if _living_swarm.size() > 0:
		PlayerData.set_objective(null, "Clear the mosquito swarm!", "%d remaining" % _living_swarm.size())
		return

	_finish_sequence()

func _finish_sequence() -> void:
	_state = SequenceState.DONE

	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "Good job. Keep moving, we need to find the source of the corruption.", 5.0)

	PlayerData.set_objective(null, "Explore deeper into the wetlands")

	PlayerData.q01_completed = true
	PlayerData.award_progression_reward("q01_complete", 40.0)
	completed.emit()

## Waits for the player to tap through the currently-shown subtitle before
## continuing — falls back to a fixed delay if there's no HUD to report a
## dismissal (e.g. a test scene), so this never hangs forever.
func _wait_for_dialogue() -> void:
	if _hud and _hud.has_signal("subtitle_dismissed"):
		await _hud.subtitle_dismissed
	else:
		await get_tree().create_timer(2.0).timeout
		
	# Add a small pacing delay so enemies don't spawn the exact instant the dialogue closes
	await get_tree().create_timer(1.0).timeout
