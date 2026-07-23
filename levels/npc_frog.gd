extends Node3D

@export var interact_distance: float = 4.0
@export var prompt_text: String = "Tap to talk"
@export var objective_text: String = "Talk to Lolo Palaka"

@export_category("NPC Settings")
@export var npc_name: String = "Lolo Palaka"
@export var is_main_quest: bool = true

var custom_dialogues: Array[String] = [
	'"Please, the snakes and biters are everywhere! I can\'t even find clean water!"',
	'"My tadpoles... I hope they are safe from those invasive predators."',
	'"We used to sing here. Now we just hide..."'
]

var _anim_player: AnimationPlayer
var _is_talking: bool = false
var _was_near: bool = false

@export var territory_radius: float = 25.0
var is_helped: bool = false
var is_intro_done: bool = false
var has_given_minigame: bool = false
var _player_in_territory: bool = false
var _territory_area: Area3D

var _local_enemies_hidden: bool = false
var _hidden_enemies: Array[Node] = []

func _ready() -> void:
	add_to_group("npc_frog")
	# Look for a visual Area3D child to use instead of the hardcoded radius
	for child in get_children():
		if child is Area3D:
			_territory_area = child
			# Force the Area to detect ALL physics layers (enemies are often on Layer 2 or 3)
			_territory_area.collision_mask = 4294967295 
			_territory_area.body_entered.connect(_on_body_entered)
			_territory_area.body_exited.connect(_on_body_exited)
			break
			
	# Find the animation player and play the idle animation
	_anim_player = _find_anim_player(self)
	if _anim_player:
		var idle_anim = _anim_player.get_animation("FrogArmature|Frog_Idle")
		if idle_anim:
			idle_anim.loop_mode = Animation.LOOP_LINEAR
		_anim_player.play("FrogArmature|Frog_Idle")

	# Restore saved state if available
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		var saved_state = PlayerData.get_object_state(scene_path, node_path_str)
		if saved_state.size() > 0:
			is_helped = saved_state.get("is_helped", false)
			is_intro_done = saved_state.get("is_intro_done", false)
			has_given_minigame = saved_state.get("has_given_minigame", false)

	if not is_main_quest and not is_helped and PlayerData.lolo_palaka_intro_done:
		call_deferred("_add_self_to_minimap")
	elif is_main_quest and PlayerData.frogs_helped >= PlayerData.total_frogs and not has_given_minigame:
		call_deferred("_add_self_to_minimap_gold")

func _add_self_to_minimap() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("add_minimap_marker"):
		hud.add_minimap_marker(self, Color(0.2, 1.0, 0.4))
	elif not is_queued_for_deletion():
		get_tree().create_timer(0.5).timeout.connect(_add_self_to_minimap)

func _add_self_to_minimap_gold() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("add_minimap_marker"):
		hud.add_minimap_marker(self, Color(1.0, 0.8, 0.2))
	elif not is_queued_for_deletion():
		get_tree().create_timer(0.5).timeout.connect(_add_self_to_minimap_gold)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_territory = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_territory = false

func _process(_delta: float) -> void:
	if not is_main_quest:
		if not PlayerData.lolo_palaka_intro_done and not _local_enemies_hidden:
			_local_enemies_hidden = true
			var all_enemies = get_tree().get_nodes_in_group("enemies")
			for e in all_enemies:
				if is_instance_valid(e) and e is Node3D and not _hidden_enemies.has(e):
					if global_position.distance_to(e.global_position) <= territory_radius + 5.0:
						e.visible = false
						e.process_mode = Node.PROCESS_MODE_DISABLED
						_hidden_enemies.append(e)
		elif PlayerData.lolo_palaka_intro_done and _local_enemies_hidden:
			_local_enemies_hidden = false
			for e in _hidden_enemies:
				if is_instance_valid(e):
					e.visible = true
					e.process_mode = Node.PROCESS_MODE_INHERIT
			_hidden_enemies.clear()

	if _is_talking:
		if _was_near:
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("hide_interact"):
				hud.hide_interact(self)
			_was_near = false
		return
		
	if not is_main_quest and not PlayerData.lolo_palaka_intro_done:
		if _was_near:
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("hide_interact"):
				hud.hide_interact(self)
			_was_near = false
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var dist_to_player = global_position.distance_to(player.global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	
	var is_in_zone = false
	if _territory_area:
		is_in_zone = _player_in_territory
	else:
		is_in_zone = dist_to_player <= territory_radius
		_player_in_territory = is_in_zone
	
	if is_in_zone and not is_helped:
		var alive_enemies = 0
		var all_enemies = get_tree().get_nodes_in_group("enemies")
		for e in all_enemies:
			if not is_instance_valid(e) or e.get("is_dead") or not e.visible:
				continue
				
			var enemy_in_zone = false
			if _territory_area:
				# Use precise physics overlap if an Area3D exists
				if _territory_area.overlaps_body(e):
					enemy_in_zone = true
			else:
				# Fallback to distance
				if global_position.distance_to(e.global_position) <= territory_radius:
					enemy_in_zone = true
					
			if enemy_in_zone:
				alive_enemies += 1
				
		if alive_enemies > 0:
			if hud and hud.has_method("show_zone_status"):
				hud.show_zone_status("Clear the area (" + str(alive_enemies) + " enemies remaining)")
			
			if _was_near:
				if hud and hud.has_method("hide_interact"):
					hud.hide_interact(self)
				_was_near = false
		else:
			if not has_given_minigame:
				if hud and hud.has_method("show_zone_status"):
					hud.show_zone_status("Talk to " + npc_name)
					
				if PlayerData.current_objective != self:
					PlayerData.set_objective(self, "Talk to " + npc_name)
					
			var _is_near = dist_to_player <= interact_distance
			if _is_near and not _was_near:
				if hud and hud.has_method("show_interact"):
					hud.show_interact("Talk", _start_dialog, self)
			elif not _is_near and _was_near:
				if hud and hud.has_method("hide_interact"):
					hud.hide_interact(self)
			_was_near = _is_near
			
	else:
		if _player_in_territory:
			_player_in_territory = false
			if hud and hud.has_method("hide_zone_status"):
				hud.hide_zone_status()
				
		var _is_near = dist_to_player <= interact_distance
		if is_helped:
			if _is_near and not _was_near:
				if hud and hud.has_method("show_interact"):
					hud.show_interact("Talk", _start_dialog, self)
			elif not _is_near and _was_near:
				if hud and hud.has_method("hide_interact"):
					hud.hide_interact(self)
			_was_near = _is_near
		else:
			if _was_near:
				if hud and hud.has_method("hide_interact"):
					hud.hide_interact(self)
				_was_near = false

func _start_dialog() -> void:
	_is_talking = true
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud or not hud.has_method("show_subtitle"):
		_is_talking = false
		return
		
	var just_completed = false
	
	if not is_helped:
		is_helped = true
		var frog_nodes = get_tree().get_nodes_in_group("npc_frog")
		var helped_count = 0
		for f in frog_nodes:
			if "is_helped" in f and f.is_helped:
				helped_count += 1
				
		PlayerData.frogs_helped = helped_count
		if frog_nodes.size() > 0:
			PlayerData.total_frogs = frog_nodes.size()
			
		if PlayerData.current_objective == self or PlayerData.current_objective == null:
			if PlayerData.frogs_helped >= PlayerData.total_frogs:
				PlayerData.set_objective(null, "Return to Lolo Palaka")
			else:
				PlayerData.set_objective(null, "Find the remaining frogs (" + str(PlayerData.frogs_helped) + "/" + str(PlayerData.total_frogs) + ")")
				
		if PlayerData.frogs_helped >= PlayerData.total_frogs:
			var frog_nodes_all = get_tree().get_nodes_in_group("npc_frog")
			for f in frog_nodes_all:
				if "is_main_quest" in f and f.is_main_quest:
					if hud.has_method("add_minimap_marker"):
						hud.add_minimap_marker(f, Color(1.0, 0.8, 0.2)) # Gold marker for return
					PlayerData.set_objective(f, "Return to Lolo Palaka")
					just_completed = true
					break

		if hud.has_method("hide_zone_status"):
			hud.hide_zone_status()
		if hud.has_method("remove_minimap_marker"):
			hud.remove_minimap_marker(self)

	if is_main_quest:
		if PlayerData.frogs_helped >= PlayerData.total_frogs:
			if not has_given_minigame:
				if hud.has_method("remove_minimap_marker"):
					hud.remove_minimap_marker(self)
				hud.show_subtitle("Lolo Palaka", '"You have saved our people. Now, show me what you can do. Clear the water!"')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				has_given_minigame = true
				PlayerData.minigame_started = true
				
				PlayerData.set_objective(null, "Explore the wetlands")
				
				# Trigger Minigame manually
				if get_tree().current_scene:
					var all_areas = get_tree().current_scene.find_children("*", "Area3D")
					for area in all_areas:
						if "trigger_type" in area and area.trigger_type == 4 and area.has_method("start_event_manually"):
							area.start_event_manually()
							break
			else:
				hud.show_subtitle("Lolo Palaka", '"Clear the water, Volunteer!"')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
		else:
			if not is_intro_done:
				is_intro_done = true
				PlayerData.lolo_palaka_intro_done = true
				hud.show_subtitle("Lolo Palaka", '"A strange skin you wear, traveler... but you carry the heartbeat of the marsh. It has been many seasons since these waters were quiet enough to think."')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
				hud.show_subtitle("Volunteer (Player)", '"I am trying to fix that. The pollution out there is bad, but those invasive swarms are making it impossible for anything to survive."') 
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
				hud.show_subtitle("Lolo Palaka", '"Ah, the biters. They are not the root of the sickness, but a symptom of the broken circle. When the toxic sludge poisoned the deep waters, the hunters died. Without us to keep them in check, the swarms multiply without end. They are a plague born from an empty throne."')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
				hud.show_subtitle("Volunteer (Player)", '"Population dynamics. Without natural predators, the invasive species consume all the resources. So, we need to restore the balance. How do we start?"')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
				hud.show_subtitle("Lolo Palaka", '"By remembering what we were made to do. A storm of them approaches our last clean pond. Words will not stop them, little frog. You must thin their numbers before they infect the water."')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
				hud.show_subtitle("Lolo Palaka", '"And it is not just me... there are others like us hiding out there in the marsh, terrified of these new predators. They need your help too."')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
				if _anim_player:
					_anim_player.play("FrogArmature|Frog_Jump")
				
				hud.show_subtitle("Lolo Palaka", '"Please, find the others. Keep them safe until we can reclaim our home!"')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
				
				# Trigger minimap markers for all other frogs
				if hud.has_method("add_minimap_marker"):
					var frogs = get_tree().get_nodes_in_group("npc_frog")
					for f in frogs:
						if "is_main_quest" in f and not f.is_main_quest:
							hud.add_minimap_marker(f, Color(0.2, 1.0, 0.4))
							
				if not ("has_seen_minimap_tutorial" in PlayerData) or not PlayerData.has_seen_minimap_tutorial:
					_wait_for_movement_and_show_tutorial(hud)
				
				if _anim_player:
					_anim_player.play("FrogArmature|Frog_Idle")
			else:
				hud.show_subtitle("Lolo Palaka", '"Please, find the others. Keep them safe until we can reclaim our home!"')
				if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
			
	else:
		# Generic Frog Dialogue
		var random_line = custom_dialogues[randi() % custom_dialogues.size()]
		hud.show_subtitle(npc_name, random_line)
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed

	if just_completed:
		if hud.has_method("show_notification"):
			hud.show_notification("OBJECTIVE COMPLETE", "All frogs rescued! Return to Lolo Palaka.", 5.0)
		
		if _anim_player:
			_anim_player.play("FrogArmature|Frog_Jump")
			
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		if _anim_player:
			_anim_player.play("FrogArmature|Frog_Idle")
	
	_is_talking = false

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_anim_player(child)
		if result:
			return result
	return null

func _wait_for_movement_and_show_tutorial(hud: Node) -> void:
	if not hud.has_method("show_tutorial"): return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Wait for a short delay so any residual input is ignored
	await get_tree().create_timer(1.0).timeout
	
	# Wait until player starts moving
	while is_instance_valid(player) and player.velocity.length() < 0.5:
		await get_tree().process_frame
		
	if "has_seen_minimap_tutorial" in PlayerData:
		PlayerData.has_seen_minimap_tutorial = true
		
	if is_instance_valid(hud):
		hud.show_tutorial("MAP UPDATED", "Follow the bouncing green triangles on your minimap to locate the remaining frogs.")
