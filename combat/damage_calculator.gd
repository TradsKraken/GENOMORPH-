class_name DamageCalculator
extends RefCounted

## Centralized Damage Calculator as specified in the Master GDD

static func calculate_player_damage(final_attack_power: float, ability_multiplier: float, vulnerability_modifier: float = 1.0) -> float:
	var final_damage = final_attack_power * ability_multiplier * vulnerability_modifier
	return final_damage

static func calculate_enemy_damage(base_enemy_damage: float, attack_variant: float = 1.0, area_encounter_scaling: float = 1.0) -> float:
	var final_damage = base_enemy_damage * attack_variant * area_encounter_scaling
	return final_damage
