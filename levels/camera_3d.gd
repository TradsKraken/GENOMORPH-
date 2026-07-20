extends Camera3D

## Top-down follow camera (MOBA / ML-style)
## Attach this script to a Camera3D node.
## The camera will look down at the player from a fixed height and angle,
## smoothly following their movement.

# ── Inspector exports ────────────────────────────────────────────────────────

## Path to the player node (CharacterBody3D / Node3D).
@export var player_path: NodePath = NodePath("../Player")

## Height above the player (Y axis).
@export var height: float = 13.0

## How far behind the player the camera sits (Z axis in world space).
## Positive = further back; adjust to taste.
@export var distance_back: float = 0.0

## Horizontal offset (X axis) – useful for slight off-centre framing.
@export var horizontal_offset: float = 0.0

## Camera tilt in degrees (0 = straight down, higher = more angled like ML).
@export_range(0.0, 89.0) var tilt_degrees: float = 35.0

## Smooth-follow speed. Lower = lazier follow, higher = snappier.
@export var follow_speed: float = 8.0

## Set to true if this scene is being loaded as the main menu background.
@export var is_main_menu: bool = false

# ── Private ──────────────────────────────────────────────────────────────────

var _player: Node3D = null
var _last_ground_y: float = 0.0
var _target_ground_y: float = 0.0

var _shake_trauma: float = 0.0

@export_group("Screen Shake")
## How fast the camera stops shaking (higher = stops faster)
@export var trauma_decay: float = 1.5
## The maximum distance the camera can shake. Lower this for a less intense shake.
@export var max_shake_offset: float = 0.3

func add_trauma(amount: float) -> void:
	_shake_trauma = min(_shake_trauma + amount, 1.0)

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Resolve the player node from the exported path.
	if not player_path.is_empty():
		_player = get_node_or_null(player_path)

	if _player == null:
		# Fallback: search the whole scene tree for the first node in the
		# "player" group (add the player to that group in the editor).
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Node3D

	if _player == null:
		push_warning("Camera3D: No player found. Set 'player_path' or add the player to the 'player' group.")
		return

	_last_ground_y = _player.global_position.y
	_target_ground_y = _player.global_position.y

	# Snap to position immediately on the first frame.
	_apply_position(1.0)
	
	# Hide Layer 11 (Fog of War) from the main camera
	cull_mask = 1047551 # 0xFFFFF ^ 1024

	# ── Spawn game systems at runtime (avoids UID-less .tscn references) ──────
	if not is_main_menu:
		if AudioManager and AudioManager.has_method("play_ambiance"):
			AudioManager.play_ambiance()
			
		var hud_scene := load("res://ui/hud.tscn") as PackedScene
		if hud_scene:
			var hud = hud_scene.instantiate()
			hud.name = "GameHUD"
			get_parent().call_deferred("add_child", hud)
		else:
			var hud_script := load("res://ui/hud.gd") as GDScript
			if hud_script:
				var hud: CanvasLayer = hud_script.new()
				hud.name = "GameHUD"
				get_parent().call_deferred("add_child", hud)

		var spawner_script := load("res://levels/orb_spawner.gd") as GDScript
		if spawner_script:
			var spawner: Node3D = spawner_script.new()
			spawner.name = "OrbSpawner"
			get_parent().call_deferred("add_child", spawner)


func _process(delta: float) -> void:
	if is_main_menu:
		# Slowly pan/rotate the camera over the swamp
		var t = Time.get_ticks_msec() / 1000.0
		var radius = 18.0
		var orbit_speed = 0.12
		var cam_height = 12.0
		
		# Orbit around the center of the level
		var target_pos = Vector3(cos(t * orbit_speed) * radius, cam_height, sin(t * orbit_speed) * radius)
		global_position = global_position.lerp(target_pos, delta * 2.0)
		look_at(Vector3.ZERO, Vector3.UP)
		return

	if _player == null:
		return

	if _player is CharacterBody3D:
		if _player.is_on_floor():
			_target_ground_y = _player.global_position.y
		elif _player.global_position.y < _target_ground_y:
			_target_ground_y = _player.global_position.y
	else:
		_target_ground_y = _player.global_position.y

	_last_ground_y = lerp(_last_ground_y, _target_ground_y, 10.0 * delta)

	_apply_position(follow_speed * delta)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _apply_position(weight: float) -> void:
	# With a tilted camera the player ends up below screen-center unless we
	# compensate. By positioning the camera directly above + behind and then
	# calling look_at() on the player, the player is always exactly centered.
	var tilt_rad := deg_to_rad(tilt_degrees)
	var z_offset := height * tan(tilt_rad) + distance_back

	var ground_pos := _player.global_position
	ground_pos.y = _last_ground_y

	var offset := Vector3(
		horizontal_offset,
		height,
		z_offset
	)
	var target_pos := ground_pos + offset

	var unshifted_pos = global_position.lerp(target_pos, clampf(weight, 0.0, 1.0))

	var shake_offset := Vector3.ZERO
	if _shake_trauma > 0:
		var amt = _shake_trauma * _shake_trauma
		shake_offset = Vector3(
			randf_range(-1.0, 1.0) * max_shake_offset * amt,
			randf_range(-1.0, 1.0) * max_shake_offset * amt,
			randf_range(-1.0, 1.0) * max_shake_offset * amt
		)
		_shake_trauma = max(0.0, _shake_trauma - trauma_decay * get_process_delta_time())
		
	global_position = unshifted_pos + shake_offset

	# To prevent the camera from swiveling/tilting when the player moves,
	# we look at a point relative to the camera's CURRENT position (excluding shake).
	# This keeps the camera angle completely rigid while it slides into place.
	look_at(unshifted_pos - offset, Vector3.UP)

	_handle_occlusion(get_process_delta_time())

# ── Occlusion Fading ──────────────────────────────────────────────────────────

var _faded_objects := {}

func _handle_occlusion(delta: float) -> void:
	if _player == null: return
	
	var space_state = _player.get_world_3d().direct_space_state
	
	# 1. Reset all targets to fully visible
	for mesh in _faded_objects.keys():
		if is_instance_valid(mesh):
			_faded_objects[mesh].target_alpha = 1.0
			
	var current_pos = global_position
	var target_pos = _player.global_position + Vector3(0, 1.0, 0) # Raycast to player's chest
	
	var exclude = [_player.get_rid()]
	
	# 2. Cast rays to find all obstructing objects
	for i in range(5): # Check up to 5 overlapping obstacles
		var query = PhysicsRayQueryParameters3D.create(current_pos, target_pos)
		query.exclude = exclude
		var result = space_state.intersect_ray(query)
		
		if result:
			exclude.append(result.rid)
			var collider = result.collider
			if collider is StaticBody3D:
				var mesh_node = collider.get_parent()
				if mesh_node is MeshInstance3D:
					_mark_mesh_for_fade(mesh_node)
		else:
			break
			
	# 3. Process fading animations
	var meshes_to_remove = []
	for mesh in _faded_objects.keys():
		if not is_instance_valid(mesh):
			meshes_to_remove.append(mesh)
			continue
			
		var data = _faded_objects[mesh]
		var all_restored = true
		
		for i in range(mesh.mesh.get_surface_count()):
			var mat = mesh.get_surface_override_material(i)
			if mat and mat is StandardMaterial3D:
				mat.albedo_color.a = move_toward(mat.albedo_color.a, data.target_alpha, delta * 3.0) # Fade speed
				if mat.albedo_color.a < 0.99:
					all_restored = false
					
		# If it's fully opaque again, remove the material overrides to restore performance
		if data.target_alpha == 1.0 and all_restored:
			for i in range(mesh.mesh.get_surface_count()):
				mesh.set_surface_override_material(i, null)
			meshes_to_remove.append(mesh)
			
	# Clean up dictionary
	for mesh in meshes_to_remove:
		_faded_objects.erase(mesh)

func _mark_mesh_for_fade(mesh: MeshInstance3D) -> void:
	if not _faded_objects.has(mesh):
		if mesh.mesh == null: return
		
		for i in range(mesh.mesh.get_surface_count()):
			var orig_mat = mesh.mesh.surface_get_material(i)
			if orig_mat is StandardMaterial3D:
				# Duplicate the material so we only fade this specific tree, not all trees!
				var new_mat = orig_mat.duplicate()
				new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mesh.set_surface_override_material(i, new_mat)
				
		_faded_objects[mesh] = { "target_alpha": 0.15 } # 15% opacity when fully faded
	else:
		_faded_objects[mesh].target_alpha = 0.15
