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

@export var trash_piles: Array[NodePath] = []

var _is_restored: bool = false
var _trash_count: int = 0

func _ready() -> void:
	super._ready()
	# Disable normal interaction prompt since it's event-driven now
	set_active(false)
	interact_prompt = ""
	
	# Connect to all assigned trash piles
	for path in trash_piles:
		if path.is_empty(): continue
		var pile = get_node_or_null(path)
		if pile and pile.has_signal("destroyed"):
			pile.destroyed.connect(_on_trash_destroyed)
			_trash_count += 1

func _on_trash_destroyed() -> void:
	_trash_count -= 1
	if _trash_count <= 0 and not _is_restored:
		_perform_interaction()

func _perform_interaction() -> void:
	if _is_restored:
		return
	_is_restored = true

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("exp_collect")

	_fade_out_damaged_visual()
	_spawn_purify_effect()
	_spawn_persistent_glow()
	_drop_genome()

	restored.emit()

func _drop_genome() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("HABITAT RESTORED", "Salamander Genome Data Extracted.")
	
	# Automatically add genome
	PlayerData.add_genome_fragment()
	
	# Spawn visual pickup object if it exists
	var orb_scene = load("res://levels/genome_fragment.tscn")
	if orb_scene:
		var orb = orb_scene.instantiate()
		get_parent().add_child(orb)
		orb.global_position = global_position + Vector3(0, 1.5, 0)

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
