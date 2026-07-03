extends Node

enum State { WAKING, HUD_BOOT, RADIO, TUTORIAL, PLAYING }
var current_state = State.WAKING

@onready var player = get_node_or_null("../Frog Player")
var camera: Camera3D = null

var dialog_index = 0
var dialog_sequence = [
	{ "speaker": "SYSTEM", "text": "BIOMETRICS ONLINE...", "duration": 2.0 },
	{ "speaker": "SYSTEM", "text": "WARNING: GENOME DATABASE CORRUPTED. RECONSTRUCTION REQUIRED.", "duration": 3.0 },
	{ "speaker": "Dr. Sterling", "text": "Volunteer! Volunteer, do you copy? The biometric stream is haywire—please respond!", "duration": 4.0 },
	{ "speaker": "Volunteer", "text": "I'm here. I'm... I'm down in the mud. Sterling, I'm a frog. I'm literally a frog.", "duration": 5.0 },
	{ "speaker": "Dr. Sterling", "text": "I know. I'm sorry. Just — stay still. I'm trying to read what's left.", "duration": 4.0 },
	{ "speaker": "Dr. Sterling", "text": "The DSEE discharged. All twelve genomes — gone from the suit. Released as raw biological energy.", "duration": 5.0 },
	{ "speaker": "Dr. Sterling", "text": "Whatever is living in that wetland right now — I don't know what it is anymore.", "duration": 4.0 },
	{ "speaker": "Volunteer", "text": "What do I do?", "duration": 3.0 },
	{ "speaker": "Dr. Sterling", "text": "The data is still out there somewhere. Your suit's Purification Module is still active.", "duration": 5.0 },
	{ "speaker": "Dr. Sterling", "text": "If you can find what absorbed those genomes and get close enough, the suit may be able to read and recover what's left.", "duration": 6.0 },
	{ "speaker": "Volunteer", "text": "Starting from a frog.", "duration": 3.0 },
	{ "speaker": "Dr. Sterling", "text": "...Starting from a frog. I'm sorry.", "duration": 3.0 },
	{ "speaker": "Dr. Sterling", "text": "Your suit is locked to Frog form for now. Go carefully, Volunteer. Whatever is out there — it isn't ordinary anymore.", "duration": 6.0 }
]

func _ready() -> void:
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
	await get_tree().create_timer(1.0).timeout
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
		
	PlayerData.has_seen_prologue = true
	PlayerData.save_game()
		
	# Animate camera back to normal
	if camera:
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(camera, "height", 13.0, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "distance_back", 0.0, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "tilt_degrees", 35.0, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		huds[0].show_tutorial("OBJECTIVE: SEEK BIOLOGICAL NUTRIENTS", "Press [SPACEBAR] to Leap.\\nClick to Feed on small insects.")
		huds[0].reveal_jump()
		huds[0].reveal_attack()
		
	current_state = State.PLAYING
