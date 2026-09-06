# GENOMORPH — ADAPTIVE PROGRESSION SYSTEM

### Implementation Specification / AI Agent Reference

**System name:** Adaptive Progression System
**Primary purpose:** Manage XP, species levels, attribute development, Genome acquisition, and Ultimate specialization for every playable animal.

---

# 1. SYSTEM OVERVIEW

GenoMorph does **not** use one universal character progression level.

Every playable animal species has its **own independent progression profile**.

Example:

```text
FROG
Level: 5
XP: 620 / 700
Attribute Points Available: 0
Health Upgrades: 1
Attack Upgrades: 1
Stamina Upgrades: 3
Stamina Recovery Upgrades: 0
Cooldown Reduction Upgrades: 0
Health Recovery Upgrades: 0
Genomes Earned: 0
Equipped Ultimate: Swamp Runner Lv1
```

The player can later switch to:

```text
SALAMANDER
Level: 3
XP: 280 / 450
...
```

The Salamander's progression is unaffected by the Frog's progression.

---

# 2. CORE PROGRESSION HIERARCHY

The entire system follows this relationship:

```text
GAMEPLAY
   ↓
ADAPTATION XP
   ↓
ADAPTATION LEVEL
   ↓
+2 ADAPTATION POINTS
   ↓
BIOLOGICAL ATTRIBUTE UPGRADES
   ↓
5 UPGRADES IN ONE ATTRIBUTE
   ↓
GENOME
   ↓
ULTIMATE ADAPTATION
   ↓
Ultimate Lv1 → Lv2 → Lv3
```

There is a separate system for **unlocking species**:

```text
GENOME DISCOVERY
      ↓
GENOME COMPATIBILITY
      ↓
TRANSFORMATION UNLOCKED
      ↓
NEW SPECIES
      ↓
SPECIES HAS ITS OWN XP/LEVEL/ATTRIBUTES/GENOMES
```

**Important:**

Species transformation is **not caused by XP or Level**.

A player does not reach Level 5 and automatically evolve.

Instead:

> Discover compatible biological genome → stabilize it → unlock transformation.

---

# 3. TERMINOLOGY

Use these names consistently in the game code, documentation, and UI.

| Concept                            | Official Name                               |
| ---------------------------------- | ------------------------------------------- |
| Overall progression                | **Adaptive Progression System**             |
| XP                                 | **Adaptation XP**                           |
| Level                              | **Adaptation Level**                        |
| Stat currency                      | **Adaptation Points**                       |
| Stats                              | **Biological Attributes**                   |
| Major milestone currency           | **Genome**                                  |
| Ultimate ability system            | **Ultimate Adaptation**                     |
| Animal's complete progression data | **Adaptation Profile**                      |
| Species unlock                     | **Genome Discovery / Genome Compatibility** |
| Species carried between biomes     | **Legacy Genome**                           |

---

# 4. SPECIES PROGRESSION

Each playable species must have an independent `AdaptationProfile`.

At minimum, the system must support:

```text
Frog
Salamander
Water Monitor
Wild Boar
Pangolin
Eagle
Tamaraw
Bear
Goat
```

Future species must use the same progression architecture.

---

# 5. ADAPTATION PROFILE DATA

Each species should maintain something equivalent to:

```text
AdaptationProfile

speciesID
speciesName

isUnlocked

currentXP
currentLevel

unspentAdaptationPoints

attributeUpgrades
    health
    attackPower
    stamina
    staminaRecovery
    cooldownReduction
    healthRecovery

genomesAvailable

ultimateProgression
    attack
        level
    defense
        level
    agility
        level

equippedUltimate
```

Additional data can be added later, but the above represents the required progression state.

---

# 6. SPECIES UNLOCK STATE

Each species has an independent unlock state.

Example:

```text
Frog
isUnlocked = true

Salamander
isUnlocked = true

Water Monitor
isUnlocked = true

Wild Boar
isUnlocked = false
```

Unlocking is triggered by the story's **Genome Discovery** system.

Example:

```text
Player finds Salamander Genome
        ↓
DSEE analyzes genome
        ↓
Compatibility confirmed
        ↓
Transformation available
        ↓
Salamander.isUnlocked = true
```

The system must **not** automatically award XP or Attribute Points simply because a species was unlocked.

The newly unlocked animal begins its progression independently.

---

# 7. ADAPTATION XP

## Purpose

Adaptation XP represents the experience gained by the **currently active species**.

If Frog is active:

```text
XP reward → Frog XP
```

If Salamander is active:

```text
XP reward → Salamander XP
```

If Water Monitor is active:

```text
XP reward → Water Monitor XP
```

---

# 8. XP SOURCES

XP can be awarded for:

### Main progression

* Completing quests
* Completing major objectives
* Major environmental discoveries
* Habitat restoration
* Genome discoveries
* Defeating major enemies
* Chimera encounters

### Secondary progression

* Combat encounters
* Exploration discoveries
* Wildlife observations
* Optional environmental interactions
* Optional activities

The exact XP values remain **BALANCING DRAFT**.

---

# 9. ENCOUNTER XP

The system should favor **encounter-based XP** rather than individual-kill XP.

Bad implementation:

```text
Rat killed = 10 XP

Rat killed = 10 XP

Rat killed = 10 XP

Rat killed = 10 XP
```

This encourages grinding.

Preferred:

```text
Rat Encounter Completed
→ +50 Adaptation XP
```

The encounter manager can track the individual enemies internally, but the XP reward is granted when the meaningful encounter objective is completed.

Example:

```text
Encounter:
Invasive Rat Group

Enemies:
Rat 1
Rat 2
Rat 3
Rat 4

Completion:
All rats defeated / encounter resolved

Reward:
+50 XP
```

---

# 10. XP MUST NOT REQUIRE GRINDING

The player should be able to progress through the main game without farming enemies.

Main story XP should provide the majority of normal progression.

Optional exploration can provide additional XP.

The player who explores more can become more developed, but the player who follows the main story should remain adequately powered.

---

# 11. XP LEVEL CAP

## LOCKED

Each species has:

**Level 1 → Level 15**

Maximum:

```text
Level = 15
```

XP beyond the Level 15 requirement should not increase the level beyond 15.

Recommended implementation:

```text
if currentLevel >= 15:
    currentLevel = 15
    XP progression stops at cap
```

The exact handling of excess XP can be decided later.

---

# 12. CURRENT XP CURVE

### BALANCING DRAFT

Use this table as the current baseline.

| Level | Total XP Required |
| ----: | ----------------: |
|     1 |                 0 |
|     2 |               100 |
|     3 |               250 |
|     4 |               450 |
|     5 |               700 |
|     6 |             1,000 |
|     7 |             1,350 |
|     8 |             1,750 |
|     9 |             2,200 |
|    10 |             2,700 |
|    11 |             3,250 |
|    12 |             3,850 |
|    13 |             4,500 |
|    14 |             5,200 |
|    15 |             6,000 |

The values are **not final production balance**.

The progression architecture must remain compatible with changing these numbers.

---

# 13. XP REQUIRED BETWEEN LEVELS

For implementation/testing:

| From | To | XP Required |
| ---: | -: | ----------: |
|    1 |  2 |         100 |
|    2 |  3 |         150 |
|    3 |  4 |         200 |
|    4 |  5 |         250 |
|    5 |  6 |         300 |
|    6 |  7 |         350 |
|    7 |  8 |         400 |
|    8 |  9 |         450 |
|    9 | 10 |         500 |
|   10 | 11 |         550 |
|   11 | 12 |         600 |
|   12 | 13 |         650 |
|   13 | 14 |         700 |
|   14 | 15 |         800 |

---

# 14. XP PROCESSING

Whenever the game awards Adaptation XP:

```text
AwardXP(amount, activeSpecies)
```

Example:

```text
AwardXP(50, Frog)
```

The system:

```text
Frog.currentXP += 50
```

Then checks:

```text
while currentXP >= XPRequiredForNextLevel
    and currentLevel < 15:

    currentLevel += 1
    grant 2 Adaptation Points
    trigger LevelUp event
```

This `while` behavior is important.

If a future quest awards enough XP to cross multiple thresholds, the system must correctly process multiple level-ups.

However, the game UI should avoid overwhelming the player with multiple simultaneous screens.

---

# 15. LEVEL-UP REWARD

## LOCKED

Every level gained awards:

**+2 Adaptation Points**

Level 1 begins with:

```text
0 Adaptation Points
```

Level 2:

```text
2
```

Level 3:

```text
4
```

...

Level 15:

```text
28 total earned
```

Formula:

```text
TotalAdaptationPointsEarned =
    (CurrentLevel - 1) × 2
```

At Level 15:

```text
(15 - 1) × 2
= 28
```

---

# 16. ADAPTATION POINTS

Adaptation Points are **spent manually by the player**.

They are not automatically assigned.

The player chooses which Biological Attributes to improve.

Example:

```text
Available Points = 2
```

Player selects:

```text
+1 Stamina
+1 Cooldown Reduction
```

Result:

```text
Available Points = 0

Stamina Upgrades += 1
Cooldown Reduction Upgrades += 1
```

---

# 17. BIOLOGICAL ATTRIBUTES

There are exactly six current attributes.

## 1. Health

Controls maximum health.

Current draft:

```text
+5% base maximum Health per upgrade
```

---

## 2. Attack Power

Controls damage output.

Current draft:

```text
+5% base Attack Power per upgrade
```

---

## 3. Stamina

Controls maximum stamina.

Current draft:

```text
+5% base Stamina per upgrade
```

---

## 4. Stamina Recovery

Controls stamina regeneration.

Current draft:

```text
+5% base Stamina Recovery per upgrade
```

---

## 5. Cooldown Reduction

Reduces ability cooldowns.

Current draft:

```text
-3% cooldown per upgrade
```

---

## 6. Health Recovery

Improves health recovery.

Current draft:

```text
+5% base Health Recovery per upgrade
```

---

# 18. ATTRIBUTE CALCULATION

Do **not** compound percentage increases.

Use the species' base stat.

For a +5% attribute:

```text
FinalStat =
    BaseStat × (1 + 0.05 × UpgradeCount)
```

Example:

Frog:

```text
Base Health = 100
Health upgrades = 6
```

Calculation:

```text
100 × (1 + 0.05 × 6)

= 100 × 1.30

= 130
```

Therefore:

**6 upgrades = +30%**

not:

```text
100 × 1.05 × 1.05 × 1.05...
```

---

# 19. COOLDOWN CALCULATION

Cooldown Reduction uses the same conceptual approach but reduces the original cooldown.

Current draft:

```text
FinalCooldown =
    BaseCooldown × (1 - 0.03 × CooldownUpgradeCount)
```

Example:

```text
Base cooldown = 10 seconds
Cooldown upgrades = 5
```

```text
10 × (1 - 0.15)
= 8.5 seconds
```

The player-facing stat is still called:

**Cooldown Reduction**

The internal implementation may represent this as a multiplier/rate if preferred.

---

# 20. ATTRIBUTE UPGRADE COUNTER

Each species tracks its own upgrade count.

Example:

```text
Frog:
Health = 2
Attack = 1
Stamina = 4
StaminaRecovery = 1
Cooldown = 0
HealthRecovery = 0
```

These are **not shared** with other species.

Salamander has its own counters.

---

# 21. GENOME MILESTONE

## LOCKED

Whenever a species reaches:

**5 upgrades in the same Biological Attribute**

the species earns:

**1 Genome**

Example:

```text
Frog Stamina Upgrades:

1
2
3
4
5
```

On the fifth upgrade:

```text
Genome +1
```

---

# 22. GENOME CALCULATION

The system should detect every time an attribute crosses a multiple of five.

Formula:

```text
GenomeMilestones =
floor(AttributeUpgradeCount / 5)
```

However, because Genomes are consumed, maintain a separate record of:

```text
GenomesEarned
GenomesSpent
GenomesAvailable
```

Example:

```text
Stamina upgrades = 10

Milestones earned from Stamina = 2
```

If both Genomes have been spent:

```text
GenomesAvailable = 0
```

---

# 23. GENOMES ARE SPECIES-SPECIFIC

This is critical.

A Frog Genome cannot be used to upgrade Salamander's Ultimate.

Example:

```text
Frog Genomes = 2
Salamander Genomes = 1
Water Monitor Genomes = 0
```

When Frog is active:

```text
Frog Genomes are available.
```

When Salamander is active:

```text
Salamander Genomes are available.
```

---

# 24. GENOME IS NOT A PERMANENT STAT BONUS

A Genome does **not** automatically increase:

* Health
* Attack
* Stamina
* Recovery
* Cooldown

Its main purpose is:

**Ultimate Adaptation progression.**

This keeps the progression hierarchy clean.

---

# 25. GENOME CONSUMPTION

A Genome is consumed when used.

There are two valid uses.

### Use 1 — Upgrade current Ultimate

Example:

```text
Toxic Trail Lv1
+
1 Frog Genome
↓
Toxic Trail Lv2
```

Another Genome:

```text
Toxic Trail Lv2
+
1 Frog Genome
↓
Toxic Trail Lv3
```

---

### Use 2 — Change Ultimate specialization

Example:

```text
Current:
Toxic Trail Lv2
```

Player chooses:

```text
Survival Frenzy
```

Spend one Genome:

```text
Survival Frenzy Lv1
```

---

# 26. ULTIMATE SYSTEM

Every species has exactly three Ultimate categories:

```text
ATTACK
DEFENSE
AGILITY
```

Each category contains one Ultimate.

Each Ultimate has:

```text
Level 1
Level 2
Level 3
```

The player equips **one Ultimate at a time**.

---

# 27. ULTIMATE PROGRESSION

The progression is:

```text
Lv1 → Lv2 → Lv3
```

The player cannot skip levels.

Example:

```text
Toxic Trail Lv1
```

can become:

```text
Toxic Trail Lv2
```

but cannot become:

```text
Toxic Trail Lv3
```

with one Genome.

---

# 28. ULTIMATE SPECIALIZATION SWITCHING

Suppose:

```text
Equipped:
Toxic Trail Lv2
```

Player decides to use:

```text
Survival Frenzy
```

Spend:

```text
1 Genome
```

Result:

```text
Survival Frenzy Lv1
```

The old Toxic Trail progression is retained.

Example:

```text
Attack:
Toxic Trail Lv2

Defense:
Survival Frenzy Lv1

Agility:
Swamp Runner Lv0
```

If the player later switches back to Toxic Trail:

```text
Toxic Trail remains Lv2
```

They do **not** lose its previous level.

Another Genome is required to continue upgrading it.

This prevents switching from being a free respec.

---

# 29. ULTIMATE DATA MODEL

Each species should maintain:

```text
UltimateProgression

AttackUltimate
    ultimateID
    currentLevel

DefenseUltimate
    ultimateID
    currentLevel

AgilityUltimate
    ultimateID
    currentLevel

equippedUltimateCategory
```

Example:

```text
Frog

AttackUltimate:
    ToxicTrail
    Level 2

DefenseUltimate:
    SurvivalFrenzy
    Level 1

AgilityUltimate:
    SwampRunner
    Level 0

Equipped:
    Attack
```

`Level 0` means the Ultimate has not yet been unlocked/developed.

---

# 30. FROG ULTIMATES

## Attack — Toxic Trail

### Lv1

Frog enters a highly toxic state.

Effects include:

* Nearby enemies receive damage/poison.
* Movement creates a poisonous trail.
* Enemies touching the trail receive damage/poison.
* Existing trail can remain temporarily after Ultimate ends.

### Lv2

Improves offensive effectiveness.

Potential improvements:

* Higher poison damage
* Better application
* Improved duration

### Lv3

Further improves the adaptation.

Exact numerical values are **BALANCING DRAFT**.

---

## Defense — Survival Frenzy

Frog gains enhanced defensive capability.

Visual:

**Semi-transparent protective bubble/aura**

Important:

This is a **visual representation of the adaptation**, not a literal magical shield.

Possible improvements across levels:

* Damage resistance
* Defensive effectiveness
* Duration

Exact numbers remain open.

---

## Agility — Swamp Runner

Improves:

* Movement performance
* Stamina performance
* Mobility

Exact values remain open.

---

# 31. SALAMANDER ULTIMATES

## Attack — Toxic Predator

During the Ultimate:

* Bite becomes stronger/faster.
* Regenerative Skin becomes stronger.
* Toxic Secretion becomes stronger.
* Poison application becomes more effective.

Genome upgrades improve offensive adaptation.

---

## Defense — Regenerative Survivor

Provides:

* Damage resistance
* Increased Health Recovery

Visual:

Semi-transparent protective aura/bubble.

Genome upgrades improve:

* Damage reduction
* Recovery
* Duration

---

## Agility — Toxic Adaptation

Provides improved:

* Movement speed
* Stamina recovery
* Movement efficiency
* Dodge-related performance **if/when dodge exists**

Do not implement an unconfirmed dodge mechanic solely because the Ultimate references it.

---

# 32. WATER MONITOR ULTIMATES

## Attack — Crushing Maul

Water Monitor performs:

**Bite/Grab → One massive slam**

It does **not** repeatedly pound the target.

Normal target:

* High damage
* Powerful slam
* Nearby AoE
* Knockback
* Heavy stagger

Large/boss targets:

* Cannot be lifted
* Animation changes to a powerful bite-and-slam

---

## Defense — Iron Hide

Focus:

* Durability
* Damage resistance
* Staying power

Exact values remain open.

---

## Agility — Relentless Hunter

Focus:

* Sustained pursuit
* Hunting mobility
* Closing distance

Exact values remain open.

---

# 33. SPECIES IDENTITY MUST BE PRESERVED

The progression system must not allow every animal to become functionally identical.

Each species starts with different base statistics.

Current Wetlands draft:

| Attribute        | Frog | Salamander | Water Monitor |
| ---------------- | ---: | ---------: | ------------: |
| Health           |  100 |        125 |           180 |
| Attack Power     |  100 |        110 |           140 |
| Stamina          |  150 |        110 |           100 |
| Stamina Recovery | 120% |       100% |           80% |
| Cooldown Rate    | 100% |        95% |          110% |
| Health Recovery  |  80% |       150% |          100% |

These numbers are **BALANCING DRAFT**.

The important implementation requirement is that each species has its own base-stat profile.

---

# 34. SPECIES PROGRESSION EXAMPLE

Suppose Frog starts:

```text
Level 1
XP 0
Adaptation Points 0
```

Player earns:

```text
+100 XP
```

System:

```text
Frog XP = 100
Frog Level = 2
Adaptation Points = 2
```

Player spends:

```text
+1 Stamina
+1 Cooldown Reduction
```

Now:

```text
Stamina upgrades = 1
Cooldown upgrades = 1
Available Points = 0
```

Later:

```text
Frog reaches Level 3
```

Player receives:

```text
+2 Adaptation Points
```

Suppose both are spent on Stamina:

```text
Stamina upgrades = 3
```

Eventually:

```text
Stamina upgrades = 5
```

System detects:

```text
Genome milestone reached
```

and awards:

```text
Frog Genome +1
```

The player can then use the Genome on:

```text
Toxic Trail
```

---

# 35. FULL EXAMPLE OF A DEVELOPED FROG

Example only:

```text
FROG
-------------------------
Adaptation Level: 6
Adaptation XP: 1,000
Adaptation Points Earned: 10
Adaptation Points Available: 0

Biological Attributes
-------------------------
Health Upgrades: 2
Attack Upgrades: 1
Stamina Upgrades: 5
Stamina Recovery: 1
Cooldown Reduction: 1
Health Recovery: 0

Genome
-------------------------
Available: 1

Ultimate Adaptations
-------------------------
Attack: Toxic Trail Lv1
Defense: Survival Frenzy Lv0
Agility: Swamp Runner Lv0

Equipped:
Toxic Trail
```

This represents a player who has deliberately specialized toward stamina.

---

# 36. LEVEL-UP GAMEPLAY BEHAVIOR

When the player levels up:

### During normal gameplay

Show a brief:

**ANIMAL LEVEL UP!**

Then:

**+2 Adaptation Points**

Do not stop gameplay for an extended tutorial.

---

### During combat

Do **not** force the player into a full attribute menu in the middle of a fight.

Instead:

```text
ANIMAL LEVEL UP!
+2 ADAPTATION POINTS
```

The player can continue fighting.

After combat, they can open the progression screen and spend the points.

This prevents combat interruption.

---

# 37. GENOME NOTIFICATION

When a Genome is earned:

```text
GENOME ACQUIRED
```

or:

```text
NEW GENOME AVAILABLE
```

Do not automatically open the Ultimate screen during combat.

The Genome is a **reward**, not a forced interruption.

---

# 38. ATTRIBUTE SPENDING RULES

When the player opens the Adaptation Profile:

```text
Available Adaptation Points: 2
```

Each upgrade costs:

```text
1 Adaptation Point
```

The player can spend both on the same attribute.

Example:

```text
Attack +2
```

is valid.

Or:

```text
Health +1
Stamina +1
```

is valid.

---

# 39. ATTRIBUTE LIMITS

Currently:

**No individual attribute cap has been finalized.**

Do not invent one.

The theoretical maximum is constrained naturally by the 28 total points.

Example:

```text
28 points → Health
```

would produce:

```text
28 Health upgrades
```

if the game permits it.

Whether this should have a per-attribute cap is a future balancing decision.

The implementation should therefore make caps **data-driven**, not hard-coded.

---

# 40. GENOME MILESTONE EXAMPLE

With 28 total points, a player could theoretically distribute:

```text
Health 5
Attack 5
Stamina 5
Stamina Recovery 5
Cooldown 5
Health Recovery 3
```

This produces:

```text
5 Genome milestones
```

because five attributes have reached five upgrades.

However, this does **not** mean the player is guaranteed to have five usable Genomes simultaneously.

They may have already spent some.

---

# 41. EXPECTED NORMAL PROGRESSION

For balance, a typical fully developed species should generally earn approximately:

**3–4 Genome milestones**

rather than making five or six Genomes routine.

This is a **design target**, not a hard rule.

A highly specialized build could reach Genome milestones more quickly in a particular attribute.

---

# 42. TRANSFORMATION VS PROGRESSION

This distinction must be preserved in code.

### Transformation system

Responsible for:

```text
Genome discovery
Compatibility
Species unlock
Transformation
```

### Adaptive Progression System

Responsible for:

```text
XP
Level
Attribute Points
Attributes
Genome milestones
Ultimate progression
```

They interact, but they are not the same system.

---

# 43. EXAMPLE: SALAMANDER DISCOVERY

Player is Frog.

Story event:

```text
Salamander Genome detected.
```

Transformation system:

```text
Validate compatibility
Unlock Salamander
```

Result:

```text
Salamander unlocked
Salamander Level = 1
Salamander XP = 0
```

The player transforms.

The Salamander's first gameplay sequence then awards XP normally.

---

# 44. LEGACY GENOME INTERACTION

Legacy Genome does **not** transfer progression.

Suppose:

```text
Frog
Level 6
```

Player enters Rainforest and chooses Frog as Legacy Genome.

The Legacy Genome means:

> Frog remains available as the selected previous-biome species.

It does **not** mean:

```text
Rainforest species inherit Frog's level.
```

Frog keeps its own Adaptation Profile.

---

# 45. RETURNING TO A PREVIOUS BIOME

When returning to Wetlands:

```text
Frog
Salamander
Water Monitor
```

remain at their previously saved levels and progression.

Example:

```text
Frog Lv6
Salamander Lv4
Water Monitor Lv5
```

Nothing is reset.

---

# 46. SAVE DATA REQUIREMENTS

The save system should store progression **per species**.

Example conceptual save:

```text
SpeciesProgression:
{
    Frog:
    {
        unlocked: true,
        xp: 620,
        level: 5,
        adaptationPoints: 0,

        attributes:
        {
            health: 2,
            attack: 1,
            stamina: 3,
            staminaRecovery: 0,
            cooldownReduction: 0,
            healthRecovery: 0
        },

        genomesAvailable: 0,

        ultimates:
        {
            attack: 1,
            defense: 0,
            agility: 0
        },

        equippedUltimate: "attack"
    }
}
```

The exact serialization format depends on the engine.

---

# 47. IMPORTANT: DATA-DRIVEN DESIGN

Do not hard-code the progression directly into individual animal scripts.

Instead, create a generic progression system.

Conceptually:

```text
AdaptiveProgressionComponent
```

can be attached to every playable species.

Then species-specific data is supplied separately.

Example:

```text
SpeciesData_Frog
SpeciesData_Salamander
SpeciesData_WaterMonitor
```

This allows new animals to use the same progression system.

---

# 48. SPECIES DATA VS PLAYER PROGRESSION

Keep these separate.

### Species Data

Defines:

```text
Base Health
Base Attack
Base Stamina
Base Recovery
Base Cooldowns
Abilities
Ultimate definitions
Species identity
```

### Player Species Progression

Defines:

```text
Current XP
Level
Attribute upgrades
Available Adaptation Points
Genomes
Ultimate levels
Equipped Ultimate
```

This distinction is important.

For example, if designers change:

```text
Frog Base Health:
100 → 110
```

the player's:

```text
Health Upgrade Count = 5
```

does not need to change.

---

# 49. FINAL STAT CALCULATION PIPELINE

When the game needs a species' actual combat stat:

```text
Species Base Stat
        ↓
Apply Attribute Upgrade Modifier
        ↓
Apply temporary gameplay buffs/debuffs
        ↓
Final Runtime Stat
```

For example:

```text
Frog Base Health
= 100

Health upgrades
= 5

Attribute modifier
= +25%

Final permanent Health
= 125
```

Then if an Ultimate grants temporary +20% defense or health, that temporary effect is applied separately.

Do not permanently modify the base species data.

---

# 50. XP AND ATTRIBUTE SYSTEM SHOULD NOT DIRECTLY CHANGE ABILITIES

Attributes modify broad biological performance.

They should not automatically rewrite the ability's identity.

For example:

Increasing Attack Power:

```text
Webbed Lunge damage ↑
Sticky Tongue Whip damage ↑
Splashdown Jump damage ↑
```

But it should not suddenly give Frog:

```text
fire damage
armor
flight
```

Those are ability/adaptation-specific behaviors.

---

# 51. ULTIMATE LEVEL EFFECTS

The Ultimate system should be data-driven.

Example:

```text
ToxicTrail_Lv1
duration = 8
poisonDamage = X
trailDuration = Y

ToxicTrail_Lv2
duration = 8
poisonDamage = X2
trailDuration = Y2

ToxicTrail_Lv3
duration = 8
poisonDamage = X3
trailDuration = Y3
```

The exact values are **OPEN/BALANCING DRAFT**.

The progression framework does not depend on the final numbers.

---

# 52. ULTIMATE DURATION

The current general baseline is:

**approximately 8 seconds**

This is a balancing baseline, not a universal hard-coded requirement.

Different Ultimates may eventually need different durations.

Do not make the progression system assume every Ultimate must always last exactly 8 seconds.

---

# 53. NO AUTOMATIC "BEST BUILD"

The system should not recommend or force a single optimal attribute distribution.

The intended design is:

```text
Same species
+
Different attribute investment
+
Different Genome spending
=
Different playstyle
```

Example:

### Frog mobility build

```text
Stamina
Stamina Recovery
Cooldown
```

### Frog offensive build

```text
Attack
Cooldown
```

### Frog survival build

```text
Health
Health Recovery
```

All should remain viable.

---

# 54. BEGINNER-FRIENDLY PRESENTATION

The entire system should **not** be presented to the player at once.

Recommended progression of system introduction:

### Early game

Introduce:

```text
XP
Level
Adaptation Points
```

---

### After player understands leveling

Introduce:

```text
Biological Attributes
```

---

### Later

Introduce:

```text
Genome milestone
```

---

### After the player has enough reason to use it

Introduce:

```text
Ultimate Adaptation
```

This prevents the first 10 minutes of GenoMorph from becoming an RPG tutorial.

---

# 55. PLAYER-FACING PROGRESSION SCREEN

The player's Adaptation Profile could conceptually look like:

```text
────────────────────────
FROG
ADAPTATION PROFILE
────────────────────────

LEVEL 4
450 / 700 XP

ADAPTATION POINTS
2

BIOLOGICAL ATTRIBUTES

♥ Health              1
⚔ Attack Power        1
◉ Stamina             3
↻ Stamina Recovery    0
◌ Cooldown Reduction  1
✚ Health Recovery     0

GENOME
1 AVAILABLE

ULTIMATE ADAPTATION

ATTACK
Toxic Trail           Lv1

DEFENSE
Survival Frenzy       Lv0

AGILITY
Swamp Runner          Lv0

EQUIPPED
Toxic Trail
────────────────────────
```

The exact UI is **not locked**; this is an implementation representation.

---

# 56. WHAT IS LOCKED

The AI/game-development agent should treat these as established design rules:

### Progression architecture

**XP → Level → Adaptation Points → Attributes → Genome → Ultimate**

### Species progression

* Each animal has independent progression.
* Species XP is not shared.
* Species level is not shared.
* Attribute upgrades are not shared.
* Genomes are not shared.

### Level

* Level 1–15.
* Level 15 maximum.
* +2 Adaptation Points per level.
* 28 total points at Level 15.

### Attributes

Six:

1. Health
2. Attack Power
3. Stamina
4. Stamina Recovery
5. Cooldown Reduction
6. Health Recovery

### Genome

* Five upgrades in one attribute = one Genome.
* Genome belongs to the species.
* Genome is consumed when used.
* Genome can upgrade an Ultimate.
* Genome can switch Ultimate specialization.
* Ultimate levels cannot be skipped.

### Ultimates

Three categories:

* Attack
* Defense
* Agility

Each:

* Lv1
* Lv2
* Lv3

One Ultimate equipped at a time.

Switching Ultimate does not erase previous Ultimate progression.

---

# 57. WHAT IS NOT LOCKED

The AI agent **must not treat these as final**:

* Exact XP values
* Exact quest XP rewards
* Exact attribute percentages
* Exact Ultimate numerical effects
* Exact Ultimate duration
* Attribute caps
* Exact Genome frequency during the story
* Exact level reached at each quest
* Exact final combat balance
* Exact UI layout
* Exact animations

These are **balancing/implementation variables**.

They should be exposed as configurable data rather than hard-coded wherever practical.

---

# 58. CURRENT WETLANDS TARGET

As a balancing target, a story-focused player should roughly reach:

| Species       | Approximate Wetlands Level |
| ------------- | -------------------------: |
| Frog          |                        Lv4 |
| Salamander    |                        Lv3 |
| Water Monitor |                        Lv4 |

This is **not a mandatory outcome**.

Exploration-heavy players can be higher.

The important goal is:

> The player should not need to grind to remain effective.

---

# 59. THE DESIGN PHILOSOPHY

The AI agent should understand that GenoMorph's progression is **not primarily about making numbers bigger**.

It represents:

### Transformation

**What organism can I become?**

↓

### Adaptation Level

**How experienced/developed is this organism?**

↓

### Biological Attributes

**What aspects of this organism am I developing?**

↓

### Genome

**What major adaptation have I developed enough to access?**

↓

### Ultimate Adaptation

**How do I specialize that organism's strongest adaptation?**

That is the intended fantasy of the system.

---

# 60. COMPLETE SYSTEM IN ONE DIAGRAM

```text
                    GENOMORPH
              ADAPTIVE PROGRESSION
                       │
          ┌────────────┴────────────┐
          │                         │
   GENOME DISCOVERY          SPECIES PROGRESSION
          │                         │
          ↓                         ↓
 Genome Compatibility         Adaptation XP
          │                         │
          ↓                         ↓
     Transformation        Adaptation Level
          │                         │
          ↓                         ↓
   New Animal Species       +2 Adaptation Points
                                    │
                                    ↓
                          Biological Attributes
                                    │
              ┌───────────┬────────┼───────────┐
              ↓           ↓        ↓           ↓
            Health      Attack   Stamina    Recovery
              │           │        │           │
              └───────────┴────────┴───────────┘
                           │
                    5 upgrades in
                    same attribute
                           │
                           ↓
                        GENOME
                           │
                 ┌─────────┴─────────┐
                 ↓                   ↓
          Upgrade Ultimate     Switch Ultimate
                 │                   │
                 ↓                   ↓
              Lv1 → Lv2           New Path Lv1
                    │
                    ↓
                   Lv3
```

## The key rule for implementation

**Do not merge these systems together.**

Keep them modular:

```text
Species Unlock System
        ↓
Species/Genome Manager

Adaptive XP System
        ↓
Level System
        ↓
Adaptation Point System
        ↓
Attribute System
        ↓
Genome Milestone System
        ↓
Ultimate Progression System
```

That architecture will let the development team tune XP, stats, quest rewards, and Ultimate values later without having to redesign the entire progression system.

**This is the version I would give directly to an AI game-development agent as the current GenoMorph progression specification.**
