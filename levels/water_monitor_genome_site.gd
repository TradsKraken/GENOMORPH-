extends InteractableBase
class_name WaterMonitorGenomeSite

signal genome_recovered(site: WaterMonitorGenomeSite)

const MonitorScene = preload("res://Models/Water Monitor Lizard/Monitor Lizard FIXED.glb")

@export var objective_text := "Recover the Water Monitor genome"
@export var objective_desc := "Approach the biological signal and tap Recover Genome."

var _recovered := false
var _signal_light: OmniLight3D

func _ready() -> void:
	interact_prompt = "Recover Genome"
	super._ready()
	_recovered = PlayerData.is_species_unlocked("water_monitor")
	_build_signal_visual()
	_set_signal_visible(is_active and not _recovered)

func set_active(active: bool) -> void:
	super.set_active(active)
	_set_signal_visible(active and not _recovered)

func _perform_interaction() -> void:
	if _recovered:
		return
	_recovered = true
	set_active(false)
	if PlayerData.unlock_species("water_monitor"):
		PlayerData.award_progression_reward("water_monitor_discovery", 20.0, 3)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Water Monitor Form Unlocked", "A powerful new form is available from the form circle.", 6.0)
	genome_recovered.emit(self)

func _build_signal_visual() -> void:
	var visual := Node3D.new()
	visual.name = "SignalVisual"
	add_child(visual)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.66, 0.12)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(1.0, 0.45, 0.06)
	material.emission_energy_multiplier = 2.4
	var hologram := MonitorScene.instantiate() as Node3D
	visual.add_child(hologram)
	hologram.scale = Vector3(0.5, 0.5, 0.5)
	_signal_light = OmniLight3D.new()
	_signal_light.light_color = Color(1.0, 0.48, 0.12)
	_signal_light.light_energy = 2.0
	_signal_light.omni_range = 8.0
	visual.add_child(_signal_light)

func _process(_delta: float) -> void:
	if _signal_light and not _recovered:
		_signal_light.light_energy = 1.6 + sin(Time.get_ticks_msec() * 0.004) * 0.5

func _set_signal_visible(should_show: bool) -> void:
	var visual := get_node_or_null("SignalVisual") as Node3D
	if visual:
		visual.visible = should_show
