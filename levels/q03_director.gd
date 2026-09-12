extends Node
class_name Q03Director

## Q03 — Fragile Habitat (see files/GenoMorph_Quest_Flow.md).
## Player finds a native frog threatened by a second rat pack. Clearing them
## unlocks "Restore the damaged habitat"; restoring it sends the frog to
## safety and ends with Sterling detecting a biological signal.
##
## Restoring the habitat reveals one fixed Salamander genome site. It is a
## named species reward, never a random generic genome-fragment pickup.

const RatScene = preload("res://enemies/rat.tscn")
const SalamanderGenomeSiteScene = preload("res://levels/salamander_genome_site.tscn")

@export var rat_pack_size: int = 2
@export var spawn_distance: float = 5.0

signal completed

var _hud: Node = null

enum SequenceState {
	INIT,
	APPROACHING,
	FIGHTING_RATS,
	AWAITING_RESTORE,
	AWAITING_GENOME,
	AWAITING_TRANSFORMATION,
	DONE
}

var _state: SequenceState = SequenceState.INIT
var _living_rats: Array[Node] = []
var _wave: int = 1

func _ready() -> void:
	add_to_group("q03_director")

	_hud = get_tree().get_first_node_in_group("hud")
	print("[Q03 DEBUG] _ready() — hud found: ", is_instance_valid(_hud))

	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	print("[Q03 DEBUG] NativeFrog found: ", frog, " at ", (frog.global_position if frog else "n/a"))
	if frog and frog.has_signal("player_approached"):
		frog.player_approached.connect(_on_frog_approached)
		print("[Q03 DEBUG] connected to NativeFrog.player_approached")
	if frog and frog.has_signal("defense_failed"):
		frog.connect("defense_failed", _on_frog_defense_failed)

	var restore_point = get_tree().current_scene.find_child("HabitatRestorePoint", true, false)
	print("[Q03 DEBUG] HabitatRestorePoint found: ", restore_point)
	if restore_point and restore_point.has_signal("restored"):
		restore_point.restored.connect(_on_habitat_restored)

	# The site can be placed in the scene from the beginning so its position is
	# authored by the level designer, but it must not be collectible early.
	var genome_site = get_tree().current_scene.find_child("SalamanderGenomeSite", true, false)
	if genome_site is SalamanderGenomeSite:
		genome_site.set_active(false)

	# Don't start until Q02 (the first rat pack) actually finishes.
	# PlayerData.q02_completed is checked first — see the matching comment in
	# q02_director.gd for why this is more reliable than the node/group lookup.
	if PlayerData.q02_completed:
		print("[Q03 DEBUG] PlayerData.q02_completed already true — starting immediately")
		_begin()
	else:
		var q02_nodes = get_tree().get_nodes_in_group("q02_director")
		print("[Q03 DEBUG] q02_completed=false, q02_director nodes found: ", q02_nodes.size())
		if q02_nodes.size() > 0:
			var q02 = q02_nodes[0]
			q02.completed.connect(_begin)
			print("[Q03 DEBUG] waiting on Q02Director.completed signal")
		else:
			# No Q02Director in this scene (e.g. a test level) — just start.
			print("[Q03 DEBUG] no Q02Director found either — starting anyway")
			_begin()

func _begin() -> void:
	print("[Q03 DEBUG] _begin() called — state now APPROACHING")
	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	PlayerData.set_objective(frog, "Something's still not right", "There's a healthier patch of wetland nearby — but it isn't safe yet.")

	_state = SequenceState.APPROACHING

	if frog:
		frog.set("_has_triggered", false)
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player) and player is Node3D:
			if frog.global_position.distance_to((player as Node3D).global_position) <= frog.get("ambush_radius"):
				frog.set("_has_triggered", true)
				_on_frog_approached()

func _on_frog_approached() -> void:
	print("[Q03 DEBUG] _on_frog_approached() fired — current _state=", _state)
	if _state != SequenceState.APPROACHING: return

	_state = SequenceState.FIGHTING_RATS

	if not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "Wait — that frog's not alone. Rats, closing in on it.", 4.0)

	await _wait_for_dialogue()

	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	if frog and frog.has_method("begin_defense"):
		if frog.has_signal("defense_health_changed") and not frog.is_connected("defense_health_changed", _on_frog_defense_health_changed):
			frog.connect("defense_health_changed", _on_frog_defense_health_changed)
		frog.begin_defense()

	_wave = 1
	_spawn_rats()

func _spawn_rats() -> void:
	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	var anchor: Node3D = frog if frog else (get_tree().get_first_node_in_group("player") as Node3D)
	_living_rats.clear()
	for i in range(rat_pack_size):
		var spawn_pos = _find_safe_spawn_point(anchor, spawn_distance)
		var rat = RatScene.instantiate()
		rat.position = spawn_pos
		rat.is_dynamic = true
		get_tree().current_scene.add_child(rat)
		rat.global_position = spawn_pos
		if rat.has_method("set_defense_target") and frog is Node3D:
			rat.set_defense_target(frog as Node3D)
		rat.tree_exited.connect(_on_rat_died)
		_living_rats.append(rat)
	PlayerData.set_objective(null, "Protect the native frog", "%d rats remaining" % _living_rats.size())

func _on_frog_defense_health_changed(current: float, maximum: float) -> void:
	if not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_method("show_frog_defense"):
		_hud.show_frog_defense(current, maximum)

func _hide_frog_defense_status() -> void:
	if not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_method("hide_frog_defense"):
		_hud.hide_frog_defense()

func _on_frog_defense_failed() -> void:
	if _state != SequenceState.FIGHTING_RATS:
		return
	# This is a local retry, not a game-over: it keeps the rescue tense without
	# discarding the player's broader quest progress.
	_state = SequenceState.APPROACHING
	for rat in _living_rats:
		if is_instance_valid(rat):
			rat.queue_free()
	_living_rats.clear()
	_hide_frog_defense_status()
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("Native Frog Overwhelmed", "Protect it from the rats. Draw their attention with an attack.", 2.0)
	PlayerData.set_objective(null, "Protect the native frog", "The defense will restart shortly.")

	await get_tree().create_timer(2.0).timeout
	if _state != SequenceState.APPROACHING:
		return
	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	if not (frog and frog.has_method("begin_defense")):
		return
	_state = SequenceState.FIGHTING_RATS
	frog.begin_defense()
	var max_defense_health := float(frog.get("defense_max_health"))
	_on_frog_defense_health_changed(max_defense_health, max_defense_health)
	_wave = 1
	_spawn_rats()

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
		PlayerData.set_objective(null, "Protect the native frog", "%d rats remaining" % _living_rats.size())
		return

	if _wave == 1:
		_wave = 2
		if not is_instance_valid(_hud):
			_hud = get_tree().get_first_node_in_group("hud")
		if _hud and _hud.has_method("show_subtitle"):
			_hud.show_subtitle("STERLING (RADIO)", "More coming out of the mud! Hold them back!", 3.0)
			await _wait_for_dialogue()
		_spawn_rats()
		return

	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	if frog and frog.has_method("set_panicking"):
		frog.set_panicking(false)
	if frog and frog.has_method("stop_defense"):
		frog.stop_defense()
	_hide_frog_defense_status()

	_state = SequenceState.AWAITING_RESTORE

	await _play_frog_conversation()

	var restore_point = get_tree().current_scene.find_child("HabitatRestorePoint", true, false)
	if restore_point and restore_point.has_method("begin_cleanup"):
		restore_point.begin_cleanup()
	else:
		PlayerData.set_objective(restore_point, "Restore the damaged habitat", "Interact with the critical damaged area.")

## The player's first real conversation with a native species — plays once the
## rat pack is cleared, before the restore objective is handed out. Ties into
## the game's genome/transformation premise: whatever the player's been
## absorbing has started letting them understand animal speech, which is why
## the player reacts with shock instead of this being treated as normal.
func _play_frog_conversation() -> void:
	if not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	if not (_hud and _hud.has_method("show_subtitle")):
		return

	_hud.show_subtitle("PLAYER", "...wait. Did you just — did that frog just *say* something?", 4.0)
	await _wait_for_dialogue()

	_hud.show_subtitle("NATIVE FROG", "You can hear me? That's... new. Usually your kind can't.", 4.0)
	await _wait_for_dialogue()

	_hud.show_subtitle("PLAYER", "I don't— I don't know how. But I understood every word of that.", 4.0)
	await _wait_for_dialogue()

	_hud.show_subtitle("NATIVE FROG", "Whatever's changing in you, it's opened something. No time to puzzle over it now, though.", 5.0)
	await _wait_for_dialogue()

	_hud.show_subtitle("NATIVE FROG", "There's a patch of ground past here, poisoned and dying. Clean it, and it'll breathe again. I'll meet you there once it's safe.", 6.0)
	await _wait_for_dialogue()

	_hud.show_subtitle("STERLING (RADIO)", "...Did you just have a conversation with a frog? Log that. Focus — the restoration comes first.", 5.0)
	await _wait_for_dialogue()

	_hud.show_subtitle("STERLING (RADIO)", "There's a faint genome signal in that damaged habitat. Contamination is interfering. Clear the trash, then use the Purification Module so the suit can read it.", 7.0)
	await _wait_for_dialogue()

func _on_habitat_restored() -> void:
	if _state != SequenceState.AWAITING_RESTORE:
		return
	PlayerData.award_progression_reward("native_frog_rescue", 40.0, 3)
	_state = SequenceState.DONE

	var frog = get_tree().current_scene.find_child("NativeFrog", true, false)
	var safe_spot = get_tree().current_scene.find_child("SafeSpot", true, false)
	if frog and frog.has_method("move_to_safety") and safe_spot:
		frog.move_to_safety(safe_spot.global_position)

	if not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_method("show_subtitle"):
		_hud.show_subtitle("STERLING (RADIO)", "The contamination is gone — the suit can read the signal now. It's the lost Salamander genome! Follow the marker and recover it to unlock Salamander form.", 7.0)

	await _wait_for_dialogue()
	if PlayerData.salamander_genome_recovered:
		PlayerData.set_objective(null, "")
		completed.emit()
		return

	var site := _get_salamander_genome_site()
	if site == null:
		push_error("Q03 could not create its Salamander genome site.")
		return
	_state = SequenceState.AWAITING_GENOME
	site.set_active(true)
	if not site.genome_recovered.is_connected(_on_salamander_genome_recovered):
		site.genome_recovered.connect(_on_salamander_genome_recovered)
	PlayerData.set_objective(site, "Recover the Salamander genome", "Follow the marker to the glowing Salamander signal. Approach it and tap Recover Genome.")

func _get_salamander_genome_site() -> SalamanderGenomeSite:
	var existing := get_tree().current_scene.find_child("SalamanderGenomeSite", true, false)
	if existing is SalamanderGenomeSite:
		return existing

	# A saved level should contain this fixed node. This fallback keeps Q03
	# playable in an older scene and anchors it at one deterministic position
	# beside the restore point, never at a random location around the player.
	var restore_point := get_tree().current_scene.find_child("HabitatRestorePoint", true, false)
	if not (restore_point is Node3D):
		return null
	var site := SalamanderGenomeSiteScene.instantiate() as SalamanderGenomeSite
	site.name = "SalamanderGenomeSite"
	get_tree().current_scene.add_child(site)
	site.global_position = _find_fixed_genome_site_point(restore_point as Node3D)
	return site

func _find_fixed_genome_site_point(restore_point: Node3D) -> Vector3:
	var intended := restore_point.global_position + Vector3(6.0, 10.0, -4.0)
	var query := PhysicsRayQueryParameters3D.create(
		intended,
		intended - Vector3(0.0, 30.0, 0.0)
	)
	var hit := restore_point.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.has("position"):
		return (hit["position"] as Vector3) + Vector3(0.0, 0.15, 0.0)
	return restore_point.global_position + Vector3(6.0, 0.15, -4.0)

func _on_salamander_genome_recovered(_site: SalamanderGenomeSite) -> void:
	if _state != SequenceState.AWAITING_GENOME:
		return
	_state = SequenceState.AWAITING_TRANSFORMATION
	PlayerData.set_objective(null, "Try Salamander form", "Tap the form circle at the top of the screen, then select Salamander.")
	if not PlayerData.active_species_changed.is_connected(_on_first_transformation):
		PlayerData.active_species_changed.connect(_on_first_transformation)
	if _hud and _hud.has_method("guide_salamander_transformation"):
		_hud.guide_salamander_transformation()
	_on_first_transformation(PlayerData.active_species)

func _on_first_transformation(species_id: String) -> void:
	if _state != SequenceState.AWAITING_TRANSFORMATION or species_id != "salamander":
		return
	PlayerData.active_species_changed.disconnect(_on_first_transformation)
	_state = SequenceState.DONE
	PlayerData.set_objective(null, "")
	completed.emit()

## Waits for the player to tap through the currently-shown subtitle before
## continuing — falls back to a fixed delay if there's no HUD to report a
## dismissal (e.g. a test scene), so this never hangs forever.
func _wait_for_dialogue() -> void:
	if not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_signal("subtitle_dismissed"):
		await _hud.subtitle_dismissed
	else:
		await get_tree().create_timer(2.0).timeout
