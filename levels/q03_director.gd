extends Node
class_name Q03Director

## Q03 — Fragile Habitat (see files/GenoMorph_Quest_Flow.md).
## Player finds a native frog threatened by a second rat pack. Clearing them
## unlocks "Restore the damaged habitat"; restoring it sends the frog to
## safety and ends with Sterling detecting a biological signal.
##
## IMPORTANT: the actual Salamander Genome discovery / transformation system
## does not exist yet (PlayerData has no species-switching code at all). This
## director ends with a clearly-labeled placeholder objective and a
## `completed` signal for whoever builds that system next — it does not
## pretend the transformation already works.

const RatScene = preload("res://enemies/rat.tscn")

@export var rat_pack_size: int = 2
@export var spawn_distance: float = 5.0

signal completed

var _hud: Node = null
var _ambush_triggered: bool = false

enum SequenceState {
	INIT,
	APPROACHING,
	FIGHTING_RATS,
	AWAITING_RESTORE,
	DONE
}

var _state: SequenceState = SequenceState.INIT
var _living_rats: Array[Node] = []

func _ready() -> void:
	add_to_group("q03_director")

	_hud = get_tree().get_first_node_in_group("hud")

	var ambush_zone = get_tree().current_scene.find_child("AmbushZone", true, false)
	if ambush_zone and ambush_zone.has_signal("body_entered"):
		ambush_zone.body_entered.connect(_on_ambush_zone_entered)

	var restore_point = get_tree().current_scene.find_child("HabitatRestorePoint", true, false)
	if restore_point and restore_point.has_signal("restored"):
		restore_point.restored.connect(_on_habitat_restored)

	# Don't start until Q02 (the first rat pack) actually finishes.
	var q02_nodes = get_tree().get_nodes_in_group("q02_director")
	if q02_nodes.size() > 0:
		var q02 = q02_nodes[0]
		if "_state" in q02 and q02._state == Q02Director.SequenceState.DONE:
			_begin()
		else:
			q02.completed.connect(_begin)
	else:
		# No Q02Director in this scene (e.g. a test level) — just start.
		_begin()

func _begin() -> void:
	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	var target: Node3D = frog if frog else get_tree().current_scene.find_child("AmbushZone", true, false)
	PlayerData.set_objective(target, "Something's still not right", "There's a healthier patch of wetland nearby — but it isn't safe yet.")

	_state = SequenceState.APPROACHING

func _on_ambush_zone_entered(body: Node) -> void:
	if _state != SequenceState.APPROACHING: return
	if _ambush_triggered: return
	if not body.is_in_group("player"): return
	_ambush_triggered = true

	_state = SequenceState.FIGHTING_RATS

	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "Wait — that frog's not alone. Rats, closing in on it.", 4.0)

	await _wait_for_dialogue()

	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	var anchor: Node3D = frog if frog else (body as Node3D)

	_living_rats.clear()
	for i in range(rat_pack_size):
		var spawn_pos = _find_safe_spawn_point(anchor, spawn_distance)
		var rat = RatScene.instantiate()
		rat.position = spawn_pos
		get_tree().current_scene.add_child(rat)
		rat.global_position = spawn_pos
		rat.tree_exited.connect(_on_rat_died)
		_living_rats.append(rat)

	PlayerData.set_objective(null, "Clear the invasive rats", "%d remaining" % _living_rats.size())

## Same approach as Q01Director/Q02Director — anchor to the player (provably
## standing in open, non-colliding space) and raycast down for real ground
## height, so nothing spawns embedded in terrain or on top of the frog.
func _find_safe_spawn_point(reference: Node3D, distance: float) -> Vector3:
	var anchor: Vector3 = reference.global_position
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player is Node3D:
		anchor = (player as Node3D).global_position

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

	return Vector3(spot.x, ground_y + 1.5, spot.z)

func _on_rat_died() -> void:
	_living_rats = _living_rats.filter(func(r): return is_instance_valid(r) and not r.is_queued_for_deletion())

	if _state != SequenceState.FIGHTING_RATS:
		return

	if _living_rats.size() > 0:
		PlayerData.set_objective(null, "Clear the invasive rats", "%d remaining" % _living_rats.size())
		return

	_state = SequenceState.AWAITING_RESTORE

	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "Clear. Now let's give this patch a real chance — the Purification Module should reach this far.", 5.0)

	var restore_point = get_tree().current_scene.find_child("HabitatRestorePoint", true, false)
	PlayerData.set_objective(restore_point, "Restore the damaged habitat", "Interact with the critical damaged area.")

func _on_habitat_restored() -> void:
	if _state != SequenceState.AWAITING_RESTORE:
		return
	_state = SequenceState.DONE

	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	var safe_spot = get_tree().current_scene.find_child("SafeSpot", true, false)
	if frog and frog.has_method("move_to_safety") and safe_spot:
		frog.move_to_safety(safe_spot.global_position)

	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "...I'm reading something. A biological signal, close by. That's not one of ours — not yet.", 6.0)

	await _wait_for_dialogue()

	# Placeholder hand-off — see the class-level note at the top of this file.
	PlayerData.set_objective(null, "Follow the signal", "Something new is out here. (Salamander Genome discovery — not yet implemented.)")

	completed.emit()

## Waits for the player to tap through the currently-shown subtitle before
## continuing — falls back to a fixed delay if there's no HUD to report a
## dismissal (e.g. a test scene), so this never hangs forever.
func _wait_for_dialogue() -> void:
	if _hud and _hud.has_signal("subtitle_dismissed"):
		await _hud.subtitle_dismissed
	else:
		await get_tree().create_timer(2.0).timeout
