extends InteractableBase
class_name SalamanderGenomeSite

## Q03's fixed, named discovery. It deliberately does not use
## GenomeFragment: this is a species genome, not another generic counter item.
signal genome_recovered(site: SalamanderGenomeSite)

@export var objective_text: String = "Recover the Salamander genome"
@export var objective_desc: String = "Follow the signal to the recovered habitat."

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
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Salamander Genome Recovered", "Species data secured. Salamander genome unlocked.", 4.0)

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

	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.38
	sphere.height = 0.76
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.95, 0.55)
	material.emission_enabled = true
	material.emission = Color(0.12, 1.0, 0.48)
	material.emission_energy_multiplier = 2.5
	sphere.material = material
	core.mesh = sphere
	core.position.y = 1.0
	visual.add_child(core)

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
