extends InteractableBase
class_name KnowledgeObject

@export var knowledge_id: String = ""

var _is_scanned: bool = false
var _outline_mat: StandardMaterial3D = null
var _target_mesh: GeometryInstance3D = null
var _hint_light: OmniLight3D = null
var _hint_tween: Tween = null

func _ready() -> void:
	super._ready() # Important to register Area3D signals
	add_to_group("knowledge_object")

	_target_mesh = _find_mesh(get_parent())
	if _target_mesh:
		_outline_mat = StandardMaterial3D.new()
		_outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_outline_mat.albedo_color = Color(0.1, 0.9, 0.7, 1.0)
		_outline_mat.grow = true
		_outline_mat.grow_amount = 0.05

	if PlayerData.unlocked_knowledge.has(knowledge_id):
		_is_scanned = true

	# A long-range hint: visible from far away (it's not gated by the
	# interact Area3D's radius at all — that still only controls when the
	# "Scan" prompt itself shows up), so the player can spot undiscovered
	# clues from a distance and be drawn toward them. Stops permanently once
	# actually scanned.
	if not _is_scanned:
		_start_hint_pulse()

func _find_mesh(node: Node) -> GeometryInstance3D:
	if node == self: return null
	if node is GeometryInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh(child)
		if result:
			return result
	return null

const InfoCardScene = preload("res://ui/info_card.tscn")

func _perform_interaction() -> void:
	_stop_hint_pulse()

	var db_entry = PlayerData.KNOWLEDGE_DB.get(knowledge_id, {})

	var card = InfoCardScene.instantiate()
	get_tree().current_scene.add_child(card)
	card.set_info(knowledge_id, db_entry)

	await card.closed

	# Only unlock if this is the first time scanning it.
	if not _is_scanned:
		_is_scanned = true
		PlayerData.unlock_knowledge(knowledge_id)
		PlayerData.award_progression_reward("investigation:" + knowledge_id, 5.0)

		if _hud and _hud.has_method("show_knowledge_unlocked"):
			var title = db_entry.get("title", "Discovery")
			_hud.show_knowledge_unlocked(title)

## Slow breathing fade between a dim outline and a bright one, plus a small
## pulsing light for extra visibility/bloom at range — both applied once at
## _ready() rather than gated behind player proximity, so the hint reads from
## far away. The interact range itself is untouched: it's still whatever the
## Area3D collision radius on InteractableBase is (the "Scan" prompt only
## shows up once the player actually walks into that).
func _start_hint_pulse() -> void:
	if _target_mesh and _outline_mat:
		_target_mesh.material_overlay = _outline_mat

	_hint_light = OmniLight3D.new()
	_hint_light.light_color = Color(0.3, 1.0, 0.85)
	_hint_light.light_energy = 0.0
	_hint_light.omni_range = 8.0
	add_child(_hint_light)

	_hint_tween = create_tween()
	_hint_tween.set_loops()
	_hint_tween.tween_method(_apply_pulse, 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_tween.tween_method(_apply_pulse, 1.0, 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_pulse(t: float) -> void:
	if _outline_mat:
		_outline_mat.albedo_color.a = lerp(0.15, 1.0, t)
	if _hint_light:
		_hint_light.light_energy = lerp(0.2, 2.2, t)

func _stop_hint_pulse() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = null
	if _target_mesh:
		_target_mesh.material_overlay = null
	if _hint_light:
		_hint_light.queue_free()
		_hint_light = null
