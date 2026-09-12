extends Node

## PlayerData — global autoload singleton.
## Access from any script: PlayerData.health, PlayerData.gain_exp(25), etc.

# ── Signals ───────────────────────────────────────────────────────────────────
signal health_changed(value: float, maximum: float)
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
var current_objective: Node3D = null
var current_objective_text: String = ""
var current_objective_desc: String = ""

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

func get_current_species_data() -> Dictionary:
	if not species_progression.has(active_species):
		return {}
	return species_progression[active_species]

func is_species_unlocked(species_id: String) -> bool:
	return species_progression.has(species_id) and species_progression[species_id].get("is_unlocked", false)

## Switches the progression profile used by the player. The HUD owns the
## selection UI; the physical form can be hooked up here when its scene/model
## is introduced.
func set_active_species(species_id: String) -> bool:
	if species_id == active_species or not is_species_unlocked(species_id):
		return false
	active_species = species_id
	health = minf(health, max_health)
	stamina = minf(stamina, max_stamina)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	exp_changed.emit(experience, exp_to_next)
	level_changed.emit(level)
	active_species_changed.emit(active_species)
	return true

# ── Base Shared Stats (Tuning) ────────────────────────────────────────────────
var base_shared_health: float = 100.0
var base_species_stamina: float = 100.0
var base_attack_power: float = 20.0

# ── Volunteer Shared Resources ────────────────────────────────────────────────
var max_health: float:
	get:
		var sp_data = get_current_species_data()
		var upgrades = sp_data.get("health_upgrades", 0) if sp_data else 0
		return base_shared_health * (1.0 + 0.05 * upgrades)
var health: float      = 100.0

var max_stamina: float:
	get:
		var sp_data = get_current_species_data()
		var upgrades = sp_data.get("stamina_upgrades", 0) if sp_data else 0
		return base_species_stamina * (1.0 + 0.05 * upgrades)
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
		return base_attack_power * (1.0 + 0.05 * upgrades)

var defense: float = 5.0
var speed: float = 4.0

var inventory: Array = []
var genome_fragments: int = 0
var has_seen_prologue: bool = false
var has_seen_minimap_tutorial: bool = false

# Runtime-only flags so a quest director can check "did the previous quest
# already finish?" without depending on sibling _ready() order matching
# creation order (which happened to work by luck, not guarantee — see
# how has_seen_prologue avoids the same race for the prologue->Q01 handoff).
# Not persisted to save data since none of these directors restore their
# _state on load either.
var q01_completed: bool = false
var q02_completed: bool = false
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
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


# ── EXP / Level API ───────────────────────────────────────────────────────────
const XP_THRESHOLDS: Array[float] = [
	0.0, 100.0, 250.0, 450.0, 700.0, 1000.0, 1350.0, 1750.0, 2200.0, 2700.0, 3250.0, 3850.0, 4500.0, 5200.0, 6000.0
]

func gain_exp(amount: float) -> void:
	experience += amount
	
	var max_level = XP_THRESHOLDS.size()
	while level < max_level and experience >= XP_THRESHOLDS[level]:
		_do_level_up()
		
	var next_req = XP_THRESHOLDS[level] if level < max_level else XP_THRESHOLDS[max_level - 1]
	exp_changed.emit(experience, next_req)

func _do_level_up() -> void:
	level += 1
	skill_points += 2
	AudioManager.play_sfx("level_up")
	level_changed.emit(level)


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
		"active_species": active_species,
		"salamander_genome_recovered": salamander_genome_recovered,
		"max_genome_fragments": max_genome_fragments,
		"frogs_helped": frogs_helped,
		"total_frogs": total_frogs,
		"minigame_started": minigame_started,
		"has_seen_prologue": has_seen_prologue,
		"lolo_palaka_intro_done": lolo_palaka_intro_done,
		"unlocked_knowledge": unlocked_knowledge,
		"unread_knowledge": unread_knowledge,
		"current_scene_path": current_scene_path,
		"timestamp": timestamp,
		"biome_name": biome_name,
		"active_form": "Small Native Frog",
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
				health = data.get("health", 100.0)
				max_health = data.get("max_health", 100.0)
				stamina = data.get("stamina", 100.0)
				max_stamina = data.get("max_stamina", 100.0)
				level = data.get("level", 1)
				experience = data.get("experience", 0.0)
				skill_points = data.get("skill_points", 0)
				attack_power = data.get("attack_power", 10.0)
				defense = data.get("defense", 5.0)
				speed = data.get("speed", 4.0)
				inventory = data.get("inventory", [])
				genome_fragments = data.get("genome_fragments", 0)
				var saved_salamander_genome: bool = data.get("salamander_genome_recovered", false)
				var saved_active_species: String = str(data.get("active_species", "frog"))
				salamander_genome_recovered = false
				if saved_salamander_genome:
					recover_salamander_genome()
				active_species = saved_active_species if is_species_unlocked(saved_active_species) else "frog"
				frogs_helped = data.get("frogs_helped", 0)
				total_frogs = data.get("total_frogs", 7)
				minigame_started = data.get("minigame_started", false)
				has_seen_prologue = data.get("has_seen_prologue", false)
				lolo_palaka_intro_done = data.get("lolo_palaka_intro_done", false)
				
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
				current_objective = null
				current_objective_text = ""
				objective_changed.emit()
				if loaded_obj_text != "":
					call_deferred("_restore_objective", loaded_obj_path, loaded_obj_text)
					
				return true
	return false

func reset_data(slot: int = -1) -> void:
	if slot != -1:
		current_save_slot = slot
	active_species = "frog"
	max_health = 100.0
	health = 100.0
	max_stamina = 100.0
	stamina = 100.0
	level = 1
	experience = 0.0
	skill_points = 0
	attack_power = 10.0
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
	objective_changed.emit()
