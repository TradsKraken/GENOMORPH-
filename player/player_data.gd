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

var current_objective: Node3D = null
var current_objective_text: String = ""

var message_log: Array[String] = []

func add_message(speaker: String, text: String, color: String = "ffffff") -> void:
	var entry: String = "[b][color=#" + color + "]" + speaker + ":[/color][/b] " + text
	if not message_log.has(entry):
		message_log.append(entry)
		if message_log.size() > 50:
			message_log.pop_front()

func set_objective(target: Node3D, text: String = "") -> void:
	current_objective = target
	
	if text != "":
		current_objective_text = text
	elif target and "objective_text" in target:
		current_objective_text = target.objective_text
	else:
		current_objective_text = ""
		
	objective_changed.emit(target)

func _restore_objective(path_str: String, text: String) -> void:
	var target: Node3D = null
	if path_str != "" and get_tree().current_scene:
		target = get_tree().current_scene.get_node_or_null(path_str)
	set_objective(target, text)

# ── Stats ─────────────────────────────────────────────────────────────────────
var max_health: float  = 100.0
var health: float      = 100.0

var max_stamina: float = 100.0
var stamina: float     = 100.0

var level: int         = 1
var experience: float  = 0.0
var exp_to_next: float = 100.0
var skill_points: int = 0:
	set(val):
		skill_points = val
		skill_points_changed.emit(val)

var attack_power: float = 10.0
var defense: float = 5.0
var speed: float = 4.0

var inventory: Array = []
var genome_fragments: int = 0
var has_seen_prologue: bool = false
var has_seen_minimap_tutorial: bool = false
var max_genome_fragments: int = 12
var minigame_started: bool = false

var frogs_helped: int = 0
var total_frogs: int = 7
var lolo_palaka_intro_done: bool = false

var current_scene_path: String = "res://levels/node_3d.scn"

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
func add_genome_fragment() -> void:
	genome_fragments = mini(genome_fragments + 1, max_genome_fragments)
	genome_collected.emit(genome_fragments, max_genome_fragments)


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

func gain_exp(amount: float) -> void:
	experience += amount
	while experience >= exp_to_next:
		_do_level_up()
	exp_changed.emit(experience, exp_to_next)


func _do_level_up() -> void:
	experience -= exp_to_next
	level += 1
	skill_points += 1
	exp_to_next = 100.0 * pow(1.4, level - 1)
	AudioManager.play_sfx("level_up")
	level_changed.emit(level)


# ── Knowledge Base ────────────────────────────────────────────────────────────

const KNOWLEDGE_DB: Dictionary = {
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
				exp_to_next = data.get("exp_to_next", 100.0)
				skill_points = data.get("skill_points", 0)
				attack_power = data.get("attack_power", 10.0)
				defense = data.get("defense", 5.0)
				speed = data.get("speed", 4.0)
				inventory = data.get("inventory", [])
				genome_fragments = data.get("genome_fragments", 0)
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
					
				current_scene_path = data.get("current_scene_path", "res://levels/node_3d.scn")
				if current_scene_path == "res://levels/node_3d.tscn":
					current_scene_path = "res://levels/node_3d.scn"
				
				has_saved_position = data.get("has_saved_position", false)
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
	max_health = 100.0
	health = 100.0
	max_stamina = 100.0
	stamina = 100.0
	level = 1
	experience = 0.0
	exp_to_next = 100.0
	skill_points = 0
	attack_power = 10.0
	defense = 5.0
	speed = 4.0
	inventory.clear()
	genome_fragments = 0
	frogs_helped = 0
	total_frogs = 7
	minigame_started = false
	has_seen_prologue = false
	lolo_palaka_intro_done = false
	unlocked_knowledge.clear()
	unlocked_knowledge.append_array(["genomorph_suit", "dr_sterling", "the_collapse"])
	unread_knowledge.clear()
	current_scene_path = "res://levels/node_3d.scn"
	
	player_position = Vector3.ZERO
	has_saved_position = false
	world_state.clear()
	
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	level_changed.emit(level)
	exp_changed.emit(experience, exp_to_next)
	
	current_objective = null
	current_objective_text = ""
	objective_changed.emit()
