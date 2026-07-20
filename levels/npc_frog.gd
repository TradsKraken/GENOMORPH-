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

func _ready() -> void:
	add_to_group("npc_frog")
	# Find the animation player and play the idle animation
	_anim_player = _find_anim_player(self)
	if _anim_player:
		var idle_anim = _anim_player.get_animation("FrogArmature|Frog_Idle")
		if idle_anim:
			idle_anim.loop_mode = Animation.LOOP_LINEAR
		_anim_player.play("FrogArmature|Frog_Idle")

func _process(_delta: float) -> void:
	if _is_talking:
		if _was_near:
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("hide_interact"):
				hud.hide_interact(self)
			_was_near = false
		return
		
	# Check distance to the player
	var _is_near = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		_is_near = dist <= interact_distance
		
	if _is_near and not _was_near:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_interact"):
			hud.show_interact("Talk", _start_dialog, self)
	elif not _is_near and _was_near:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_interact"):
			hud.hide_interact(self)
			
	_was_near = _is_near

func _start_dialog() -> void:
	_is_talking = true
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud or not hud.has_method("show_subtitle"):
		_is_talking = false
		return

	if is_main_quest:
		hud.show_subtitle("Lolo Palaka", '"A strange skin you wear, traveler... but you carry the heartbeat of the marsh. It has been many seasons since these waters were quiet enough to think."')
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		hud.show_subtitle("Volunteer (Player)", '"I\'m trying to fix that. The pollution out there is bad, but those invasive swarms are making it impossible for anything to survive."')
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
					
		hud.show_subtitle("Sterling", '"I have synced their life signatures to your minimap. Follow the bouncing green triangles to find the remaining frogs."')
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		if _anim_player:
			_anim_player.play("FrogArmature|Frog_Idle")
			
	else:
		# Generic Frog Dialogue
		var random_line = custom_dialogues[randi() % custom_dialogues.size()]
		hud.show_subtitle(npc_name, random_line)
		
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

