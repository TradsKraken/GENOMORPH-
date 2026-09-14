extends Node
class_name Q04Director

## Q04 — The Salamander Sequence
## After unlocking the Salamander genome, the player encounters an ambush.
## When they take damage, they discover the Salamander's regenerative abilities.

const RatScene = preload("res://enemies/rat.tscn")
const Q05DirectorScript = preload("res://levels/q05_director.gd")

@export var rat_pack_size: int = 3
@export var spawn_distance: float = 6.0

signal completed

var _hud: Node = null
var _has_triggered: bool = false
var _living_rats: Array[Node] = []
var _dialogue_triggered: bool = false
var _transform_dialogue_played: bool = false

func _ready() -> void:
	add_to_group("q04_director")
	
	if PlayerData.q04_completed:
		_start_q05()
		return
		
	# Find HUD
	await get_tree().create_timer(1.0).timeout
	_hud = get_tree().get_first_node_in_group("hud")
	
	# Hook up to the trigger Area3D (which the user must place and name "Q04Trigger")
	var trigger = get_tree().current_scene.find_child("Q04Trigger", true, false)
	if trigger and trigger is Area3D:
		print("[Q04 DEBUG] Successfully found Q04Trigger and connected!")
		trigger.body_entered.connect(_on_trigger_entered)
		if not PlayerData.active_species_changed.is_connected(_on_species_changed):
			PlayerData.active_species_changed.connect(_on_species_changed)
	else:
		print("[Q04 DEBUG] WARNING: No Q04Trigger Area3D found in scene!")
		
func _on_trigger_entered(body: Node3D) -> void:
	print("[Q04 DEBUG] _on_trigger_entered fired for body: ", body.name)
	if _has_triggered or PlayerData.q04_completed:
		print("[Q04 DEBUG] Already triggered or completed. _has_triggered=", _has_triggered, " q04_completed=", PlayerData.q04_completed)
		return
		
	if body.is_in_group("player"):
		print("[Q04 DEBUG] Body is player. active_species=", PlayerData.active_species)
		if PlayerData.active_species == "salamander":
			print("[Q04 DEBUG] Starting ambush!")
			_start_ambush()
		else:
			print("[Q04 DEBUG] Player is not salamander, ignoring.")

func _on_species_changed(species_id: String) -> void:
	if _has_triggered or PlayerData.q04_completed:
		return
		
	if species_id == "salamander":
		if not _transform_dialogue_played:
			_transform_dialogue_played = true
			if not is_instance_valid(_hud):
				_hud = get_tree().get_first_node_in_group("hud")
			if _hud and _hud.has_method("show_subtitle"):
				_hud.show_subtitle("STERLING (RADIO)", "You've assimilated the Salamander genome. I'm seeing massive changes to your vitals.", 4.5)

		var trigger = get_tree().current_scene.find_child("Q04Trigger", true, false)
		if trigger and trigger is Area3D:
			for body in trigger.get_overlapping_bodies():
				if body.is_in_group("player"):
					print("[Q04 DEBUG] Player transformed while inside trigger. Starting ambush!")
					_start_ambush()
					return

func _start_ambush() -> void:
	print("[Q04 DEBUG] _start_ambush() called.")
	_has_triggered = true
	
	# Spawn rats
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		print("[Q04 DEBUG] ERROR: Player node not found!")
		return
		
	print("[Q04 DEBUG] Spawning ", rat_pack_size, " rats around player.")
	for i in range(rat_pack_size):
		var spawn_pos = _find_safe_spawn_point(player as Node3D, spawn_distance)
		var rat = RatScene.instantiate()
		rat.position = spawn_pos
		get_tree().current_scene.add_child(rat)
		rat.global_position = spawn_pos
		rat.tree_exited.connect(_on_rat_died)
		_living_rats.append(rat)
		
	PlayerData.set_objective(null, "Survive the Ambush", "Defeat the aggressive rats.")
	
	# Listen for health drops to explain regeneration
	if not PlayerData.health_changed.is_connected(_on_player_health_changed):
		PlayerData.health_changed.connect(_on_player_health_changed)

func _find_safe_spawn_point(reference: Node3D, distance: float) -> Vector3:
	var anchor: Vector3 = reference.global_position
	var angle := randf() * TAU
	var spot := anchor + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)

	var space := reference.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		spot + Vector3(0, 10.0, 0),
		spot - Vector3(0, 20.0, 0)
	)
	var hit := space.intersect_ray(query)

	var ground_y: float = anchor.y
	if hit.has("position"):
		ground_y = (hit["position"] as Vector3).y

	return Vector3(spot.x, ground_y + 1.0, spot.z)

func _on_player_health_changed(value: float, maximum: float) -> void:
	if _dialogue_triggered or PlayerData.q04_completed:
		return
		
	if value < maximum:
		_dialogue_triggered = true
		PlayerData.health_changed.disconnect(_on_player_health_changed)
		
		# Give it a tiny delay for dramatic effect
		await get_tree().create_timer(1.0).timeout
		
		if not is_instance_valid(_hud):
			_hud = get_tree().get_first_node_in_group("hud")
		
		if _hud and _hud.has_method("show_subtitle"):
			_hud.show_subtitle("STERLING (RADIO)", "Notice how your wounds are closing? That's the Salamander's regenerative tissue. Don't be afraid to get close.", 4.5)

func _on_rat_died() -> void:
	_living_rats = _living_rats.filter(func(r): return is_instance_valid(r) and not r.is_queued_for_deletion())
	
	if _living_rats.size() == 0 and _has_triggered and not PlayerData.q04_completed:
		_finish_sequence()

func _finish_sequence() -> void:
	PlayerData.q04_completed = true
	PlayerData.set_objective(null, "FOLLOW THE BIOLOGICAL SIGNAL", "Move deeper into the contaminated wetlands.")
	completed.emit()
	_start_q05()
	
	if not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "Good. The toxic secretion is working too. Your vitals are stable. Let's keep moving deeper.", 5.0)
	
	# Disconnect health listener just in case it wasn't triggered
	if PlayerData.health_changed.is_connected(_on_player_health_changed):
		PlayerData.health_changed.disconnect(_on_player_health_changed)

func _start_q05() -> void:
	if get_tree().get_first_node_in_group("q05_director") == null:
		var q05 := Q05DirectorScript.new()
		add_child(q05)
