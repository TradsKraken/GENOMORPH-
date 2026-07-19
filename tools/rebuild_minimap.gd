extends SceneTree

func _init() -> void:
	print("Rebuilding Minimap...")
	
	var current_scene = load("res://ui/hud.tscn")
	var instance = current_scene.instantiate()
	var root = instance.get_node("Root")
	
	if root.has_node("MinimapPanel"):
		print("Minimap already exists!")
		quit()
		return
		
	var minimap_panel = PanelContainer.new()
	minimap_panel.name = "MinimapPanel"
	minimap_panel.custom_minimum_size = Vector2(256, 256)
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.offset_left = -288
	minimap_panel.offset_top = 32
	minimap_panel.offset_right = -32
	minimap_panel.offset_bottom = 288
	minimap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.border_color = Color(0.2, 0.8, 1.0, 0.8)
	style.set_border_width_all(4)
	style.set_corner_radius_all(128) # circular
	style.anti_aliasing = true
	minimap_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	minimap_panel.add_child(margin)
	
	var svc = SubViewportContainer.new()
	svc.name = "SubViewportContainer"
	svc.stretch = true
	margin.add_child(svc)
	
	var vp = SubViewport.new()
	vp.name = "SubViewport"
	vp.transparent_bg = true
	vp.handle_input_locally = false
	vp.gui_disable_input = true
	svc.add_child(vp)
	
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 50.0
	cam.far = 1000.0
	vp.add_child(cam)
	
	root.add_child(minimap_panel)
	_set_owner_recursive(minimap_panel, instance)
	
	var new_packed = PackedScene.new()
	new_packed.pack(instance)
	ResourceSaver.save(new_packed, "res://ui/hud.tscn")
	print("Minimap successfully restored and saved!")
	
	instance.free()
	quit()

func _set_owner_recursive(node: Node, r: Node) -> void:
	if node != r and node.owner == null:
		node.owner = r
	for child in node.get_children():
		_set_owner_recursive(child, r)
