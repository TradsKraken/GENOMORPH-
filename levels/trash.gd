extends Node3D
class_name Trash

## Attach this script to any scene object that represents discarded waste.
## The selected value is saved with the object. Trash is also a cleanable
## target: the player's attacks remove it during cleanup objectives.

signal cleaned

@export_category("Trash")
@export_enum(
	"Plastic Bottle",
	"Plastic Packaging",
	"Metal Can",
	"Glass",
	"Paper / Cardboard",
	"Food Waste",
	"Fishing Gear",
	"Electronic Waste",
	"Chemical Waste",
	"Mixed Waste"
) var trash_type: String = "Plastic Bottle"

@export_range(1.0, 100.0, 1.0, "or_greater") var cleanup_health: float = 20.0
@export_multiline var notes: String = ""

var health: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	health = cleanup_health
	add_to_group("trash")
	# Reuses the existing Frog attack targeting while keeping the separate
	# "trash" group available for cleanup objectives.
	add_to_group("enemies")

	if get_tree().current_scene:
		var scene_path := get_tree().current_scene.scene_file_path
		var node_path := str(get_tree().current_scene.get_path_to(self))
		if PlayerData.is_object_destroyed(scene_path, node_path):
			queue_free()

func take_damage(amount: float, _knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return

	health -= amount
	if health <= 0.0:
		clean_up()

func clean_up() -> void:
	if is_dead:
		return
	is_dead = true

	if get_tree().current_scene:
		var scene_path := get_tree().current_scene.scene_file_path
		var node_path := str(get_tree().current_scene.get_path_to(self))
		PlayerData.mark_object_destroyed(scene_path, node_path)

	cleaned.emit()
	queue_free()

func get_trash_type_name() -> String:
	return trash_type
