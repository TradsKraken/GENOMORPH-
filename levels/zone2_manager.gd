extends Node

enum State { START, NESTS_ACTIVE, FIND_DALAG, UNLOCK_ZONE_3, DONE }

@export var zone2_nests: Array[NodePath]
@export var dalag_npc: NodePath
@export var zone3_barrier: NodePath

var current_state: State = State.START
var _nests: Array[Node] = []
var _has_started: bool = false
var _check_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Load state
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		var saved_state = PlayerData.get_object_state(scene_path, node_path_str)
		if saved_state.size() > 0:
			current_state = saved_state.get("state", State.START)
			
	if current_state == State.DONE:
		set_process(false)
		return
		
	# Resolve node paths
	for p in zone2_nests:
		var n = get_node_or_null(p)
		if n: _nests.append(n)

func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0: return
	_check_timer = 1.0 # Check every second
	
	var player = get_tree().get_first_node_in_group("player")
	var hud = get_tree().get_first_node_in_group("hud")
	if not player or not hud: return
	
	# Start Zone 2 automatically if the player gets near the nodes (or just instantly if they are loaded)
	if current_state == State.START:
		if _nests.size() > 0:
			var dist = player.global_position.distance_to(_nests[0].global_position)
			if dist < 80.0 and PlayerData.genome_fragments >= 1: # Player is in Zone 2 AND finished Zone 1
				_start_zone_2(hud)
			elif PlayerData.frogs_helped >= PlayerData.total_frogs and PlayerData.minigame_started:
				# Player has finished Zone 1 (talked to Lolo Palaka) but isn't in Zone 2 yet. Point them to the swamp!
				if PlayerData.current_objective != _nests[0]:
					PlayerData.set_objective(_nests[0], "Head deeper into the swamp")
				
	elif current_state == State.NESTS_ACTIVE:
		_check_nests()
		
	elif current_state == State.FIND_DALAG:
		# If Dalag's minigame is completed (Genome Fragment 2 awarded)
		if PlayerData.genome_fragments >= 2:
			_transition_to_unlock(hud)
			
	elif current_state == State.UNLOCK_ZONE_3:
		# Barrier is handled by its own script, we just point the arrow to it
		var barrier = get_node_or_null(zone3_barrier)
		if not is_instance_valid(barrier):
			# Barrier is gone (queue_freed)
			current_state = State.DONE
			_save_state()
			PlayerData.set_objective(null, "Explore the wetlands")
			set_process(false)

func _start_zone_2(hud: Node) -> void:
	current_state = State.NESTS_ACTIVE
	_save_state()
	
	if hud.has_method("show_subtitle"):
		hud.show_subtitle("System", "WARNING: HIGH CONCENTRATION OF INVASIVE LIFEFORMS DETECTED IN THE SWAMP.")
		
	_check_nests() # Immediately set first nest objective

func _check_nests() -> void:
	# Filter out destroyed nests
	_nests = _nests.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	
	if _nests.size() > 0:
		var next_nest = _nests[0]
		if PlayerData.current_objective != next_nest:
			PlayerData.set_objective(next_nest, "Clear the Invasive Threats (" + str(_nests.size()) + " remaining)")
	else:
		# All threats cleared!
		current_state = State.FIND_DALAG
		_save_state()
		
		var dalag = get_node_or_null(dalag_npc)
		if dalag:
			PlayerData.set_objective(dalag, "Find the Mudfish Elder")
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_subtitle"):
				hud.show_subtitle("System", "THREATS CLEARED. NATIVE LIFEFORM DETECTED NEARBY.")

func _transition_to_unlock(hud: Node) -> void:
	current_state = State.UNLOCK_ZONE_3
	_save_state()
	
	if hud and hud.has_method("show_subtitle"):
		hud.show_subtitle("System", "ZONE 3 BARRIER UNLOCKED.")
		
	var barrier = get_node_or_null(zone3_barrier)
	if barrier:
		PlayerData.set_objective(barrier, "Proceed to Zone 3")
	else:
		PlayerData.set_objective(null, "Explore the wetlands")

func _save_state() -> void:
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		PlayerData.set_object_state(scene_path, node_path_str, {"state": current_state})
