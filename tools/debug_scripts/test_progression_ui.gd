extends Node3D

const Rules = preload("res://systems/adaptation_rules.gd")
const Poison = preload("res://combat/adaptation_poison.gd")
var failures := 0
var capture := false

class DummyEnemy extends CharacterBody3D:
	var health := 10000.0
	var is_dead := false
	var hits := 0
	var stagger_remaining := 0.0
	var knockback_velocity := Vector3.ZERO
	func take_damage(amount: float) -> void:
		health -= amount
		hits += 1
		is_dead = health <= 0.0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	capture = "--capture-ui" in OS.get_cmdline_user_args()
	call_deferred("_run")

func _run() -> void:
	PlayerData.reset_data()
	PlayerData.gain_exp(10000.0)
	check(PlayerData.level == 15 and PlayerData.skill_points == 28 and PlayerData.experience == 524.0, "Level cap and +2 AP per level")
	PlayerData.gain_exp(10000.0)
	check(PlayerData.skill_points == 28, "No extra AP at cap")
	PlayerData.reset_data()
	check(PlayerData.award_progression_reward("test_quest", 40.0, 3), "Quest reward applies")
	check(not PlayerData.award_progression_reward("test_quest", 40.0, 3), "Quest reward cannot be farmed")
	PlayerData.reset_data()
	PlayerData.skill_points = 63
	for i in range(20):
		check(PlayerData.get_attribute_upgrade_cost("attack") == Rules.COSTS[i / 5][i % 5], "Exact GDD cost for upgrade %d" % (i + 1))
		check(PlayerData.upgrade_attribute("attack"), "Funded attribute purchase")
	check(PlayerData.skill_points == 0 and int(PlayerData.get_current_species_data().genomes_available) == 4, "63 AP earns four same-attribute Genomes")
	check(not PlayerData.upgrade_attribute("attack"), "No spending without AP")
	check(is_equal_approx(PlayerData.attack_power, 15.0 + 6.0 * 63.0), "ATK uses AP spent, not upgrade count")
	PlayerData.reset_data()
	var player = load("res://player/player.gd").new()
	add_child(player)
	player.set_physics_process(false)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 12, 10)
	camera.look_at(Vector3.ZERO)
	var hud = load("res://ui/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	# Use the actual menu entry point and actual button signals.
	PlayerData.skill_points = 9
	hud._open_character_menu()
	var menu := get_tree().get_first_node_in_group("progression_menu")
	check(menu != null and get_tree().paused, "Badge opens progression and pauses gameplay")
	for i in range(5):
		menu._attribute_rows.health.button.pressed.emit()
	check(PlayerData.skill_points == 0 and PlayerData.max_health == 125.0, "UI upgrades change real health and spend displayed cost")
	check(menu._attribute_rows.health.button.disabled, "Unaffordable UI button disabled")
	check(int(PlayerData.get_current_species_data().genomes_available) == 1, "UI fifth upgrade earns Genome")
	check("125" in menu._stats.text, "Stats tab refreshes after purchase")
	PlayerData.skill_points = 10
	for id in ["attack", "stamina", "stamina_recovery", "cooldown", "health_recovery"]:
		menu._attribute_rows[id].button.pressed.emit()
		check(PlayerData.get_attribute_upgrade_count(id) == 1, "Actual UI button upgrades " + id)
	check(PlayerData.max_stamina == 105.0 and is_equal_approx(PlayerData.get_cooldown_multiplier(), 0.97), "Stamina and cooldown attributes affect gameplay")
	check(is_equal_approx(PlayerData.get_health_recovery_multiplier(), 1.05) and is_equal_approx(PlayerData.get_stamina_recovery_multiplier(), 1.05), "Both recovery attributes affect gameplay")
	if capture:
		await _capture(menu, 1, "progression_attributes.png")
	menu._ultimate_rows.attack.button.pressed.emit()
	check(menu._confirmation.visible, "Ultimate purchase shows concrete confirmation")
	menu._confirmation.hide()
	menu._confirmation.confirmed.emit()
	check(PlayerData.get_equipped_ultimate_level() == 1, "UI unlocks and equips Ultimate")
	check(PlayerData.can_activate_ultimate(), "Unlocked Ultimate is immediately available when off cooldown")
	PlayerData.get_current_species_data().genomes_available = 8
	PlayerData.get_current_species_data().genomes_earned = 9
	check(PlayerData.develop_ultimate("attack") and PlayerData.develop_ultimate("attack"), "Sequential path upgrades to level 3")
	check(not PlayerData.develop_ultimate("attack"), "Maxed equipped path cannot charge again")
	check(PlayerData.develop_ultimate("defense"), "Switch to another path")
	check(PlayerData.develop_ultimate("attack") and PlayerData.get_equipped_ultimate_level() == 3, "Return to maxed path retains rank")
	check(PlayerData.develop_ultimate("defense") and PlayerData.get_equipped_ultimate_level() == 1, "Switch does not upgrade old path")
	if capture:
		await _capture(menu, 2, "progression_ultimates.png")
	menu._on_close()
	await menu.closed
	check(not get_tree().paused, "Closing menu resumes game")
	PlayerData.health = 60.0
	PlayerData.stamina = 70.0
	hud._refresh_ultimate_button()
	check(not hud._skill3_btn.disabled and "READY" in hud._skill3_btn.text, "Ready Ultimate enables HUD activation")
	hud._on_ultimate_pressed()
	check(PlayerData.ultimate_active and PlayerData.ultimate_cooldown_remaining == 0.0, "HUD activates the Ultimate without a charge requirement")
	check(PlayerData.get_ultimate_damage_reduction() > 0.0, "Defense reduces damage")
	check(not PlayerData.develop_ultimate("agility"), "Active Ultimate cannot be changed in menu")
	PlayerData.update_ultimate(20.0)
	check(not PlayerData.ultimate_active and PlayerData.get_ultimate_damage_reduction() == 0.0 and PlayerData.ultimate_cooldown_remaining == 10.0, "Effect expiry starts its post-duration cooldown")
	check(hud._skill3_btn.disabled and "CD 10s" in hud._skill3_btn.text, "HUD shows the post-duration cooldown")
	PlayerData.update_ultimate(10.0)
	check(PlayerData.can_activate_ultimate() and "READY" in hud._skill3_btn.text, "Ultimate returns after its cooldown")
	PlayerData.unlock_species("salamander")
	check(PlayerData.set_active_species("salamander"), "Discovered species selectable")
	check(PlayerData.health == 60.0 and PlayerData.stamina == 70.0, "Switching preserves shared resources")
	check(PlayerData.max_health == 125.0, "Shared maximum health does not shrink on transformation")
	check(PlayerData.level == 1 and PlayerData.get_attribute_upgrade_count("health") == 0 and PlayerData.get_equipped_ultimate_level() == 0, "Species progression stays separate")
	# Round-trip the real save method in an unused test slot, removing only this fixture.
	var test_slot := -98761
	var test_path := PlayerData.get_save_path(test_slot)
	if FileAccess.file_exists(test_path):
		check(false, "Test save slot already exists; refusing to overwrite")
	else:
		PlayerData.award_progression_reward("saved_reward", 5.0, 1)
		PlayerData.ultimate_cooldown_remaining = 4.0
		PlayerData.ultimate_cooldown_changed.emit(4.0, PlayerData.ULTIMATE_COOLDOWN_DURATION)
		PlayerData.save_game(test_slot)
		PlayerData.reset_data()
		check(PlayerData.load_game(test_slot), "Actual save/load succeeds")
		check(PlayerData.active_species == "salamander" and PlayerData.ultimate_cooldown_remaining == 4.0, "Save retains species and Ultimate cooldown")
		check(int(PlayerData.species_progression.frog.attack_ultimate_level) == 3, "Save retains inactive species Ultimate")
		check(not PlayerData.award_progression_reward("saved_reward", 5.0, 1), "Reload cannot duplicate milestone reward")
		DirAccess.remove_absolute(test_path)
	PlayerData.restore_progression({"level": 2, "experience": 12, "skill_points": 2})
	check(not PlayerData.is_species_unlocked("salamander") and PlayerData.get_attribute_upgrade_count("health") == 0, "Legacy save does not inherit other slot's upgrades")
	# Distinct abilities and poison stacking.
	PlayerData.unlock_species("salamander")
	PlayerData.set_active_species("salamander")
	await get_tree().create_timer(0.9).timeout
	PlayerData.health = 30.0
	player._skill1_cooldown_timer = 0.0
	player._skill1()
	player._adaptation.tick(1.0)
	check(PlayerData.health > 30.0, "Regenerative Skin heals during gameplay")
	var enemy := DummyEnemy.new()
	add_child(enemy)
	enemy.add_to_group("enemies")
	enemy.position = player.position + Vector3(1, 0, 0)
	for i in range(4): Poison.apply(enemy, 4.0)
	var poison: Node = enemy.get_node("AdaptationPoison")
	check(poison.stacks == 3, "Fourth poison application caps at three stacks")
	poison._physics_process(1.0)
	check(enemy.health == 9988.0, "Poison stacks deal actual damage")
	poison.queue_free()
	await get_tree().process_frame
	PlayerData.stamina = 100.0
	check(player.use_secondary_skill(), "Salamander secondary creates toxic area")
	check(not player.use_secondary_skill(), "Secondary cooldown blocks repeated use")
	# Every defined species/path has concrete effects and can activate/expire.
	for species in Rules.SPECIES:
		PlayerData.unlock_species(species)
		PlayerData.set_active_species(species)
		await get_tree().create_timer(0.9).timeout
		var profile := PlayerData.get_current_species_data()
		profile.genomes_available = 20
		for category in ["attack", "defense", "agility"]:
			PlayerData.develop_ultimate(category)
			check(PlayerData.activate_ultimate(), "%s %s activates" % [species, category])
			check(PlayerData.ultimate_remaining > 0.0, "Data-driven duration")
			PlayerData.end_ultimate()
	PlayerData.set_active_species("frog")
	await get_tree().create_timer(0.9).timeout
	PlayerData.develop_ultimate("attack")
	player._activate_ultimate()
	player._adaptation.tick(0.1)
	check(enemy.has_node("AdaptationPoison"), "Frog Toxic Trail poisons nearby enemy")
	PlayerData.end_ultimate()
	PlayerData.set_active_species("water_monitor")
	await get_tree().create_timer(0.9).timeout
	PlayerData.develop_ultimate("attack")
	for node in get_children():
		if node.get_script() == load("res://combat/adaptation_field.gd"):
			node.queue_free()
	if enemy.has_node("AdaptationPoison"):
		enemy.get_node("AdaptationPoison").queue_free()
	await get_tree().process_frame
	var hits_before := enemy.hits
	player._activate_ultimate()
	await get_tree().create_timer(0.5).timeout
	check(enemy.hits == hits_before + 1, "Water Monitor Maul produces exactly one slam")
	PlayerData.end_ultimate()
	print("PROGRESSION INTEGRATION: %d failures" % failures)
	hud.queue_free()
	player.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures > 0 else 0)

func _capture(menu: Node, tab: int, filename: String) -> void:
	menu._tab_container.current_tab = tab
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://" + filename)
