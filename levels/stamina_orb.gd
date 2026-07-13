extends Area3D

## Purple neon stamina orb.
## Go near to reveal tap button. Tap once to collect.
## Movement during collection cancels the process.

# ── Constants ─────────────────────────────────────────────────────────────────
const STAMINA_GRANT := 35.0
const COLLECT_TIME  := 1.5    # seconds to complete collection
const INTERACT_DIST := 2.0    # max distance to show ring and allow tap
const MOVE_TOLERANCE:= 0.3    # how much player can move before cancelling

const ORB_COLOR     := Color(0.58, 0.00, 1.00)
const ORB_EMIT      := Color(0.72, 0.05, 1.00)
const LIGHT_COLOR   := Color(0.75, 0.15, 1.00)
const RING_COLOR    := Color(0.72, 0.20, 1.00)

# ── Node refs ─────────────────────────────────────────────────────────────────
var _mesh:         MeshInstance3D
var _light:        OmniLight3D
var _orb_mat:      StandardMaterial3D
var _player:       Node3D

# ── State ─────────────────────────────────────────────────────────────────────
var _is_near:        bool  = false
var _was_near:       bool  = false
var _bob_time:       float = 0.0
var _collected:      bool  = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	collision_layer = 8
	collision_mask  = 0
	_build_mesh()
	_build_light()
	_build_collision()


func _build_mesh() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.42
	sphere.height = 0.84
	sphere.radial_segments = 20
	sphere.rings = 12
	_mesh.mesh = sphere
	_orb_mat = StandardMaterial3D.new()
	_orb_mat.albedo_color = Color(ORB_COLOR.r, ORB_COLOR.g, ORB_COLOR.b, 0.92)
	_orb_mat.emission_enabled = true
	_orb_mat.emission = ORB_EMIT
	_orb_mat.emission_energy_multiplier = 2.5
	_orb_mat.metallic  = 0.30
	_orb_mat.roughness = 0.12
	_orb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh.material_override = _orb_mat
	add_child(_mesh)


func _build_light() -> void:
	_light = OmniLight3D.new()
	_light.light_color  = LIGHT_COLOR
	_light.light_energy = 2.8
	_light.omni_range   = 4.0
	add_child(_light)


func _build_collision() -> void:
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.2
	cs.shape  = sh
	add_child(cs)

# ── Update ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _collected:
		return

	var cam := get_viewport().get_camera_3d()
	if cam and not cam.is_position_in_frustum(global_position):
		return

	_bob_time += delta * 1.8
	_mesh.position.y = sin(_bob_time) * 0.12
	_light.light_energy = 2.8 + sin(_bob_time * 2.1) * 0.6

	# Find player once
	if _player == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Node3D

	# Distance check
	if _player != null:
		var dist := global_position.distance_to(_player.global_position)
		_is_near = dist < INTERACT_DIST
	else:
		_is_near = false

	# Logic
	if _is_near and not _was_near:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_interact"):
			hud.show_interact("Collect", _collect, self)
	elif not _is_near and _was_near:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_interact"):
			hud.hide_interact(self)
			
	_was_near = _is_near

	var s := 1.0 + sin(_bob_time * 3.0) * 0.03
	_mesh.scale = Vector3(s, s, s)

	_mesh.scale = Vector3(s, s, s)

# ── Helpers ───────────────────────────────────────────────────────────────────


func _show_float_text(text: String, color: Color) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var scr := cam.unproject_position(global_position)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_float_text"):
			hud.show_float_text(text, scr, color)

# ── Collection ────────────────────────────────────────────────────────────────

func _collect() -> void:
	if _collected:
		return
	_collected  = true
	
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_interact"):
		hud.hide_interact(self)

	PlayerData.gain_stamina(STAMINA_GRANT)
	_show_float_text("+%d ⚡" % int(STAMINA_GRANT), Color(0.65, 0.30, 1.00))

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_mesh,  "scale",        Vector3.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_light, "light_energy", 8.0,          0.12)
	tween.tween_property(_light, "light_energy", 0.0,          0.22).set_delay(0.12)

	await get_tree().create_timer(0.42).timeout
	queue_free()
