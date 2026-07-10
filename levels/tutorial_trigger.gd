extends Area3D
class_name TutorialTrigger

@export_enum("Intro", "Nest1_Attack", "Nest2_Dodge", "Find_NPC", "Minigame_Arena") var trigger_type: int = 0
@export var minigame_enemies: Array[NodePath]

var _triggered: bool = false
var _active_enemies: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
		
	_triggered = true
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

func _activate_children() -> void:
	for child in get_children():
		if child is EnemyBase:
			if "is_active" in child:
				child.is_active = true

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
	for enemy_or_spawner in _active_enemies:
		if is_instance_valid(enemy_or_spawner):
			if enemy_or_spawner is EnemyBase and not enemy_or_spawner.is_dead:
				all_dead = false
				break
			elif enemy_or_spawner is EnemySpawner:
				# If the spawner is still valid (not queue_freed), it hasn't cleared all waves yet
				all_dead = false
				break
			
	if all_dead and _active_enemies.size() > 0:
		set_process(false)
		_spawn_reward()

func _spawn_reward() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_subtitle"):
		hud.show_subtitle("Sterling", "Threat eliminated. Reading a high concentration of useful genetic data... A Genome Fragment.", 5.0)
		
	var reward_script = load("res://levels/genome_fragment.gd")
	if reward_script:
		var reward = reward_script.new()
		# Spawn in the center of the trigger zone
		reward.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", reward)
