extends Node

## PlayerData — global autoload singleton.
## Access from any script: PlayerData.health, PlayerData.gain_exp(25), etc.

# ── Signals ───────────────────────────────────────────────────────────────────
signal health_changed(value: float, maximum: float)
signal stamina_changed(value: float, maximum: float)
signal exp_changed(value: float, needed: float)
signal level_changed(new_level: int)

# ── Stats ─────────────────────────────────────────────────────────────────────
var max_health: float  = 100.0
var health: float      = 100.0

var max_stamina: float = 100.0
var stamina: float     = 100.0

var level: int         = 1
var experience: float  = 0.0
var exp_to_next: float = 100.0
var skill_points: int  = 0

var attack_power: float = 10.0
var defense: float = 5.0
var speed: float = 4.0

var inventory: Array = []
var genome_fragments: int = 0
var has_seen_prologue: bool = false

var current_scene_path: String = "res://levels/node_3d.tscn"


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
	level_changed.emit(level)


# ── Knowledge Base ────────────────────────────────────────────────────────────

const KNOWLEDGE_DB: Dictionary = {
	"mosquito": {
		"title": "Giant Mosquito",
		"category": "Species",
		"icon": "⬡",
		"desc": "A heavily mutated, blood-sucking insect. It flies in erratic patterns and drains stamina as well as health. Avoid its stinger!"
	},
	"swamp": {
		"title": "Toxic Swamp",
		"category": "Environment",
		"icon": "⌬",
		"desc": "A hazardous wetland teeming with aggressive flora and fauna. The water itself is highly acidic, slowly eating away at any organic matter submerged in it."
	},
	"lolo_palaka": {
		"title": "Lolo Palaka",
		"category": "Characters",
		"icon": "◈",
		"desc": "A wise old amphibian who guides young tadpoles through the dangerous environment. Often speaks in riddles."
	},
	"genomorph_suit": {
		"title": "GenoMorph Prototype",
		"category": "Technology",
		"icon": "⌬",
		"desc": "A cutting-edge biological shape-shifting suit designed to adapt to extreme environments by assimilating local genome fragments."
	},
	"dr_sterling": {
		"title": "Dr. Alistair Sterling",
		"category": "Characters",
		"icon": "◈",
		"desc": "The lead researcher and creator of the GenoMorph project. He monitors the suit's telemetry from a secure clinical laboratory."
	},
	"the_collapse": {
		"title": "The Collapse",
		"category": "History",
		"icon": "⬡",
		"desc": "The ecological catastrophe that decimated the region's diverse ecosystems, leaving behind highly toxic and mutated zones."
	}
}

var unlocked_knowledge: Array[String] = ["genomorph_suit", "dr_sterling", "the_collapse"]

signal knowledge_unlocked(id: String)

func unlock_knowledge(id: String) -> void:
	if id in KNOWLEDGE_DB and not id in unlocked_knowledge:
		unlocked_knowledge.append(id)
		knowledge_unlocked.emit(id)

# ── Save & Load ───────────────────────────────────────────────────────────────

var current_save_slot: int = 1

func get_save_path(slot: int = -1) -> String:
	if slot == -1:
		slot = current_save_slot
	return "user://genomorph_save_%d.json" % slot

func has_save_file(slot: int = -1) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_save_preview(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				return {
					"level": data.get("level", 1),
					"has_seen_prologue": data.get("has_seen_prologue", false),
					"timestamp": data.get("timestamp", "Unknown Date"),
					"biome_name": data.get("biome_name", "Unknown Region"),
					"active_form": data.get("active_form", "Unknown Form"),
					"genome_fragments": data.get("genome_fragments", 0),
					"max_genome_fragments": data.get("max_genome_fragments", 4)
				}
	return {}

func save_game(slot: int = -1) -> void:
	var current_level_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else current_scene_path
	if current_level_path != "":
		current_scene_path = current_level_path

	var biome_name = "Level 1: The Polluted Wetlands"
	if "mosquito_zone" in current_scene_path:
		biome_name = "Level 1: Mosquito Swarm Zone"
		
	var datetime = Time.get_datetime_dict_from_system()
	# Format: YYYY-MM-DD HH:MM
	var timestamp = "%04d-%02d-%02d %02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute
	]

	var data = {
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
		"max_genome_fragments": 4, # Default to 4 for now
		"has_seen_prologue": has_seen_prologue,
		"unlocked_knowledge": unlocked_knowledge,
		"current_scene_path": current_scene_path,
		"timestamp": timestamp,
		"biome_name": biome_name,
		"active_form": "Small Native Frog"
	}
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game(slot: int = -1) -> bool:
	if not has_save_file(slot):
		return false
		
	if slot != -1:
		current_save_slot = slot
		
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_str)
		if error == OK:
			var data = json.get_data()
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
				has_seen_prologue = data.get("has_seen_prologue", false)
				
				var loaded_knowledge = data.get("unlocked_knowledge", [])
				unlocked_knowledge.clear()
				for k in loaded_knowledge:
					unlocked_knowledge.append(str(k))
					
				current_scene_path = data.get("current_scene_path", "res://levels/node_3d.tscn")
				
				health_changed.emit(health, max_health)
				stamina_changed.emit(stamina, max_stamina)
				level_changed.emit(level)
				exp_changed.emit(experience, exp_to_next)
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
	has_seen_prologue = false
	unlocked_knowledge.clear()
	unlocked_knowledge.append_array(["genomorph_suit", "dr_sterling", "the_collapse"])
	current_scene_path = "res://levels/node_3d.tscn"
	
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	level_changed.emit(level)
	exp_changed.emit(experience, exp_to_next)
