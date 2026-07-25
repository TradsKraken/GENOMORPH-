extends CanvasLayer

var _scroll_container: Control
var _rtl: RichTextLabel
var _scroll_speed: float = 40.0
var _is_scrolling: bool = false

func _ready() -> void:
	layer = 120 # Above everything else
	
	# Full screen cinematic black background
	var bg_rect := ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 0.95)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	_scroll_container = Control.new()
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.clip_contents = true
	add_child(_scroll_container)
	
	_rtl = RichTextLabel.new()
	_rtl.bbcode_enabled = true
	_rtl.fit_content = true
	_rtl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_rtl.add_theme_font_override("normal_font", ThemeDB.fallback_font)
	
	var text := """[center]

[font_size=52][color=#b3d9ff][b]GENOMORPH[/b][/color][/font_size]

[font_size=20][color=#aaaaaa]A Game by[/color] [color=#ffffff]PhsynTaKâ€™s[/color][/font_size]


[font_size=24][color=#80bfff]- THE CORE TEAM -[/color][/font_size]

[font_size=16][color=#888888]LEAD PROGRAMMER & TECHNICAL DESIGNER[/color][/font_size]
[font_size=22][color=#ffffff]Kent Dave R. Pilar[/color][/font_size]

[font_size=16][color=#888888]NARRATIVE & GAMEPLAY DESIGNER[/color][/font_size]
[font_size=22][color=#ffffff]Pshych Earl B. CaleÃ±ada[/color][/font_size]

[font_size=16][color=#888888]RESEARCH, CONCEPT & DOCUMENTATION LEAD[/color][/font_size]
[font_size=22][color=#ffffff]Thomas Kyle L. Galo[/color][/font_size]


[font_size=24][color=#80bfff]- EXTERNAL ASSETS & TOOLS -[/color][/font_size]

[font_size=16][color=#888888]GAME ENGINE[/color][/font_size]
[font_size=20][color=#ffffff]Godot Engine[/color][/font_size]

[font_size=16][color=#888888]3D MODELING & ANIMATION[/color][/font_size]
[font_size=20][color=#ffffff]Blender[/color][/font_size]

[font_size=16][color=#888888]3D ANIMATION LIBRARY[/color][/font_size]
[font_size=20][color=#ffffff]Universal Animation Library by Quaternius[/color][/font_size]


[font_size=24][color=#80bfff]- SPECIAL THANKS & ACKNOWLEDGMENTS -[/color][/font_size]

[font_size=16][color=#888888]INSTITUTION[/color][/font_size]
[font_size=20][color=#ffffff]Valencia National Highschool[/color][/font_size]

[font_size=16][color=#888888]PROJECT ADVISOR[/color][/font_size]
[font_size=20][color=#ffffff]Ace B. CardeÃ±o[/color][/font_size]

[font_size=16][color=#888888]PLAYTESTERS[/color][/font_size]
[font_size=20][color=#ffffff]Our Amazing Friends & Classmates[/color][/font_size]


[font_size=22][color=#b3d9ff][i]"Thank you for playing!"[/i][/color][/font_size]

[font_size=24][color=#b3d9ff]"Transform and Thrive. Keep the Wild Alive."[/color][/font_size]



[font_size=14][color=#666666]Â© 2026 PhsynTaKâ€™s. All rights reserved.[/color][/font_size]

[/center]"""
	
	_rtl.text = text
	_scroll_container.add_child(_rtl)
	
	# Skip label
	var skip_lbl := Label.new()
	skip_lbl.text = "Click anywhere to skip"
	skip_lbl.add_theme_font_size_override("font_size", 24)
	skip_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	skip_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_lbl.offset_right = -20
	skip_lbl.offset_bottom = -20
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(skip_lbl)
	
	# Start below screen
	call_deferred("_start_scroll")

func _start_scroll() -> void:
	_rtl.position.y = get_viewport().get_visible_rect().size.y
	_is_scrolling = true

func _process(delta: float) -> void:
	if _is_scrolling:
		_rtl.position.y -= _scroll_speed * delta
		
		# Auto-close when text scrolls completely off the top
		if _rtl.position.y < -_rtl.size.y - 100:
			_close()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		_close()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	queue_free()
