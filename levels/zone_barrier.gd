extends StaticBody3D

enum UnlockCondition {
	GENOME_FRAGMENTS,
	MINIGAME_STARTED
}

@export var unlock_condition: UnlockCondition = UnlockCondition.GENOME_FRAGMENTS
@export var required_amount: int = 1
@export var warning_message: String = "The path ahead is blocked."
@export var warning_speaker: String = "System"

var _warning_cooldown: float = 0.0
var _time_alive: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_unlock_condition()
	
	# Create a trigger area to warn the player when they get close
	var trigger_area = Area3D.new()
	trigger_area.collision_mask = 4294967295 # Detect everything
	add_child(trigger_area)
	trigger_area.body_entered.connect(_on_body_entered)
	
	# Find the collision shape and make a slightly larger copy for the trigger
	for child in get_children():
		if child is CollisionShape3D and child.get_parent() == self:
			var new_col = CollisionShape3D.new()
			if child.shape:
				var new_shape = child.shape.duplicate()
				if new_shape is BoxShape3D:
					new_shape.size += Vector3(2.0, 2.0, 2.0) # Expand by 1 unit in all directions
				new_col.shape = new_shape
			new_col.transform = child.transform
			trigger_area.add_child(new_col)
			break

func _process(delta: float) -> void:
	_time_alive += delta
	# Continuously check if the player has met the conditions to open the barrier
	_check_unlock_condition()
	
	if _warning_cooldown > 0:
		_warning_cooldown -= delta

func _check_unlock_condition() -> void:
	if unlock_condition == UnlockCondition.GENOME_FRAGMENTS:
		if PlayerData.genome_fragments >= required_amount:
			queue_free()
	elif unlock_condition == UnlockCondition.MINIGAME_STARTED:
		if PlayerData.minigame_started:
			queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and _warning_cooldown <= 0:
		# Prevent this from triggering immediately when the scene loads
		if _time_alive < 3.0:
			return
			
		# Player got too close! Display the warning.
		_warning_cooldown = 5.0 # Wait 5 seconds before showing the message again
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_subtitle"):
			hud.show_subtitle(warning_speaker, warning_message, 4.0)
