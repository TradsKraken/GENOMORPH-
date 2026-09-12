extends Node3D
class_name NativeFrog

## Q03's "native frog in danger" — a plain visual, not a dialogue NPC (unlike
## the old Lolo Palaka content this replaces). Just sits idle until the
## habitat is restored, then hops to a safe spot and settles there for good.
##
## Carries its own ambush-trigger Area3D as a child, built in code, so the
## trigger radius is always centered on wherever this node actually ends up
## placed — no separate marker node that can drift out of sync with it (that
## was the exact bug Q02's original "DisturbanceMarker" had).

signal player_approached
signal defense_health_changed(current: float, maximum: float)
signal defense_failed

@export var ambush_radius: float = 6.0
@export var defense_max_health: float = 100.0

const FrogModel = preload("res://Models/Frog.glb")

var _anim_player: AnimationPlayer = null
var _is_safe: bool = false
var _has_triggered: bool = false
var _debug_timer: float = 0.0
var _is_panicking: bool = false
var _panic_tween: Tween = null
var _idle_anim: String = ""
var _jump_anim: String = ""
var _defense_health: float = 100.0
var _defense_active: bool = false

func _ready() -> void:
	add_to_group("native_frog")

	var model = FrogModel.instantiate()
	add_child(model)

	_anim_player = _find_animation_player(model)
	if _anim_player:
		var anims = _anim_player.get_animation_list()
		# Animation resources loaded from a .glb are SHARED in memory across
		# every instance of that model — they are not unique per node. Blindly
		# grabbing anims[0] and forcing it to loop was corrupting the actual
		# player's shared "FrogArmature|Frog_Attack" animation (forcing it
		# into an infinite loop) whenever that name happened to sort first.
		# Look specifically for an idle-named animation instead.
		for a in anims:
			var lower_a = a.to_lower()
			if "idle" in lower_a:
				_idle_anim = a
			elif "jump" in lower_a:
				_jump_anim = a
		
		if _idle_anim == "" and anims.size() > 0:
			_idle_anim = anims[0]

		if _idle_anim != "":
			var anim = _anim_player.get_animation(_idle_anim)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			_anim_player.play(_idle_anim)

	# Snap to the real ground on spawn — whatever height this node was placed
	# at in the editor doesn't always match the actual terrain surface below
	# it, which is why it could end up hovering.
	global_position.y = _get_ground_height(global_position, global_position.y)

	var zone := Area3D.new()
	zone.name = "AmbushTrigger"
	zone.collision_layer = 0
	zone.collision_mask = 3
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ambush_radius
	shape.shape = sphere
	zone.add_child(shape)
	add_child(zone)
	zone.body_entered.connect(_on_body_entered)

	print("[FROG DEBUG] ready at global_position=", global_position, " ambush_radius=", ambush_radius, " zone global_position=", zone.global_position)

func _process(delta: float) -> void:
	if _has_triggered: return
	_debug_timer += delta
	if _debug_timer < 1.0: return
	_debug_timer = 0.0

	var player = get_tree().get_first_node_in_group("player")
	if player and player is Node3D:
		var dist = global_position.distance_to((player as Node3D).global_position)
		print("[FROG DEBUG] distance to player: ", dist, " (trigger radius: ", ambush_radius, ")")
	else:
		print("[FROG DEBUG] no node in 'player' group found at all")

func _on_body_entered(body: Node3D) -> void:
	print("[FROG DEBUG] body_entered fired — body=", body, " path=", body.get_path(), " in 'player' group=", body.is_in_group("player"))
	if _has_triggered: return
	if not body.is_in_group("player"): return
	_has_triggered = true
	print("[FROG DEBUG] player confirmed — emitting player_approached")
	player_approached.emit()

## Same raycast-down technique the quest directors use for safe enemy spawns —
## finds the actual terrain height under a point instead of assuming flat
## ground, so hops land on the real surface instead of floating or sinking.
func _get_ground_height(pos: Vector3, fallback: float) -> float:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		pos + Vector3(0, 10.0, 0),
		pos - Vector3(0, 20.0, 0)
	)
	var hit := space.intersect_ray(query)
	if hit.has("position"):
		return (hit["position"] as Vector3).y
	return fallback

## Plays the jump animation stretched or compressed to exactly match how long
## the physical hop tween takes — same trick player.gd uses for its real jump
## (speed_scale = anim.length / actual_air_time) — so the leap and the visual
## landing frame always line up instead of drifting out of sync.
func _play_synced_hop_anim(hop_duration: float) -> void:
	if not (_anim_player and _jump_anim != ""):
		return
	var anim = _anim_player.get_animation(_jump_anim)
	_anim_player.play(_jump_anim)
	if anim and anim.length > 0.0 and hop_duration > 0.0:
		_anim_player.speed_scale = anim.length / hop_duration
	else:
		_anim_player.speed_scale = 1.0

func _play_idle_anim() -> void:
	if _anim_player:
		_anim_player.speed_scale = 1.0
		if _idle_anim != "":
			_anim_player.play(_idle_anim)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

func set_panicking(p: bool) -> void:
	if _is_safe:
		p = false
	_is_panicking = p
	if p and _panic_tween == null:
		_do_panic_jump()
	elif not p and _panic_tween != null:
		_panic_tween.kill()
		_panic_tween = null

func begin_defense() -> void:
	if _is_safe:
		return
	_defense_active = true
	_defense_health = defense_max_health
	set_panicking(true)
	defense_health_changed.emit(_defense_health, defense_max_health)

func stop_defense() -> void:
	_defense_active = false
	set_panicking(false)

func take_damage(amount: float) -> void:
	if not _defense_active or _is_safe:
		return
	_defense_health = maxf(0.0, _defense_health - amount)
	defense_health_changed.emit(_defense_health, defense_max_health)
	if _defense_health <= 0.0:
		_defense_active = false
		set_panicking(false)
		defense_failed.emit()

func _do_panic_jump() -> void:
	if not _is_panicking or _is_safe:
		_panic_tween = null
		return
	var offset = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized() * randf_range(0.3, 1.5)
	var target = global_position + offset
	var target_ground_y = _get_ground_height(target, global_position.y)
	target.y = target_ground_y
	var mid = global_position.lerp(target, 0.5)
	mid.y = max(global_position.y, target.y) + randf_range(0.5, 1.2)

	if offset.length_squared() > 0.01:
		rotation.y = atan2(offset.x, offset.z)

	var hop_duration := 0.4
	_play_synced_hop_anim(hop_duration)

	_panic_tween = create_tween()
	_panic_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_panic_tween.tween_property(self, "global_position", mid, hop_duration * 0.5)
	_panic_tween.set_ease(Tween.EASE_IN)
	_panic_tween.tween_property(self, "global_position", target, hop_duration * 0.5)
	_panic_tween.tween_callback(func():
		_play_idle_anim()
		if _is_panicking:
			await get_tree().create_timer(randf_range(0.1, 0.5)).timeout
			_do_panic_jump()
	)

func move_to_safety(target_pos: Vector3) -> void:
	set_panicking(false)
	if _is_safe:
		return
	_is_safe = true
	_do_safe_hop(target_pos)

func _do_safe_hop(target_pos: Vector3) -> void:
	var dist = global_position.distance_to(target_pos)
	if dist < 0.5:
		_play_idle_anim()
		return

	var max_hop_dist = 2.0
	var dir = (target_pos - global_position).normalized()
	dir.y = 0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		rotation.y = atan2(dir.x, dir.z)

	var hop_dist = min(dist, max_hop_dist)
	var end_pos = global_position + dir * hop_dist
	# Always raycast for the real ground height at the landing spot instead of
	# assuming flat terrain between here and the target — this is what made
	# the frog look like it was floating/sinking mid-hop on uneven ground.
	end_pos.y = _get_ground_height(end_pos, target_pos.y if dist <= max_hop_dist else global_position.y)
	var mid_pos = global_position.lerp(end_pos, 0.5)
	mid_pos.y = max(global_position.y, end_pos.y) + 1.0

	var hop_duration := 0.5
	_play_synced_hop_anim(hop_duration)

	var tw = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", mid_pos, hop_duration * 0.5)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "global_position", end_pos, hop_duration * 0.5)
	tw.tween_callback(func():
		_play_idle_anim()
		await get_tree().create_timer(0.2).timeout
		_do_safe_hop(target_pos)
	)
