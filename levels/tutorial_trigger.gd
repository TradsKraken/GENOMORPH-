extends Area3D
class_name TutorialTrigger

@export_enum("Intro", "Nest1_Attack", "Nest2_Dodge", "Find_NPC", "Minigame_Arena") var trigger_type: int = 0
@export var minigame_enemies: Array[NodePath]
@export var requires_manual_trigger: bool = false

var _triggered: bool = false
var _active_enemies: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		var saved_state = PlayerData.get_object_state(scene_path, node_path_str)
		if saved_state.size() > 0:
			_triggered = saved_state.get("triggered", false)

func _on_body_entered(body: Node3D) -> void:
	if _triggered or requires_manual_trigger or not body.is_in_group("player"):
		return
		
	_triggered = true
	_save_state()
	var hud = get_tree().get_first_node_in_group("hud")
	
	if not hud:
		_activate_children()
		if trigger_type == 4:
			_start_minigame()
		return
	
	match trigger_type:
		0: # Intro
			if hud.has_method("reveal_jump"): hud.reveal_jump()
			if hud.has_method("show_subtitle"): hud.show_subtitle("Sterling", "Volunteer, your suit is locked to Frog form for now. The data's out there. Find it. Get a feel for the locomotion system—it's going to be heavier than you're used to.")
		1: # Nest1_Attack
			if hud.has_method("reveal_attack"): hud.reveal_attack()
			if hud.has_method("show_subtitle"): hud.show_subtitle("Sterling", "I'm reading an invasive cluster ahead. Mosquito swarm. The ecosystem can't filter them out anymore. Clear them out—a basic strike will disrupt the swarm.")
			PlayerData.unlock_knowledge("mosquito")
		2: # Nest2_Dodge
			if hud.has_method("flash_dodge"): hud.flash_dodge()
			if hud.has_method("show_subtitle"): hud.show_subtitle("Sterling", "Careful! This cluster is aggressive. Use your form's natural agility to evade before you strike.")
		3: # Find_NPC
			if hud.has_method("show_subtitle"): hud.show_subtitle("Sterling", "Wait. There's a life signature nearby. It's clean... native. Approach carefully and see what the suit's translation matrix can pick up.")
		4: # Minigame_Arena
			if hud.has_method("show_subtitle"): hud.show_subtitle("Lolo Palaka", "Show me what you can do. Clear the water!")

	if hud.has_signal("subtitle_dismissed"):
		await hud.subtitle_dismissed
		
	_activate_children()
	
	if trigger_type == 4:
		_start_minigame()

func start_event_manually() -> void:
	if _triggered: return
	_triggered = true
	_save_state()
	var hud = get_tree().get_first_node_in_group("hud")
	
	if trigger_type == 4:
		# Update objective and add minimap marker
		PlayerData.set_objective(self, "Clear the Biological Control Arena")
		if hud and hud.has_method("add_minimap_marker"):
			hud.add_minimap_marker(self, Color(1.0, 0.2, 0.2)) # Red marker for combat
		
		_activate_children()
		_start_minigame()

func _activate_children() -> void:
	for child in get_children():
		if child is EnemyBase:
			pass # Let them wake up naturally via their own aggro_range
		elif child is EnemySpawner:
			if child.has_method("activate"):
				child.activate()
			PlayerData.set_objective(child)

func _start_minigame() -> void:
	for path in minigame_enemies:
		var node = get_node_or_null(path)
		if node:
			if node is EnemyBase:
				if "is_active" in node:
					node.is_active = true
				if "is_passive" in node:
					node.is_passive = false
				_active_enemies.append(node)
			elif node is EnemySpawner:
				# It's a spawner! We just need to track when it deletes itself (nest cleared)
				_active_enemies.append(node)
			
	# Monitor enemies/spawners to spawn reward
	set_process(true)
	
func _process(delta: float) -> void:
	if trigger_type != 4 or not _triggered:
		set_process(false)
		return
		
	# Check if all active enemies and spawners are dead/cleared
	var all_dead = true
	var first_alive = null
	
	for enemy_or_spawner in _active_enemies:
		if is_instance_valid(enemy_or_spawner):
			if enemy_or_spawner is EnemyBase and not enemy_or_spawner.is_dead:
				all_dead = false
				if not first_alive: first_alive = enemy_or_spawner
			elif enemy_or_spawner is EnemySpawner:
				# If the spawner is still valid (not queue_freed), it hasn't cleared all waves yet
				all_dead = false
				if not first_alive: first_alive = enemy_or_spawner
			
	var hud = get_tree().get_first_node_in_group("hud")
	if not all_dead:
		if hud and hud.has_method("show_zone_status"):
			hud.show_zone_status("Eliminate them all!")
			
		if first_alive and PlayerData.current_objective != first_alive:
			PlayerData.set_objective(first_alive, "Clear the Biological Control Arena")
			
	if all_dead and _active_enemies.size() > 0:
		if hud and hud.has_method("hide_zone_status"):
			hud.hide_zone_status()
		set_process(false)
		
		# Minigame over, clear objective!
		if hud and hud.has_method("remove_minimap_marker"):
			hud.remove_minimap_marker(self)
		PlayerData.set_objective(null, "Explore the wetlands")
		_spawn_reward()

func _spawn_reward() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		if hud.has_method("show_subtitle"):
			hud.show_subtitle("Sterling", "Threat eliminated. Integrating recovered Genome Fragment into your suit.", 5.0)
		if hud.has_method("show_zone_status"):
			hud.show_zone_status("Quest Complete! Genome Fragment Recovered")
			# Hide the zone status after 5 seconds
			var timer = get_tree().create_timer(5.0)
			timer.timeout.connect(func(): if hud.has_method("hide_zone_status"): hud.hide_zone_status())
			
	# Automatically give the fragment instead of dropping it
	AudioManager.play_sfx("level_up")
	PlayerData.add_genome_fragment()

func _save_state() -> void:
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		PlayerData.set_object_state(scene_path, node_path_str, {"triggered": _triggered})
