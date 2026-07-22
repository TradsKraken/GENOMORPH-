extends StaticBody3D

enum UnlockCondition {
	GENOME_FRAGMENTS,
	MINIGAME_STARTED
}

@export var unlock_condition: UnlockCondition = UnlockCondition.GENOME_FRAGMENTS
@export var required_amount: int = 1
@export var warning_message: String = "The path ahead is blocked."
@export var warning_speaker: String = "System"

var _time_alive: float = 0.0
var _player_inside: bool = false
var _is_warning_active: bool = false

var _ui_label: RichTextLabel = null
var _ui_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_unlock_condition()
	
	# Create the trigger area
	var trigger_area = Area3D.new()
	trigger_area.collision_mask = 4294967295
	add_child(trigger_area)
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)
	
	for child in get_children():
		if child is CollisionShape3D and child.get_parent() == self:
			var new_col = CollisionShape3D.new()
			if child.shape:
				var new_shape = child.shape.duplicate()
				
				# Get the total scale applied to this shape so we don't accidentally multiply our padding
				var g_scale = child.global_transform.basis.get_scale()
				var inv_scale = Vector3.ONE
				if g_scale.x != 0 and g_scale.y != 0 and g_scale.z != 0:
					inv_scale = Vector3(1.0 / g_scale.x, 1.0 / g_scale.y, 1.0 / g_scale.z)
				
				if new_shape is BoxShape3D:
					# Exactly 1 meter of padding in world space, regardless of how they scaled the barrier
					new_shape.size += Vector3(1.0, 1.0, 1.0) * inv_scale
				elif new_shape is SphereShape3D:
					new_shape.radius += 0.5 * min(inv_scale.x, min(inv_scale.y, inv_scale.z))
				elif new_shape is CylinderShape3D:
					new_shape.radius += 0.5 * min(inv_scale.x, inv_scale.z)
					new_shape.height += 1.0 * inv_scale.y
				elif new_shape is CapsuleShape3D:
					new_shape.radius += 0.5 * min(inv_scale.x, inv_scale.z)
					new_shape.height += 1.0 * inv_scale.y
				else:
					new_col.scale = Vector3(1.05, 1.05, 1.05)
					
				new_col.shape = new_shape
			new_col.transform = child.transform
			trigger_area.add_child(new_col)

func _create_ui_label() -> void:
	if is_instance_valid(_ui_label): return
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud: return
	
	_ui_label = RichTextLabel.new()
	_ui_label.bbcode_enabled = true
	_ui_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_label.fit_content = true
	_ui_label.scroll_active = false
	_ui_label.text = "[center][b][color=#ff4444]" + warning_message + "[/color][/b][/center]"
	
	_ui_label.add_theme_font_size_override("normal_font_size", 22)
	_ui_label.add_theme_font_size_override("bold_font_size", 22)
	_ui_label.add_theme_color_override("default_color", Color(1, 1, 1, 1))
	_ui_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_ui_label.add_theme_constant_override("outline_size", 6)
	
	_ui_label.custom_minimum_size = Vector2(400, 30)
	_ui_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_ui_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# Position it slightly below the top center so it doesn't overlap the Zone Status panel
	_ui_label.offset_top = 90
	
	_ui_label.modulate.a = 0.0
	
	if hud.has_node("Root"):
		hud.get_node("Root").add_child(_ui_label)
	else:
		hud.add_child(_ui_label)

func _process(delta: float) -> void:
	_time_alive += delta
	_check_unlock_condition()
	
	# Check for warnings during process so we don't miss players who spawned near it
	if _player_inside and _time_alive >= 3.0:
		if not _is_warning_active:
			_is_warning_active = true
			if not is_instance_valid(_ui_label): _create_ui_label()
			if is_instance_valid(_ui_label):
				if _ui_tween and _ui_tween.is_valid(): _ui_tween.kill()
				_ui_tween = create_tween()
				_ui_tween.tween_property(_ui_label, "modulate:a", 1.0, 0.3)
	else:
		if _is_warning_active:
			_is_warning_active = false
			if is_instance_valid(_ui_label):
				if _ui_tween and _ui_tween.is_valid(): _ui_tween.kill()
				_ui_tween = create_tween()
				_ui_tween.tween_property(_ui_label, "modulate:a", 0.0, 0.3)

func _check_unlock_condition() -> void:
	if unlock_condition == UnlockCondition.GENOME_FRAGMENTS:
		if PlayerData.genome_fragments >= required_amount:
			_clear_warning_and_free()
	elif unlock_condition == UnlockCondition.MINIGAME_STARTED:
		if PlayerData.minigame_started:
			_clear_warning_and_free()

func _clear_warning_and_free() -> void:
	if _is_warning_active and is_instance_valid(_ui_label):
		_ui_label.queue_free()
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _exit_tree() -> void:
	if is_instance_valid(_ui_label):
		_ui_label.queue_free()
