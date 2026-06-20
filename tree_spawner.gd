@tool
extends Node3D

## Procedural tree scatterer — works in the EDITOR via @tool.
##
## HOW TO USE:
##   1. Tweak the settings below in the Inspector.
##   2. Tick the "Generate Trees" checkbox to bake the trees into the scene.
##   3. Trees appear in the viewport; move/delete individual ones as you like.
##   4. Save the scene (Ctrl+S) — layout is now permanent.
##   5. Tick "Clear Trees" to remove them and start fresh.

# ── Inspector exports ─────────────────────────────────────────────────────────

## Total number of trees to scatter.
@export var tree_count: int = 40

## Half-size of the square area trees can appear in (should be ≤ ground half-size).
@export var spawn_radius: float = 70.0

## No trees will be placed within this distance from the origin (player spawn).
@export var clear_radius: float = 5.0

## Minimum tree trunk height.
@export var trunk_height_min: float = 1.2

## Maximum tree trunk height.
@export var trunk_height_max: float = 2.8

## Minimum canopy radius.
@export var canopy_radius_min: float = 0.8

## Maximum canopy radius.
@export var canopy_radius_max: float = 2.2

## Seed for reproducible layouts. Change this number to get a different layout.
@export var random_seed: int = 42

## Tick this in the Inspector to bake trees into the scene.
@export var generate_trees: bool:
	set(_v):
		if Engine.is_editor_hint():
			_clear_trees()
			_spawn_all()
			# Notify the editor that the scene has changed so Ctrl+S saves them
			notify_property_list_changed()

## Tick this to remove all generated trees.
@export var clear_trees: bool:
	set(_v):
		if Engine.is_editor_hint():
			_clear_trees()

# ── Colour palettes ───────────────────────────────────────────────────────────

const TRUNK_COLOURS := [
	Color(0.36, 0.22, 0.10),
	Color(0.42, 0.26, 0.13),
	Color(0.30, 0.18, 0.08),
]

const CANOPY_COLOURS := [
	Color(0.13, 0.50, 0.13),
	Color(0.10, 0.42, 0.10),
	Color(0.20, 0.55, 0.18),
	Color(0.08, 0.38, 0.20),
	Color(0.25, 0.60, 0.15),
]

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# In the editor: do nothing on _ready — trees are baked via the button.
	if Engine.is_editor_hint():
		return

	# At runtime: if no trees were baked into the scene, spawn them now
	# using the fixed seed so they always look the same.
	if get_child_count() == 0:
		_spawn_all()


# ── Private ───────────────────────────────────────────────────────────────────

func _spawn_all() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	for i in tree_count:
		var pos := _random_position(rng)
		_spawn_tree(pos, rng)


func _clear_trees() -> void:
	# Use free() (not queue_free) so nodes disappear instantly in the editor.
	for child in get_children():
		child.free()


func _random_position(rng: RandomNumberGenerator) -> Vector3:
	var pos := Vector3.ZERO
	for _attempt in 200:
		var x := rng.randf_range(-spawn_radius, spawn_radius)
		var z := rng.randf_range(-spawn_radius, spawn_radius)
		pos = Vector3(x, 0.0, z)
		if pos.length() >= clear_radius:
			break
	return pos


func _spawn_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var trunk_h  := rng.randf_range(trunk_height_min, trunk_height_max)
	var canopy_r := rng.randf_range(canopy_radius_min, canopy_radius_max)
	var scale_xz := rng.randf_range(0.85, 1.15)

	# ── Root static body (makes trees solid) ─────────────────────────────────
	var body := StaticBody3D.new()
	body.name     = "Tree_%d" % get_child_count()
	body.position = pos
	# Ownership must be set for the node to be saved with the scene in @tool
	add_child(body)
	if Engine.is_editor_hint():
		body.set_owner(get_tree().edited_scene_root)

	# ── Trunk ─────────────────────────────────────────────────────────────────
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius    = 0.12 * scale_xz
	trunk_mesh.bottom_radius = 0.18 * scale_xz
	trunk_mesh.height        = trunk_h

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = TRUNK_COLOURS[rng.randi() % TRUNK_COLOURS.size()]
	trunk_mat.roughness    = 0.95
	trunk_mesh.surface_set_material(0, trunk_mat)

	var trunk_mi := MeshInstance3D.new()
	trunk_mi.mesh     = trunk_mesh
	trunk_mi.position = Vector3(0.0, trunk_h * 0.5, 0.0)
	body.add_child(trunk_mi)
	if Engine.is_editor_hint():
		trunk_mi.set_owner(get_tree().edited_scene_root)

	# Trunk collision
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = trunk_mesh.bottom_radius
	trunk_shape.height = trunk_h
	var trunk_col := CollisionShape3D.new()
	trunk_col.shape    = trunk_shape
	trunk_col.position = Vector3(0.0, trunk_h * 0.5, 0.0)
	body.add_child(trunk_col)
	if Engine.is_editor_hint():
		trunk_col.set_owner(get_tree().edited_scene_root)

	# ── Canopy (two sphere layers for a fuller look) ──────────────────────────
	_add_canopy_sphere(body, rng, canopy_r,
		Vector3(0.0, trunk_h + canopy_r * 0.65, 0.0))
	_add_canopy_sphere(body, rng, canopy_r * 0.75,
		Vector3(0.0, trunk_h + canopy_r * 1.3, 0.0))

	body.rotation.y = rng.randf_range(0.0, TAU)


func _add_canopy_sphere(
		parent: Node3D,
		rng: RandomNumberGenerator,
		radius: float,
		offset: Vector3) -> void:

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius           = radius
	sphere_mesh.height           = radius * 2.0
	sphere_mesh.rings            = 8
	sphere_mesh.radial_segments  = 10

	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = CANOPY_COLOURS[rng.randi() % CANOPY_COLOURS.size()]
	canopy_mat.roughness    = 0.85
	sphere_mesh.surface_set_material(0, canopy_mat)

	var canopy_mi := MeshInstance3D.new()
	canopy_mi.mesh     = sphere_mesh
	canopy_mi.position = offset
	parent.add_child(canopy_mi)
	if Engine.is_editor_hint():
		canopy_mi.set_owner(get_tree().edited_scene_root)

	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	var canopy_col := CollisionShape3D.new()
	canopy_col.shape    = sphere_shape
	canopy_col.position = offset
	parent.add_child(canopy_col)
	if Engine.is_editor_hint():
		canopy_col.set_owner(get_tree().edited_scene_root)
