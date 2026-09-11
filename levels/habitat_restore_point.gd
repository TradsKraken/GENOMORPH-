extends InteractableBase
class_name HabitatRestorePoint

## Q03's "critical damaged area" — one-shot interactable representing the
## Purification Module activation. Leaves a lasting visual change (a soft
## green ground glow, an ambient light that settles in and stays, and slow
## drifting motes) instead of just a burst that fades away to nothing — we
## don't have separate dirty/clean terrain textures to swap, so the ambience
## itself has to carry "this patch is alive again."

signal restored

## Optional: if there's an existing "damaged" visual at this spot already
## placed in the scene (a dead-plant cluster, a murky puddle mesh, a trash
## pile), drag it in here in the Inspector and it will shrink away when the
## habitat is restored. Leave empty if there's nothing to hide.
@export var damaged_visual_path: NodePath

## Legacy/manual cleanup targets. TrashPile scenes can still be assigned here.
@export var trash_piles: Array[NodePath] = []

## Optional manual reference to the plain Node that contains this quest's trash.
## If empty, Q03 automatically uses the node named "Q03TrashRegion".
@export var cleanup_region: NodePath

var _is_restored: bool = false
var _trash_count: int = 0
var _trash_total: int = 0
var _cleanup_started: bool = false
var _registered_trash: Array[Node] = []

func _ready() -> void:
	super._ready()
	# Disable normal interaction prompt since it's event-driven now
	set_active(false)
	interact_prompt = ""
	
	# Connect to explicitly assigned legacy TrashPile nodes.
	for path in trash_piles:
		if path.is_empty(): continue
		_register_trash(get_node_or_null(path))

	# Deferred so every placed trash object has completed _ready() before this
	# point scans the children of its assigned cleanup region.
	call_deferred("_register_region_trash")

func _register_region_trash() -> void:
	var region: Node = null
	if not cleanup_region.is_empty():
		region = get_node_or_null(cleanup_region)
	else:
		# The default Q03 setup requires no Inspector assignment: create a
		# plain Node called Q03TrashRegion and place the trash objects beneath it.
		region = get_tree().current_scene.find_child("Q03TrashRegion", true, false)

	if region == null:
		push_warning("Q03 cleanup region not found. Add a plain Node named Q03TrashRegion and make its trash objects children of it.")
		return

	_register_trash_children(region)

func _register_trash_children(parent: Node) -> void:
	for child in parent.get_children():
		# Both reusable Trash objects and the older TrashPile scene expose a
		# cleanup signal. Looking at the actual child hierarchy means a level
		# designer only needs to put the object under Q03TrashRegion; no group
		# setup or additional Inspector assignment is required.
		_register_trash(child)
		_register_trash_children(child)

func _register_trash(trash: Node) -> void:
	if trash == null or _registered_trash.has(trash):
		return

	if trash.has_signal("cleaned"):
		trash.connect("cleaned", _on_trash_destroyed)
	elif trash.has_signal("destroyed"):
		trash.connect("destroyed", _on_trash_destroyed)
	else:
		return

	_registered_trash.append(trash)
	_trash_count += 1
	_trash_total += 1

## Called by Q03 after the native-frog conversation. Keeping this dormant until
## then prevents a level's cleanup objective from overwriting Q01/Q02.
func begin_cleanup() -> void:
	if _is_restored or _cleanup_started:
		return

	_cleanup_started = true
	if _trash_count > 0:
		PlayerData.set_objective(null, "Clear the habitat trash", "%d remaining" % _trash_count)
		_update_cleanup_progress()
	else:
		_enable_restore()

func _on_trash_destroyed() -> void:
	_trash_count -= 1
	if not _cleanup_started or _is_restored:
		return
	_update_cleanup_progress()
	if _trash_count > 0:
		PlayerData.set_objective(null, "Clear the habitat trash", "%d remaining" % _trash_count)
	else:
		_enable_restore()

func _enable_restore() -> void:
	set_active(true)
	PlayerData.set_objective(self, "Restore the damaged habitat", "The habitat is clear. Activate the Purification Module.")

func _update_cleanup_progress() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_cleanup_progress"):
		hud.show_cleanup_progress(_trash_total - _trash_count, _trash_total)

func _hide_cleanup_progress() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("hide_cleanup_progress"):
		hud.hide_cleanup_progress()

func _perform_interaction() -> void:
	if _is_restored or not _cleanup_started or _trash_count > 0:
		return
	_is_restored = true
	set_active(false)
	_hide_cleanup_progress()

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("exp_collect")

	PlayerData.set_objective(null, "")

	_fade_out_damaged_visual()
	_spawn_purify_effect()
	_spawn_persistent_glow()
	_drop_genome()

	restored.emit()

func _drop_genome() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("SALAMANDER GENOME RECOVERED", "Habitat restoration data secured.")

	# This is the quest's only genome reward. It intentionally skips the
	# generic fragment popup because the dedicated notification above already
	# communicates the reward; spawning a second pickup used to award it twice.
	PlayerData.add_genome_fragment(false)

func _fade_out_damaged_visual() -> void:
	if damaged_visual_path.is_empty():
		return
	var node = get_node_or_null(damaged_visual_path)
	if not (node and node is Node3D):
		return
	var tw = create_tween()
	tw.tween_property(node, "scale", Vector3.ZERO, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(node.queue_free)

func _spawn_purify_effect() -> void:
	var light = OmniLight3D.new()
	light.light_color = Color(0.6, 1.0, 0.8)
	light.light_energy = 0.0
	light.omni_range = 6.0
	get_parent().add_child(light)
	light.global_position = global_position

	var particles = GPUParticles3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 1.0, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 1.0, 0.6)
	mat.emission_energy_multiplier = 2.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES

	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.2, 0.2)
	mesh.material = mat
	particles.draw_pass_1 = mesh

	var process_mat = ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_mat.emission_sphere_radius = 2.0
	process_mat.direction = Vector3(0, 1, 0)
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 1.0
	process_mat.initial_velocity_max = 3.0
	process_mat.gravity = Vector3(0, 0.5, 0)
	process_mat.scale_min = 0.5
	process_mat.scale_max = 1.5
	particles.process_material = process_mat

	particles.amount = 60
	particles.lifetime = 2.0
	particles.explosiveness = 0.8
	particles.one_shot = true

	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true

	var tw = create_tween()
	tw.tween_property(light, "light_energy", 3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(light, "light_energy", 0.0, 1.2).set_delay(0.3)
	tw.tween_callback(func():
		light.queue_free()
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()
	)

## The lasting part — a soft ambient light that settles in and stays lit, a
## faint green ground glow decal, and a handful of slow-drifting motes that
## never stop, so the spot visibly reads as "restored" long after the
## interaction moment has passed (unlike the burst above, which is one-shot).
func _spawn_persistent_glow() -> void:
	var light = OmniLight3D.new()
	light.light_color = Color(0.55, 1.0, 0.75)
	light.light_energy = 0.0
	light.omni_range = 5.0
	get_parent().add_child(light)
	light.global_position = global_position + Vector3(0, 0.5, 0)

	var light_tw = create_tween()
	light_tw.tween_property(light, "light_energy", 1.4, 1.2).set_trans(Tween.TRANS_SINE).set_delay(0.6)
	light_tw.tween_property(light, "light_energy", 0.7, 1.5)

	var decal = Decal.new()
	decal.texture_albedo = _generate_radial_glow_texture()
	decal.size = Vector3(5.0, 3.0, 5.0)
	decal.modulate = Color(0.6, 1.0, 0.7, 0.0)
	decal.upper_fade = 0.5
	decal.lower_fade = 0.5
	get_parent().add_child(decal)
	decal.global_position = global_position + Vector3(0, 1.0, 0)

	var decal_tw = create_tween()
	decal_tw.tween_property(decal, "modulate:a", 0.8, 1.5).set_delay(0.5)

	var motes = GPUParticles3D.new()
	var mote_mat = StandardMaterial3D.new()
	mote_mat.albedo_color = Color(0.6, 1.0, 0.75)
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(0.6, 1.0, 0.75)
	mote_mat.emission_energy_multiplier = 1.5
	mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mote_mesh = QuadMesh.new()
	mote_mesh.size = Vector2(0.08, 0.08)
	mote_mesh.material = mote_mat
	motes.draw_pass_1 = mote_mesh

	var mote_process_mat = ParticleProcessMaterial.new()
	mote_process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mote_process_mat.emission_sphere_radius = 2.5
	mote_process_mat.direction = Vector3(0, 1, 0)
	mote_process_mat.spread = 30.0
	mote_process_mat.initial_velocity_min = 0.1
	mote_process_mat.initial_velocity_max = 0.3
	mote_process_mat.gravity = Vector3.ZERO
	mote_process_mat.scale_min = 0.6
	mote_process_mat.scale_max = 1.4
	motes.process_material = mote_process_mat

	motes.amount = 14
	motes.lifetime = 4.0
	motes.preprocess = 4.0 # avoids a visibly "empty" first second when it appears
	motes.one_shot = false
	motes.emitting = true

	get_parent().add_child(motes)
	motes.global_position = global_position

## Bakes a soft radial falloff (white, alpha only) so the ground decal doesn't
## need a separate imported texture asset — the greenish tint comes from the
## decal's own modulate color instead.
func _generate_radial_glow_texture(size: int = 64) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center) / max_dist
			var alpha = pow(clampf(1.0 - dist, 0.0, 1.0), 2.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)
