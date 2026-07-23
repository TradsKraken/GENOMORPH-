extends Control

var scenes: Array[Dictionary] = [
	{
		"mood": "archival", 
		"label": "ARCHIVAL FOOTAGE", 
		"speaker": "DR. STERLING (V.O.)",
		"text": '"There is a word ecologists use: keystone. A species whose presence keeps the balance, whose absence causes collapse."',
		"dir": 'Amber, golden-hour images. Herons in still water. A frog on a lily pad. A hornbill calling.',
		"rec": true
	},
	{
		"mood": "degraded", 
		"label": "ARCHIVAL FOOTAGE — CONT.", 
		"speaker": "DR. STERLING (V.O.)",
		"text": '"This region lost most of its keystones. Not at once. Quietly, over decades — the way a wall loses its mortar."',
		"dir": 'Same places, degraded. Brown water. Dead trees. Concrete through forest. Bleached reef.',
		"rec": true
	},
	{
		"mood": "lab", 
		"label": "INTERIOR — LAB — NIGHT", 
		"speaker": "DR. STERLING",
		"text": '"My name is Dr. Alistair Sterling. I am a geneticist and biomedical engineer. I\'ve spent eleven years building something I have to believe can help."',
		"dir": 'Sterling at a workbench, monitors and biological equipment around him. He looks tired.'
	},
	{
		"mood": "lab", 
		"label": "INTERIOR — LAB — NIGHT", 
		"speaker": "DR. STERLING",
		"text": '"The ecosystem already knows how to fix itself. I just need to give it a way back in."',
		"dir": 'He holds up a panel of the adaptive armor layer.'
	},
	{
		"mood": "lab", 
		"label": "MONTAGE — SUIT ASSEMBLY", 
		"speaker": "",
		"text": 'Time-lapse: the GenoMorph suit built, tested, refined. A suited figure flickers between human silhouette and frog outline.',
		"dir": 'Sterling watches data streams, writes notes, discards designs, starts over.'
	},
	{
		"mood": "degraded", 
		"label": "EXTERIOR — WETLANDS BORDER — DAY", 
		"speaker": "",
		"text": 'The Volunteer stands at a wire fence, overlooking the ruined, brown wetlands. Quiet grief hardens into resolve.',
		"dir": 'Seen from behind. They fold Sterling\'s recruitment listing and turn from the dead water.'
	},
	{
		"mood": "lab", 
		"label": "EXTERIOR — LAB ENTRANCE — DAY", 
		"speaker": "DR. STERLING (V.O.)",
		"text": '"I found the right person. Someone who knew this land. Someone who wanted it back."',
		"dir": 'The Volunteer arrives. A brief, firm handshake with Sterling at the door.'
	},
	{
		"mood": "lab", 
		"label": "INTERIOR — LAB — LATER", 
		"speaker": "DR. STERLING",
		"text": '"There is something else I need to tell you. About why it\'s you specifically."',
		"dir": 'The suit hangs in its storage frame. Sterling pulls up a genomic display — two DNA profiles side by side.'
	},
	{
		"mood": "lab", 
		"label": "INTERIOR — LAB — LATER", 
		"speaker": "DR. STERLING",
		"text": '"I tested myself first, years ago. My genome doesn\'t carry it. The suit would tear my mind apart speaking a language it has forgotten how to hear."',
		"dir": 'Close on the second profile, labeled simply: AS.'
	},
	{
		"mood": "lab", 
		"label": "INTERIOR — LAB — LATER", 
		"speaker": "DR. STERLING",
		"text": '"You were the only applicant who matched. The suit was always going to need you. I just needed to find you."',
		"dir": 'The Volunteer looks at the suit for a long moment, then back at Sterling.'
	},
	{
		"mood": "lab", 
		"label": "INTERIOR — LAB — LATER", 
		"speaker": "VOLUNTEER",
		"text": '"When do we start?"', 
		"dir": 'A beat of quiet resolve.'
	},
	{
		"mood": "dawn", 
		"label": "EXTERIOR — WETLAND EDGE — DAWN", 
		"speaker": "DR. STERLING",
		"text": '"Tomorrow morning. Test run only. Sixty seconds in Frog form, then we debrief."',
		"dir": 'The Volunteer, now suited, stands at the wetland\'s edge. Dark panels glow faintly green.'
	},
	{
		"mood": "dawn", 
		"label": "EXTERIOR — WETLAND EDGE — DAWN", 
		"speaker": "DR. STERLING (RADIO)",
		"text": '"BioScan readings coming in. Contamination higher than expected — but within tolerance. Initiating Frog transformation on your mark."',
		"dir": 'Radio crackle over the earpiece.'
	},
	{
		"mood": "dawn", 
		"label": "EXTERIOR — WETLAND EDGE — DAWN", 
		"speaker": "VOLUNTEER",
		"text": '"Mark."', 
		"dir": 'The suit shimmers. Silhouette shifts smoothly into the shape of a native frog.'
	},
	{
		"mood": "surge", 
		"label": "THE SURGE", 
		"speaker": "",
		"text": 'A blinding burst of white light. A violent electrical crackle. Twelve pulses of golden light erupt outward — the DNA database, scattering. Gone.',
		"dir": 'SLOW MOTION. A warning klaxon sounds briefly, then dies.'
	},
	{
		"mood": "swamp", 
		"label": "FROG-EYE VIEW", 
		"speaker": "",
		"text": 'The world drops to frog-height. Reeds tower like redwoods. Sludge drops the size of boulders. Breath comes shallow — the breathing of a small, panicked animal.',
		"dir": 'Webbed hands press into the mud. Center of gravity too low — a wobble, a tumble onto their side.'
	},
	{
		"mood": "swamp", 
		"label": "THE DEEP MARSH", 
		"speaker": "",
		"text": 'Silence, save for a wet throat pulsing. Then — a distant, water-muffled roar. Something massive, waking. The sound vibrates through the mud.',
		"dir": 'Nothing visible yet. Only sound.'
	},
	{
		"mood": "radio", 
		"label": "RADIO — HAYWIRE", 
		"speaker": "DR. STERLING (RADIO)",
		"text": '"Volunteer! Volunteer, do you copy? The biometric stream is haywire — please respond!"',
		"dir": 'Heavy static. Genuine panic in his voice.'
	},
	{
		"mood": "swamp", 
		"label": "FROG-EYE VIEW", 
		"speaker": "VOLUNTEER",
		"text": '"I\'m here. I\'m... I\'m down in the mud. Sterling, I\'m a frog. I\'m literally a frog."',
		"dir": 'High-pitched, trembling voice. They look down at webbed limbs.'
	},
	{
		"mood": "radio", 
		"label": "RADIO", 
		"speaker": "DR. STERLING (RADIO)",
		"text": '"The DSEE discharged. All twelve genomes — gone from the suit. Released as raw biological energy. Whatever is living in that wetland right now — I don\'t know what it is anymore."',
		"dir": 'Frantic keystrokes through the static.'
	},
	{
		"mood": "radio", 
		"label": "RADIO", 
		"speaker": "VOLUNTEER / DR. STERLING",
		"text": '"What do I do?" — "...The data is still out there. Your suit\'s Purification Module is still active. Go carefully, Volunteer. Whatever is out there — it isn\'t ordinary anymore."',
		"dir": 'A long pause before Sterling answers, quieter than before.'
	},
	{
		"mood": "title", 
		"label": "", 
		"speaker": "", 
		"text": "", 
		"dir": ""
	},
	{
		"mood": "swamp", 
		"label": "GAMEPLAY BEGINS", 
		"speaker": "DR. STERLING (RADIO)",
		"text": '"Okay... suit telemetry is stable. Your basic systems are functioning. You need to get moving, Volunteer — something big is heading toward your signature."',
		"dir": 'A chemical-laced droplet falls from a giant reed.'
	},
	{
		"mood": "swamp", 
		"label": "PLAYER GAINS CONTROL", 
		"speaker": "",
		"text": 'The player leaps just in time. An invasive mosquito flies close — a tongue snaps out, catching it, healing minor armor damage.',
		"dir": 'Control passes to the player.'
	}
]

var _idx: int = 0
var _is_typing: bool = false
var _typed_length: float = 0.0
var _current_text: String = ""

# UI Nodes
var _bg: ColorRect
var _speaker_label: Label
var _text_label: RichTextLabel
var _dir_label: Label
var _scene_label: Label
var _prompt_label: Label
var _title_label: Label

func _ready() -> void:
	# Filter out non-narration scenes based on user request, but keep the title.
	# Stop collecting scenes after the title to jump straight into the tutorial.
	var narration_scenes: Array[Dictionary] = []
	for s in scenes:
		if s.get("mood", "") == "title":
			narration_scenes.append(s)
			break # Stop here, skip the rest
		elif s.get("speaker", "") != "":
			narration_scenes.append(s)
	scenes = narration_scenes
	
	# Set up the UI hierarchy
	set_anchors_preset(PRESET_FULL_RECT)
	
	_bg = ColorRect.new()
	_bg.set_anchors_preset(PRESET_FULL_RECT)
	_bg.color = Color(0.02, 0.03, 0.02)
	add_child(_bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)
	
	# Top bar (hidden based on user request to only show narration)
	var top_bar = HBoxContainer.new()
	top_bar.size_flags_vertical = SIZE_SHRINK_BEGIN
	top_bar.visible = false
	margin.add_child(top_bar)
	
	_scene_label = Label.new()
	_scene_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 0.7))
	_scene_label.add_theme_font_size_override("font_size", 16)
	_scene_label.size_flags_horizontal = SIZE_EXPAND_FILL
	top_bar.add_child(_scene_label)
	
	_dir_label = Label.new()
	_dir_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	_dir_label.add_theme_font_size_override("font_size", 14)
	_dir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dir_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_dir_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_dir_label.custom_minimum_size = Vector2(400, 0)
	top_bar.add_child(_dir_label)
	
	# Center content (Text)
	var center_vbox = VBoxContainer.new()
	center_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(center_vbox)
	
	_speaker_label = Label.new()
	_speaker_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.4, 0.9))
	_speaker_label.add_theme_font_size_override("font_size", 18)
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker_label.custom_minimum_size = Vector2(0, 30)
	center_vbox.add_child(_speaker_label)
	
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.add_theme_font_size_override("normal_font_size", 28)
	_text_label.add_theme_font_size_override("italics_font_size", 28)
	_text_label.custom_minimum_size = Vector2(800, 150)
	_text_label.fit_content = true
	center_vbox.add_child(_text_label)
	
	# Title splash (hidden by default)
	_title_label = Label.new()
	_title_label.text = "GENOMORPH"
	_title_label.add_theme_font_size_override("font_size", 72)
	_title_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.4, 1.0))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(PRESET_FULL_RECT)
	_title_label.visible = false
	add_child(_title_label)
	
	# Bottom prompt
	_prompt_label = Label.new()
	_prompt_label.text = "Press SPACE or CLICK to advance  |  Press ESC to skip"
	_prompt_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	_prompt_label.add_theme_font_size_override("font_size", 14)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_prompt_label.offset_bottom = -20
	add_child(_prompt_label)
	
	if AudioManager and AudioManager.has_method("play_main_menu_bgm"):
		# Ensure some mood music is playing
		AudioManager.play_main_menu_bgm()
		
	_load_scene(0)

func _process(delta: float) -> void:
	if _is_typing:
		var speed = 35.0 # characters per second
		_typed_length += speed * delta
		var int_len = int(_typed_length)
		
		if int_len >= _current_text.length():
			_text_label.text = "[center]" + _current_text + "[/center]"
			_is_typing = false
		else:
			_text_label.text = "[center]" + _current_text.substr(0, int_len) + "[/center]"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_finish_prologue()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance()
			get_viewport().set_input_as_handled()
			return
			
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()

func _advance() -> void:
	if _is_typing:
		# skip typing
		_is_typing = false
		_text_label.text = "[center]" + _current_text + "[/center]"
	else:
		_idx += 1
		if _idx >= scenes.size():
			_finish_prologue()
		else:
			_load_scene(_idx)

func _load_scene(i: int) -> void:
	var s = scenes[i]
	
	var mood_colors = {
		"archival": Color(0.1, 0.08, 0.05),
		"degraded": Color(0.08, 0.09, 0.06),
		"lab": Color(0.04, 0.08, 0.1),
		"dawn": Color(0.06, 0.1, 0.08),
		"surge": Color(0.12, 0.08, 0.02),
		"swamp": Color(0.04, 0.06, 0.02),
		"radio": Color(0.03, 0.05, 0.05),
		"title": Color(0.01, 0.02, 0.01)
	}
	
	var bg_col = mood_colors.get(s["mood"], Color(0.02, 0.03, 0.02))
	var tw = create_tween()
	tw.tween_property(_bg, "color", bg_col, 0.5)
	
	_scene_label.text = ("● REC  " if (s.has("rec") and s["rec"]) else "") + str(s.get("label", ""))
	_dir_label.text = s.get("dir", "")
	_speaker_label.text = s.get("speaker", "")
	
	_current_text = "[i]" + s.get("text", "") + "[/i]"
	_text_label.text = ""
	_typed_length = 0
	_is_typing = _current_text.length() > 0
	
	if s["mood"] == "title":
		_title_label.visible = true
		_title_label.modulate.a = 0
		var t2 = create_tween()
		t2.tween_property(_title_label, "modulate:a", 1.0, 1.0)
	else:
		_title_label.visible = false

func _finish_prologue() -> void:
	set_process_input(false)
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func():
		if AudioManager and AudioManager.has_method("play_game_bgm"):
			AudioManager.play_game_bgm()
		get_node("/root/SceneLoader").load_scene("res://levels/node_3d.scn")
	)
