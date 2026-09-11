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

@export var ambush_radius: float = 6.0

const FrogModel = preload("res://Models/Frog.glb")

var _anim_player: AnimationPlayer = null
var _is_safe: bool = false
var _has_triggered: bool = false
var _debug_timer: float = 0.0
var _is_panicking: bool = false
var _panic_tween: Tween = null
var _idle_anim: String = ""
var _jump_anim: String = ""

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

func _do_panic_jump() -> void:
	if not _is_panicking or _is_safe:
		_panic_tween = null
		return
	var offset = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized() * randf_range(0.3, 1.5)
	var target = global_position + offset
	var mid = global_position.lerp(target, 0.5)
	mid.y += randf_range(0.5, 1.2)

	if offset.length_squared() > 0.01:
		rotation.y = atan2(offset.x, offset.z)
	if _anim_player and _jump_anim != "":
		_anim_player.play(_jump_anim)

	_panic_tween = create_tween()
	_panic_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_panic_tween.tween_property(self, "global_position", mid, 0.2)
	_panic_tween.set_ease(Tween.EASE_IN)
	_panic_tween.tween_property(self, "global_position", Vector3(target.x, global_position.y, target.z), 0.2)
	_panic_tween.tween_callback(func():
		if _anim_player and _idle_anim != "":
			_anim_player.play(_idle_anim)
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
		if _anim_player and _idle_anim != "":
			_anim_player.play(_idle_anim)
		return

	var max_hop_dist = 2.0
	var dir = (target_pos - global_position).normalized()
	dir.y = 0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		rotation.y = atan2(dir.x, dir.z)

	var hop_dist = min(dist, max_hop_dist)
	var end_pos = global_position + dir * hop_dist
	end_pos.y = target_pos.y if dist <= max_hop_dist else global_position.y
	var mid_pos = global_position.lerp(end_pos, 0.5)
	mid_pos.y += 1.0

	if _anim_player and _jump_anim != "":
		_anim_player.play(_jump_anim)

	var tw = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", mid_pos, 0.25)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "global_position", end_pos, 0.25)
	tw.tween_callback(func():
		if _anim_player and _idle_anim != "":
			_anim_player.play(_idle_anim)
		await get_tree().create_timer(0.2).timeout
		_do_safe_hop(target_pos)
	)
