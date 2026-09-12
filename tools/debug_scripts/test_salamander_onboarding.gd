extends Node

## Run with --headless --path <project> res://tools/debug_scripts/test_salamander_onboarding.tscn
var _completion_count := 0

class GuideHUD extends Node:
	var guide_started := false
	func show_notification(_title: String, _description: String, _duration: float) -> void:
		pass
	func guide_salamander_transformation() -> void:
		guide_started = true

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var hud_script := load("res://ui/hud.gd") as GDScript
	assert(hud_script.can_instantiate(), "The transformation HUD must compile")
	var data := get_tree().root.get_node("PlayerData")
	data.salamander_genome_recovered = false
	data.species_progression.erase("salamander")
	data.active_species = "frog"
	var level := Node3D.new()
	add_child(level)
	var hud := GuideHUD.new()
	level.add_child(hud)
	hud.add_to_group("hud")
	var director := Q03Director.new()
	level.add_child(director)
	director._state = Q03Director.SequenceState.AWAITING_GENOME
	director.completed.connect(func(): _completion_count += 1)
	var site := preload("res://levels/salamander_genome_site.tscn").instantiate() as SalamanderGenomeSite
	level.add_child(site)
	site.genome_recovered.connect(director._on_salamander_genome_recovered)
	site.set_active(true)
	assert(site.get_node("SignalVisual").visible, "Recovery signal should be visible")
	assert(not site.find_children("*", "Label3D", true, false).is_empty(), "Signal needs a species label")
	await site._perform_interaction()
	assert(data.salamander_genome_recovered, "Recovery must unlock the species")
	assert(hud.guide_started, "Recovery must start the control highlight")
	assert(data.current_objective_text == "Try Salamander form", "Transformation instruction must persist")
	assert(_completion_count == 0, "Quest must wait for the first transformation")
	assert(not site.is_active and not site.get_node("SignalVisual").visible, "Recovered signal must disappear")
	director._on_first_transformation("frog")
	assert(_completion_count == 0, "Other forms must not complete the guide")
	assert(data.set_active_species("salamander"), "Unlocked form must be selectable")
	assert(_completion_count == 1, "Selecting Salamander should complete the quest once")
	assert(data.current_objective_text.is_empty(), "Completed guide must clear its objective")
	await site._perform_interaction()
	assert(_completion_count == 1, "Repeated recovery must not repeat quest completion")
	print("PASS: Salamander recovery, guidance, transformation, and duplicate recovery")
	level.queue_free()
	await get_tree().process_frame
	get_tree().quit()
