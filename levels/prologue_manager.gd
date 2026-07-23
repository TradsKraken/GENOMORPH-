extends Node

enum State { WAKING, HUD_BOOT, RADIO, TUTORIAL, PLAYING }
var current_state = State.WAKING

@onready var player = get_node_or_null("../Frog Player")
var camera: Camera3D = null

var dialog_index = 0
var dialog_sequence = [
	{ "speaker": "SYSTEM", "text": "BIOMETRICS ONLINE...", "duration": 2.0 },
	{ "speaker": "SYSTEM", "text": "WARNING: GENOME DATABASE CORRUPTED. RECONSTRUCTION REQUIRED.", "duration": 3.0 }
]

func _ready() -> void:
	var tut2 = get_node_or_null("../tut2/EnemySpawner")
	if tut2:
		PlayerData.call_deferred("set_objective", tut2)
		
	if PlayerData.has_seen_prologue:
		if player:
			player.input_locked = false
		queue_free()
		return
		
	# Lock player
	if player:
		player.input_locked = true
		
	# Override camera to ground level
	camera = get_node_or_null("../Camera3D") as Camera3D
	if camera:
		camera.set("height", 4.0)
		camera.set("distance_back", 5.0)
		camera.set("tilt_degrees", 15.0)
		
	# Start sequence
	call_deferred("_start_sequence")

func _start_sequence() -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		if huds[0].has_method("play_boot_sequence"):
			huds[0].play_boot_sequence()
		


	current_state = State.HUD_BOOT
	await get_tree().create_timer(6.0).timeout # Wait for boot sequence
	
	current_state = State.RADIO
	_play_next_dialog()

func _play_next_dialog() -> void:
	if dialog_index < dialog_sequence.size():
		var line = dialog_sequence[dialog_index]
		var huds = get_tree().get_nodes_in_group("hud")
		if huds.size() > 0:
			huds[0].show_subtitle(line.speaker, line.text, line.duration)
			
			if not huds[0].is_connected("subtitle_dismissed", _on_subtitle_dismissed):
				huds[0].subtitle_dismissed.connect(_on_subtitle_dismissed)
	else:
		_start_tutorial()

func _on_subtitle_dismissed() -> void:
	if current_state == State.RADIO:
		dialog_index += 1
		_play_next_dialog()

func _start_tutorial() -> void:
	current_state = State.TUTORIAL
	if player:
		player.input_locked = false
		
	# DO NOT set has_seen_prologue = true here anymore.
	# The new hud.start_tutorial() will set it after all 15 steps complete.
		
	# Animate camera back to normal
	if camera:
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(camera, "height", 13.0, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "distance_back", 0.0, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "tilt_degrees", 35.0, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
	# Kick off the full 15-step HUD tutorial
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0 and huds[0].has_method("start_tutorial"):
		huds[0].start_tutorial()
		
	current_state = State.PLAYING
