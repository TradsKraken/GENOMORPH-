extends StaticBody3D

@export var npc_name: String = "Dalag"
@export var interact_distance: float = 3.0

var _was_near: bool = false
var _is_talking: bool = false
var has_given_minigame: bool = false

func _ready() -> void:
	add_to_group("npc")
	
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		var saved_state = PlayerData.get_object_state(scene_path, node_path_str)
		if saved_state.size() > 0:
			has_given_minigame = saved_state.get("has_given_minigame", false)

	var anim = _find_animation_player(self)
	if anim:
		if anim.has_animation("idle"):
			anim.play("idle")
		elif anim.get_animation_list().size() > 0:
			anim.play(anim.get_animation_list()[0])

func _find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or _is_talking: return
	
	var dist_to_player = global_position.distance_to(player.global_position)
	var hud = get_tree().get_first_node_in_group("hud")
	var is_near = dist_to_player <= interact_distance
	
	if is_near and not _was_near:
		if hud and hud.has_method("show_interact"):
			hud.show_interact("Talk", _start_dialog, self)
	elif not is_near and _was_near:
		if hud and hud.has_method("hide_interact"):
			hud.hide_interact(self)
			
	_was_near = is_near

func _start_dialog() -> void:
	_is_talking = true
	var hud = get_tree().get_first_node_in_group("hud")
	
	if not has_given_minigame:
		if hud and hud.has_method("show_subtitle"):
			hud.show_subtitle("Dalag", '"Listen to me, Volunteer. The dissolved oxygen here is almost gone... They are suffocating the young ones!"')
			if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
			hud.show_subtitle("Dalag", '"The Feral Tilapia are coming to finish them off. You have to defend the school!"')
			if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
			
			has_given_minigame = true
			_save_state()
			
			# Trigger the Minigame manager manually
			var minigame = get_tree().get_first_node_in_group("oxygen_defense")
			if minigame and minigame.has_method("start_minigame"):
				minigame.start_minigame()
	else:
		if hud and hud.has_method("show_subtitle"):
			hud.show_subtitle("Dalag", '"Watch the young ones. The water is still thick, but you gave them a fighting chance."')
			if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed

	_is_talking = false

func _save_state() -> void:
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		PlayerData.set_object_state(scene_path, node_path_str, {"has_given_minigame": has_given_minigame})
