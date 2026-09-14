extends Node

## PlayerData — global autoload singleton.
## Access from any script: PlayerData.health, PlayerData.gain_exp(25), etc.

# ── Signals ───────────────────────────────────────────────────────────────────
signal health_changed(value: float, maximum: float)
signal damage_taken(value: float, maximum: float)
signal stamina_changed(value: float, maximum: float)
signal exp_changed(value: float, needed: float)
signal level_changed(new_level: int)
signal skill_points_changed(points: int)
signal objective_changed(target_node: Node3D)
signal genome_collected(current: int, total: int)
signal salamander_genome_unlocked
signal species_unlocked(species_id: String)
signal active_species_changed(species_id: String)
signal skill1_cooldown_started(duration: float)
signal progression_changed(species_id: String)
signal genome_earned(species_id: String)
signal adaptation_level_gained(new_level: int)
signal skill2_cooldown_started(duration: float)

const AdaptationRules = preload("res://systems/adaptation_rules.gd")
signal ultimate_state_changed(active: bool, remaining: float)
signal ultimate_cooldown_changed(remaining: float, duration: float)
var current_objective: Node3D = null
var current_objective_text: String = ""
var current_objective_desc: String = ""

# Runtime-only: saved low health must not look like a fresh hit when a level
# first loads. The HUD arms its critical-health feedback after real damage.
var has_taken_damage_this_session: bool = false

var message_log: Array[String] = []

func add_message(speaker: String, text: String, color: String = "ffffff") -> void:
	var entry: String = "[b][color=#" + color + "]" + speaker + ":[/color][/b] " + text
	if not message_log.has(entry):
		message_log.append(entry)
		if message_log.size() > 50:
			message_log.pop_front()

func set_objective(target: Node3D, text: String = "", desc: String = "") -> void:
	current_objective = target
	
	if text != "":
		current_objective_text = text
		current_objective_desc = desc
	elif target and "objective_text" in target:
		current_objective_text = target.objective_text
		current_objective_desc = target.get("objective_desc") if "objective_desc" in target else ""
	else:
		current_objective_text = ""
		current_objective_desc = ""
		
	objective_changed.emit(target)

func _restore_objective(path_str: String, text: String, desc: String = "") -> void:
	var target: Node3D = null
	if path_str != "" and get_tree().current_scene:
		target = get_tree().current_scene.get_node_or_null(path_str)
	set_objective(target, text, desc)

# ── Species Progression ───────────────────────────────────────────────────────
var active_species: String = "frog"
var salamander_genome_recovered: bool = false
var species_progression: Dictionary = {
	"frog": {
		"is_unlocked": true,
		"current_xp": 0.0,
		"current_level": 1,
		"unspent_ap": 0,
		"health_upgrades": 0,
		"attack_power_upgrades": 0,
		"stamina_upgrades": 0,
		"stamina_recovery_upgrades": 0,
		"cooldown_reduction_upgrades": 0,
		"health_recovery_upgrades": 0,
		"genomes_earned": 0,
		"genomes_spent": 0,
		"genomes_available": 0,
		"attack_ultimate_level": 0,
		"defense_ultimate_level": 0,
		"agility_ultimate_level": 0,
		"equipped_ultimate_category": ""
	}
}

const ATTRIBUTE_DEFINITIONS := {
	"health": {"key": "health_upgrades", "name": "Health", "description": "+5% capacity per upgrade; strongest health adaptation sets shared maximum"},
	"attack": {"key": "attack_power_upgrades", "name": "Attack Power", "description": "+6 ATK per AP invested; base ATK grows with level"},
	"stamina": {"key": "stamina_upgrades", "name": "Stamina", "description": "+5% maximum stamina per upgrade"},
	"stamina_recovery": {"key": "stamina_recovery_upgrades", "name": "Stamina Recovery", "description": "+5% stamina recovery per upgrade"},
	"cooldown": {"key": "cooldown_reduction_upgrades", "name": "Cooldown Reduction", "description": "-3% ability cooldown per upgrade"},
	"health_recovery": {"key": "health_recovery_upgrades", "name": "Health Recovery", "description": "+5% health recovery per upgrade"}
}

const ULTIMATE_DEFINITIONS = AdaptationRules.ULTIMATES
var ultimate_active: bool = false
var ultimate_remaining: float = 0.0
const ULTIMATE_COOLDOWN_DURATION := 10.0
var ultimate_cooldown_remaining: float = 0.0
var _ultimate_effects: Dictionary = {}
var claimed_progression_rewards: Dictionary = {}

func _make_species_profile() -> Dictionary:
	return {
		"is_unlocked": true, "current_xp": 0.0, "current_level": 1, "unspent_ap": 0,
		"health_upgrades": 0, "attack_power_upgrades": 0, "stamina_upgrades": 0,
		"stamina_recovery_upgrades": 0, "cooldown_reduction_upgrades": 0, "health_recovery_upgrades": 0,
		"genomes_earned": 0, "genomes_spent": 0, "genomes_available": 0,
		"attack_ultimate_level": 0, "defense_ultimate_level": 0, "agility_ultimate_level": 0,
		"equipped_ultimate_category": ""
	}

func _ensure_profile(species_id: String) -> Dictionary:
	if not species_progression.has(species_id):
		species_progression[species_id] = _make_species_profile()
	var profile: Dictionary = species_progression[species_id]
	var defaults := _make_species_profile()
	for key in defaults:
		if not profile.has(key):
			profile[key] = defaults[key]
	return profile

func get_current_species_data() -> Dictionary:
	return _ensure_profile(active_species)

func is_species_unlocked(species_id: String) -> bool:
	return species_progression.has(species_id) and species_progression[species_id].get("is_unlocked", false)

## Switches the progression profile used by the player. The HUD owns the
## selection UI; the physical form can be hooked up here when its scene/model
## is introduced.
func set_active_species(species_id: String) -> bool:
	if species_id == active_species or not is_species_unlocked(species_id):
		return false
	active_species = species_id
	end_ultimate()
	health = minf(health, max_health)
	stamina = minf(stamina, max_stamina)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	exp_changed.emit(experience, exp_to_next)
	level_changed.emit(level)
	active_species_changed.emit(active_species)
	skill_points_changed.emit(skill_points)
	progression_changed.emit(active_species)
	return true

func get_attribute_upgrade_count(attribute_id: String) -> int:
	var definition: Dictionary = ATTRIBUTE_DEFINITIONS.get(attribute_id, {})
	return int(get_current_species_data().get(definition.get("key", ""), 0))

func get_attribute_upgrade_cost(attribute_id: String) -> int:
	return AdaptationRules.attribute_cost(get_attribute_upgrade_count(attribute_id))

func attribute_value(attribute_id: String, extra: int = 0) -> String:
	var count := get_attribute_upgrade_count(attribute_id) + extra
	match attribute_id:
		"health": return "%.1f shared HP" % maxf(max_health, base_shared_health * (1.0 + 0.05 * count))
		"attack": return "%.1f ATK" % (15.0 + 4.0 * (level - 1) + 6.0 * AdaptationRules.total_attribute_cost(count))
		"stamina": return "%.1f stamina" % (float(AdaptationRules.SPECIES.get(active_species, {}).get("stamina", 100.0)) * (1.0 + 0.05 * count))
		"stamina_recovery": return "%.1f/s" % (float(AdaptationRules.SPECIES.get(active_species, {}).get("recovery", 10.0)) * (1.0 + 0.05 * count))
		"health_recovery": return "%.1f HP / 2s" % (5.0 * (1.0 + 0.05 * count))
		"cooldown": return "-%d%%" % roundi(minf(0.75, 0.03 * count) * 100.0)
	return ""

func unlock_species(species_id: String) -> bool:
	if not AdaptationRules.SPECIES.has(species_id) or is_species_unlocked(species_id):
		return false
	_ensure_profile(species_id)["is_unlocked"] = true
	species_unlocked.emit(species_id)
	return true

func award_progression_reward(reward_id: String, xp: float, ap: int = 0) -> bool:
	if claimed_progression_rewards.has(reward_id):
		return false
	claimed_progression_rewards[reward_id] = active_species
	gain_exp(xp)
	skill_points += maxi(0, ap)
	progression_changed.emit(active_species)
	return true

func upgrade_attribute(attribute_id: String) -> bool:
	if not ATTRIBUTE_DEFINITIONS.has(attribute_id):
		return false
	var profile := get_current_species_data()
	var key: String = ATTRIBUTE_DEFINITIONS[attribute_id]["key"]
	var cost := get_attribute_upgrade_cost(attribute_id)
	if int(profile.get("unspent_ap", 0)) < cost:
		return false
	profile["unspent_ap"] = int(profile["unspent_ap"]) - cost
	profile[key] = int(profile.get(key, 0)) + 1
	if int(profile[key]) % 5 == 0:
		profile["genomes_earned"] = int(profile.get("genomes_earned", 0)) + 1
		profile["genomes_available"] = int(profile.get("genomes_available", 0)) + 1
		genome_earned.emit(active_species)
	_emit_progression_changed()
	return true

func ultimate_purchase_action(category: String) -> String:
	if not ULTIMATE_DEFINITIONS.get(active_species, {}).has(category):
		return "Unavailable"
	var profile := get_current_species_data()
	if str(profile.equipped_ultimate_category) != category:
		return "Unlock & equip" if int(profile.get(category + "_ultimate_level", 0)) == 0 else "Switch path"
	return "Upgrade" if int(profile.get(category + "_ultimate_level", 0)) < 3 else "Max level"

func develop_ultimate(category: String) -> bool:
	if ultimate_active or not ULTIMATE_DEFINITIONS.get(active_species, {}).has(category):
		return false
	var profile := get_current_species_data()
	if int(profile.genomes_available) < 1:
		return false
	var key := category + "_ultimate_level"
	var rank := int(profile[key])
	if str(profile.equipped_ultimate_category) == category:
		if rank >= 3:
			return false
		profile[key] = rank + 1
	else:
		# Changing specialization costs one Genome but retains its previous rank.
		profile[key] = maxi(1, rank)
	profile.equipped_ultimate_category = category
	profile.genomes_available = int(profile.genomes_available) - 1
	profile.genomes_spent = int(profile.genomes_spent) + 1
	_emit_progression_changed()
	return true

func get_equipped_ultimate_level() -> int:
	var category: String = str(get_current_species_data().get("equipped_ultimate_category", ""))
	return int(get_current_species_data().get(category + "_ultimate_level", 0)) if category != "" else 0

func get_equipped_ultimate_definition() -> Dictionary:
	var category: String = str(get_current_species_data().get("equipped_ultimate_category", ""))
	return ULTIMATE_DEFINITIONS.get(active_species, {}).get(category, {})

func get_stamina_recovery_multiplier() -> float:
	return 1.0 + 0.05 * get_attribute_upgrade_count("stamina_recovery")

func get_health_recovery_multiplier() -> float:
	return 1.0 + 0.05 * get_attribute_upgrade_count("health_recovery")

func get_cooldown_multiplier() -> float:
	return maxf(0.25, 1.0 - 0.03 * get_attribute_upgrade_count("cooldown"))

func ultimate_effect(key: String, fallback: float = 1.0) -> float:
	return float(_ultimate_effects.get(key, fallback)) if ultimate_active else fallback

func get_ultimate_damage_multiplier() -> float:
	return ultimate_effect("damage")

func get_ultimate_damage_reduction() -> float:
	return ultimate_effect("resistance", 0.0)

func get_ultimate_speed_multiplier() -> float:
	return ultimate_effect("speed")

func can_activate_ultimate() -> bool:
	return health > 0.0 and not ultimate_active and ultimate_cooldown_remaining <= 0.0 and get_equipped_ultimate_level() > 0

func activate_ultimate() -> bool:
	if not can_activate_ultimate():
		return false
	_ultimate_effects = AdaptationRules.effects(active_species, str(get_current_species_data().equipped_ultimate_category), get_equipped_ultimate_level())
	if _ultimate_effects.is_empty():
		return false
	ultimate_active = true
	ultimate_remaining = float(_ultimate_effects.get("duration", 8.0))
	ultimate_state_changed.emit(true, ultimate_remaining)
	return true

func update_ultimate(delta: float) -> void:
	if ultimate_active:
		ultimate_remaining = maxf(0.0, ultimate_remaining - delta)
		if ultimate_remaining <= 0.0:
			# The cooldown deliberately starts only after the full effect ends.
			end_ultimate(true)
		else:
			ultimate_state_changed.emit(true, ultimate_remaining)
		return
	if ultimate_cooldown_remaining > 0.0:
		ultimate_cooldown_remaining = maxf(0.0, ultimate_cooldown_remaining - delta)
		ultimate_cooldown_changed.emit(ultimate_cooldown_remaining, ULTIMATE_COOLDOWN_DURATION)

func end_ultimate(start_cooldown: bool = false) -> void:
	ultimate_active = false
	ultimate_remaining = 0.0
	_ultimate_effects.clear()
	ultimate_state_changed.emit(false, 0.0)
	if start_cooldown:
		ultimate_cooldown_remaining = ULTIMATE_COOLDOWN_DURATION
		ultimate_cooldown_changed.emit(ultimate_cooldown_remaining, ULTIMATE_COOLDOWN_DURATION)

func _emit_progression_changed() -> void:
	health = minf(health, max_health)
	stamina = minf(stamina, max_stamina)
	skill_points_changed.emit(skill_points)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	progression_changed.emit(active_species)

# ── Base Shared Stats (Tuning) ────────────────────────────────────────────────
var base_shared_health: float = 100.0
var base_species_stamina: float = 100.0
var base_attack_power: float = 20.0

# ── Volunteer Shared Resources ────────────────────────────────────────────────
var max_health: float:
	get:
		# Shared maximum is stable on transformation. Species still own their
		# upgrade counts/Genome milestones; use the strongest developed capacity.
		var upgrades := 0
		for profile in species_progression.values():
			if profile.get("is_unlocked", false):
				upgrades = maxi(upgrades, int(profile.get("health_upgrades", 0)))
		return base_shared_health * (1.0 + 0.05 * upgrades)
var health: float      = 100.0

var max_stamina: float:
	get:
		var sp_data = get_current_species_data()
		var upgrades = sp_data.get("stamina_upgrades", 0) if sp_data else 0
		return float(AdaptationRules.SPECIES.get(active_species, {}).get("stamina", base_species_stamina)) * (1.0 + 0.05 * upgrades)
var stamina: float     = 100.0

var level: int:
	get: return get_current_species_data().get("current_level", 1)
	set(val): get_current_species_data()["current_level"] = val

var experience: float:
	get: return get_current_species_data().get("current_xp", 0.0)
	set(val): get_current_species_data()["current_xp"] = val

var exp_to_next: float:
	get:
		var max_level = XP_THRESHOLDS.size()
		if level < max_level:
			return XP_THRESHOLDS[level]
		else:
			return XP_THRESHOLDS[max_level - 1]

var skill_points: int:
	get: return get_current_species_data().get("unspent_ap", 0)
	set(val):
		get_current_species_data()["unspent_ap"] = val
		skill_points_changed.emit(val)

var attack_power: float:
	get:
		var sp_data = get_current_species_data()
		var upgrades = sp_data.get("attack_power_upgrades", 0) if sp_data else 0
		return 15.0 + 4.0 * (level - 1) + 6.0 * AdaptationRules.total_attribute_cost(int(upgrades))

var defense: float = 5.0
var speed: float = 4.0

var inventory: Array = []
var genome_fragments: int = 0
var has_seen_prologue: bool = false
var has_seen_minimap_tutorial: bool = false
var has_seen_ui_intro: bool = false
var has_seen_character_tutorial: bool = false
var has_seen_knowledge_tutorial: bool = false

# Runtime-only flags so a quest director can check "did the previous quest
# already finish?" without depending on sibling _ready() order matching
# creation order (which happened to work by luck, not guarantee — see
# how has_seen_prologue avoids the same race for the prologue->Q01 handoff).
# Not persisted to save data since none of these directors restore their
# _state on load either.
var q01_completed: bool = false
var q02_completed: bool = false
var q03_completed: bool = false
var q04_completed: bool = false
var q05_completed: bool = false
# Fine-grained quest checkpoints. Completion booleans alone cannot restore a
# save made halfway through a multi-step quest (for example, after its trash
# is cleared but before the habitat-restoration interaction).
var quest_progress: Dictionary = {}
var max_genome_fragments: int = 12
var minigame_started: bool = false

var frogs_helped: int = 0
var total_frogs: int = 7
var lolo_palaka_intro_done: bool = false

var current_scene_path: String = "res://levels/main terrain.scn"

var player_position: Vector3 = Vector3.ZERO
var has_saved_position: bool = false
var world_state: Dictionary = {}

func mark_object_destroyed(scene_path: String, node_path: String) -> void:
	if not world_state.has(scene_path):
		world_state[scene_path] = {}
	if not world_state[scene_path].has(node_path):
		world_state[scene_path][node_path] = {}
	world_state[scene_path][node_path]["destroyed"] = true

func is_object_destroyed(scene_path: String, node_path: String) -> bool:
	if world_state.has(scene_path) and world_state[scene_path].has(node_path):
		return world_state[scene_path][node_path].get("destroyed", false)
	return false

func get_object_state(scene_path: String, node_path: String) -> Dictionary:
	if world_state.has(scene_path) and world_state[scene_path].has(node_path):
		return world_state[scene_path][node_path]
	return {}

func set_object_state(scene_path: String, node_path: String, state: Dictionary) -> void:
	if not world_state.has(scene_path):
		world_state[scene_path] = {}
	world_state[scene_path][node_path] = state

func set_quest_checkpoint(quest_id: String, checkpoint: String) -> void:
	quest_progress[quest_id] = checkpoint

func get_quest_checkpoint(quest_id: String) -> String:
	return str(quest_progress.get(quest_id, ""))
func add_genome_fragment(announce: bool = true) -> void:
	genome_fragments = mini(genome_fragments + 1, max_genome_fragments)
	if announce:
		genome_collected.emit(genome_fragments, max_genome_fragments)

## Q03's reward is a named genome discovery, separate from the generic
## reconstruction fragments scattered around the world.
func recover_salamander_genome() -> bool:
	if salamander_genome_recovered:
		return false
	salamander_genome_recovered = true
	if not species_progression.has("salamander"):
		species_progression["salamander"] = {
			"is_unlocked": true,
			"current_xp": 0.0,
			"current_level": 1,
			"unspent_ap": 0,
			"health_upgrades": 0,
			"attack_power_upgrades": 0,
			"stamina_upgrades": 0,
			"stamina_recovery_upgrades": 0,
			"cooldown_reduction_upgrades": 0,
			"health_recovery_upgrades": 0,
			"genomes_earned": 0,
			"genomes_spent": 0,
			"genomes_available": 0,
			"attack_ultimate_level": 0,
			"defense_ultimate_level": 0,
			"agility_ultimate_level": 0,
			"equipped_ultimate_category": ""
		}
	species_unlocked.emit("salamander")
	salamander_genome_unlocked.emit()
	return true


# ── Stamina API ───────────────────────────────────────────────────────────────

func gain_stamina(amount: float) -> void:
	stamina = minf(stamina + amount, max_stamina)
	stamina_changed.emit(stamina, max_stamina)


## Deducts stamina if enough is available. Returns true on success.
func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	stamina_changed.emit(stamina, max_stamina)
	return true


## Call from player_s _physics_process to passively restore stamina.
func recover_stamina(delta: float, rate: float) -> void:
	if stamina < max_stamina:
		stamina = move_toward(stamina, max_stamina, rate * delta)
		stamina_changed.emit(stamina, max_stamina)


# ── Health API ────────────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	has_taken_damage_this_session = true
	health_changed.emit(health, max_health)
	damage_taken.emit(health, max_health)

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


# ── EXP / Level API ───────────────────────────────────────────────────────────
const XP_THRESHOLDS: Array[float] = [
	0.0, 12.0, 26.0, 42.0, 61.0, 83.0, 108.0, 137.0, 171.0, 210.0, 256.0, 309.0, 370.0, 441.0, 524.0
]

func gain_exp(amount: float) -> void:
	if amount <= 0.0:
		return
	experience = minf(XP_THRESHOLDS[-1], experience + amount)
	
	var max_level = XP_THRESHOLDS.size()
	while level < max_level and experience >= XP_THRESHOLDS[level]:
		_do_level_up()
		
	var next_req = XP_THRESHOLDS[level] if level < max_level else XP_THRESHOLDS[max_level - 1]
	exp_changed.emit(experience, next_req)
	progression_changed.emit(active_species)

func _do_level_up() -> void:
	level += 1
	skill_points += 2
	AudioManager.play_sfx("level_up")
	level_changed.emit(level)
	adaptation_level_gained.emit(level)


# ── Knowledge Base ────────────────────────────────────────────────────────────

const KNOWLEDGE_DB: Dictionary = {
	"q01_water": {
		"title": "Contaminated Water",
		"category": "Environment",
		"subcategory": "Chemical Runoff",
		"icon": "",
		"summary": "A chemical sheen coats the surface. Dead fish drift near the edge. Whatever caused this happened more than once."
	},
	"q01_plants": {
		"title": "Damaged Vegetation",
		"category": "Environment",
		"subcategory": "Ecosystem Collapse",
		"icon": "",
		"summary": "Blackened, wilted reeds. The roots are rotting. Small prey animals have lost both food and shelter here."
	},
	"q01_debris": {
		"title": "Human Debris",
		"category": "Environment",
		"subcategory": "Industrial Waste",
		"icon": "",
		"summary": "A rusted pipe fragment and degraded plastic. This wasn't a natural die-off; humans left this behind."
	},
	"q02_burrows": {
		"title": "Invasive Burrows",
		"category": "Environment",
		"subcategory": "Invasive Species",
		"icon": "",
		"summary": "Freshly dug tunnels, gnaw marks, and scattered tracks. Something is nesting here — and it isn't native to this wetland."
	},
	"rat": {
		"title": "Invasive Rat",
		"category": "Species",
		"subcategory": "Invasive Mammal",
		"icon": "⬡",
		"classification": "Rattus sp.",
		"threat_level": "MODERATE",
		"summary": "Invasive rats outcompete native wetland species for food and shelter, and their burrowing accelerates bank erosion. Alone they're minor pests; in numbers, they gut a habitat.",
		"facts": [
			"A single breeding pair can produce hundreds of descendants in a year.",
			"They raid the nests and burrows of native amphibians and small mammals.",
			"Their tunneling destabilizes riverbanks and wetland embankments.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] They come in packs. Don't get surrounded — clear them one at a time."
	},
	"mosquito": {
		"title": "Mosquito Swarm",
		"category": "Species",
		"subcategory": "Invasive Insect",
		"icon": "⬡",
		"classification": "Culex sp. / Aedes sp.",
		"threat_level": "HIGH",
		"summary": "Mosquito swarms are among the most ecologically damaging invasive insects in enclosed wetland biomes. Their ability to breed rapidly in stagnant water makes eradication difficult without disrupting native ecosystems.",
		"facts": [
			"A single female mosquito can lay up to 300 eggs in a single batch.",
			"They carry and transmit pathogens like malaria, dengue, and West Nile virus.",
			"Swarms compete with native dragonfly larvae and small fish for breeding sites.",
			"Their population can double every 48 hours in a warm, stagnant environment.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Strike the swarm's center of mass. Disrupting the core will scatter the entire colony."
	},
	"invasive_snake": {
		"title": "Invasive Snake", "category": "Species", "subcategory": "Invasive Reptile", "icon": "⬡", "classification": "Serpentes sp.", "threat_level": "HIGH",
		"summary": "A territorial invasive snake adapted to polluted wetlands. It strikes from cover, then retreats through the reeds when pressured.",
		"facts": ["Invasive snake populations can overwhelm weakened native wetlands.", "Its retreat trail can reveal polluted water sources."],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Keep moving and pressure it until it abandons its territory."
	},
	"feral_tilapia": {
		"title": "Feral Tilapia", "category": "Species", "subcategory": "Invasive Fish", "icon": "⬡", "classification": "Oreochromis sp.", "threat_level": "HIGH",
		"summary": "A fast-breeding invasive fish that consumes oxygen and food needed by native wetland species.",
		"facts": ["Tilapia can rapidly dominate shallow, warm water.", "Dense schools worsen oxygen depletion for native fish."],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Do not let the school surround vulnerable native fish."
	},
	"native_frog": {
		"title": "Native Wetland Frog", "category": "Species", "subcategory": "Native Amphibian", "icon": "◈", "classification": "Anura sp.", "threat_level": "ALLY",
		"summary": "A surviving native frog and a sensitive indicator of wetland health. Its presence marks habitat worth protecting.",
		"facts": ["Amphibians absorb water through their skin, making them highly vulnerable to pollution.", "Healthy frog populations indicate a recovering food web."],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Protect native frogs from invasive predators."
	},
	"wetlands_chimera": {
		"title": "Wetlands Chimera", "category": "Species", "subcategory": "Mutated Apex Predator", "icon": "⬡", "classification": "Genome Cascade Entity", "threat_level": "CRITICAL",
		"summary": "An unstable organism shaped by contamination and incompatible genomic material.",
		"facts": ["Its biology combines traits that do not naturally coexist.", "It is strongest near heavily contaminated habitat."],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Watch its attack pattern and avoid long attacks."
	},
	"swamp": {
		"title": "Toxic Swamp Biome",
		"category": "Environment",
		"subcategory": "Contaminated Wetland",
		"icon": "⌬",
		"classification": "Biome Class IV — Hazardous",
		"threat_level": "MODERATE",
		"summary": "A severely degraded wetland ecosystem, now characterized by hypoxic water, acidic soil, and a collapse of native biodiversity. Once a thriving freshwater habitat, it now acts as an incubator for invasive and mutated species.",
		"facts": [
			"Wetlands naturally filter up to 90% of pollutants before water reaches rivers.",
			"Hypoxic (oxygen-poor) water kills most native fish within hours of exposure.",
			"Acidic swamp water (pH < 5) corrodes organic matter and dissolves minerals from the soil.",
			"Despite toxicity, some species have evolved resistance, becoming apex predators in this disrupted niche.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Avoid prolonged submersion in swamp water. Your suit's biological filters have a finite capacity."
	},
	"lolo_palaka": {
		"title": "Lolo Palaka",
		"category": "Characters",
		"subcategory": "Elder / Guide",
		"icon": "◈",
		"classification": "Amphibian — Native",
		"threat_level": "ALLY",
		"summary": "An elder frog of remarkable longevity who has survived the ecosystem's collapse through wisdom and adaptation. He is the last keeper of pre-Collapse environmental knowledge in the wetland.",
		"facts": [
			"He has memorized the original migration routes of all native species before The Collapse.",
			"His croaking contains encoded biological data interpretable by the GenoMorph suit.",
			"He leads a small community of surviving native species in the deeper, less-polluted zones.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Speak with Lolo Palaka to receive biological wisdom and unlock new objectives."
	},
	"genomorph_suit": {
		"title": "GenoMorph Prototype",
		"category": "Technology",
		"subcategory": "Biotech — Adaptive Suit",
		"icon": "⌬",
		"classification": "Classified — Project GENESIS",
		"threat_level": "ASSET",
		"summary": "A cutting-edge experimental suit that assimilates local genome data to unlock biological adaptations. The suit's core function is to integrate fragments of local DNA, adapting the wearer's physiology to survive in extreme environments.",
		"facts": [
			"The suit uses lateral gene transfer (LGT) principles found in bacteria and archaea.",
			"Each Genome Fragment contains compressed DNA data from a native or invasive species.",
			"The suit's AI cross-references absorbed genomes to synthesize viable hybrid adaptations.",
			"Overloading the suit with incompatible genomes can trigger an unstable mutation cascade.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Collect all 12 Genome Fragments to unlock the suit's full potential."
	},
	"dr_sterling": {
		"title": "Dr. Alistair Sterling",
		"category": "Characters",
		"subcategory": "Researcher / Handler",
		"icon": "◈",
		"classification": "Project GENESIS — Lead Scientist",
		"threat_level": "UNKNOWN",
		"summary": "The architect of the GenoMorph project and the primary handler communicating via the suit's comm-link. His motivations appear scientific, though certain logged transmissions suggest a hidden agenda behind the fieldwork.",
		"facts": [
			"His published research covers lateral gene transfer and cross-species genome integration.",
			"He monitors the suit's vitals and genome absorption rate in real-time from a remote lab.",
			"Suit logs indicate he has run four previous field trials, all resulting in data loss.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Trust Sterling's tactical guidance, but question his strategic motivations."
	},
	"the_collapse": {
		"title": "The Collapse",
		"category": "History",
		"subcategory": "Ecological Event",
		"icon": "⬡",
		"classification": "Event — Year 0 of Current Timeline",
		"threat_level": "CRITICAL",
		"summary": "A cascading ecological catastrophe triggered by a combination of industrial pollution and the mass introduction of invasive species. Within a decade, over 70% of native species in the region were classified as locally extinct.",
		"facts": [
			"The event began with uncontrolled industrial runoff contaminating the primary water table.",
			"Invasive species, introduced via the supply chain, exploited the weakened ecosystem.",
			"Native apex predators collapsed first, removing population controls on smaller species.",
			"The contamination is now self-sustaining due to the sediment layer of industrial byproducts.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Understanding The Collapse is key to understanding the behavior of every species you encounter."
	},
	"giant_african_snail": {
		"title": "Giant African Snail",
		"category": "Species",
		"subcategory": "Invasive Gastropod",
		"icon": "⬡",
		"classification": "Lissachatina fulica",
		"threat_level": "HIGH",
		"summary": "One of the most destructive invasive land mollusks on Earth. Introduced via the supply chain during pre-Collapse industrialization, it has since bred unchecked and outcompeted all native snail species.",
		"facts": [
			"It can consume over 500 plant species, making it a devastating agricultural and ecological threat.",
			"A single snail is hermaphroditic and can produce up to 1,200 eggs per year.",
			"Its mucus trail contains irritant compounds that are toxic to small amphibians on direct contact.",
			"It carries the rat lungworm parasite (Angiostrongylus cantonensis), harmful to mammals.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Keep distance from its spit arc. Its toxin corrodes your suit's biological membrane."
	},
	"healing_worm": {
		"title": "Regenerative Earthworm",
		"category": "Species",
		"subcategory": "Mutated Annelid",
		"icon": "⬡",
		"classification": "Oligochaeta sp. (Mutated)",
		"threat_level": "LOW",
		"summary": "A mutated descendant of native earthworms that absorbed trace genomic data from the contamination event. It has developed accelerated cellular regeneration as a survival mechanism, making it a valuable biological resource.",
		"facts": [
			"Standard earthworms aerate up to 2 tonnes of soil per hectare annually, critical to soil health.",
			"This variant's cells divide 40x faster than its non-mutated counterparts.",
			"When consumed by amphibians, its regenerative enzymes temporarily boost the consumer's own healing.",
			"Its presence in soil indicates a patch of partially recovering, less-toxic ground.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Collect worms as they flee. Their regenerative properties restore your biological integrity."
	},
	"toxic_sludge": {
		"title": "Toxic Sludge",
		"category": "Environment",
		"subcategory": "Chemical Hazard",
		"icon": "⌬",
		"classification": "Hazard Class V — Corrosive",
		"threat_level": "CRITICAL",
		"summary": "A viscous industrial byproduct that has permanently saturated sections of the wetland. It is a complex mixture of heavy metals, acidic compounds, and mutated biological runoff that actively dissolves organic tissue.",
		"facts": [
			"Heavy metals like lead and mercury bioaccumulate up the food chain, causing cascading toxicity.",
			"The sludge's pH can drop as low as 2.5, similar to gastric acid.",
			"It permanently renders soil infertile by binding to and neutralizing essential minerals.",
			"Some extremophile bacteria thrive in it, accelerating the breakdown of surrounding organic matter.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Exit immediately on contact. Prolonged exposure bypasses suit insulation layers."
	},
	"mudfish": {
		"title": "Native Mudfish (Dalag)",
		"category": "Species",
		"subcategory": "Keystone Predator",
		"icon": "◈",
		"classification": "Channa striata",
		"threat_level": "ALLY",
		"summary": "A highly resilient native freshwater predator and ecological keystone species. The Dalag is critical to maintaining wetland biodiversity by controlling invasive fish populations. Its near-extinction is a key indicator of the ecosystem's overall collapse.",
		"facts": [
			"It breathes atmospheric air using a labyrinth organ, surviving in oxygen-depleted water.",
			"Can survive buried in mud for months during dry seasons using estivation.",
			"As an apex predator, its presence naturally suppresses invasive tilapia and carp populations.",
			"Young mudfish (fry) are communally protected by both parents, a rare behavior among fish.",
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] The Dalag is a restoration indicator. Protect its young to restore a balanced ecosystem."
	},
	"water_bottle": {
		"title": "Discarded Water Bottle",
		"category": "Environment",
		"subcategory": "Plastic Pollution",
		"icon": "⌬",
		"classification": "Non-Biodegradable Waste",
		"threat_level": "LOW",
		"summary": "A typical single-use plastic water bottle. While small, accumulations of microplastics from these bottles severely disrupt the hormonal balance of native wetland amphibians.",
		"facts": [
			"A plastic bottle can take up to 450 years to completely decompose in a wetland environment.",
			"As it breaks down, it releases microplastics that are ingested by fish and amphibians.",
			"Chemicals leaching from the plastic (like BPA) mimic estrogen, disrupting frog reproduction rates."
		],
		"guide_tip": "[color=#1affa0]Field Guide:[/color] Even simple plastic waste contributes to the collapse. Every piece removed helps the ecosystem recover."
	}
}

var unlocked_knowledge: Array[String] = ["genomorph_suit", "dr_sterling", "the_collapse"]
var unread_knowledge: Array[String] = []

signal knowledge_unlocked(id: String)
signal knowledge_read(id: String)

func unlock_knowledge(id: String) -> void:
	if id in KNOWLEDGE_DB and not id in unlocked_knowledge:
		unlocked_knowledge.append(id)
		unread_knowledge.append(id)
		knowledge_unlocked.emit(id)

## Unlocks a Field Guide entry the first time a species is encountered.
func discover_species(id: String) -> void:
	unlock_knowledge(id)

func mark_knowledge_read(id: String) -> void:
	if id in unread_knowledge:
		unread_knowledge.erase(id)
		knowledge_read.emit(id)

# ── Save & Load ───────────────────────────────────────────────────────────────

var current_save_slot: int = 1

func get_save_path(slot: int = -1) -> String:
	if slot == -1:
		slot = current_save_slot
	return "user://genomorph_save_%d.json" % slot

func has_save_file(slot: int = -1) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_save_preview(slot: int) -> Dictionary:
	var path: String = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var json: JSON = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data: Variant = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				return {
					"level": data.get("level", 1),
					"has_seen_prologue": data.get("has_seen_prologue", false),
					"timestamp": data.get("timestamp", "Unknown Date"),
					"biome_name": data.get("biome_name", "Unknown Region"),
					"active_form": data.get("active_form", "Unknown Form"),
					"genome_fragments": data.get("genome_fragments", 0),
					"max_genome_fragments": data.get("max_genome_fragments", 12)
				}
	return {}

func save_game(slot: int = -1) -> void:
	var current_level_path: String = get_tree().current_scene.scene_file_path if get_tree().current_scene else current_scene_path
	if current_level_path != "":
		current_scene_path = current_level_path

	var biome_name: String = "Level 1: The Polluted Wetlands"
	if "mosquito_zone" in current_scene_path:
		biome_name = "Level 1: Mosquito Swarm Zone"
		
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	# Format: YYYY-MM-DD HH:MM
	var timestamp: String = "%04d-%02d-%02d %02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute
	]

	# Grab player position
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		player_position = player.global_position
		has_saved_position = true
		
	# Grab fog map
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("get_fog_data"):
		var fog_data: String = hud.get_fog_data()
		if fog_data != "":
			if not world_state.has(current_scene_path):
				world_state[current_scene_path] = {}
			world_state[current_scene_path]["fog_map"] = fog_data

	var data: Dictionary = {
		"health": health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"level": level,
		"experience": experience,
		"exp_to_next": exp_to_next,
		"skill_points": skill_points,
		"attack_power": attack_power,
		"defense": defense,
		"speed": speed,
		"inventory": inventory,
		"genome_fragments": genome_fragments,
		"species_progression": species_progression,
		"progression_version": 3,
		"ultimate_cooldown_remaining": ultimate_cooldown_remaining,
		"claimed_progression_rewards": claimed_progression_rewards,
		"active_species": active_species,
		"salamander_genome_recovered": salamander_genome_recovered,
		"max_genome_fragments": max_genome_fragments,
		"frogs_helped": frogs_helped,
		"total_frogs": total_frogs,
		"minigame_started": minigame_started,
		"has_seen_prologue": has_seen_prologue,
		"has_seen_ui_intro": has_seen_ui_intro,
		"has_seen_character_tutorial": has_seen_character_tutorial,
		"has_seen_knowledge_tutorial": has_seen_knowledge_tutorial,
		"lolo_palaka_intro_done": lolo_palaka_intro_done,
		"q01_completed": q01_completed,
		"q02_completed": q02_completed,
		"q03_completed": q03_completed,
		"q04_completed": q04_completed,
		"q05_completed": q05_completed,
		"quest_progress": quest_progress,
		"unlocked_knowledge": unlocked_knowledge,
		"unread_knowledge": unread_knowledge,
		"current_scene_path": current_scene_path,
		"timestamp": timestamp,
		"biome_name": biome_name,
		"active_form": active_species.replace("_", " ").capitalize(),
		"player_pos_x": player_position.x,
		"player_pos_y": player_position.y,
		"player_pos_z": player_position.z,
		"has_saved_position": has_saved_position,
		"world_state": world_state
	}
	
	var obj_path_str: String = ""
	if current_objective != null and is_instance_valid(current_objective) and current_objective.is_inside_tree() and get_tree().current_scene:
		obj_path_str = str(get_tree().current_scene.get_path_to(current_objective))
	data["current_objective_path"] = obj_path_str
	data["current_objective_text"] = current_objective_text
	data["current_objective_desc"] = current_objective_desc
	
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game(slot: int = -1) -> bool:
	if not has_save_file(slot):
		return false
		
	if slot != -1:
		current_save_slot = slot
		
	var file: FileAccess = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file:
		var json_str: String = file.get_as_text()
		var json: JSON = JSON.new()
		var error: int = json.parse(json_str)
		if error == OK:
			var data: Variant = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				restore_progression(data)
				health = clampf(float(data.get("health", max_health)), 0.0, max_health)
				stamina = clampf(float(data.get("stamina", max_stamina)), 0.0, max_stamina)
				defense = data.get("defense", 5.0)
				speed = data.get("speed", 4.0)
				inventory = data.get("inventory", [])
				genome_fragments = data.get("genome_fragments", 0)
				frogs_helped = data.get("frogs_helped", 0)
				total_frogs = data.get("total_frogs", 7)
				minigame_started = data.get("minigame_started", false)
				has_seen_prologue = data.get("has_seen_prologue", false)
				has_seen_ui_intro = data.get("has_seen_ui_intro", false)
				has_seen_character_tutorial = data.get("has_seen_character_tutorial", false)
				has_seen_knowledge_tutorial = data.get("has_seen_knowledge_tutorial", false)
				lolo_palaka_intro_done = data.get("lolo_palaka_intro_done", false)
				q01_completed = data.get("q01_completed", false)
				q02_completed = data.get("q02_completed", false)
				q03_completed = data.get("q03_completed", false)
				q04_completed = data.get("q04_completed", false)
				q05_completed = data.get("q05_completed", false)
				var saved_quest_progress: Variant = data.get("quest_progress", {})
				quest_progress = saved_quest_progress.duplicate(true) if saved_quest_progress is Dictionary else {}
				_migrate_legacy_quest_progress(data)
				
				var loaded_knowledge: Array = data.get("unlocked_knowledge", [])
				unlocked_knowledge.clear()
				for k in loaded_knowledge:
					unlocked_knowledge.append(str(k))
					
				var loaded_unread: Array = data.get("unread_knowledge", [])
				unread_knowledge.clear()
				for k in loaded_unread:
					unread_knowledge.append(str(k))
					
				current_scene_path = data.get("current_scene_path", "res://levels/main terrain.scn")
				if current_scene_path == "res://levels/main terrain.scn":
					current_scene_path = "res://levels/main terrain.scn"
				
				has_saved_position = data.get("has_saved_position", false)
				var p_pos = data.get("player_position", {})
				if typeof(p_pos) == TYPE_DICTIONARY and p_pos.has("x"):
					player_position = Vector3(
						p_pos.get("x", 0.0),
						p_pos.get("y", 0.0),
						p_pos.get("z", 0.0)
					)
				else:
					player_position = Vector3(
						data.get("player_pos_x", 0.0),
						data.get("player_pos_y", 0.0),
						data.get("player_pos_z", 0.0)
					)
				var loaded_world_state: Dictionary = data.get("world_state", {})
				world_state.clear()
				for scene in loaded_world_state:
					world_state[scene] = loaded_world_state[scene]
				
				health_changed.emit(health, max_health)
				stamina_changed.emit(stamina, max_stamina)
				level_changed.emit(level)
				exp_changed.emit(experience, exp_to_next)
				active_species_changed.emit(active_species)
				
				var loaded_obj_path: String = data.get("current_objective_path", "")
				var loaded_obj_text: String = data.get("current_objective_text", "")
				var loaded_obj_desc: String = data.get("current_objective_desc", "")
				current_objective = null
				current_objective_text = ""
				objective_changed.emit(null)
				if loaded_obj_text != "":
					call_deferred("_restore_objective", loaded_obj_path, loaded_obj_text, loaded_obj_desc)
					
				return true
	return false

func restore_progression(data: Dictionary) -> void:
	end_ultimate()
	species_progression = {"frog": _make_species_profile()}
	var saved: Variant = data.get("species_progression", {})
	if saved is Dictionary and not saved.is_empty():
		for species_id in AdaptationRules.SPECIES:
			if saved.get(species_id) is Dictionary:
				species_progression[species_id] = saved[species_id].duplicate(true)
				var profile := _ensure_profile(species_id)
				profile.current_level = clampi(int(profile.current_level), 1, 15)
				profile.current_xp = clampf(float(profile.current_xp), 0.0, XP_THRESHOLDS[-1])
				profile.unspent_ap = maxi(0, int(profile.unspent_ap))
				for attribute in ATTRIBUTE_DEFINITIONS.values():
					profile[attribute.key] = clampi(int(profile[attribute.key]), 0, 100)
				for category in ["attack", "defense", "agility"]:
					var key: String = category + "_ultimate_level"
					profile[key] = clampi(int(profile[key]), 0, 3)
				if not ULTIMATE_DEFINITIONS[species_id].has(str(profile.equipped_ultimate_category)):
					profile.equipped_ultimate_category = ""
				profile.genomes_earned = maxi(0, int(profile.genomes_earned))
				profile.genomes_spent = clampi(int(profile.genomes_spent), 0, int(profile.genomes_earned))
				profile.genomes_available = int(profile.genomes_earned) - int(profile.genomes_spent)
	else:
		var profile := _ensure_profile("frog")
		profile.current_level = clampi(int(data.get("level", 1)), 1, 15)
		profile.current_xp = clampf(float(data.get("experience", 0.0)), 0.0, XP_THRESHOLDS[-1])
		profile.unspent_ap = maxi(0, int(data.get("skill_points", 0)))
		# Old flat-stat saves carry health/stamina investments but no species profiles.
		profile.health_upgrades = maxi(0, roundi((float(data.get("max_health", 100.0)) - 100.0) / 5.0))
		profile.stamina_upgrades = maxi(0, roundi((float(data.get("max_stamina", 100.0)) - 100.0) / 5.0))
	salamander_genome_recovered = bool(data.get("salamander_genome_recovered", false)) or is_species_unlocked("salamander")
	if salamander_genome_recovered:
		_ensure_profile("salamander").is_unlocked = true
	active_species = str(data.get("active_species", "frog"))
	if not is_species_unlocked(active_species):
		active_species = "frog"
	ultimate_cooldown_remaining = clampf(float(data.get("ultimate_cooldown_remaining", 0.0)), 0.0, ULTIMATE_COOLDOWN_DURATION)
	var rewards: Variant = data.get("claimed_progression_rewards", {})
	claimed_progression_rewards = rewards.duplicate(true) if rewards is Dictionary else {}
	ultimate_cooldown_changed.emit(ultimate_cooldown_remaining, ULTIMATE_COOLDOWN_DURATION)
	_emit_progression_changed()

func _migrate_legacy_quest_progress(data: Dictionary) -> void:
	# Saves created before quest_progress still contain enough information to
	# resume their current milestone instead of replaying the whole quest.
	if not quest_progress.has("q03"):
		if q03_completed:
			quest_progress["q03"] = "completed"
		elif salamander_genome_recovered:
			quest_progress["q03"] = "awaiting_transformation"
		elif str(data.get("current_objective_text", "")) == "Restore the damaged habitat":
			quest_progress["q03"] = "awaiting_restore"
		elif claimed_progression_rewards.has("native_frog_rescue"):
			quest_progress["q03"] = "awaiting_genome"

func reset_data(slot: int = -1) -> void:
	if slot != -1:
		current_save_slot = slot
	active_species = "frog"
	species_progression = {"frog": _make_species_profile()}
	end_ultimate()
	ultimate_cooldown_remaining = 0.0
	ultimate_cooldown_changed.emit(ultimate_cooldown_remaining, ULTIMATE_COOLDOWN_DURATION)
	claimed_progression_rewards.clear()
	q01_completed = false
	q02_completed = false
	q03_completed = false
	q04_completed = false
	q05_completed = false
	quest_progress.clear()
	has_taken_damage_this_session = false
	health = 100.0
	stamina = 100.0
	level = 1
	experience = 0.0
	skill_points = 0
	defense = 5.0
	speed = 4.0
	inventory.clear()
	genome_fragments = 0
	salamander_genome_recovered = false
	species_progression.erase("salamander")
	frogs_helped = 0
	total_frogs = 7
	minigame_started = false
	has_seen_prologue = false
	has_seen_ui_intro = false
	has_seen_character_tutorial = false
	has_seen_knowledge_tutorial = false
	lolo_palaka_intro_done = false
	unlocked_knowledge.clear()
	unlocked_knowledge.append_array(["genomorph_suit", "dr_sterling", "the_collapse"])
	unread_knowledge.clear()
	current_scene_path = "res://levels/main terrain.scn"
	
	player_position = Vector3.ZERO
	has_saved_position = false
	world_state.clear()
	
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	level_changed.emit(level)
	exp_changed.emit(experience, exp_to_next)
	active_species_changed.emit(active_species)
	
	current_objective = null
	current_objective_text = ""
	objective_changed.emit(null)
