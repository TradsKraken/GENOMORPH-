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


# ── EXP / Level API ───────────────────────────────────────────────────────────

func gain_exp(amount: float) -> void:
	experience += amount
	while experience >= exp_to_next:
		_do_level_up()
	exp_changed.emit(experience, exp_to_next)


func _do_level_up() -> void:
	experience -= exp_to_next
	level += 1
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
	}
}

var unlocked_knowledge: Array[String] = []

signal knowledge_unlocked(id: String)

func unlock_knowledge(id: String) -> void:
	if id in KNOWLEDGE_DB and not id in unlocked_knowledge:
		unlocked_knowledge.append(id)
		knowledge_unlocked.emit(id)

# ── Save & Load ───────────────────────────────────────────────────────────────

const SAVE_PATH := "user://genomorph_save.json"

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var current_level_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else current_scene_path
	if current_level_path != "":
		current_scene_path = current_level_path

	var data = {
		"health": health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"level": level,
		"experience": experience,
		"exp_to_next": exp_to_next,
		"genome_fragments": genome_fragments,
		"has_seen_prologue": has_seen_prologue,
		"unlocked_knowledge": unlocked_knowledge,
		"current_scene_path": current_scene_path
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> bool:
	if not has_save_file():
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
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

func reset_data() -> void:
	max_health = 100.0
	health = 100.0
	max_stamina = 100.0
	stamina = 100.0
	level = 1
	experience = 0.0
	exp_to_next = 100.0
	genome_fragments = 0
	has_seen_prologue = false
	unlocked_knowledge.clear()
	current_scene_path = "res://levels/node_3d.tscn"
	
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	level_changed.emit(level)
	exp_changed.emit(experience, exp_to_next)
