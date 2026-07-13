extends SceneTree

func _init():
	var hud = load("res://ui/hud.gd").new()
	hud.name = "GameHUD"
	
	hud.layer = 10
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_to_group("hud")

	hud._root = Control.new()
	hud._root.name = "Root"
	hud._root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud._root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud._root)

	hud._build_player_status()
	hud._build_action_buttons()
	hud._build_cancel_zone()
	hud._build_menu_panel()
	hud._build_tutorial_panel()
	hud._build_subtitle_panel()
	
	hud._status_group.name = "StatusGroup"
	hud._attack_btn.name = "AttackBtn"
	hud._skill1_btn.name = "Skill1Btn"
	hud._jump_btn.name = "JumpBtn"
	hud._skill3_btn.name = "Skill3Btn"
	hud._interact_btn.name = "InteractBtn"
	hud._menu_btn.name = "MenuBtn"
	hud._knowledge_btn.name = "KnowledgeBtn"
	hud._menu_panel.name = "MenuPanel"
	hud._tutorial_panel.name = "TutorialPanel"
	hud._subtitle_panel.name = "SubtitlePanel"
	hud._hp_bar.name = "HpBar"
	hud._hp_lbl.name = "HpLbl"
	hud._stam_bar.name = "StamBar"
	hud._exp_bar.name = "ExpBar"
	hud._lvl_lbl.name = "LvlLbl"
	hud._cancel_zone.name = "CancelZone"
	hud._tutorial_title.name = "TutorialTitle"
	hud._tutorial_desc.name = "TutorialDesc"
	hud._subtitle_label.name = "SubtitleLabel"
	
	_set_owner_recursive(hud, hud)
	
	var packed = PackedScene.new()
	packed.pack(hud)
	ResourceSaver.save(packed, "res://ui/hud.tscn")
	print("Saved hud.tscn successfully")
	quit()

func _set_owner_recursive(node: Node, owner: Node):
	if node != owner:
		node.owner = owner
		if node.name == "" or node.name.begins_with("@"):
			node.name = node.get_class() + str(node.get_instance_id())
	for child in node.get_children():
		_set_owner_recursive(child, owner)
