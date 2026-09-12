extends RefCounted

## Gameplay tuning, separated from saved progression. See files/GenoMorph_Progression_Implementation.md.
const SPECIES := {
	"frog": {"name": "Frog", "role": "Mobility and area control", "stamina": 100.0, "recovery": 10.0,
		"skills": ["Webbed Lunge", "Sticky Tongue Whip", "Splashdown Jump"]},
	"salamander": {"name": "Salamander", "role": "Recovery and poison", "stamina": 100.0, "recovery": 10.0,
		"skills": ["Bite", "Regenerative Skin", "Toxic Secretion"]},
	"water_monitor": {"name": "Water Monitor", "role": "Power and durability", "stamina": 120.0, "recovery": 8.0,
		"skills": ["Claw Slash", "Tail Sweep", "Crushing Bite"]}
}
const COSTS := [[1, 1, 2, 2, 3], [1, 1, 3, 3, 4], [2, 2, 4, 4, 6], [3, 3, 5, 5, 8]]
const ULTIMATES := {
	"frog": {
		"attack": {"name": "Toxic Trail", "description": "Poison nearby enemies and leave lingering toxic patches as you move.", "duration": [8.0, 9.0, 10.0], "poison": [3.0, 4.5, 6.0], "trail_duration": [4.0, 5.0, 6.0]},
		"defense": {"name": "Survival Frenzy", "description": "A protective aura reduces incoming damage.", "duration": [8.0, 9.0, 10.0], "resistance": [0.30, 0.40, 0.50]},
		"agility": {"name": "Swamp Runner", "description": "Move faster, recover stamina faster and spend less stamina on leaps.", "duration": [8.0, 9.0, 10.0], "speed": [1.25, 1.40, 1.55], "stamina_recovery": [1.5, 1.75, 2.0], "stamina_cost": [0.8, 0.7, 0.6]}
	},
	"salamander": {
		"attack": {"name": "Toxic Predator", "description": "Faster, stronger bites; stronger Regenerative Skin and Toxic Secretion.", "duration": [8.0, 9.0, 10.0], "damage": [1.35, 1.55, 1.75], "attack_speed": [1.25, 1.4, 1.55], "healing": [1.4, 1.6, 1.8], "poison_multiplier": [1.4, 1.7, 2.0]},
		"defense": {"name": "Regenerative Survivor", "description": "Reduce incoming damage and regenerate health even during combat.", "duration": [8.0, 9.0, 10.0], "resistance": [0.25, 0.35, 0.45], "heal_per_second": [3.0, 4.5, 6.0]},
		"agility": {"name": "Toxic Adaptation", "description": "Move faster, recover stamina faster and reduce ability stamina costs.", "duration": [8.0, 9.0, 10.0], "speed": [1.2, 1.35, 1.5], "stamina_recovery": [1.5, 1.75, 2.0], "stamina_cost": [0.8, 0.7, 0.6]}
	},
	"water_monitor": {
		"attack": {"name": "Crushing Maul", "description": "Grab a small enemy and slam once. Bosses stay grounded. Nearby foes take damage and knockback.", "duration": [1.2, 1.2, 1.2], "slam": [4.0, 5.0, 6.0], "splash": [1.5, 2.0, 2.5]},
		"defense": {"name": "Iron Hide", "description": "A thick protective adaptation absorbs a portion of incoming damage.", "duration": [8.0, 9.0, 10.0], "resistance": [0.35, 0.45, 0.55]},
		"agility": {"name": "Relentless Hunter", "description": "Sustain pursuit with faster movement and improved stamina recovery.", "duration": [10.0, 11.0, 12.0], "speed": [1.2, 1.3, 1.4], "stamina_recovery": [1.5, 1.75, 2.0], "stamina_cost": [0.8, 0.7, 0.6]}
	}
}

static func attribute_cost(upgrades: int) -> int:
	var tier := upgrades / 5
	var step := upgrades % 5
	if tier < COSTS.size():
		return int(COSTS[tier][step])
	return maxi(1, roundi(float(COSTS[3][step]) * pow(1.4, tier - 3)))

static func total_attribute_cost(upgrades: int) -> int:
	var total := 0
	for step in range(upgrades):
		total += attribute_cost(step)
	return total

static func effects(species: String, category: String, rank: int) -> Dictionary:
	var definition: Dictionary = ULTIMATES.get(species, {}).get(category, {})
	var result := {}
	if rank < 1 or rank > 3:
		return result
	for key in definition:
		if definition[key] is Array:
			result[key] = definition[key][rank - 1]
	return result

static func effect_summary(species: String, category: String, rank: int) -> String:
	var e := effects(species, category, rank)
	var parts: PackedStringArray = []
	parts.append("%.1fs" % float(e.get("duration", 0.0)))
	for key in ["resistance", "speed", "stamina_recovery", "damage", "attack_speed", "healing", "stamina_cost"]:
		if not e.has(key):
			continue
		var percent := roundi(float(e[key]) * 100.0)
		match key:
			"resistance": parts.append("-%d%% damage taken" % percent)
			"stamina_cost": parts.append("-%d%% stamina cost" % (100 - percent))
			_: parts.append("+%d%% %s" % [percent - 100, key.replace("_", " ")])
	if e.has("poison"): parts.append("%.1f poison damage/s per stack" % float(e.poison))
	if e.has("heal_per_second"): parts.append("%.1f health/s" % float(e.heal_per_second))
	if e.has("poison_multiplier"): parts.append("%.1f× poison" % float(e.poison_multiplier))
	if e.has("slam"): parts.append("%.1f× ATK slam + %.1f× ATK splash" % [e.slam, e.splash])
	return " • ".join(parts)
