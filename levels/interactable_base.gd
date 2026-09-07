extends Area3D
class_name InteractableBase

signal interacted

@export var interact_prompt: String = "Interact"
@export var is_active: bool = true

var _hud: Node = null
var _is_player_near: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player layer (2)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	add_to_group("interactables")

func _on_body_entered(body: Node3D) -> void:
	if not is_active: return
	if body.is_in_group("player"):
		_is_player_near = true
		_hud = get_tree().get_first_node_in_group("hud")
		if _hud and _hud.has_method("show_interact"):
			_hud.show_interact(interact_prompt, _on_interact_pressed, self)
		_on_player_entered()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_is_player_near = false
		if _hud and _hud.has_method("hide_interact"):
			_hud.hide_interact(self)
		_on_player_exited()

func _on_interact_pressed() -> void:
	if not is_active or not _is_player_near: return
	
	if _hud and _hud.has_method("hide_interact"):
		_hud.hide_interact(self)
		
	interacted.emit()
	_perform_interaction()

func set_active(active: bool) -> void:
	is_active = active
	if not is_active and _is_player_near:
		if _hud and _hud.has_method("hide_interact"):
			_hud.hide_interact(self)
	elif is_active and _is_player_near:
		if _hud and _hud.has_method("show_interact"):
			_hud.show_interact(interact_prompt, _on_interact_pressed, self)

# Virtual functions for subclasses to override
func _on_player_entered() -> void:
	pass

func _on_player_exited() -> void:
	pass

func _perform_interaction() -> void:
	pass
