extends Node3D

@export var wave_spawns: Array[NodePath]
@export var tilapia_scene: PackedScene = preload("res://enemies/feral_tilapia.tscn")

var _mudfish_nodes: Array[Node] = []
var _is_running: bool = false
var _current_wave: int = 0
var _wave_timer: float = 0.0
var _active_tilapias: Array[Node] = []

func _ready() -> void:
	add_to_group("oxygen_defense")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		var saved_state = PlayerData.get_object_state(scene_path, node_path_str)
		if saved_state.size() > 0 and saved_state.get("is_cleared", false):
			queue_free()

func start_minigame() -> void:
	if _is_running: return
	
	_mudfish_nodes = get_tree().get_nodes_in_group("mudfish")
	if _mudfish_nodes.size() == 0:
		print("Error: No young mudfish found!")
		return
		
	_is_running = true
	_current_wave = 1
	_wave_timer = 5.0 # Initial delay before wave 1
	_active_tilapias.clear()
	
	PlayerData.set_objective(self, "Protect the Young Mudfish")
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_float_text"):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var scr := cam.unproject_position(global_position + Vector3(0, 3.0, 0))
			hud.show_float_text("DEFEND THE MUDFISH!", scr, Color.CYAN)
			
	set_process(true)

func _process(delta: float) -> void:
	if not _is_running:
		set_process(false)
		return
		
	# Clean up dead tilapias from tracking list
	_active_tilapias = _active_tilapias.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion() and not e.is_dead)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_zone_status"):
		hud.show_zone_status("Wave " + str(_current_wave) + "/3 - " + str(_active_tilapias.size()) + " Tilapia remaining")
	
	if _wave_timer > 0.0:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_spawn_wave(_current_wave)
	else:
		if _active_tilapias.size() == 0:
			if _current_wave < 3:
				_current_wave += 1
				_wave_timer = 3.0
			else:
				_win_minigame()

func _spawn_wave(wave_num: int) -> void:
	var count = wave_num * 2 # Wave 1: 2, Wave 2: 4, Wave 3: 6
	for i in range(count):
		var spawn_point = get_node_or_null(wave_spawns[randi() % wave_spawns.size()])
		if spawn_point and tilapia_scene:
			var tilapia = tilapia_scene.instantiate()
			tilapia.global_position = spawn_point.global_position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			
			# Assign a random mudfish as their target
			_mudfish_nodes = _mudfish_nodes.filter(func(m): return is_instance_valid(m) and not m.is_queued_for_deletion())
			if _mudfish_nodes.size() > 0:
				tilapia._minigame_target = _mudfish_nodes[randi() % _mudfish_nodes.size()]
			
			get_tree().current_scene.add_child(tilapia)
			_active_tilapias.append(tilapia)

func _on_mudfish_died(_mudfish: Node) -> void:
	if not _is_running: return
	
	# Check if any mudfish remain
	var alive_count = 0
	for m in _mudfish_nodes:
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m != _mudfish:
			alive_count += 1
			
	if alive_count <= 0:
		_fail_minigame()

func _fail_minigame() -> void:
	_is_running = false
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_subtitle"):
		hud.show_subtitle("Dalag", '"No! The young ones! We failed... Leave me."')
	if hud and hud.has_method("hide_zone_status"):
		hud.hide_zone_status()
		
	# Clean up remaining tilapias
	for t in _active_tilapias:
		if is_instance_valid(t): t.queue_free()
	_active_tilapias.clear()
	
	PlayerData.set_objective(null, "Talk to Dalag to retry")
	
	# Reset Dalag so you can speak to him again
	var dalag = get_tree().get_first_node_in_group("npc")
	if dalag and "has_given_minigame" in dalag:
		dalag.has_given_minigame = false

func _win_minigame() -> void:
	_is_running = false
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_subtitle"):
		hud.show_subtitle("Dalag", '"You did it... The young ones are safe. Take this... it holds the secret to breathing in this muck."')
	if hud and hud.has_method("hide_zone_status"):
		hud.hide_zone_status()
		
	AudioManager.play_sfx("level_up")
	PlayerData.add_genome_fragment()
	PlayerData.set_objective(null, "Explore the wetlands")
	
	# Save state
	if get_tree().current_scene:
		var scene_path = get_tree().current_scene.scene_file_path
		var node_path_str = str(get_tree().current_scene.get_path_to(self))
		PlayerData.set_object_state(scene_path, node_path_str, {"is_cleared": true})
		
	queue_free()
