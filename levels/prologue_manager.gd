extends Node

signal finished

enum State { WAKING, HUD_BOOT, RADIO, PLAYING }
var current_state = State.WAKING

@onready var player = get_node_or_null("../Frog Player")
var camera: Camera3D = null

var dialog_index = 0
var dialog_sequence = [
	{ "speaker": "STERLING", "text": "Volunteer! Volunteer, do you copy? The biometric stream is haywire—please respond!", "duration": 4.0 },
	{ "speaker": "VOLUNTEER", "text": "I'm here. I'm... I'm down in the mud. Sterling, I'm a frog. I'm literally a frog.", "duration": 4.0 },
	{ "speaker": "STERLING", "text": "I know. I'm sorry. Just — stay still. I'm trying to read what's left.", "duration": 4.0 },
	{ "speaker": "STERLING", "text": "The DSEE discharged. All twelve genomes — gone from the suit. Released as raw biological energy. I don't know where they landed.", "duration": 6.0 },
	{ "speaker": "STERLING", "text": "The water, the soil... anything that was close enough could have absorbed fragments. Whatever is living in that wetland right now — I don't know what it is anymore.", "duration": 7.0 },
	{ "speaker": "VOLUNTEER", "text": "What do I do?", "duration": 2.0 },
	{ "speaker": "STERLING", "text": "The data is still out there somewhere. It has to be. Your suit's Purification Module is still active — if you can find what absorbed those genomes and get close enough, the suit may be able to read and recover what's left.", "duration": 8.0 },
	{ "speaker": "VOLUNTEER", "text": "Starting from a frog.", "duration": 3.0 },
	{ "speaker": "STERLING", "text": "...Starting from a frog. I'm sorry.", "duration": 3.0 },
	{ "speaker": "STERLING", "text": "Your suit is locked to Frog form for now. Go carefully, Volunteer. Whatever is out there — it isn't ordinary anymore.", "duration": 6.0 }
]

func _ready() -> void:
	add_to_group("prologue_manager")

	if PlayerData.has_seen_prologue:
		if player:
			player.input_locked = false
		finished.emit()
		queue_free()
		return

	# Lock player during fade in, and for the whole conversation that follows.
	if player:
		player.input_locked = true

	# Override camera to ground level for immersion. This framing stays put
	# for the entire conversation — pulling the camera back at the same time
	# the player is trying to read dialogue would split their attention.
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
	await get_tree().create_timer(4.0).timeout # Wait for boot sequence fade in

	# Straight into the conversation — the player is still locked and the
	# camera is still in its close intro framing throughout.
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
		_finish_prologue()

func _on_subtitle_dismissed() -> void:
	if current_state == State.RADIO:
		dialog_index += 1
		_play_next_dialog()

func _finish_prologue() -> void:
	current_state = State.PLAYING
	PlayerData.has_seen_prologue = true
	# We DO NOT call start_tutorial() here anymore to avoid the aggressive UI walkthrough.
	# The player is now free to explore the wetlands.

	# Only NOW — conversation actually over — give control back and pull the
	# camera out to its normal gameplay framing.
	if player:
		player.input_locked = false

	if camera:
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(camera, "height", 13.0, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "distance_back", 0.0, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "tilt_degrees", 35.0, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	finished.emit()
