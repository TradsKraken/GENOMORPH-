extends InteractableBase
class_name KnowledgeObject

@export var knowledge_id: String = ""

var _is_scanned: bool = false
var _outline_mat: StandardMaterial3D = null
var _target_mesh: GeometryInstance3D = null

func _ready() -> void:
	super._ready() # Important to register Area3D signals
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

func _on_player_entered() -> void:
	_set_highlight(not _is_scanned)

func _on_player_exited() -> void:
	_set_highlight(false)

const InfoCardScene = preload("res://ui/info_card.tscn")

func _perform_interaction() -> void:
	_set_highlight(false)
		
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
