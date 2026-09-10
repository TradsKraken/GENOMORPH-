extends Node3D
class_name NativeFrog

## Q03's "native frog in danger" — a plain visual, not a dialogue NPC (unlike
## the old Lolo Palaka content this replaces). Just sits idle until the
## habitat is restored, then hops to a safe spot and settles there for good.

const FrogModel = preload("res://Models/Frog.glb")

var _anim_player: AnimationPlayer = null
var _is_safe: bool = false

func _ready() -> void:
	add_to_group("native_frog")

	var model = FrogModel.instantiate()
	add_child(model)

	_anim_player = _find_animation_player(model)
	if _anim_player:
		var anims = _anim_player.get_animation_list()
		if anims.size() > 0:
			var anim = _anim_player.get_animation(anims[0])
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			_anim_player.play(anims[0])

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
