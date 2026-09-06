> ⚠️ SOURCE-OF-TRUTH NOTICE
>
> This document records the current GenoMorph design state.
> LOCKED decisions must not be changed without explicit approval.
> OPEN decisions must not be silently resolved.
> DRAFT values are for balancing and testing only.

# GenoMorph — Complete Game Design & Development Specification

## Table of Contents

1. [Document Purpose](#1-document-purpose)
2. [Document Status System](#2-document-status-system)
3. [Game Overview](#3-game-overview)
4. [Design Philosophy](#4-design-philosophy)
5. [Player Character](#5-player-character)
6. [Dr. Alistair Sterling](#6-dr-alistair-sterling)
7. [Locked Prologue](#7-locked-prologue)
8. [Biome Progression](#8-biome-progression)
9. [Shared Player Resource Model](#9-shared-player-resource-model)
10. [Shared Health](#10-shared-health)
11. [Shared Stamina](#11-shared-stamina)
12. [Shared Ultimate Charge](#12-shared-ultimate-charge)
13. [Species Switching](#13-species-switching)
14. [Adaptive Progression System](#14-adaptive-progression-system)
15. [Adaptation XP](#15-adaptation-xp)
16. [XP Table](#16-xp-table)
17. [XP Level-Up Calculation](#17-xp-level-up-calculation)
18. [Adaptation Points](#18-adaptation-points)
19. [Biological Attributes](#19-biological-attributes)
20. [Attribute Formulas](#20-attribute-formulas)
21. [Health Formula](#21-health-formula)
22. [Attack Power Formula](#22-attack-power-formula)
23. [Stamina Formula](#23-stamina-formula)
24. [Stamina Recovery Formula](#24-stamina-recovery-formula)
25. [Health Recovery Formula](#25-health-recovery-formula)
26. [Cooldown Reduction Formula](#26-cooldown-reduction-formula)
27. [Attribute Data Architecture](#27-attribute-data-architecture)
28. [Genome System](#28-genome-system)
29. [Genome Earned/Spent/Available](#29-genome-earnedspentavailable)
30. [Ultimate Adaptation System](#30-ultimate-adaptation-system)
31. [Ultimate Development](#31-ultimate-development)
32. [No Free Ultimate Swapping](#32-no-free-ultimate-swapping)
33. [Species Ultimate Memory](#33-species-ultimate-memory)
34. [Frog Specification](#34-frog-specification)
35. [Frog Ultimates](#35-frog-ultimates)
36. [Salamander Specification](#36-salamander-specification)
37. [Salamander Ultimates](#37-salamander-ultimates)
38. [Water Monitor Specification](#38-water-monitor-specification)
39. [Water Monitor Ultimates](#39-water-monitor-ultimates)
40. [Combat Design](#40-combat-design)
41. [Player Damage Formula](#41-player-damage-formula)
42. [Frog Damage Multipliers](#42-frog-damage-multipliers)
43. [Damage Precision](#43-damage-precision)
44. [Critical Hits](#44-critical-hits)
45. [Damage Numbers](#45-damage-numbers)
46. [Enemy HP](#46-enemy-hp)
47. [Enemy Damage](#47-enemy-damage)
48. [Player Damage Cooldown](#48-player-damage-cooldown)
49. [Player Hit Reaction](#49-player-hit-reaction)
50. [Player Attack Interruption](#50-player-attack-interruption)
51. [Hit Count](#51-hit-count)
52. [Enemy AI](#52-enemy-ai)
53. [AI Architecture](#53-ai-architecture)
54. [Encounter Size](#54-encounter-size)
55. [Enemy Respawn](#55-enemy-respawn)
56. [Restoration and Enemy Distribution](#56-restoration-and-enemy-distribution)
57. [Mosquito — Detailed Specification](#57-mosquito--detailed-specification)
58. [Mosquito State Machine](#58-mosquito-state-machine)
59. [Mosquito Detection](#59-mosquito-detection)
60. [Mosquito Chase](#60-mosquito-chase)
61. [Mosquito Attack](#61-mosquito-attack)
62. [Mosquito Animation Damage Event](#62-mosquito-animation-damage-event)
63. [Mosquito Single-Hit Protection](#63-mosquito-single-hit-protection)
64. [Mosquito Death](#64-mosquito-death)
65. [Mosquito Test Requirements](#65-mosquito-test-requirements)
66. [Interaction System](#66-interaction-system)
67. [Educational System](#67-educational-system)
68. [Quest Guidance](#68-quest-guidance)
69. [Hint System](#69-hint-system)
70. [Optional Discoveries](#70-optional-discoveries)
71. [Quest Completion](#71-quest-completion)
72. [Checkpoints](#72-checkpoints)
73. [Death](#73-death)
74. [Wetland Quest Flow](#74-wetland-quest-flow)
75. [Q01 — First Awakening](#75-q01--first-awakening)
76. [Q01 XP Draft](#76-q01-xp-draft)
77. [Q02 — Investigate the Disturbance](#77-q02--investigate-the-disturbance)
78. [Q02 XP Draft](#78-q02-xp-draft)
79. [Q03 — Fragile Habitat](#79-q03--fragile-habitat)
80. [Q03 XP Draft](#80-q03-xp-draft)
81. [Salamander Introduction](#81-salamander-introduction)
82. [Salamander XP Draft](#82-salamander-xp-draft)
83. [Q04 — Contaminated Water](#83-q04--contaminated-water)
84. [Q04 XP Draft](#84-q04-xp-draft)
85. [Water Monitor Introduction](#85-water-monitor-introduction)
86. [Water Monitor XP Draft](#86-water-monitor-xp-draft)
87. [Nutria Colony](#87-nutria-colony)
88. [Nutria XP Draft](#88-nutria-xp-draft)
89. [Wetland Chimera](#89-wetland-chimera)
90. [Chimera Phase 1](#90-chimera-phase-1)
91. [Chimera Phase 2](#91-chimera-phase-2)
92. [Chimera Phase 3](#92-chimera-phase-3)
93. [Chimera Weak Points](#93-chimera-weak-points)
94. [Genome Core Recovery](#94-genome-core-recovery)
95. [Wetland Restoration](#95-wetland-restoration)
96. [Wetland → Rainforest Transition](#96-wetland--rainforest-transition)
97. [Rainforest Opening](#97-rainforest-opening)
98. [Wild Boar](#98-wild-boar)
99. [Wild Boar Introduction](#99-wild-boar-introduction)
100. [Pangolin](#100-pangolin)
101. [Eagle](#101-eagle)
102. [Mountain Progression](#102-mountain-progression)
103. [Full Game Structure](#103-full-game-structure)
104. [Current Implementation Status](#104-current-implementation-status)
105. [Implementation Roadmap](#105-implementation-roadmap)
106. [Technical Data Models](#106-technical-data-models)
107. [Required Formula Reference](#107-required-formula-reference)
108. [Required Locked-Decision Table](#108-required-locked-decision-table)
109. [Required Open-Decision Table](#109-required-open-decision-table)
110. [Required Balance Table](#110-required-balance-table)
111. [Implementation Rules for Future AI Agents](#111-implementation-rules-for-future-ai-agents)
112. [Current State Summary](#112-current-state-summary)

---

## 1. Document Purpose

The Markdown file functions as the comprehensive Game Design Document, Systems Design Document, Combat Design Specification, Progression Design Specification, Species Design Reference, Quest/World Progression Reference, Technical Implementation Reference, and Current Project State Reference for GenoMorph. 

It is detailed enough that a new AI agent or developer can read the file and understand exactly what the game is, how its mechanics function mathematically, and what the current status is, without inventing unestablished mechanics or referencing past chat history.

---

## 2. Document Status System

> **LOCKED:** Confirmed design decision. Do not change without explicit approval.
>
> **OPEN:** Not finalized. Do not invent a final value.
>
> **DRAFT:** Current working value for balancing/testing.
>
> **RECOMMENDATION:** Suggested implementation/design direction, not a locked decision.
>
> **IMPLEMENTED:** Already developed/working according to current project status.
>
> **PLANNED:** Established as future development but not yet implemented.

---

## 3. Game Overview

**Genre:**
GenoMorph is a Mobile Third-person 3D Action RPG. It is Action-adventure first, focused on environmental restoration and ecology/wildlife education integrated directly into gameplay. The world is semi-open/interconnected, delivering a fast-paced experience without being excessively long or grindy.

**Core Gameplay Loop:**
```text
Explore
→ Discover environmental problems
→ Investigate
→ Fight invasive creatures/Chimeras
→ Restore ecosystem
→ Discover biological signals/genomes
→ Transform
→ Learn new animal adaptations
→ Explore deeper
→ Restore the next ecosystem
```

**Adaptive Loop:**
```text
Environment
→ Challenge
→ Player Choice
→ Adaptation
→ New Capability
```

---

## 4. Design Philosophy

* Action-adventure first.
* Education through gameplay.
* Avoid excessive exposition.
* Avoid excessive grinding.
* Avoid unnecessary downtime.
* Keep combat fast and readable.
* Keep mobile controls simple.
* Let the player experience a new animal before over-explaining it.
* Environmental clues should matter.
* Sterling should guide rather than constantly narrate.
* Normal enemies should not become giant HP sponges.
* Difficulty should come from behavior, positioning, timing, combinations, and adaptation.
* Species should have different roles rather than simply becoming stronger versions of previous species.
* Physical biome transitions should feel continuous rather than like level selection.

---

## 5. Player Character

**LOCKED Details:**
* 18-year-old male Volunteer.
* Environmentally passionate.
* Rare genetic compatibility.
* High neural plasticity.
* Personally recruited by Dr. Alistair Sterling.
* Sterling remains at the laboratory.
* Communication is through radio during the main game.
* Sterling is guide/scientific adviser.

*(Do not invent additional backstory)*

---

## 6. Dr. Alistair Sterling

**LOCKED Details:**
* Geneticist.
* Biomedical engineer.
* 11 years developing GenoMorph.
* Tested himself first.
* His genome is not compatible.
* Recruited the Volunteer because of compatibility.
* Communicates through radio.
* Does not physically accompany the player.
* Should not become a constant GPS narrator.

---

## 7. Locked Prologue

The prologue is already complete and **LOCKED**. The game begins detailed gameplay immediately after:
> “...Starting from a frog. I'm sorry.”
> “Your suit is locked to Frog form for now. Go carefully, Volunteer. Whatever is out there — it isn't ordinary anymore.”

**LOCKED Prologue Facts:**
* Sterling explains keystone species/ecological collapse.
* Damaged ecosystems are shown.
* GenoMorph is meant to give ecosystems a way to recover.
* Volunteer was selected due to compatibility.
* Sterling's own genome is incompatible.
* Volunteer starts at the wetland edge.
* Frog transformation overloads.
* 12 genomes discharge into the wetlands.
* The genomes become raw biological energy.
* Organisms/environment may absorb genome fragments.
* Invasive organisms can absorb fragments and become Invasive Chimeras.
* Purification Module remains active.
* The player must recover genome data.
* Player begins as Small Native Frog.
* Sterling communicates through radio.

---

## 8. Biome Progression

**Wetlands (LOCKED):**
```text
Frog
→ Salamander
→ Water Monitor
```

**Rainforest (LOCKED):**
```text
Wild Boar
→ Pangolin
→ Eagle
```

**Mountain (LOCKED):**
```text
Tamaraw
→ Bear
→ Goat
```

*Note: 12 genomes are planned total; 9 are represented in the base-game progression, and 3 are reserved for future content.*

---

## 9. Shared Player Resource Model

The player is ONE person. Animal forms are transformations of the same player. Therefore:

**Shared (LOCKED):**
* Current Health
* Maximum Health
* Current Stamina
* Ultimate Charge

**Species-specific (LOCKED):**
* Adaptation XP
* Adaptation Level
* Adaptation Points
* Attribute Upgrade Counts
* Genomes
* Ultimate progression
* Equipped/developed Ultimate path

---

## 10. Shared Health

**LOCKED:** One shared Health pool across all transformations.
Example:
```text
Frog:
40 / 100

Transform

Water Monitor:
40 / 100
```
Switching does not heal. Health belongs to the Volunteer/player rather than individual animal instances.

---

## 11. Shared Stamina

**LOCKED:**
* One shared current Stamina.
* Each species has its own maximum Stamina.
* Switching does not refill Stamina.
* If new species has lower maximum, current Stamina is clamped.
* If new species has higher maximum, existing current Stamina remains unchanged.

Formula:
```text
NewCurrentStamina = min(CurrentStamina, NewMaxStamina)
```
Example:
```text
Frog:
70 / 150

Switch to Water Monitor:
70 / 100
```

---

## 12. Shared Ultimate Charge

**LOCKED:**
* One Ultimate meter.
* Shared across the Volunteer.
* Transformation does not reset/refill it.

Example:
```text
Frog = 70%
→ Water Monitor = 70%
```

---

## 13. Species Switching

**LOCKED Rules:**
* Switching is possible outside combat.
* Switching is also possible during combat.
* Switching uses a short 1–2 second biological transformation animation.
* No loading screen.
* During transformation:
  * cannot attack
  * cannot use skills
  * player remains vulnerable
* New species becomes controllable when transformation finishes.
* Switching cooldown begins AFTER transformation finishes.
* Exact switch cooldown duration is **OPEN**.

---

## 14. Adaptive Progression System

Official terminology:
| Concept | Name |
|---|---|
| Overall system | Adaptive Progression System |
| XP | Adaptation XP |
| Level | Adaptation Level |
| Points | Adaptation Points |
| Stats | Biological Attributes |
| Major milestone | Genome |
| Ultimate | Ultimate Adaptation |
| Species progression | Adaptation Profile |
| Species discovery | Genome Discovery / Genome Compatibility |
| Previous biome | Legacy Genome |

Flow:
```text
Adaptation XP
→ Adaptation Level
→ Adaptation Points
→ Biological Attribute Upgrades
→ Genome Milestones
→ Ultimate Adaptation Development
```

---

## 15. Adaptation XP

**LOCKED:**
* XP belongs to active species.
* Main quests provide most XP.
* Combat, exploration, environmental discoveries and restoration supplement it.
* No mandatory grinding.
* Encounter-level XP is preferred over per-kill XP.
* XP is cumulative.
* XP is stored separately for every species.

Function Concept: `AwardXP(amount, activeSpecies)`

---

## 16. XP Table

**DRAFT/TUNING:**

| Level | Total XP |
| ----: | -------: |
|     1 |        0 |
|     2 |      100 |
|     3 |      250 |
|     4 |      450 |
|     5 |      700 |
|     6 |    1,000 |
|     7 |    1,350 |
|     8 |    1,750 |
|     9 |    2,200 |
|    10 |    2,700 |
|    11 |    3,250 |
|    12 |    3,850 |
|    13 |    4,500 |
|    14 |    5,200 |
|    15 |    6,000 |

Level cap: `15`

---

## 17. XP Level-Up Calculation

**LOCKED Logic:**
```text
currentXP += amount

while currentXP >= XPRequiredForNextLevel
      and currentLevel < 15:

    currentLevel += 1
    unspentAdaptationPoints += 2
```
* XP is cumulative. Multiple thresholds must be handled. Excess XP is retained. Level-up during combat does not pause combat.

---

## 18. Adaptation Points

**LOCKED:**
```text
2 AP per level gained from Level 2 onward.
```

Formula:
```text
TotalAdaptationPointsEarned = (CurrentLevel - 1) × 2
```
Level 1 = 0, Level 2 = 2, Level 15 = 28.
AP can be spent anytime outside combat. Level-up during combat yields a brief notification, combat continues, and points can be spent later.

---

## 19. Biological Attributes

**LOCKED:** There are exactly six attributes.
1. Health
2. Attack Power
3. Stamina
4. Stamina Recovery
5. Cooldown Reduction
6. Health Recovery

*(Do not add a Defense attribute)*

---

## 20. Attribute Formulas

**Generic +5% attributes Formula (LOCKED):**
```text
FinalStat = BaseStat × (1 + 0.05 × UpgradeCount)
```
*Note: Bonus is calculated from the ORIGINAL BASE STAT. It is NOT compounded.*
Example: `Base = 100, Upgrades = 3 -> 100 * 1.15 = 115`

---

## 21. Health Formula

**LOCKED:**
```text
FinalMaxHealth = BaseSharedHealth × (1 + 0.05 × HealthUpgradeCount)
```
*(Health is shared across forms. Do not use separate Frog/Salamander/Monitor HP pools)*

---

## 22. Attack Power Formula

**LOCKED:**
```text
FinalAttackPower = BaseAttackPower × (1 + 0.05 × AttackPowerUpgradeCount)
```

---

## 23. Stamina Formula

**LOCKED:**
```text
FinalMaxStamina = BaseSpeciesStamina × (1 + 0.05 × StaminaUpgradeCount)
```

---

## 24. Stamina Recovery Formula

**LOCKED:**
```text
FinalStaminaRecovery = BaseStaminaRecovery × (1 + 0.05 × StaminaRecoveryUpgradeCount)
```

---

## 25. Health Recovery Formula

**LOCKED:**
```text
FinalHealthRecovery = BaseHealthRecovery × (1 + 0.05 × HealthRecoveryUpgradeCount)
```
*(Affects healing/regeneration effects; not automatically equivalent to permanent passive regeneration)*

---

## 26. Cooldown Reduction Formula

**LOCKED:**
```text
FinalCooldown = BaseCooldown × (1 - 0.03 × CooldownReductionUpgradeCount)
```
*Note: NOT compounded. Future cap is OPEN.*

---

## 27. Attribute Data Architecture

**LOCKED:** Base species stats must NOT be overwritten.
* `SpeciesData`: Stores Base Health, Base Attack Power, Base Stamina, Base Stamina Recovery, Base Cooldown, Base Health Recovery, Abilities, Ultimate definitions.
* `SpeciesProgression`: Stores XP, Level, AP, Attribute upgrade counts, Genomes, Ultimate progression.

Runtime calculation combines both.

---

## 28. Genome System

**LOCKED:** Every 5 upgrades in the same attribute produces 1 Genome milestone.
Formula:
```text
GenomeMilestones = floor(AttributeUpgradeCount / 5)
```
Examples: 4 upgrades → 0; 5 upgrades → 1; 12 upgrades → 2.
Genomes are species-specific.

---

## 29. Genome Earned/Spent/Available

**LOCKED Conceptual Distinction:**
Store:
```text
genomesEarned
genomesSpent
genomesAvailable
```
Conceptually:
```text
genomesAvailable = genomesEarned - genomesSpent
```
Do not confuse *milestones earned* with *currently available Genome resource*, because Genomes can be consumed.

---

## 30. Ultimate Adaptation System

**LOCKED:** Each species has 3 ultimate paths, with 3 levels each:
```text
Attack Ultimate (Lv1, Lv2, Lv3)
Defense Ultimate (Lv1, Lv2, Lv3)
Agility Ultimate (Lv1, Lv2, Lv3)
```

---

## 31. Ultimate Development

**LOCKED:** Genomes can be spent to:
1. **Upgrade current path**: Lv1 → Lv2, Lv2 → Lv3 (No skipping)
2. **Change path**: e.g., Attack Lv2 → spend Genome → Defense Lv1. When switching to a new path, it begins at Lv1.

---

## 32. No Free Ultimate Swapping

**LOCKED:** The player cannot freely switch between Attack/Defense/Agility Ultimates from a menu. Changing/developing the Ultimate path requires spending a Genome. Each species remembers its own Ultimate state.

---

## 33. Species Ultimate Memory

**LOCKED:** Switching species restores that species' own Ultimate path. Do not transfer Ultimate progression between species.
Example: Frog uses Toxic Trail. Salamander uses Toxic Predator.

---

## 34. Frog Specification

Role: **Agile Controller**
Strengths: mobility, stamina, jumping, crowd control, exploration
Weaknesses: lower durability, lower sustained damage

Abilities (LOCKED):
* **Basic Attack**: Webbed Lunge
* **Skill 1**: Sticky Tongue Whip (Attacks enemy, pulls small enemies/light objects)
* **Skill 2**: Splashdown Jump (Targeted jump attack, AoE landing damage, uses stamina)

---

## 35. Frog Ultimates

* **Attack — Toxic Trail**: ~8 seconds. High toxicity, nearby enemies damaged/poisoned, movement leaves poisonous trail. (Exact numerical values OPEN)
* **Defense — Survival Frenzy**: ~8 seconds. Increased defensive capability, semi-transparent protective visual.
* **Agility — Swamp Runner**: Improves movement/stamina performance. (Exact numerical values OPEN)

---

## 36. Salamander Specification

Role: **Recovery + Poison**
Priorities: Health Recovery very high, Health high, Attack moderate-high, Cooldown moderate, Stamina moderate, Stamina Recovery moderate.

Abilities:
* **Basic Bite**: No poison.
* **Regenerative Skin**: Restores Health over time while player can move/fight.
* **Toxic Secretion**: Creates poisonous area/effect. Poison caps at 3 stacks; fourth application refreshes duration.

---

## 37. Salamander Ultimates

* **Toxic Predator**: Stronger Bite, faster attack, stronger Regenerative Skin, stronger Toxic Secretion, stronger poison.
* **Regenerative Survivor**: Damage resistance, increased Health Recovery, ~8 sec baseline.
* **Toxic Adaptation**: Movement speed, stamina recovery, reduced movement-related stamina cost, faster recovery. (Do not invent Dodge mechanics)

---

## 38. Water Monitor Specification

Role: **Bruiser**
Strengths: High Health, high raw damage, heavy attacks, durability.

Abilities:
* **Claw Slash**: Basic attack.
* **Tail Sweep**: Wide attack, moderate damage, knockback, cooldown, wind-up, no stamina cost.
* **Crushing Bite**: High single-target damage, brief stagger, strong against bosses/large enemies.

---

## 39. Water Monitor Ultimates

* **Crushing Maul**: Bite/Grab → ONE massive slam. High damage, AoE, knockback, strong stagger. Bosses/large enemies cannot be grabbed (powerful bite → slam without lifting).
* **Iron Hide**: Exact values OPEN.
* **Relentless Hunter**: Focused on sustained pursuit/hunting mobility. Exact values OPEN.

---

## 40. Combat Design

**Philosophy (LOCKED):** Fast, responsive, readable, deterministic. Normal enemies die relatively quickly. Difficulty should come from behavior rather than inflated HP.

---

## 41. Player Damage Formula

**LOCKED:** For normal enemies:
```text
FinalDamage = FinalAttackPower × AbilityMultiplier
```
(No universal Enemy Defense stat).

---

## 42. Frog Damage Multipliers

**DRAFT:**
| Attack | Multiplier |
|---|---:|
| Basic Attack | 1.00 |
| Skill 1 | 1.50 |
| Skill 2 | 1.80 |

Example: `Attack Power = 120, Skill 1 = 120 × 1.50 = 180`

---

## 43. Damage Precision

**LOCKED:** Internal float precision (e.g., 12.6), UI display rounds to whole number (e.g., 13). Do not round before applying damage.

---

## 44. Critical Hits

**LOCKED:** No random critical hits. Weak points on Chimeras are deliberate vulnerability mechanics.

---

## 45. Damage Numbers

**LOCKED:** Damage numbers appear when player attacks successfully. Display whole numbers.

---

## 46. Enemy HP

**LOCKED Formula:**
```text
Normal enemy HP = Base HP × Variant Multiplier × Area/Encounter Multiplier
```
**DRAFT/BALANCE Values:**
* Mosquito: ~100
* Rat: ~180
* Snake: ~300
* Nutria: ~450
* Colony Defender: ~1,500

---

## 47. Enemy Damage

**LOCKED Formula:**
```text
FinalEnemyDamage = BaseEnemyDamage × AttackVariant × AreaEncounterScaling
```
**DRAFT:** Mosquito Base Bite Damage ≈ 10.

---

## 48. Player Damage Cooldown

**LOCKED:** After player takes damage, there is a brief damage cooldown. Additional enemy hits during this cooldown are ignored. Exact duration: **OPEN / TUNABLE**.

---

## 49. Player Hit Reaction

**LOCKED:** Brief Flinch. The player remains controllable. Movement is NOT fully disabled. Do not implement long universal stun.

---

## 50. Player Attack Interruption

**LOCKED:** No universal player attack interruption rule has been established. Do not invent one.

---

## 51. Hit Count

**LOCKED:** Normal attacks do one damage instance per enemy per activation. Multi-hit abilities define `NumberOfHits`, `DamagePerHit`, and `TimeBetweenHits`. Persistent hitboxes must not accidentally cause repeated damage.

---

## 52. Enemy AI

**LOCKED Core State Machine:**
```text
Idle/Patrol → Detect Player → Chase → Attack → Recover → Chase
(Any state → Dead when HP reaches zero)
```

---

## 53. AI Architecture

**LOCKED:** Shared reusable AI archetypes + species-specific behavior where meaningful. Core functionality: detect, move, attack, recover, take damage, die. Archetypes: Chaser, Heavy, Ambusher, Ranged/Area (if needed). Do not give every species completely unique AI.

---

## 54. Encounter Size

**LOCKED Variable sizes:**
Small = 1–3, Medium = ~3–6, Large = special situations (Rat infestation, Nutria colony, quests, bosses). Do not use enormous enemy counts as primary difficulty.

---

## 55. Enemy Respawn

**LOCKED:** Quest/story enemies are Permanent after defeat. Normal enemies are Respawnable after leaving the area or progression.

---

## 56. Restoration and Enemy Distribution

**LOCKED:** After an area is restored, major quest enemies remain gone, normal invasive enemies stop spawning in restored core, but nearby damaged areas may still contain invasive enemies. Restoration must have mechanical consequences.

---

## 57. Mosquito — Detailed Specification

**Required (LOCKED):** Enemy prefab/actor, Animator, collider, health, detection, movement, target, attack, attack damage window, recovery, cooldown, hit reaction, death, AI state machine. Do not recreate existing models/animations.

---

## 58. Mosquito State Machine

**LOCKED:**
```text
Idle ↓ Detect Player ↓ Chase ↓ Attack ↓ Recover ↓ Chase (Any state → Dead)
```

---

## 59. Mosquito Detection

**LOCKED:** Configurable `DetectionRadius`. When player enters, `Target = Player` and `State = Chase`. Mosquito is immediately hostile.

---

## 60. Mosquito Chase

**LOCKED:** Mosquito flies toward player. Do not build a complex flight simulation. Use configurable `MoveSpeed` and `PreferredAttackDistance`. Maintain appropriate flying height/distance.

---

## 61. Mosquito Attack

**LOCKED:** Attack is a Bite. Current damage ≈ 10 (DRAFT/TUNABLE). Sequence:
```text
Attack begins → attack animation → wind-up → bite/contact frame → damage window → apply damage once → close damage window → recovery → cooldown → attack again
```

---

## 62. Mosquito Animation Damage Event

**LOCKED:** Prefer Animation Event/Notify at the actual bite contact frame. Do NOT apply damage at attack-state entry. Do NOT let the hitbox remain active for the entire animation.

---

## 63. Mosquito Single-Hit Protection

**LOCKED Logic:**
Each bite should have `HasAppliedDamage = false`. At the correct contact frame:
```text
if target valid AND HasAppliedDamage == false AND PlayerDamageCooldown == false:
    ApplyDamage()
    HasAppliedDamage = true
```

---

## 64. Mosquito Death

**LOCKED Logic:**
At `CurrentHealth <= 0`, `State = Dead`. Stop AI, stop attacking, disable attack hitbox, play death animation, deactivate/destroy after animation.

---

## 65. Mosquito Test Requirements

**LOCKED Tests:**
* **One Mosquito**: detection, chase, attack, attack timing, damage, player flinch, movement remains controllable, damage cooldown, recovery, repeated attacks, Frog damage, damage numbers, death.
* **Two Mosquitoes**: overlapping attacks and cooldown.
* **Three Mosquitoes**: whether the player remains responsive and fair.

---

## 66. Interaction System

**LOCKED:** Player approaches environmental object → Interact → Compact Information Card appears. (Examples: polluted water, damaged vegetation, Genome signals, Genome Cores).

---

## 67. Educational System

**LOCKED:** Education must arise from gameplay. Avoid long forced lectures. Use three layers:
* Layer 1: Brief explanation.
* Layer 2: Optional Learn More.
* Layer 3: Knowledge Database.

---

## 68. Quest Guidance

**LOCKED:** Hybrid guidance. Main objectives receive clear directional guidance. Actual discovery relies on environmental clues (general destination + environmental evidence). Avoid constant marker/glowing object logic.

---

## 69. Hint System

**LOCKED:** Two types: Automatic (after prolonged inactivity) and Player-requested (contextual). Hints should be short, contextual, and progressively clearer. Sterling assists without becoming GPS.

---

## 70. Optional Discoveries

**LOCKED:** Subtle environmental cues. No obvious checklist markers before discovery. Recorded in Knowledge Database after discovery. Never blocks main story. Rewards: Knowledge + small Adaptation XP.

---

## 71. Quest Completion

**LOCKED:** Normal quest: `QUEST COMPLETE +XP` then gameplay continues. Major milestones (new species, Chimera defeat, Genome Core, restoration) can receive a short transition beat. No long cutscene requirement.

---

## 72. Checkpoints

**LOCKED:** Automatic checkpoints at major quest milestones, Genome discoveries, transformations, Chimera completion, Genome Core recovery, restoration, biome transitions. Physical checkpoints at important safe/restored locations.

---

## 73. Death

**LOCKED:** On defeat, respawn at latest checkpoint. Retain quest progress, genomes, species unlocks, XP, levels, AP, attributes, Genomes. Health returns to full after respawn.

---

## 74. Wetland Quest Flow

The established Wetlands sequence is detailed in the following sections.

---

## 75. Q01 — First Awakening

**LOCKED:** Starts immediately after prologue. Player is Small Native Frog. Flow: Wake → movement tutorial → explore shallow wetland → investigate damaged vegetation → observe polluted/damaged environment → Sterling detects danger → Mosquito encounter (First combat tutorial).

---

## 76. Q01 XP Draft

**DRAFT:**
```text
Initial investigation = +40 XP
Mosquito encounter = +30 XP
Discover rat disturbance = +30 XP
Total = 100 XP (Reaches Frog Level 2)
```

---

## 77. Q02 — Investigate the Disturbance

**LOCKED Flow:** Damaged vegetation → burrows → traces → displaced wildlife → rats → hostile encounter. Rats are immediately hostile when approached. First one rat, then additional rats. The player intervenes.

---

## 78. Q02 XP Draft

**DRAFT:**
```text
Investigate burrows/traces = +40
Rat encounter = +50
Quest completion = +60
Total = +150 XP (Frog: 100 → 250 XP, Level 3)
```

---

## 79. Q03 — Fragile Habitat

**LOCKED Flow:** Player protects native frogs from invasive rats. Native frogs threatened → clear rats → restore habitat → Purification Module → contamination reduces → vegetation begins recovering → Salamander biological signal → Salamander Genome → transformation.

---

## 80. Q03 XP Draft

**DRAFT:**
```text
Rescue/clear rats = +60
Restore habitat = +50
Salamander Genome discovery = +40
Quest completion = +50
Total = +200 XP (Frog: 250 → 450 XP, Level 4)
```

---

## 81. Salamander Introduction

**LOCKED:** After transformation, short free experimentation (movement, Bite, Regenerative Skin, Toxic Secretion). Then: controlled environmental damage → regeneration demonstration → small combat → larger combat → poison demonstration → follow biological signal. The player experiences regeneration rather than receiving a lecture.

---

## 82. Salamander XP Draft

**DRAFT:**
```text
Regeneration demonstration = +25
Toxic Secretion combat = +35
Follow biological signal = +40
Total = +100 XP (Salamander reaches Level 2)
```

---

## 83. Q04 — Contaminated Water

**LOCKED Flow:** contaminated wetland → Snake encounter → Snake retreats → follow evidence → native wildlife disturbance → investigate water → biological signal → large tracks/disturbance → Water Monitor Genome → transform.

---

## 84. Q04 XP Draft

**DRAFT:**
```text
Snake encounter = +40
Investigate contamination = +40
Follow biological signal = +50
Water Monitor Genome = +20
Total = +150 XP (Salamander: 100 → 250 XP, Level 3)
```

---

## 85. Water Monitor Introduction

**LOCKED:** After transformation: fallen tree → interact → push/shift obstacle. Then: several invasive creatures → combat (Demonstrate Claw Slash, Tail Sweep, Crushing Bite). Then large tracks/burrows lead to Nutria.

---

## 86. Water Monitor XP Draft

**DRAFT:**
```text
Clear first obstacle = +25
First combat = +40
Explore large tracks/burrows = +35
Total = +100 XP (Water Monitor reaches Level 2)
```

---

## 87. Nutria Colony

**LOCKED:** Environment: damaged wetland bank, feeding area, burrows, eroded bank, damaged vegetation. Combat: Normal Nutria → group pressure → Colony Defender. Colony Defender has more HP, stronger attacks, stronger knockback, slower movement, longer commitment (Not a Chimera).

---

## 88. Nutria XP Draft

**DRAFT:**
```text
Investigate colony = +40
Defeat nutria group = +60
Colony Defender = +50
Total = +150 XP
```

---

## 89. Wetland Chimera

**LOCKED:** Species: Snail–Cane Toad Chimera. Opening: nutria flee → wetland becomes quiet → heavy movement → Chimera emerges → brief intimidation → full creature framing → boss name appears → objective appears. Do not create an artificial arena wall.

---

## 90. Chimera Phase 1

**LOCKED Core Attacks:** 1. Body Rush, 2. Tongue Strike, 3. Shell Roll, 4. Occasional Toxic Slime Burst. Purpose: movement, positioning, telegraphs, vulnerability.

---

## 91. Chimera Phase 2

**LOCKED Theme:** Toxic Territory. Attacks: Toxic Splash, Toxic Tongue, Shell Slam, Special Toxic Territory. Toxic zones must eventually disappear. The arena must not become permanently unusable.

---

## 92. Chimera Phase 3

**LOCKED Attacks:** Crushing Charge, Shell Crush, Toad Lunge. Special: Frenzied Rampage (Sequence: Charge → turn → body slam → recovery). Recovery creates vulnerability.

---

## 93. Chimera Weak Points

**LOCKED:** Examples: throat, underside, body opening. These are deterministic vulnerability windows. They are NOT random critical hits.

---

## 94. Genome Core Recovery

**LOCKED:** After Chimera defeat: Approach → automatic scan → GENOME CORE DETECTED → INTERACT — EXTRACT → Purification Module → GENOME CORE RECOVERED. No complicated minigame.

---

## 95. Wetland Restoration

**LOCKED Flow:** Restore damaged habitat → clear invasive material/debris → Purification Module → contamination decreases → water improves → vegetation recovers → insects return → wildlife returns. No crafting/minigame.

---

## 96. Wetland → Rainforest Transition

**LOCKED:** This is a physical transition. Path: marsh → riverbank → floodplain → forest edge → dense vegetation → rainforest. At the ecosystem boundary: GenoMorph detects ecosystem transition → player selects one Legacy Genome. No teleport or level-select feel.

---

## 97. Rainforest Opening

**LOCKED:** Human NPCs are intentionally avoided. Opening uses: Abandoned Logging Site. Flow: logging damage → stumps → sawdust → broken branches → disturbed soil → logs/tire tracks → displaced wildlife → damaged feeding ground → one trapped native animal → clear obstruction → animal escapes → biological signal. Keep this opening short.

---

## 98. Wild Boar

**LOCKED Role:** Charge / Power. Focus: momentum, charging, stamina, knockback, stagger, breaking obstacles. 
**PROVISIONAL/OPEN Abilities:** Headbutt, Tusk Strike, Front Hoof Slam. 
**PROVISIONAL/OPEN Ultimates:** Wild Charge, Unstoppable, Momentum Breaker.

---

## 99. Wild Boar Introduction

**LOCKED:** After Genome discovery: Wild Boar Genome → transformation → fallen tree → break/clear obstacle → invasive creatures revealed → immediate combat.

---

## 100. Pangolin

**LOCKED Role:** Armor / Defense.
**PROVISIONAL/OPEN:** rolling, hardening scales, deflection, counterattack, digging, hiding. Do not present them as final.

---

## 101. Eagle

**LOCKED Role:** Flight / Aerial.
**OPEN:** Flight system is OPEN. Do not assume advanced flight, complex aerial controls, or aerial combat system until explicitly approved.

---

## 102. Mountain Progression

**LOCKED Progression:** Tamaraw → Bear → Goat.
**OPEN:** Detailed kits remain OPEN. Do not invent final mechanics.

---

## 103. Full Game Structure

**LOCKED Structure:**
**Act I — Wetlands:** Prologue → Frog → Rats → Salamander → Water Monitor → Nutria → Wetland Chimera → Genome Core → Restoration.
**Act II/III:** Wetland → Rainforest transition → Legacy Genome selection.
**Rainforest:** Logging aftermath → Wild Boar → Pangolin → Eagle → Rainforest Chimera → Genome Core → Restoration.
**Mountain:** Transition → Legacy Genome → Tamaraw → Bear → Goat → Mountain Chimera → Restoration.
**Endgame:** Final restoration → final Sterling sequence → ending. (Latter sections are higher-level/provisional).

---

## 104. Current Implementation Status

**IMPLEMENTED:**
* Frog model/form, third-person camera, movement, Frog Basic Attack, Frog Skill 1, Frog Skill 2, Mosquito model, Mosquito animation assets.
**IN DEVELOPMENT:**
* Core combat foundation, Base Enemy architecture, Mosquito functional behavior, Player Health/damage integration, Damage cooldown, Player hit reaction.
**PLANNED:**
* Interaction system, Progression system, Rat, Salamander, Species switching, Water Monitor, etc.

---

## 105. Implementation Roadmap

**LOCKED Roadmap:**
* **Phase 0:** Existing Frog foundation.
* **Phase 1 (Core combat):** 1. Player Health, 2. Base Enemy, 3. Enemy AI, 4. Mosquito, 5. Frog vs Mosquito, 6. Interaction, 7. Investigation card, 8. Quest/objectives, 9. Q01 environment, 10. Sterling radio, 11. Complete Q01.
* **Phase 2 (Adaptive Progression):** 12. XP, 13. Level, 14. AP, 15. Attributes, 16. Adaptation screen, 17. Genome, 18. Ultimate progression.
* **Phase 3 (Frog → Salamander):** 19. Rat, 20. Q02, 21. Q03, 22. Genome Discovery, 23. Transformation, 24. Salamander.
* **Phase 4 (Switching):** 25. Shared Health, 26. Shared Stamina, 27. Shared Ultimate, 28. Species Switching, 29. Species progression.
* **Phase 5 (Water Monitor/Wetlands):** 30. Snake, 31. Q04, 32. Water Monitor, 33. Water Monitor introduction, 34. Nutria, 35. Chimera, 36. Genome Core, 37. Restoration.
* **Future:** Rainforest, Mountain, Endgame.

---

## 106. Technical Data Models

Conceptual data structures separating base definitions from active progression:

**SpeciesData**
```text
speciesID, speciesName, baseHealth, baseAttackPower, baseStamina, baseStaminaRecovery, baseCooldown, baseHealthRecovery, basicAttack, skill1, skill2, attackUltimate, defenseUltimate, agilityUltimate
```
**SpeciesProgression**
```text
speciesID, isUnlocked, currentXP, currentLevel, unspentAdaptationPoints, healthUpgradeCount, attackPowerUpgradeCount, staminaUpgradeCount, staminaRecoveryUpgradeCount, cooldownReductionUpgradeCount, healthRecoveryUpgradeCount, genomesEarned, genomesSpent, genomesAvailable, attackUltimateLevel, defenseUltimateLevel, agilityUltimateLevel, equippedUltimateCategory
```

---

## 107. Required Formula Reference

All core formulas centralized:

* **XP level-up**: `currentXP += XPReward` (Accumulate XP across thresholds).
* **Total AP**: `(CurrentLevel - 1) × 2` (Grants 2 AP per level starting at Lv2).
* **Generic attribute**: `Base × (1 + 0.05 × Upgrades)` (Calculates linear 5% boost from base).
* **Cooldown**: `BaseCooldown × (1 - 0.03 × Upgrades)` (Calculates linear 3% reduction).
* **Genome milestone**: `floor(Upgrades / 5)` (Yields 1 Genome per 5 upgrades in a single stat).
* **Shared stamina clamp**: `min(CurrentStamina, NewMaxStamina)` (Stamina is conserved but capped by the new form).
* **Player damage**: `FinalAttackPower × AbilityMultiplier` (Direct damage output against enemies).
* **Enemy damage**: `BaseEnemyDamage × AttackVariant × AreaEncounterScaling` (Scales enemy output).
* **Enemy HP**: `BaseHP × VariantMultiplier × AreaEncounterMultiplier` (Calculates enemy durability without using arbitrary RPG stats).

---

## 108. Required Locked-Decision Table

| System | Decision | Status |
|---|---|---|
| Health | Shared player Health | LOCKED |
| Stamina | Shared current, species-specific max | LOCKED |
| Ultimate Charge | Shared | LOCKED |
| Species switching | During/outside combat | LOCKED |
| Transformation | 1–2 sec | LOCKED |
| Switch cooldown | Starts after transformation | LOCKED |
| Player hit reaction | Brief flinch | LOCKED |
| Player movement during hit | Remains controllable | LOCKED |
| Player damage cooldown | Brief cooldown | LOCKED |
| Critical hits | None | LOCKED |
| Enemy Defense | None for normal enemies | LOCKED |
| Enemy HP | Base + variants + controlled scaling | LOCKED |
| Enemy damage | Base + variants + scaling | LOCKED |
| Hit count | Ability-dependent | LOCKED |
| XP | Species-specific | LOCKED |
| Level cap | 15 | DRAFT/WORKING |
| AP | 2 per level | LOCKED |
| Attribute upgrades | Player-selected | LOCKED |
| Genome | 5 same-attribute upgrades | LOCKED |
| Ultimate | 3 paths × 3 levels | LOCKED |
| Free Ultimate swapping | Not allowed | LOCKED |
| Quest guidance | Hybrid | LOCKED |
| Optional discoveries | Environmental clues | LOCKED |
| Optional rewards | Knowledge + small XP | LOCKED |
| Death | Checkpoint respawn | LOCKED |
| Healing | Environmental | LOCKED |
| Enemy AI | Reusable archetypes + specific behavior | LOCKED |

---

## 109. Required Open-Decision Table

| System | Open Item |
|---|---|
| Player Health | Exact base value |
| Damage cooldown | Exact duration |
| Species switch | Exact cooldown |
| Attribute caps | Not finalized |
| Mosquito | Exact damage |
| Mosquito | Exact detection radius |
| Mosquito | Exact attack range |
| Mosquito | Exact attack cooldown |
| Enemy scaling | Exact multipliers |
| Ultimate | Exact numerical values |
| Eagle | Flight implementation |
| Pangolin | Final ability details |
| Mountain | Species kits |
| Chimera | Final numerical balance |

---

## 110. Required Balance Table

| Element | Value | Status | Purpose | Tunable |
|---|---|---|---|---|
| Mosquito HP | ~100 | DRAFT | First normal enemy | YES |
| Rat HP | ~180 | DRAFT | Basic swarm enemy | YES |
| Snake HP | ~300 | DRAFT | Early tough enemy | YES |
| Nutria HP | ~450 | DRAFT | Mid-wetland bruiser | YES |
| Colony Defender HP | ~1,500 | DRAFT | Mini-boss equivalent | YES |
| Mosquito Damage | ~10 | DRAFT | First attack benchmark | YES |

---

## 111. Implementation Rules for Future AI Agents

1. Read this document before implementing systems.
2. Never overwrite locked decisions.
3. Never invent missing mechanics.
4. Use data-driven values.
5. Keep formulas centralized.
6. Keep species data separate from progression.
7. Keep shared player resources separate from species progression.
8. Use reusable enemy architecture.
9. Ask for a design decision only when an unresolved choice materially changes gameplay.
10. Do not treat recommendations as locked.
11. Do not treat draft numbers as final.
12. Report implementation status after each milestone.

---

## 112. Current State Summary

### Implemented
* Frog model/form, third-person camera, movement, Frog Basic Attack, Frog Skill 1, Frog Skill 2.
* Mosquito model and Mosquito animation assets.
* Phase 1 combat core: player health tracking, base enemy logic, mosquito lunge behavior, damage calculation script.

### Locked
* Shared player resource systems, attribute calculation math, progression design, XP design, overall game flow, and biome hierarchy.

### In Development
* Phase 1 combat systems and mosquito complete tuning.

### Planned
* Interaction system, investigation card, UI, and further Phase 1 Q01 objectives.

### Open
* Final tuning values, cooldown timers, ultimate durations.

### Balance/Tuning
* Mosquito HP, Mosquito attack distance, player damage values.

### Immediate Next Development Task
The immediate development priority is:
> **Complete the Frog vs Mosquito combat loop using the existing Mosquito model and animations.**
