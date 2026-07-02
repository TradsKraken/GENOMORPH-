class_name MosquitoSwarm
extends EnemyBase

@export var damage_per_second: float = 5.0
@export var attack_range: float = 2.0

var _attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Override base values
	max_health = 100.0
	health = max_health
	speed = 4.0
	exp_value = 15.0
	
	# Find and play the mosquito animation
	var anim_player = _find_animation_player(self)
	if anim_player:
		var anims = anim_player.get_animation_list()
		if anims.size() > 0:
			var anim = anim_player.get_animation(anims[0])
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.play(anims[0])

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var ap = _find_animation_player(child)
		if ap:
			return ap
	return null

@export var is_passive: bool = false
var is_active: bool = false

func _process_movement(delta: float) -> void:
	if not is_active or target == null:
		return
		
	var dist = global_position.distance_to(target.global_position)
	
	# Always face the target horizontally
	var face_dir = global_position.direction_to(target.global_position)
	face_dir.y = 0
	if face_dir.length_squared() > 0.001:
		face_dir = face_dir.normalized()
		look_at(global_position + face_dir, Vector3.UP)
		# Some models face +Z (backwards) by default. To fix this, you could rotate the mesh by 180 deg (PI) around Y,
		# but standard look_at assumes -Z is forward. We'll stick to standard look_at.
	
	# Move towards target (skip if passive)
	if not is_passive and dist > attack_range * 0.9:
		# Slight vertical bobbing
		var target_y = target.global_position.y + 1.0
		var y_diff = target_y - global_position.y
		velocity = Vector3(face_dir.x * speed, y_diff * 2.0, face_dir.z * speed)
		
		move_and_slide()
	else:
		# Stop pushing the player once in attack range
		velocity = Vector3.ZERO
		
	# Attack logic
	if not is_passive and dist <= attack_range:
		_attack_timer += delta
		if _attack_timer >= 1.0:
			_attack_timer = 0.0
			if target.has_method("take_damage"):
				target.take_damage(damage_per_second)
	else:
		_attack_timer = 0.0
