extends Node3D

@export var interact_distance: float = 4.0
@export var prompt_text: String = "Tap to talk"

var _label: Label3D
var _anim_player: AnimationPlayer
var _is_talking: bool = false
var _can_interact: bool = false

func _ready() -> void:
	# Create a floating 3D text label above the frog dynamically
	_label = Label3D.new()
	_label.text = prompt_text
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true # Ensure it draws on top of other objects
	_label.position = Vector3(0, 1.5, 0) # Height above the frog
	_label.font_size = 100
	_label.outline_size = 8
	_label.visible = false
	add_child(_label)

	# Find the animation player and play the idle animation
	_anim_player = _find_anim_player(self)
	if _anim_player:
		var idle_anim = _anim_player.get_animation("FrogArmature|Frog_Idle")
		if idle_anim:
			idle_anim.loop_mode = Animation.LOOP_LINEAR
		_anim_player.play("FrogArmature|Frog_Idle")

func _process(_delta: float) -> void:
	if _is_talking:
		_label.visible = false
		_can_interact = false
		return
		
	# Check distance to the player to show/hide the prompt
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= interact_distance:
			_label.visible = true
			_can_interact = true
		else:
			_label.visible = false
			_can_interact = false

func _unhandled_input(event: InputEvent) -> void:
	if _can_interact and not _is_talking:
		if (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("attack") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			_start_dialog()

func _start_dialog() -> void:
	_is_talking = true
	_label.visible = false
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_subtitle"):
		hud.show_subtitle("Lolo Palaka", "(A slow, raspy croak that the suit translates)\n"A strange skin you wear, traveler... but you carry the heartbeat of the marsh. It has been many seasons since these waters were quiet enough to think."")
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		hud.show_subtitle("Volunteer (Player)", ""I'm trying to fix that. The pollution out there is bad, but those invasive swarms are making it impossible for anything to survive."")
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		hud.show_subtitle("Lolo Palaka", ""Ah, the biters. They are not the root of the sickness, but a symptom of the broken circle. When the toxic sludge poisoned the deep waters, the hunters died. Without us to keep them in check, the swarms multiply without end. They are a plague born from an empty throne."")
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		hud.show_subtitle("Volunteer (Player)", ""Population dynamics. Without natural predators, the invasive species consume all the resources. So, we need to restore the balance. How do we start?"")
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		hud.show_subtitle("Lolo Palaka", ""By remembering what we were made to do. A storm of them approaches our last clean pond. Words will not stop them, little frog. You must thin their numbers before they infect the water."")
		if hud.has_signal("subtitle_dismissed"): await hud.subtitle_dismissed
		
		if _anim_player:
			_anim_player.play("FrogArmature|Frog_Jump")
		
		hud.show_subtitle("Lolo Palaka", "(Standing up, gesturing to the pond)\n"Show me what you can do. Clear the water!"")
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
