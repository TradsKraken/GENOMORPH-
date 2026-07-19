extends Node

var bgm_player: AudioStreamPlayer
var ambiance_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player: int = 0

var sounds: Dictionary = {}

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	# Generate BGM
	var bgm_stream = _generate_bgm()
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.volume_db = -30.0 # Lowered to reduce buzzing hum
	bgm_player.bus = "Master"
	add_child(bgm_player)
	bgm_player.play()
	
	ambiance_player = AudioStreamPlayer.new()
	ambiance_player.stream = load("res://audio/ambiance.ogg")
	ambiance_player.bus = "Master"
	add_child(ambiance_player)
	
	# Load SFX files
	sounds["jump"] = preload("res://audio/Frog Jump.ogg")
	sounds["whip"] = preload("res://audio/tongue whip.ogg")
	sounds["lunge"] = preload("res://audio/Lunge.ogg")
	sounds["exp_collect"] = preload("res://audio/exp collect.ogg")
	sounds["exp_drop"] = preload("res://audio/exp_drop).ogg")
	sounds["level_up"] = preload("res://audio/level up.ogg")
	sounds["mosquito_fly"] = preload("res://audio/Mosquito flying sound.ogg")
	
	sounds["hit"] = [
		preload("res://audio/hit 1 .ogg"),
		preload("res://audio/Hit 2.ogg"),
		preload("res://audio/Hit 3.ogg")
	]
	
	# Procedural fallbacks
	sounds["error"] = _generate_sfx("error")
	sounds["ui_click"] = _generate_sfx("ui_click")
	
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func play_sfx(sound_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if sound_name in sounds:
		var sound = sounds[sound_name]
		var stream: AudioStream
		
		if sound is Array:
			stream = sound.pick_random()
		else:
			stream = sound
			
		if stream:
			var p = sfx_players[next_sfx_player]
			p.stream = stream
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			next_sfx_player = (next_sfx_player + 1) % sfx_players.size()

func play_ambiance() -> void:
	if ambiance_player and not ambiance_player.playing:
		ambiance_player.play()

func _generate_bgm() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	var length = int(22050 * 2.0) # 2 second loop
	var data = PackedByteArray()
	data.resize(length * 2)
	
	stream.loop_begin = 0
	stream.loop_end = length
	
	for i in range(length):
		var t = float(i) / 22050.0
		# Rounded frequencies to integer or .5 to prevent phase clipping on a 2.0s loop
		var val = sin(t * 110.0 * TAU) * 0.2 + sin(t * 131.0 * TAU) * 0.1 + sin(t * 165.0 * TAU) * 0.1
		var sample = int(clampf(val, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
		
	stream.data = data
	return stream

func _generate_sfx(type: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	
	var length = 0
	var data = PackedByteArray()
	
	if type == "jump":
		length = int(22050 * 0.25)
		data.resize(length * 2)
		for i in range(length):
			var t = float(i) / 22050.0
			var freq = 300.0 + 800.0 * (t / 0.25)
			var val = sin(t * freq * TAU) * (1.0 - t/0.25) * 0.5
			var sample = int(clampf(val, -1.0, 1.0) * 32767.0)
			data[i * 2] = sample & 0xFF
			data[i * 2 + 1] = (sample >> 8) & 0xFF
			
	elif type == "whip":
		length = int(22050 * 0.15)
		data.resize(length * 2)
		for i in range(length):
			var t = float(i) / 22050.0
			var freq = maxf(50.0, 1200.0 - 7000.0 * t)
			var noise = randf() * 2.0 - 1.0
			var val = noise * 0.4 * sin(t * freq * TAU) * (1.0 - t/0.15)
			var sample = int(clampf(val, -1.0, 1.0) * 32767.0)
			data[i * 2] = sample & 0xFF
			data[i * 2 + 1] = (sample >> 8) & 0xFF
			
	elif type == "hit":
		length = int(22050 * 0.12)
		data.resize(length * 2)
		for i in range(length):
			var t = float(i) / 22050.0
			var val = (randf() * 2.0 - 1.0) * 0.6 * (1.0 - t/0.12)
			var sample = int(clampf(val, -1.0, 1.0) * 32767.0)
			data[i * 2] = sample & 0xFF
			data[i * 2 + 1] = (sample >> 8) & 0xFF
			
	elif type == "error":
		length = int(22050 * 0.15)
		data.resize(length * 2)
		for i in range(length):
			var t = float(i) / 22050.0
			# Square wave
			var val = (0.3 if sin(t * 120.0 * TAU) > 0 else -0.3) * (1.0 - t/0.15)
			var sample = int(clampf(val, -1.0, 1.0) * 32767.0)
			data[i * 2] = sample & 0xFF
			data[i * 2 + 1] = (sample >> 8) & 0xFF
			
	elif type == "ui_click":
		length = int(22050 * 0.05)
		data.resize(length * 2)
		for i in range(length):
			var t = float(i) / 22050.0
			var freq = 1200.0 - 8000.0 * t
			var val = sin(t * freq * TAU) * (1.0 - t/0.05) * 0.4
			var sample = int(clampf(val, -1.0, 1.0) * 32767.0)
			data[i * 2] = sample & 0xFF
			data[i * 2 + 1] = (sample >> 8) & 0xFF
			
	stream.data = data
	return stream
