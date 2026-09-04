extends Node3D
class_name KnowledgeObject

@export var knowledge_id: String = ""
@export var interact_text: String = "Scan"
@export var interact_distance: float = 3.0

var _was_near: bool = false
var _is_scanned: bool = false
var _hud: Node = null

var _outline_mat: StandardMaterial3D = null
var _target_mesh: GeometryInstance3D = null

func _ready() -> void:
	add_to_group("knowledge_object")
	
	_target_mesh = _find_mesh(get_parent())
	if _target_mesh:
		_outline_mat = StandardMaterial3D.new()
		_outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline_mat.albedo_color = Color(0.1, 0.9, 0.7, 1.0)
		_outline_mat.grow = true
		_outline_mat.grow_amount = 0.05
	
	if PlayerData.unlocked_knowledge.has(knowledge_id):
		_is_scanned = true

func _find_mesh(node: Node) -> GeometryInstance3D:
	if node == self: return null
	if node is GeometryInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh(child)
		if result:
			return result
	return null

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var dist_to_player = global_position.distance_to(player.global_position)
	if not _hud:
		_hud = get_tree().get_first_node_in_group("hud")
		
	var is_near = dist_to_player <= interact_distance
	
	if is_near and not _was_near:
		_set_highlight(not _is_scanned) # Optional: outline only if unscanned. If you want it always, remove 'not _is_scanned'
		if _hud and _hud.has_method("show_interact"):
			_hud.show_interact(interact_text, _on_interact, self)
	elif not is_near and _was_near:
		_set_highlight(false)
		if _hud and _hud.has_method("hide_interact"):
			_hud.hide_interact(self)
			
	_was_near = is_near

const InfoCardScene = preload("res://ui/info_card.tscn")

func _on_interact() -> void:
	_set_highlight(false)
	
	if _hud and _hud.has_method("hide_interact"):
		_hud.hide_interact(self)
		
	var db_entry = PlayerData.KNOWLEDGE_DB.get(knowledge_id, {})
	
	var card = InfoCardScene.instantiate()
	get_tree().current_scene.add_child(card)
	card.set_info(knowledge_id, db_entry)
	
	await card.closed
	
	# Only unlock and show notification if this is the first time scanning it
	if not _is_scanned:
		_is_scanned = true
		PlayerData.unlock_knowledge(knowledge_id)
		
		if _hud and _hud.has_method("show_notification"):
			var title = db_entry.get("title", "Discovery")
			_hud.show_notification("NEW KNOWLEDGE", title + " Unlocked", 2.5)

func _set_highlight(active: bool) -> void:
	if _target_mesh and _outline_mat:
		_target_mesh.material_overlay = _outline_mat if active else null
