extends Node
class_name SceneLoaderAutoload

# Global Loading Screen Singleton
# Usage: SceneLoader.load_scene("res://levels/node_3d.scn")

var _canvas: CanvasLayer
var _root: Control
var _bg_rect: ColorRect
var _bg_texture: TextureRect
var _progress_bar: ProgressBar
var _label: Label

var _target_scene: String = ""
var _is_loading: bool = false
var _progress_array: Array = [0.0]

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	_canvas = CanvasLayer.new()
	_canvas.layer = 128 # Very high so it covers everything
	_canvas.visible = false
	add_child(_canvas)
	
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(_root)
	
	_bg_rect = ColorRect.new()
	_bg_rect.color = Color(0.05, 0.05, 0.08, 1.0) # Dark sleek background
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_bg_rect)
	
	_bg_texture = TextureRect.new()
	_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_root.add_child(_bg_texture)
	
	_label = Label.new()
	_label.text = "LOADING..."
	_label.add_theme_font_size_override("font_size", 42)
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.offset_bottom = -140
	_root.add_child(_label)
	
	_progress_bar = ProgressBar.new()
	_progress_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_progress_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_progress_bar.custom_minimum_size = Vector2(800, 30)
	_progress_bar.offset_bottom = -80
	_progress_bar.show_percentage = false
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	sb_bg.border_color = Color(0.2, 0.3, 0.4, 0.5)
	sb_bg.set_border_width_all(2)
	sb_bg.set_corner_radius_all(15)
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.3, 0.9, 0.4, 1.0) # Vibrant green fill!
	sb_fill.set_corner_radius_all(15)
	
	_progress_bar.add_theme_stylebox_override("background", sb_bg)
	_progress_bar.add_theme_stylebox_override("fill", sb_fill)
	
	_root.add_child(_progress_bar)

func load_scene(path: String, texture_path: String = "") -> void:
	_target_scene = path
	
	if texture_path != "":
		_bg_texture.texture = load(texture_path)
	else:
		_bg_texture.texture = null
		
	_progress_bar.value = 0.0
	_root.modulate.a = 0.0
	_canvas.visible = true
	
	# Smooth fade in
	var tween = create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func():
		# Check if the scene was already pre-loaded by another script (e.g. prologue)
		var status = ResourceLoader.load_threaded_get_status(_target_scene)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Already done! Skip straight to the scene switch
			print("[SceneLoader] Scene was pre-loaded, switching instantly")
			_is_loading = false
			_progress_bar.value = 100.0
			var packed_scene = ResourceLoader.load_threaded_get(_target_scene)
			get_tree().change_scene_to_packed(packed_scene)
			var fade_tw = create_tween()
			fade_tw.tween_interval(0.2)
			fade_tw.tween_property(_root, "modulate:a", 0.0, 0.4)
			fade_tw.tween_callback(_finish_loading)
			return
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Already loading in background, just piggyback on it
			print("[SceneLoader] Scene is already loading in background, piggybacking")
			_is_loading = true
			return

		# Normal case: start a fresh threaded load
		var err = ResourceLoader.load_threaded_request(_target_scene)
		if err == OK:
			_is_loading = true
		else:
			push_error("SceneLoader: Failed to load scene ", path)
			_finish_loading()
	)

func _process(_delta: float) -> void:
	if not _is_loading:
		return
		
	var status = ResourceLoader.load_threaded_get_status(_target_scene, _progress_array)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var target_val = _progress_array[0] * 100.0
		# Smooth interpolation for the progress bar
		_progress_bar.value = lerpf(_progress_bar.value, target_val, 0.1)
		
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		_is_loading = false
		_progress_bar.value = 100.0
		
		var packed_scene = ResourceLoader.load_threaded_get(_target_scene)
		get_tree().change_scene_to_packed(packed_scene)
		
		# Give a tiny delay so the scene can _ready() before fading out
		var tween = create_tween()
		tween.tween_interval(0.2)
		tween.tween_property(_root, "modulate:a", 0.0, 0.4)
		tween.tween_callback(_finish_loading)
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_is_loading = false
		push_error("SceneLoader: Thread load failed for ", _target_scene)
		_finish_loading()

func _finish_loading() -> void:
	_canvas.visible = false
	_bg_texture.texture = null
