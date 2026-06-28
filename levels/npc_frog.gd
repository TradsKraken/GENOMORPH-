extends Node3D

@export var interact_distance: float = 4.0
@export var prompt_text: String = "Talk with Lolo Palaka..."

var _label: Label3D
var _anim_player: AnimationPlayer

func _ready() -> void:
	# Create a floating 3D text label above the frog dynamically
	_label = Label3D.new()
	_label.text = prompt_text
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true # Ensure it draws on top of other objects
	_label.position = Vector3(0, 1.5, 0) # Height above the frog
	_label.font_size = 70
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
	# Check distance to the player to show/hide the prompt
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= interact_distance:
			_label.visible = true
		else:
			_label.visible = false

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_anim_player(child)
		if result:
			return result
	return null
