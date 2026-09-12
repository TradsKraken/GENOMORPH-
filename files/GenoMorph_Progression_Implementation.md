# Wetlands progression implementation — 2026-09-12

This records the working implementation and provisional tuning. It does not finalize the open balance decisions in the GDD.

Sources: Master GDD v1.2 (design intent and species kits), Complete Design Specification §§9–15, 30–43 (shared resources, progression and combat), and Progression Economy v0.3 (the explicitly resolved XP/AP/cost economy). Later-biome kits remain undesigned and are not invented here.

## Implemented flow

Open the level badge → ATTRIBUTES to spend AP. Rows show the real current/next value, price and progress toward the next adaptation Genome. Five upgrades in one attribute award one adaptation Genome to that species. ULTIMATES shows all three levels of each path and its numerical effects. Purchases require confirmation and consume one adaptation Genome. Unlocking equips level 1; upgrading advances the equipped path by one level; switching preserves the destination's rank, including level 3. Switching is not a simultaneous upgrade. All balances, paths, species profiles and the shared Ultimate charge are saved.

Discovery genomes unlock forms. Suit fragments remain a separate collectible. Adaptation Genomes are earned through attributes and spent on Ultimates; the UI explains the distinction.

XP is cumulative, capped at 524 for level 15, and each level grants 2 AP. The first four five-upgrade price blocks exactly match Economy v0.3: `1,1,2,2,3`; `1,1,3,3,4`; `2,2,4,4,6`; `3,3,5,5,8`. Beyond the published table, prices use rounded 40% growth from block four (provisional). ATK uses the economy draft's `15 + 4*(level-1) + 6*(AP spent in Attack)`; health, stamina and recovery use the specification's base-relative 5% upgrades. Cooldown reduction is 3% per upgrade, provisionally capped at 75%.

Health aggregation is a provisional resolution of two requirements: maximum health is shared, but health-upgrade counts are species-specific. The strongest unlocked health adaptation sets the shared maximum; switching never reduces or refills it. Each species retains its own upgrade counts and Genome milestones. The UI previews this shared capacity, so a weaker profile's next health upgrade may leave the shared maximum unchanged. Current stamina and charge are shared; stamina clamps to the new species' capacity without refilling.

## Combat tuning (provisional)

Definitions and all level-dependent Ultimate values live in `systems/adaptation_rules.gd`. Runtime effects live in `combat/adaptation_combat.gd`, `adaptation_field.gd`, and `adaptation_poison.gd`.

- Shared charge: 0–100, gained at 0.25 per actual enemy damage (capped at remaining HP), plus 0.5 per damage received (up to 30 damage per hit). No charging while an Ultimate is active. Full charge is consumed once; switching cannot refill it. Temporary effects end on switching, death and scene exit; remaining charge persists.
- Frog: Toxic Trail applies poison nearby and leaves stationary lingering patches while moving. Survival Frenzy reduces incoming damage. Swamp Runner increases movement/stamina recovery and reduces leap cost; the hopping animation retains the speed bonus. Splashdown scales with ATK ×1.8. Sticky Tongue Whip costs no stamina.
- Salamander: Regenerative Skin heals over five seconds while moving/fighting; Toxic Secretion creates a six-second poison field. Poison is one status per victim, caps at three stacks and refreshes duration on further applications. Toxic Predator increases bite damage/rate, skin healing and poison strength/application rate. Regenerative Survivor heals during combat and reduces damage. Toxic Adaptation improves movement/stamina performance. No dodge mechanic is invented.
- Water Monitor: the existing model is used when its genome is unlocked through `PlayerData.unlock_species("water_monitor")`. Tail Sweep damages/knocks back nearby foes; Crushing Bite damages/staggers a target. Crushing Maul lifts small enemies and performs exactly one slam; bosses and large enemies stay grounded. Iron Hide reduces damage; Relentless Hunter improves sustained mobility. This task implements its progression and combat support, not a new Water Monitor discovery quest.

First skills have no stamina cost. Salamander/Water Monitor skill 2 costs 30 stamina before temporary modifiers. Regenerative Skin cooldown is 12s, Tail Sweep 5s, skill 2 8s; the attribute reduces these. Frog's existing leap is limited by stamina/landing, not a new cooldown. Ultimate durations and effects vary by species/path/rank instead of assuming every Ultimate lasts eight seconds.

## Earnable rewards

Q01 and Q02 completion each give 40 XP. Native Frog rescue/restoration gives 40 XP +3 AP; Salamander discovery gives 100 XP +3 AP. First-time clue scans give 5 XP. These rewards are claimed once per save (including across species) to prevent replay farming. Enemy orbs now respect `exp_value` rather than awarding a random 10–20 XP; the default is 3 XP. Existing larger enemy reward overrides are retained. These are tuning values, not a claim that the full Wetlands economy has been playtested.

## Validation

`test_progression_ui.tscn` exercises the actual HUD scene/menu buttons, five-upgrade milestone, all cost blocks, level cap, path unlock/upgrade/switch including maxed paths, activation gates, charge consumption, expiry, independent species, shared resources, the real save/load path in a disposable unused test slot, legacy-save isolation, poison stack cap, Salamander healing/secondary cooldown and a single Water Monitor slam. `test_salamander_onboarding.tscn` checks the discovery-to-transformation handoff.

Run with `--headless --path <project> res://tools/debug_scripts/test_progression_ui.tscn`. Add `-- --capture-ui` with a graphical renderer to capture the attributes and Ultimates screens. The latter writes two PNG previews to the project root. Balance still needs real encounter playtesting on the target phone.
