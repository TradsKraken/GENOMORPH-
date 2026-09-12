extends Control

var subtitles: Array[Dictionary] = [
	{ "time": 3.0, "speaker": "Dr. Alistair Sterling", "text": "There is a word ecologists use: keystone. A keystone species is one that holds everything else in place, whose presence keeps the balance, whose absence causes collapse." },
	{ "time": 15.0, "speaker": "Dr. Alistair Sterling", "text": "This region lost most of its keystones. Not at once. Quietly, over decades. The way a wall loses its mortar." },
	{ "time": 25.0, "speaker": "Dr. Alistair Sterling", "text": "My name is Dr. Alistair Sterling. I am a geneticist and biomedical engineer. I have spent the last 11 years building something that I believe, that I have to believe, can help." },
	{ "time": 36.0, "speaker": "Dr. Alistair Sterling", "text": "I found the right person. Someone who knew this land. Someone who wanted it back." },
	{ "time": 43.0, "speaker": "Dr. Alistair Sterling", "text": "There is something else I need to tell you... about why it's you specifically." },
	{ "time": 49.0, "speaker": "Dr. Alistair Sterling", "text": "The suit's neural interface, the system that makes the transformation survivable, it requires a very specific genetic profile. You were the only applicant who matched. Which means the suit was always going to need you. I just needed to find you." },
	{ "time": 65.0, "speaker": "Recruit", "text": "When do we start?" },
	{ "time": 66.0, "speaker": "Dr. Alistair Sterling", "text": "Tomorrow morning. Test run only." },
	{ "time": 70.0, "speaker": "Dr. Alistair Sterling", "text": "Bio-scan readings are coming in. The contamination is higher than I expected, but within tolerance. Initiating frog transformation on your mark." },
	{ "time": 81.0, "speaker": "Recruit", "text": "Mark." },
	{ "time": 85.0, "speaker": "", "text": "" }
]

var _video_player: VideoStreamPlayer
var _speaker_label: Label
var _text_label: RichTextLabel
var _current_sub_idx: int = -1
var _is_fading_out: bool = false

const MAIN_TERRAIN_PATH = "res://levels/main terrain.scn"
var _preload_started: bool = false

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color.BLACK
	add_child(bg)
	
	_video_player = VideoStreamPlayer.new()
	_video_player.set_anchors_preset(PRESET_FULL_RECT)
	_video_player.expand = true
	_video_player.stream = load("res://assets/Prologue.ogv")
	add_child(_video_player)
	
	var top_bar = ColorRect.new()
	top_bar.color = Color.BLACK
	top_bar.set_anchors_preset(PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 80)
	add_child(top_bar)
	
	var bottom_bar = ColorRect.new()
	bottom_bar.color = Color.BLACK
	bottom_bar.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom_bar.custom_minimum_size = Vector2(0, 100)
	bottom_bar.grow_horizontal = 2
	bottom_bar.grow_vertical = 0
	add_child(bottom_bar)
	
	var textzone = VBoxContainer.new()
	textzone.set_anchors_preset(PRESET_BOTTOM_WIDE)
	textzone.offset_bottom = -30
	textzone.grow_vertical = 0
	textzone.alignment = BoxContainer.ALIGNMENT_END
	add_child(textzone)
	
	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", Color("9fe870"))
	_speaker_label.add_theme_font_size_override("font_size", 16)
	_speaker_label.add_theme_constant_override("character_spacing", 2)
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker_label.uppercase = true
	_speaker_label.modulate.a = 0.85
	textzone.add_child(_speaker_label)
	
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.add_theme_color_override("default_color", Color("eef3ea"))
	_text_label.add_theme_font_size_override("normal_font_size", 28)
	_text_label.add_theme_font_size_override("italics_font_size", 28)
	_text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_text_label.add_theme_constant_override("shadow_offset_x", 0)
	_text_label.add_theme_constant_override("shadow_offset_y", 2)
	_text_label.add_theme_constant_override("shadow_outline_size", 10)
	_text_label.custom_minimum_size = Vector2(800, 100)
	_text_label.fit_content = true
	textzone.add_child(_text_label)
	
	var prompt_label = Label.new()
	prompt_label.text = "Press ESC or SPACE to skip"
	prompt_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt_label.set_anchors_preset(PRESET_BOTTOM_WIDE)
	prompt_label.offset_bottom = -10
	prompt_label.offset_right = -20
	add_child(prompt_label)
	
	if AudioManager and AudioManager.has_method("fade_to_main_menu_bgm"):
		if AudioManager.bgm_player:
			var tw = create_tween()
			tw.tween_property(AudioManager.bgm_player, "volume_db", -80.0, 1.0)
			tw.tween_callback(func(): AudioManager.bgm_player.stop())
			
	_video_player.finished.connect(_finish_prologue)
	_video_player.play()
	
	# ── Pre-load the main terrain in the background while the video plays ──
	var err = ResourceLoader.load_threaded_request(MAIN_TERRAIN_PATH)
	if err == OK:
		_preload_started = true
		print("[PRELOAD] Started background loading of main terrain")
	else:
		push_warning("[PRELOAD] Could not start background load, will use SceneLoader fallback")

func _process(_delta: float) -> void:
	if not _video_player.is_playing():
		return
		
	var t = _video_player.stream_position
	
	if t >= 85.0 and not _is_fading_out:
		_is_fading_out = true
		_start_fade_out()
	
	var target_sub = -1
	for i in range(subtitles.size()):
		if t >= subtitles[i].time:
			target_sub = i
		else:
			break
			
	if target_sub != _current_sub_idx and target_sub >= 0:
		_current_sub_idx = target_sub
		_show_subtitle(subtitles[target_sub])

func _show_subtitle(sub: Dictionary) -> void:
	_speaker_label.text = sub.speaker
	if sub.text != "":
		_text_label.text = "[center][i]" + sub.text + "[/i][/center]"
	else:
		_text_label.text = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_finish_prologue()
			get_viewport().set_input_as_handled()
			return
			
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_prologue()
		get_viewport().set_input_as_handled()

func _finish_prologue() -> void:
	if _is_fading_out: return
	_is_fading_out = true
	set_process_input(false)
	_video_player.stop()
	
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		if AudioManager and AudioManager.has_method("play_game_bgm"):
			AudioManager.play_game_bgm()
		_transition_to_terrain()
	)

func _start_fade_out() -> void:
	set_process_input(false)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_video_player, "volume_db", -40.0, 2.0)
	tw.tween_property(self, "modulate:a", 0.0, 2.0)
	tw.chain().tween_callback(func():
		_video_player.stop()
		if AudioManager and AudioManager.has_method("play_game_bgm"):
			AudioManager.play_game_bgm()
		_transition_to_terrain()
	)

func _transition_to_terrain() -> void:
	# If the background preload finished, use it directly (instant transition)
	if _preload_started:
		var status = ResourceLoader.load_threaded_get_status(MAIN_TERRAIN_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			print("[PRELOAD] Terrain was pre-loaded! Switching instantly.")
			var packed_scene = ResourceLoader.load_threaded_get(MAIN_TERRAIN_PATH)
			get_tree().change_scene_to_packed(packed_scene)
			return
		else:
			print("[PRELOAD] Terrain not ready yet (status=%d), falling back to SceneLoader" % status)
	# Fallback: use the normal loading screen
	get_node("/root/SceneLoader").load_scene(MAIN_TERRAIN_PATH)
