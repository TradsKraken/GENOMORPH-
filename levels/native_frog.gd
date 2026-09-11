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
		var idle_name := ""
		for a in anims:
			if "idle" in a.to_lower():
				idle_name = a
				break
		if idle_name == "" and anims.size() > 0:
			idle_name = anims[0]

		if idle_name != "":
			var anim = _anim_player.get_animation(idle_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			_anim_player.play(idle_name)

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

## Hops to safety in two small bounces rather than a straight glide, then
## settles for good. Safe to call more than once — only the first call moves it.
func move_to_safety(target_pos: Vector3) -> void:
	if _is_safe:
		return
	_is_safe = true

	var mid_pos = global_position.lerp(target_pos, 0.5)
	mid_pos.y += 1.0

	var tw = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_position", mid_pos, 0.4)
	tw.tween_property(self, "global_position", target_pos, 0.4)
