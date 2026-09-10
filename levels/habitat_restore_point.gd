extends InteractableBase
class_name HabitatRestorePoint

## Q03's "critical damaged area" — one-shot interactable representing the
## Purification Module activation. Plays a small local visual (we don't have
## dirty/clean mesh variants to swap yet) and notifies Q03Director.

signal restored

var _is_restored: bool = false

func _ready() -> void:
	super._ready()
	interact_prompt = "Restore"

func _perform_interaction() -> void:
	if _is_restored:
		return
	_is_restored = true
	set_active(false)

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("exp_collect")

	_spawn_purify_effect()

	restored.emit()

func _spawn_purify_effect() -> void:
	var light = OmniLight3D.new()
	light.light_color = Color(0.6, 1.0, 0.8)
	light.light_energy = 0.0
	light.omni_range = 6.0
	get_parent().add_child(light)
	light.global_position = global_position

	var tw = create_tween()
	tw.tween_property(light, "light_energy", 3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(light, "light_energy", 0.0, 1.2).set_delay(0.3)
	tw.tween_callback(light.queue_free)
