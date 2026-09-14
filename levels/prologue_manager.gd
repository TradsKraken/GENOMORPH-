extends Node

signal finished

enum State { WAKING, HUD_BOOT, RADIO, PLAYING }
var current_state = State.WAKING

@onready var player = get_node_or_null("../Frog Player")
var camera: Camera3D = null

var dialog_index = 0
var dialog_sequence = [
	{ "speaker": "STERLING", "text": "Volunteer, do you copy? The suit survived, but its biometric stream is unstable.", "duration": 3.2 },
	{ "speaker": "VOLUNTEER", "text": "I do. Sterling... I'm a frog.", "duration": 2.5 },
	{ "speaker": "STERLING", "text": "The DSEE discharge scattered the suit's genomes through the wetland. The water and soil absorbed them.", "duration": 4.0 },
	{ "speaker": "STERLING", "text": "Your Purification Module can recover genome data from nearby signals. Get close enough to scan them.", "duration": 3.8 },
	{ "speaker": "STERLING", "text": "Frog form is all we have for now. Move carefully and investigate the wetland.", "duration": 3.2 }
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
	await get_tree().create_timer(1.2).timeout

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
			_auto_advance_dialogue(dialog_index, line.duration, huds[0])
	else:
		_finish_prologue()

func _on_subtitle_dismissed() -> void:
	if current_state == State.RADIO:
		dialog_index += 1
		_play_next_dialog()

func _auto_advance_dialogue(line_index: int, duration: float, hud: Node) -> void:
	await get_tree().create_timer(duration).timeout
	if current_state == State.RADIO and dialog_index == line_index and is_instance_valid(hud):
		if hud.has_method("hide_subtitle"):
			hud.hide_subtitle()

func _finish_prologue() -> void:
	current_state = State.PLAYING
	PlayerData.has_seen_prologue = true
	# A short orientation-only HUD tour follows the prologue. Detailed lessons
	# are introduced only when their feature becomes useful.
	var huds = get_tree().get_nodes_in_group("hud")
	if not PlayerData.has_seen_ui_intro and huds.size() > 0 and huds[0].has_method("start_tutorial"):
		huds[0].call_deferred("start_tutorial", "intro")

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
