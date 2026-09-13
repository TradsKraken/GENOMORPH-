extends InteractableBase
class_name SalamanderGenomeSite

const SalamanderScene = preload("res://Models/Salamander/Salamander.glb")

## Q03's fixed, named discovery. It deliberately does not use
## GenomeFragment: this is a species genome, not another generic counter item.
signal genome_recovered(site: SalamanderGenomeSite)

@export var objective_text: String = "Recover the Salamander genome"
@export var objective_desc: String = "Approach the glowing Salamander signal and tap Recover Genome."

var _recovered: bool = false
var _signal_light: OmniLight3D

func _ready() -> void:
	interact_prompt = "Recover Genome"
	super._ready()
	_build_signal_visual()
	if PlayerData.salamander_genome_recovered:
		_recovered = true
		set_active(false)
	_set_signal_visible(is_active and not _recovered)

func set_active(active: bool) -> void:
	super.set_active(active)
	_set_signal_visible(active and not _recovered)
	# The player may already be standing here when purification reveals it.
	if active and is_inside_tree():
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				_on_body_entered(body)

func _process(_delta: float) -> void:
	if _signal_light and not _recovered:
		_signal_light.light_energy = 1.1 + sin(Time.get_ticks_msec() * 0.004) * 0.35

func _perform_interaction() -> void:
	if _recovered:
		return
	_recovered = true
	set_active(false)

	var first_recovery := PlayerData.recover_salamander_genome()
	if first_recovery:
		PlayerData.award_progression_reward("salamander_discovery", 100.0, 3)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Salamander Form Unlocked", "Species genomes unlock forms. Try Salamander using the form circle at the top of the screen.", 6.0)
		
		# Give player the prompt to move forward into the Q04 trigger
		if not PlayerData.q04_completed:
			PlayerData.set_objective(null, "Test the Salamander Form", "Switch to the Salamander form and proceed deeper into the wetlands.")

	genome_recovered.emit(self)
	if _signal_light:
		_signal_light.light_energy = 0.0
	await get_tree().create_timer(0.35).timeout
	_set_signal_visible(false)

func _set_signal_visible(should_show: bool) -> void:
	var visual := get_node_or_null("SignalVisual") as Node3D
	if visual:
		visual.visible = should_show

func _build_signal_visual() -> void:
	if get_node_or_null("SignalVisual"):
		return
	var visual := Node3D.new()
	visual.name = "SignalVisual"
	add_child(visual)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.95, 0.55)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.12, 1.0, 0.48)
	material.emission_energy_multiplier = 2.5
	var hologram := SalamanderScene.instantiate() as Node3D
	visual.add_child(hologram)
	# Normalize the imported model to a two-metre display, regardless of asset scale.
	var bounds := AABB()
	var has_bounds := false
	for mesh_node in hologram.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var local_bounds: AABB = (hologram.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		bounds = bounds.merge(local_bounds) if has_bounds else local_bounds
		has_bounds = true
	if has_bounds:
		var display_scale := 2.0 / maxf(bounds.size.x, maxf(bounds.size.y, maxf(bounds.size.z, 0.01)))
		hologram.scale = Vector3.ONE * display_scale
		hologram.position = Vector3(0.0, 1.0, 0.0) - bounds.get_center() * display_scale

	var label := Label3D.new()
	label.text = "SALAMANDER GENOME SIGNAL"
	label.position.y = 2.3
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.pixel_size = 0.008
	visual.add_child(label)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.65
	torus.outer_radius = 0.72
	torus.material = material
	ring.mesh = torus
	ring.position.y = 0.12
	visual.add_child(ring)

	_signal_light = OmniLight3D.new()
	_signal_light.light_color = Color(0.25, 1.0, 0.58)
	_signal_light.light_energy = 1.2
	_signal_light.omni_range = 5.0
	_signal_light.position.y = 1.0
	visual.add_child(_signal_light)
