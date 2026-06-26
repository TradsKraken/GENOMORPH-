extends Area3D

## Purple neon stamina orb. Tap and hold to collect, grants stamina.

# ── Constants ─────────────────────────────────────────────────────────────────
const STAMINA_GRANT := 35.0
const COLLECT_TIME  := 1.5    # seconds to hold before collection
const ORB_COLOR     := Color(0.58, 0.00, 1.00)
const ORB_EMIT      := Color(0.72, 0.05, 1.00)
const LIGHT_COLOR   := Color(0.75, 0.15, 1.00)
const RING_COLOR    := Color(0.72, 0.20, 1.00)

# ── Progress ring (canvas overlay) ───────────────────────────────────────────

class _ProgressRing extends Control:
	var fill_color: Color = Color.WHITE
	var progress: float   = 0.0
	var _orb: Area3D

	func _process(_delta: float) -> void:
		if not is_instance_valid(_orb):
			return
		var cam := get_viewport().get_camera_3d()
		if cam == null or not cam.is_position_in_frustum(_orb.global_position):
			visible = false
			return
		var scr := cam.unproject_position(_orb.global_position)
		position = scr - size / 2.0
		visible = progress > 0.001
		if visible:
			queue_redraw()

	func _draw() -> void:
		if progress <= 0.001:
			return
		var c := size / 2.0
		var r := 32.0
		draw_arc(c, r, 0.0, TAU, 64, Color(0.0, 0.0, 0.0, 0.55), 10.0)
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * progress, 32,
				fill_color * Color(1, 1, 1, 0.30), 18.0)
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * progress, 64, fill_color, 7.0, true)
		var font := ThemeDB.fallback_font
		var pct := "%d%%" % roundi(progress * 100.0)
		var tw := font.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, c - Vector2(tw / 2.0, -6.0), pct,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

# ── Node refs ─────────────────────────────────────────────────────────────────
var _mesh:         MeshInstance3D
var _light:        OmniLight3D
var _ring_canvas:  CanvasLayer
var _ring:         _ProgressRing
var _orb_mat:      StandardMaterial3D

# ── State ─────────────────────────────────────────────────────────────────────
var _progress:    float = 0.0
var _is_tapping:  bool  = false
var _tap_finger:  int   = -1
var _bob_time:    float = 0.0
var _collected:   bool  = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	collision_layer = 8
	collision_mask  = 0
	_build_mesh()
	_build_light()
	_build_collision()
	_build_ring_ui()


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


func _build_ring_ui() -> void:
	_ring_canvas = CanvasLayer.new()
	_ring_canvas.layer = 5
	add_child(_ring_canvas)
	_ring = _ProgressRing.new()
	_ring.custom_minimum_size = Vector2(80, 80)
	_ring.size       = Vector2(80, 80)
	_ring.fill_color = RING_COLOR
	_ring._orb       = self
	_ring.visible    = false
	_ring_canvas.add_child(_ring)

# ── Update ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _collected:
		return
	_bob_time += delta * 1.8
	_mesh.position.y = sin(_bob_time) * 0.12
	_light.light_energy = 2.8 + sin(_bob_time * 2.1) * 0.6

	if _is_tapping:
		_progress = move_toward(_progress, 1.0, delta / COLLECT_TIME)
		if _progress >= 1.0:
			_collect()
	else:
		_progress = move_toward(_progress, 0.0, delta / (COLLECT_TIME * 0.55))

	_ring.progress = _progress

	var s := 1.0 + _progress * 0.18 + sin(_bob_time * 3.0) * 0.03
	_mesh.scale = Vector3(s, s, s)

# ── Input: tap detection ──────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _collected:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _tap_finger == -1 and _is_tap_on_me(event.position):
				if not _is_player_near():
					_show_too_far()
					return
				_tap_finger = event.index
				_is_tapping = true
				get_viewport().set_input_as_handled()
		else:
			if event.index == _tap_finger:
				_tap_finger = -1
				_is_tapping = false


func _is_tap_on_me(screen_pos: Vector2) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var space := get_world_3d().direct_space_state
	if space == null:
		return false
	var origin := cam.project_ray_origin(screen_pos)
	var target := origin + cam.project_ray_normal(screen_pos) * 200.0
	var params  := PhysicsRayQueryParameters3D.create(origin, target, 8)
	params.collide_with_areas = true
	var result  := space.intersect_ray(params)
	return result.has("collider") and result["collider"] == self


func _is_player_near() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var player := players[0] as Node3D
	var dist := global_position.distance_to(player.global_position)
	return dist < 4.5


func _show_too_far() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var scr := cam.unproject_position(global_position)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_float_text"):
			hud.show_float_text("Too Far!", scr, Color(0.9, 0.3, 0.3))

# ── Collection ────────────────────────────────────────────────────────────────

func _collect() -> void:
	if _collected:
		return
	_collected  = true
	_is_tapping = false
	_ring.visible = false

	PlayerData.gain_stamina(STAMINA_GRANT)

	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var scr := cam.unproject_position(global_position)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_float_text"):
			hud.show_float_text("+%d ⚡" % int(STAMINA_GRANT), scr, Color(0.65, 0.30, 1.00))

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_mesh,  "scale",        Vector3.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_light, "light_energy", 8.0,          0.12)
	tween.tween_property(_light, "light_energy", 0.0,          0.22).set_delay(0.12)

	await get_tree().create_timer(0.42).timeout
	queue_free()
