# GENOMORPH — MASTER GAME DESIGN DOCUMENT

**Project:** GenoMorph
**Genre:** Third-person 3D Action RPG
**Platform:** Mobile
**Setting:** Asia-inspired ecological region
**Document Status:** Current Master Design Baseline
**Last Consolidated:** September 2026

---

# TABLE OF CONTENTS

1. [GAME OVERVIEW](#1-game-overview)
2. [DESIGN PILLARS](#2-design-pillars)
3. [STORY & WORLD](#3-story--world)
4. [MAIN CHARACTERS](#4-main-characters)
5. [GENOMORPH TECHNOLOGY](#5-genomorph-technology)
6. [CORE GAMEPLAY LOOP](#6-core-gameplay-loop)
7. [WORLD & ECOSYSTEM STRUCTURE](#7-world--ecosystem-structure)
8. [TRANSFORMATION SYSTEM](#8-transformation-system)
9. [LEGACY GENOME SYSTEM](#9-legacy-genome-system)
10. [LEVELING & PROGRESSION](#10-leveling--progression)
11. [ATTRIBUTES](#11-attributes)
12. [GENOME SYSTEM](#12-genome-system)
13. [ULTIMATE SYSTEM](#13-ultimate-system)
14. [MOBILE CONTROLS & UI](#14-mobile-controls--ui)
15. [INVESTIGATION & KNOWLEDGE SYSTEM](#15-investigation--knowledge-system)
16. [COMBAT SYSTEM](#16-combat-system)
17. [WETLANDS — COMPLETE STORY PROGRESSION](#17-wetlands--complete-story-progression)
18. [NATIVE FROG RESCUE](#18-native-frog-rescue)
19. [SALAMANDER TRANSFORMATION](#19-salamander-transformation)
20. [SALAMANDER](#20-salamander)
21. [SALAMANDER DEEPER WETLANDS](#21-salamander-deeper-wetlands)
22. [INVASIVE SNAKE](#22-invasive-snake)
23. [DAMAGED WATER SOURCE](#23-damaged-water-source)
24. [WATER MONITOR GENOME](#24-water-monitor-genome)
25. [WATER MONITOR](#25-water-monitor)
26. [WATER MONITOR GAMEPLAY SECTION](#26-water-monitor-gameplay-section)
27. [NUTRIA / COYPU COLONY](#27-nutria--coypu-colony)
28. [CHIMERA LEAD-IN](#28-chimera-lead-in)
29. [CHIMERA TERRITORY](#29-chimera-territory)
30. [WETLANDS CHIMERA](#30-wetlands-chimera)
31. [CHIMERA PHASES](#31-chimera-phases)
32. [CHIMERA ATTACK DESIGN](#32-chimera-attack-design)
33. [USING THE "WRONG" ANIMAL](#33-using-the-wrong-animal)
34. [CHIMERA WEAK POINTS](#34-chimera-weak-points)
35. [WETLANDS CHIMERA DEFEAT](#35-wetlands-chimera-defeat)
36. [WETLAND RESTORATION](#36-wetland-restoration)
37. [CONSERVATION MESSAGE](#37-conservation-message)
38. [WETLAND → RAINFOREST TRANSITION](#38-wetland--rainforest-transition)
39. [RAINFOREST LEGACY GENOME CHOICE](#39-rainforest-legacy-genome-choice)
40. [RAINFOREST OPENING](#40-rainforest-opening)
41. [RAINFOREST DISCOVERY](#41-rainforest-discovery)
42. [ACTIVE LOGGING SITE — OPEN DESIGN](#42-active-logging-site--open-design)
43. [WILD BOAR](#43-wild-boar)
44. [PANGOLIN](#44-pangolin)
45. [EAGLE](#45-eagle)
46. [MOUNTAIN PROGRESSION](#46-mountain-progression)
47. [EDUCATIONAL DESIGN](#47-educational-design)
48. [KNOWLEDGE DATABASE](#48-knowledge-database)
49. [BRANCHING TRANSFORMATION SYSTEM](#49-branching-transformation-system)
50. [WHY BRANCHES MATTER](#50-why-branches-matter)
51. [SPECIES DESIGN PHILOSOPHY](#51-species-design-philosophy)
52. [CURRENT SPECIES IDENTITY MAP](#52-current-species-identity-map)
53. [PACING PHILOSOPHY](#53-pacing-philosophy)
54. [TUTORIAL STRUCTURE](#54-tutorial-structure)
55. [IMPORTANT DESIGN PRINCIPLE: PLAYER DISCOVERY](#55-important-design-principle-player-discovery)
56. [COMBAT DIFFICULTY PHILOSOPHY](#56-combat-difficulty-philosophy)
57. [CHIMERA DESIGN PHILOSOPHY](#57-chimera-design-philosophy)
58. [RESTORATION DESIGN PHILOSOPHY](#58-restoration-design-philosophy)
59. [WHAT IS CURRENTLY LOCKED](#59-what-is-currently-locked)
60. [CURRENTLY OPEN](#60-currently-open)
61. [DESIGN RULES FOR FUTURE DEVELOPMENT](#61-design-rules-for-future-development)
62. [RECOMMENDED DEVELOPMENT ORDER](#62-recommended-development-order)
63. [MASTER GAME FLOW](#63-master-game-flow)
64. [THE CORE IDENTITY OF GENOMORPH](#64-the-core-identity-of-genomorph)

---

# 1. GAME OVERVIEW

## 1.1 Game Concept

**GenoMorph** is a mobile third-person 3D action RPG centered around environmental restoration and biological adaptation.

The player explores damaged ecosystems and uses animal genomes to transform into different native species. Each animal provides a distinct set of biological abilities that can be used for:

* exploration
* combat
* environmental interaction
* survival
* investigation
* ecological restoration

The player is not simply becoming stronger through conventional RPG progression.

Instead:

> **The player becomes more adaptable.**

A Frog may be better at mobility and crowd control.

A Salamander may be better at recovery and poison.

A Water Monitor may be better at power and durability.

This means progression is about choosing the right biological toolkit for the situation.

---

# 2. DESIGN PILLARS

## 2.1 Action-Adventure First

GenoMorph should feel like an adventure game first.

The player should:

* explore
* discover
* fight
* investigate
* transform
* solve environmental problems
* restore ecosystems

Education should exist naturally inside those activities.

The game should **not feel like a science lesson disguised as a game.**

---

## 2.2 Education Through Gameplay

Scientific and ecological information should be discovered through:

* animal behavior
* environmental clues
* investigation
* combat abilities
* restoration
* Knowledge Database entries
* short radio conversations with Sterling

The player should learn **because the world demonstrates the information**, rather than because the game forces a long explanation.

---

## 2.3 Adaptation Rather Than Simple Power

A new animal is not automatically stronger than the previous animal.

Instead, every species should answer a different gameplay need.

For example:

| Animal        | Primary identity      |
| ------------- | --------------------- |
| Frog          | Mobility / Controller |
| Salamander    | Recovery / Poison     |
| Water Monitor | Power / Durability    |
| Wild Boar     | Charge / Momentum     |
| Pangolin      | Armor / Defense       |
| Eagle         | Aerial / Flight       |

An older animal should remain useful even after newer animals are unlocked.

---

## 2.4 Beginner-Friendly Mobile Design

The game is designed specifically for mobile.

Controls should therefore remain:

* readable
* simple
* responsive
* consistent between animals

The player should not have to learn an entirely new control scheme for every transformation.

---

## 2.5 Fast but Meaningful Pacing

The game should be fast-paced, but **not rushed**.

The intended pacing is:

> Explore → discover → act → experiment → progress.

Avoid:

* excessive grinding
* long forced tutorials
* unnecessary dialogue
* repetitive exposition
* long periods where the player cannot play

When the player unlocks something exciting, they should be allowed to use it quickly.

---

# 3. STORY & WORLD

# 3.1 The Ecological Crisis

The world once contained interconnected ecosystems.

These included:

* wetlands
* rainforests
* mountains
* coral reefs
* other ecological zones

Over decades, environmental damage accumulated.

Major causes include:

* industrial runoff
* pollution
* invasive species
* deforestation
* ocean acidification
* e-waste
* habitat destruction

The damage caused more than isolated environmental problems.

It disrupted the relationships between organisms.

Keystone species disappeared.

Food chains became unstable.

Invasive organisms expanded.

Eventually, entire ecosystems became biologically unstable.

---

# 3.2 Dr. Alistair Sterling

**Dr. Alistair Sterling** is a biomedical engineer.

He believes damaged ecosystems can recover if their biological systems are properly restored.

He spent approximately **11 years** developing genetic technology capable of interacting with animal DNA.

Sterling created the GenoMorph technology.

He is not physically accompanying the player throughout the world.

Instead, he remains at a distant laboratory.

---

# 3.3 The Player

The protagonist is:

* 18 years old
* male
* environmentally passionate
* highly compatible with GenoMorph technology
* capable of unusually strong neural adaptation

Sterling personally recruited him for the project.

The protagonist's rare compatibility is essential because the transformation system requires an unusually adaptable human nervous system.

---

# 3.4 The Opening Accident

The game begins with the player in human form.

Sterling conducts a field test of the GenoMorph Suit.

Something goes wrong.

Pollutants interact with the suit's biological systems.

This causes:

1. A power surge.
2. The DNA Sequence Engine to overload.
3. The stored genomes to discharge.
4. The released biological energy to spread into the environment.
5. Invasive organisms to absorb that energy.
6. Those organisms to mutate into **Invasive Chimeras**.

The player is caught in the malfunction.

When he wakes up, he is no longer human.

He is trapped in:

> **Small Native Frog form.**

The damaged suit cannot immediately return him to human form.

This becomes the beginning of the game.

---

# 4. MAIN CHARACTERS

## 4.1 Player

The player's immediate goal is survival and understanding what happened.

The larger objectives gradually become:

* restore ecosystems
* recover genomes
* investigate the Chimeras
* obtain Genome Cores
* repair the GenoMorph system
* eventually regain control over the transformation system

---

# 4.2 Sterling

Sterling functions as:

* scientific adviser
* radio contact
* story guide
* source of biological information

He should **not** function as:

* a constant narrator
* a quest marker explaining every action
* someone who tells the player exactly what to do every second

His dialogue should generally be contextual.

For example:

> Player discovers unusual biological evidence → Sterling reacts.

Rather than:

> Sterling explains everything before the player discovers anything.

---

# 5. GENOMORPH TECHNOLOGY

## 5.1 GenoMorph Suit

The player wears a biomedical suit containing the genetic transformation technology.

Its main system is the:

> **DNA Sequence Engine — DSEE**

---

## 5.2 Stored Genomes

The system is designed around **12 native species genomes**.

These genomes allow the player to access different animal forms.

The transformation is:

* biological
* genetic
* suit-assisted

It is **not magic**.

---

# 5.3 Why the Suit Is Important to Gameplay

The opening accident damaged the GenoMorph system.

This damage explains an important gameplay limitation:

> The player cannot freely carry every animal genome between every ecosystem.

This leads to the **Legacy Genome System**.

---

# 6. CORE GAMEPLAY LOOP

The primary loop is:

**EXPLORE**

↓

**DISCOVER ENVIRONMENTAL PROBLEM**

↓

**INVESTIGATE**

↓

**QUEST / COMBAT**

↓

**RESTORE HABITAT**

↓

**DISCOVER GENOME**

↓

**TRANSFORM**

↓

**EXPERIMENT WITH NEW FORM**

↓

**EXPLORE DEEPER**

↓

**RESTORE NEXT ECOSYSTEM**

The loop repeats while introducing increasingly different animals, environments, threats, and ecological problems.

---

# 7. WORLD & ECOSYSTEM STRUCTURE

The world is semi-open and interconnected.

The player should physically travel from one ecosystem to another.

There should not be a feeling of:

> "Select Level 2."

Instead:

> Wetland → riverbank → floodplain → forest edge → rainforest.

The environment itself communicates progression.

---

## 7.1 Wetlands

Transformation order:

**Frog → Salamander → Water Monitor**

---

## 7.2 Rainforest

Transformation order:

**Wild Boar → Pangolin → Eagle**

---

## 7.3 Mountain

Transformation order:

**Tamaraw → Bear → Goat**

---

## 7.4 Future Content

The long-term plan contains:

* 12 total story genomes
* 9 planned for the base game
* 3 planned for future updates/DLC

The final future species are not yet finalized.

---

# 8. TRANSFORMATION SYSTEM

Transformations are not conventional RPG upgrades.

The player does not simply go:

> Frog Level 15 → stronger animal → Salamander Level 1 → automatically better.

Instead:

Each species has its own identity.

---

## 8.1 Species Levels

Each species has its own level.

Current recommended maximum:

> **Level 15**

This keeps progression substantial without creating excessive mobile-game grinding.

---

## 8.2 Species Independence

Frog progression belongs to Frog.

Salamander progression belongs to Salamander.

Water Monitor progression belongs to Water Monitor.

A player cannot simply transfer all of Frog's biological development to Salamander.

---

# 9. LEGACY GENOME SYSTEM

This is one of the major systems of GenoMorph.

When the player enters a new biome, they can bring:

> **ONE species from the previous biome.**

That species becomes the player's:

> **Legacy Genome**

---

## 9.1 Example

Wetlands contains:

* Frog
* Salamander
* Water Monitor

Once the player reaches Rainforest, they choose one.

For example:

> Water Monitor = Legacy Genome

The Rainforest then contains:

* Water Monitor — Legacy Genome
* Wild Boar
* Pangolin
* Eagle

---

## 9.2 What Happens to the Other Animals?

They are **not lost**.

They remain stored in the GenoMorph system.

When the player returns to Wetlands, those genomes can become active again.

---

## 9.3 Why Only One?

The damaged suit can stabilize multiple compatible genomes within their native ecosystem.

However, crossing into a different ecological zone creates additional biological stress.

Maintaining all three previous-biome genomes outside their ecosystem could cause another overload.

Therefore:

> One previous-biome genome can be stabilized safely.

---

## 9.4 Design Purpose

The Legacy Genome system:

* preserves biome identity
* makes transitions meaningful
* prevents the player from bringing the entire roster everywhere
* keeps old animals relevant
* creates playstyle choices
* gives players reasons to revisit old biomes

The choice should affect **how the player experiences the next biome**, not whether they can finish the main story.

---

# 10. LEVELING & PROGRESSION

The recommended progression hierarchy is:

### Level

How developed the animal is.

### Attributes

Where the player chooses to develop that animal.

### Genome

A biological adaptation milestone earned through attribute development.

### Ultimate

The player's chosen specialization.

---

# 10.1 Level Cap

Recommended:

> **Level 15 per species**

---

## 10.2 Level Purpose

| Level | Purpose                   |
| ----- | ------------------------- |
| 1–3   | Learn the animal          |
| 4–6   | Begin preferred playstyle |
| 7–9   | Build specialization      |
| 10–12 | Develop customized animal |
| 13–14 | High specialization       |
| 15    | Fully developed species   |

This is a **design target**, not yet a final numerical balance.

---

# 11. ATTRIBUTES

There are six attributes.

| Attribute          | Function                       |
| ------------------ | ------------------------------ |
| Health             | Maximum survivability          |
| Attack Power       | Damage output                  |
| Stamina            | Stamina capacity               |
| Stamina Recovery   | Stamina recovery               |
| Cooldown Reduction | Ability cooldown reduction     |
| Health Recovery    | Healing/recovery effectiveness |

---

## 11.1 Attribute Investment

The player receives Attribute Points from progression and rewards.

The player decides where to spend them.

This allows two players using the same animal to build it differently.

For example:

### Frog A

High:

* Stamina
* Stamina Recovery
* Cooldown Reduction

This creates a highly mobile ability-focused Frog.

### Frog B

Higher:

* Health
* Attack Power

This creates a more aggressive and durable Frog.

---

## 11.2 Reward Philosophy

Normal progression should provide Attribute Points.

Additional rewards may come from:

* quests
* milestones
* discoveries
* achievements
* restoration

Different reward amounts may be used, such as:

* 1
* 2
* 3
* 5

The exact economy is still OPEN.

---

# 12. GENOME SYSTEM

A Genome is earned when an attribute has been upgraded:

> **5 times**

The Genome belongs to that species.

Example:

> Frog Attribute Development → 5 upgrades → Frog Genome

It cannot be transferred to Salamander.

---

## 12.1 Why This Matters

The Genome represents more than another stat increase.

It represents:

> **A significant biological adaptation milestone.**

The player has developed a particular aspect of an animal enough to unlock deeper specialization.

---

# 13. ULTIMATE SYSTEM

Every species has three Ultimate paths:

### Attack

Offensive specialization.

### Defense

Survivability specialization.

### Agility

Movement/mobility specialization.

Each Ultimate has:

* Level 1
* Level 2
* Level 3

The player equips one Ultimate at a time.

---

## 13.1 Genome + Ultimate

A Genome can:

* improve the currently selected Ultimate
* allow the player to switch to another Ultimate path

Once the player changes Ultimate specialization, another change requires another Genome.

This makes Ultimate decisions meaningful.

---

# 14. MOBILE CONTROLS & UI

Current confirmed controls:

| Control               | Function                |
| --------------------- | ----------------------- |
| Left virtual joystick | Movement                |
| Right swipe/drag      | Camera                  |
| Attack                | Basic attack            |
| Skill 1               | First skill             |
| Skill 2               | Second skill            |
| Ultimate              | Ultimate                |
| Interact              | Contextual interaction  |
| Knowledge Database    | Scientific information  |
| Pause/Main Menu       | Menu                    |
| Perspective           | Third-person ↔ top-down |
| Minimap               | Navigation              |
| Dialogue Log          | Dialogue history        |

---

## 14.1 Frog Movement

Frog automatically hops while moving.

There is no separate jump button.

When stationary, Frog has an idle animation.

---

## 14.2 Unconfirmed Mechanics

Do **not** currently treat the following as established:

* sprint
* dodge
* swimming
* deep swimming
* underwater combat
* diving
* advanced climbing
* parkour
* grappling
* burrowing
* ocean exploration
* advanced flight controls

These remain open unless specifically decided later.

---

# 15. INVESTIGATION & KNOWLEDGE SYSTEM

Investigation is deliberate.

The player:

1. Approaches something interesting.
2. Uses **Interact**.
3. Receives information.

There is no random investigation selection menu.

---

## 15.1 First Investigation

The player can choose which clue to investigate.

The first investigated clue becomes the clue that advances the quest.

Other clues remain optional.

---

## 15.2 Information Layers

Information uses three levels:

### Layer 1 — Brief Explanation

Required information.

### Layer 2 — Learn More

Optional additional explanation.

### Layer 3 — Knowledge Database

Full scientific/ecological information.

This prevents players from being trapped in long explanations.

---

# 16. COMBAT SYSTEM

The standard combat layout is:

**Basic Attack + Skill 1 + Skill 2 + Ultimate**

Combat does not have to occur in every quest.

Some quests can focus on:

* exploration
* investigation
* restoration
* environmental interaction
* wildlife

---

## 16.1 Major Chimeras

Chimeras are major encounters.

They:

* have multiple phases
* change behavior
* react to the player's current animal
* create different combat situations

---

## 16.2 Weak Point System

The intended sequence is:

**Major attack**

↓

**Attack finishes**

↓

**Short vulnerability**

↓

**Weak point appears**

↓

**Short attack window**

↓

**Weak point disappears**

The weak point is biologically justified.

---

## 16.3 Weak Point Results

Successful weak-point attacks produce:

* increased damage
* brief stagger
* clear biological reaction

---

# 17. WETLANDS — COMPLETE STORY PROGRESSION

This is currently the most developed biome.

---

# 17.1 First Awakening

The player wakes as Frog.

Sterling establishes only the immediate situation.

He does not explain the entire game.

The player then tests Frog abilities.

---

# 17.2 Initial Environment

The area is relatively safe.

The first environmental danger is not an immediate large combat encounter.

The player notices:

* polluted water
* damaged vegetation
* human debris / signs of human activity

The purpose is to establish:

> Something is wrong with this ecosystem.

---

# 17.3 Investigation

The player chooses something to investigate.

Possible environmental clues are presented differently depending on what was selected.

The first investigated clue advances the quest.

---

# 17.4 Environmental Event

Sterling reacts to the investigation.

Then:

> One mosquito appears.

The player attacks it.

After it is defeated:

> A mosquito swarm arrives.

---

# 17.5 Frog Combat Introduction

The combat tutorial is integrated into the encounter.

The abilities are introduced in sequence:

1. Basic Attack
2. Skill 1
3. Skill 2

The player still has access to the complete Frog kit rather than being artificially locked behind multiple tutorial gates.

The Ultimate is introduced later.

---

# 17.6 Larger Environmental Reveal

After the mosquito swarm, the environment reveals a larger problem.

The player notices:

* more pollution
* damaged areas
* organisms affected by the disturbance
* invasive creatures deeper inside the wetlands

Sterling briefly reacts.

---

# 17.7 First General Objective

The player receives:

> **Investigate the disturbance.**

A visible waypoint appears.

The waypoint points toward a general area of interest rather than forcing an exact path.

---

# 17.8 Polluted Area

The waypoint leads to:

* heavily polluted environment
* invasive creatures
* obvious ecological damage

The player first observes the ecological impact.

Then the creatures become hostile.

---

# 17.9 Invasive Rat

The first larger invasive enemy is:

> **Invasive Rat**

The encounter begins with:

> One rat.

Then:

> Additional rats arrive.

The exact teaching structure of this encounter remains **OPEN**.

---

# 18. NATIVE FROG RESCUE

The player eventually discovers another native frog affected by the damaged ecosystem.

The habitat is being affected by:

* invasive rats
* environmental damage

The player helps the frog.

---

## 18.1 Rescue Structure

The player:

1. Removes the invasive rats.
2. Restores the immediate habitat.
3. Allows the native frog to move toward a safer area.

The rescue should take approximately:

> **2–4 minutes**

It is intentionally short.

---

# 19. SALAMANDER TRANSFORMATION

The rescue reveals something unusual.

Sterling detects a biological signal.

The player follows the signal.

Eventually:

> The Salamander Genome is physically discovered.

The player uses Interact.

A compact genome presentation appears.

The player selects:

> Transform

Transformation happens immediately.

The player gains direct control of Salamander.

---

## 19.1 Transformation Philosophy

Do not explain every Salamander mechanic before transformation.

Instead:

> Transform → play → discover.

This is intentional.

---

# 20. SALAMANDER

## Role

> **Recovery + Poison**

Salamander is not a simple stronger Frog.

Its strengths revolve around:

* recovery
* sustained survival
* poison
* area control

---

## 20.1 Attribute Priorities

| Attribute        | Priority      |
| ---------------- | ------------- |
| Health Recovery  | Very High     |
| Health           | High          |
| Attack           | Moderate-High |
| Cooldown         | Moderate      |
| Stamina          | Moderate      |
| Stamina Recovery | Moderate      |

---

## 20.2 Abilities

### Basic Attack — Bite

Normal bite.

No poison.

No stamina cost.

---

### Skill 1 — Regenerative Skin

Restores health over time.

The player can:

* move
* fight
* continue playing

while recovery occurs.

---

### Skill 2 — Toxic Secretion

Creates a poisonous area.

Useful for:

* area denial
* sustained damage
* controlling enemy positioning

---

# 20.3 Poison System

Maximum:

> **3 stacks**

Each hit applies one stack after the appropriate interval.

A fourth application does not create a fourth stack.

Instead:

> The poison duration is refreshed.

This keeps the system readable and prevents unlimited stacking.

---

# 20.4 Salamander Ultimates

### Attack — Toxic Predator

Baseline:

> 8 seconds

During the Ultimate:

* Bite deals increased damage
* Bite attacks faster
* Regenerative Skin becomes stronger
* Toxic Secretion becomes stronger
* Poison applies more effectively

---

### Defense — Regenerative Survivor

Baseline:

> 8 seconds

Effects:

* increased damage resistance
* increased Health Recovery

Visual:

> semi-transparent protective bubble/aura

The bubble is a visual indicator rather than a literal physical shield.

An optional ripple can appear when the player is hit.

---

### Agility — Toxic Adaptation

Designed around:

* movement speed
* stamina recovery
* reduced dodge cost
* shorter dodge cooldown
* faster recovery after being hit

The dodge-related parts remain conditional because dodge itself has not been locked as a core system.

---

# 20.5 Salamander Tutorial Philosophy

There is:

> **No formal Salamander tutorial.**

The player learns Salamander by playing.

Sterling may make natural observations, but should not say:

> "This is your Skill 1."

The environment should create situations where Salamander's abilities become useful naturally.

---

# 21. SALAMANDER DEEPER WETLANDS

After transformation:

> Free experimentation + visible waypoint.

The player is allowed to play with Salamander without a forced tutorial.

The waypoint leads deeper into the wetlands.

The environment becomes:

* more contaminated
* less healthy
* more dangerous

Vegetation becomes sparse or unhealthy.

Animal behavior becomes abnormal.

Salamander's:

* recovery
* poison
* sustained survival

become naturally useful.

---

# 22. INVASIVE SNAKE

The stronger invasive creature encountered during this section is:

> **Invasive Snake**

Its defining behavior is:

> **Ambush + Hit-and-Run**

The snake:

1. partially hides in vegetation
2. suddenly attacks
3. retreats
4. circles or repositions
5. attacks again

The challenge comes from behavior rather than simply giving the snake huge HP.

---

# 23. DAMAGED WATER SOURCE

After the snake encounter, the player discovers:

* a severely damaged water source
* dead or weakened native animals
* displaced wildlife
* evidence of something much larger

This is the lead-in to the Water Monitor Genome.

The game does **not** immediately jump to the Chimera.

---

# 24. WATER MONITOR GENOME

The player encounters an environmental problem.

They find clues.

Sterling detects another biological signal.

The player follows it.

Eventually:

> The Water Monitor Genome is physically discovered.

The player interacts with it and transforms.

---

# 25. WATER MONITOR

## Role

> **Bruiser — Power + Durability**

Water Monitor should feel physically powerful.

---

## 25.1 Attribute Priorities

| Attribute          | Priority     |
| ------------------ | ------------ |
| Health             | Very High    |
| Attack             | High         |
| Health Recovery    | Moderate     |
| Stamina            | Moderate     |
| Stamina Recovery   | Low-Moderate |
| Cooldown Reduction | Low-Moderate |

---

## 25.2 Basic Attack

### Claw Slash

A straightforward close-range attack.

---

## 25.3 Skill 1 — Tail Sweep

A wide tail attack.

Properties:

* moderate damage
* knockback
* cooldown
* wind-up
* no stamina cost

---

## 25.4 Skill 2 — Crushing Bite

A powerful single-target attack.

Properties:

* high damage
* brief stagger
* effective against bosses and large targets

---

# 25.5 Water Monitor Ultimates

### Attack — Crushing Maul

The attack is:

> Bite/grab → ONE massive slam

It is **not** repeated ground pounding.

Primary target:

* very high damage
* heavy stagger

Nearby enemies:

* lower AoE damage
* knockback

Very large enemies and bosses cannot be lifted.

Against them, the animation becomes:

> powerful bite + slam

without physically lifting them.

---

### Defense — Iron Hide

Defensive specialization.

Exact numerical effects remain OPEN.

---

### Agility — Relentless Hunter

Designed around sustained pursuit and hunting mobility.

Exact numerical effects remain OPEN.

---

# 26. WATER MONITOR GAMEPLAY SECTION

After transformation, Water Monitor must receive meaningful gameplay time.

The player encounters:

* physical obstacles
* stronger invasive creatures
* environmental damage

The first major obstacle is:

> Fallen tree + natural debris blocking passage.

Water Monitor uses physical strength to clear or force through it.

There should be no unnecessary:

> "Press this button because Water Monitor can break objects."

The environment itself should communicate the mechanic.

---

# 27. NUTRIA / COYPU COLONY

The major invasive encounter here is:

> **Nutria / Coypu**

This is the locked main invasive encounter for the Water Monitor section.

---

## 27.1 Environmental Setup

The player reaches a heavily damaged wetland bank.

The player sees:

* nutria actively feeding
* damaged vegetation
* disturbed soil
* burrows
* weakened riverbank

The nutria are visibly contributing to the ecological damage.

---

## 27.2 Encounter

The player can approach and investigate.

Information about the animal/ecological impact can be provided concisely.

Some nutria retreat.

Others defend the colony.

The encounter becomes hostile.

The player fights the colony using Water Monitor.

This demonstrates:

> power + durability.

---

# 28. CHIMERA LEAD-IN

After the nutria colony, the environment changes.

The wetlands become unusually quiet.

The player notices:

* unusual water behavior
* vegetation disturbance
* a massive trail
* fleeing animals

Sterling detects a biological signal.

But this signal is different.

It is:

> unusually strong.

Sterling becomes concerned.

The waypoint updates toward the source.

---

# 29. CHIMERA TERRITORY

The player eventually reaches an area clearly belonging to the Chimera.

The player sees:

* heavy ecological damage
* disturbed vegetation
* destruction
* evidence of a large organism

Then:

> A brief distant sighting of the Chimera.

It disappears.

Wildlife reacts.

Sterling detects an abnormal biological signature.

This establishes the threat without immediately starting the battle.

---

# 30. WETLANDS CHIMERA

## Species Combination

> **Snail–Cane Toad Chimera**

---

# 30.1 Battle Format

The Chimera battle is a:

> **Dedicated arena battle**

It is not a chase sequence.

---

## 30.2 Arena

The arena is a natural wetland environment.

There are:

* no visible artificial walls
* no obvious gamey barriers

Instead, an:

> **Invisible boundary**

prevents the player from leaving.

After the Chimera is defeated, the boundary disappears.

---

# 30.3 Transformation Switching

During the Chimera fight, the player can freely switch between unlocked Wetlands species:

* Frog
* Salamander
* Water Monitor

Switching has a transformation cooldown.

The player is not forced to use one animal.

However, each phase naturally favors a particular species.

---

# 31. CHIMERA PHASES

Phase transitions are:

> **Health threshold + noticeable behavior change**

The Chimera should not simply lose HP and suddenly change phases invisibly.

The player should feel:

> "It is behaving differently now."

---

## Phase 1 — Chase / Mobility

**Favored:** Frog

The Chimera emphasizes:

* movement
* chasing
* mobility pressure

Frog's mobility becomes useful.

---

## Phase 2 — Toxic Territory

**Favored:** Salamander

The Chimera emphasizes:

* toxic attacks
* territory control
* environmental danger

Salamander's poison and recovery become useful.

---

## Phase 3 — Brutal Clash

**Favored:** Water Monitor

The encounter becomes more direct and physically aggressive.

Water Monitor's:

* durability
* attack power
* stagger

become useful.

---

# 32. CHIMERA ATTACK DESIGN

The Chimera uses a combination of:

### A. Tongue + Body Attacks

The cane toad/snail biological combination allows close and ranged physical threats.

### B. Shell Defense + Toxic Attacks

The shell provides protection.

Toxic attacks punish careless positioning.

### C. Movement + Toxic Territory

The Chimera controls parts of the arena.

### D. Adaptive Attacks

The Chimera can respond to the player's current animal.

The overall attack set must remain:

> **Readable on mobile.**

---

# 33. USING THE "WRONG" ANIMAL

The player is never hard-countered.

If the player uses a less suitable animal:

* it is less efficient
* the Chimera may respond behaviorally
* the player can still succeed
* a different strategy may be required

There should be:

> **No hard counters.**

This is important because players should feel free to experiment.

---

# 34. CHIMERA WEAK POINTS

The weak point is biological.

It can involve:

* vulnerable body regions
* shell openings
* changing protection

The weak point changes between phases.

This makes players observe the Chimera rather than simply attack continuously.

---

## 34.1 Weak Point Result

When successfully attacked:

* increased damage
* brief stagger
* obvious biological reaction

The player should immediately understand:

> "That worked."

---

# 35. WETLANDS CHIMERA DEFEAT

After defeating the Chimera:

### 1. Genome Core Recovery

The player recovers a:

> **Genome Core**

This is connected to the mutated biological energy released by the original accident.

---

### 2. Habitat Restoration

The player performs one meaningful restoration action.

---

### 3. Natural Recovery

The ecosystem begins to heal.

The player sees:

* wildlife cautiously returning
* vegetation beginning to recover
* the habitat becoming usable again

---

# 36. WETLAND RESTORATION

The restoration action is:

> **Restore a damaged critical habitat.**

The player:

1. Finds a small severely damaged habitat.
2. Clears remaining invasive material/debris.
3. Makes the habitat usable again.
4. Observes native wildlife cautiously return.
5. Sees early vegetation recovery.

This is:

> **short**

and is not intended to become a separate restoration minigame.

---

# 37. CONSERVATION MESSAGE

The important message is:

> The player removes the major threat and helps repair the habitat. The ecosystem then begins restoring itself.

This is preferable to the player magically fixing an entire ecosystem personally.

---

# 38. WETLAND → RAINFOREST TRANSITION

The transition uses three simultaneous signals:

### 1. Geography

The landscape physically changes.

### 2. Genome Core

The Genome Core points toward another biological signal.

### 3. Wildlife Behavior

Animals begin moving toward the denser forest.

---

## 38.1 Physical Transition

The environment gradually changes through:

**Wetland**

↓

**Marsh / Riverbank**

↓

**Floodplain**

↓

**Forest Edge**

↓

**Dense Vegetation**

↓

**Rainforest**

There is no sudden level-loading feeling.

---

# 39. RAINFOREST LEGACY GENOME CHOICE

At the ecological boundary, the damaged suit recognizes that the player is entering a different ecosystem.

The player chooses one Wetlands species to remain active as:

> **Legacy Genome**

Choices:

* Frog
* Salamander
* Water Monitor

The others remain stored.

---

# 40. RAINFOREST OPENING

The opening Rainforest structure is:

> Dense forest exploration + wildlife observation + environmental problem.

The main environmental problem is:

> **Deforestation + active/illegal logging**

---

# 41. RAINFOREST DISCOVERY

The player first encounters the aftermath.

They see:

* freshly cut trees
* damaged vegetation
* canopy gaps
* disturbed habitat
* displaced wildlife

Wildlife behavior communicates that something is wrong.

The player follows clues.

Eventually:

> They reach an active logging site.

---

# 42. ACTIVE LOGGING SITE — OPEN DESIGN

This part has **not been finalized**.

Previously discussed possibilities include:

### A — Observe / Investigate

The player studies the logging operation.

### B — Find a Way Around

The player avoids direct confrontation.

### C — Help Displaced Wildlife

The player addresses the ecological consequences.

### D — Environmental Obstacle

The logging site creates an obstacle where Wild Boar's physical abilities become useful.

### E — Combination

Investigation + wildlife assistance + physical environmental interaction.

**Current status: OPEN.**

---

# 43. WILD BOAR

## Role

> **Charge / Power / Momentum**

Wild Boar should not simply become another tank.

Its identity is:

* momentum
* impact
* charging
* stamina
* knockback
* stagger
* breaking obstacles

---

## 43.1 Working Attribute Priorities

| Attribute        | Priority  |
| ---------------- | --------- |
| Health           | High      |
| Attack           | Very High |
| Stamina          | Very High |
| Stamina Recovery | Low       |
| Cooldown         | Low       |
| Health Recovery  | Moderate  |

These are currently provisional.

---

# 43.2 Working Abilities

### Basic

**Headbutt**

### Skill 1

**Tusk Strike**

### Skill 2

**Front Hoof Slam**

### Attack Ultimate

**Wild Charge**

### Defense Ultimate

**Unstoppable**

### Agility Ultimate

**Momentum Breaker**

These are current working concepts and still require final balancing.

---

# 43.3 Wild Boar Exploration

Potential environmental strengths:

* breaking obstacles
* digging
* scent tracking

These support the biological identity of the animal.

---

# 44. PANGOLIN

Current role:

> **Armor / Defense**

Potential biological gameplay includes:

* rolling
* hardened scales
* deflection
* counterattack
* hiding
* possible digging

The exact kit is still:

> **OPEN**

Pangolin must feel fundamentally different from Water Monitor.

---

# 45. EAGLE

Current role:

> **Flight / Aerial**

The Eagle should provide a different exploration perspective and potentially aerial combat.

However, the exact:

* flight controls
* camera behavior
* combat controls
* stamina system
* aerial abilities

remain:

> **OPEN**

The flight system must be designed specifically for mobile usability.

---

# 46. MOUNTAIN PROGRESSION

The current order is:

**Tamaraw → Bear → Goat**

All three are locked as the Mountain progression.

Their detailed:

* abilities
* attributes
* Ultimates
* transformation quests
* exploration roles
* Chimera encounters

are still OPEN.

---

# 47. EDUCATIONAL DESIGN

GenoMorph's educational content should come from the gameplay itself.

For example:

Instead of simply saying:

> "Nutria damage riverbanks."

The player sees:

* nutria burrows
* weakened soil
* damaged vegetation
* unstable riverbank

Then the Knowledge Database explains the ecological relationship.

This makes the information contextual.

---

# 48. KNOWLEDGE DATABASE

The Database is the deeper educational layer.

It can contain:

* animal biology
* adaptations
* ecological relationships
* environmental damage
* invasive species
* restoration information
* discoveries

The Database should reward curiosity.

It should not be required reading for basic progression.

---

# 49. BRANCHING TRANSFORMATION SYSTEM

The transformation system can eventually create meaningful branches.

For example:

> Frog → Pangolin → Wild Boar

could provide a different experience from:

> Frog → Salamander → Water Monitor → another route

The difference should not merely be:

> +5 Attack vs +5 Defense.

Instead, branches can affect:

* abilities
* exploration options
* combat strategies
* environmental interactions
* ecological knowledge
* available situations
* consequences
* potentially endings

---

# 50. WHY BRANCHES MATTER

The player should eventually feel:

> "My GenoMorph journey is different because of the forms I chose."

This makes transformations part of the player's identity.

The player is effectively building a biological toolkit.

---

# 51. SPECIES DESIGN PHILOSOPHY

Every species should have:

1. A clear biological identity.
2. A clear combat identity.
3. A clear exploration contribution.
4. A distinct reason to use it.
5. Strengths.
6. Weaknesses.
7. Situations where another animal is preferable.

No animal should simply be:

> "The previous animal, but stronger."

---

# 52. CURRENT SPECIES IDENTITY MAP

| Species       | Primary gameplay identity |
| ------------- | ------------------------- |
| Frog          | Agile Controller          |
| Salamander    | Recovery + Poison         |
| Water Monitor | Bruiser                   |
| Wild Boar     | Charge / Momentum         |
| Pangolin      | Armor / Defense           |
| Eagle         | Aerial / Flight           |
| Tamaraw       | OPEN                      |
| Bear          | OPEN                      |
| Goat          | OPEN                      |

---

# 53. PACING PHILOSOPHY

The beginning of the game should not spend too long explaining systems.

The preferred approach is:

### Explain enough.

↓

### Let the player act.

↓

### Let the player discover.

↓

### Explain deeper only when useful.

For example:

The player does not need a 5-minute lecture about Salamander before transforming.

Instead:

> Find genome → transform → play → encounter situation → understand ability.

---

# 54. TUTORIAL STRUCTURE

## Frog

Frog is the main onboarding animal.

It teaches:

* movement
* camera
* interaction
* investigation
* combat
* skills
* environmental clues
* progression basics

---

## Salamander

No formal tutorial.

The player learns naturally.

---

## Water Monitor

No conventional tutorial.

The environment demonstrates its physical strength naturally.

For example:

> Fallen tree blocks path → Water Monitor can clear it.

---

## Future Animals

The same philosophy should generally continue.

New animals should teach themselves through situations.

---

# 55. IMPORTANT DESIGN PRINCIPLE: PLAYER DISCOVERY

GenoMorph should frequently let the player think:

> "Oh, this animal can do that."

rather than:

> "The game told me this animal can do that."

This is particularly important for a game centered around biological adaptation.

---

# 56. COMBAT DIFFICULTY PHILOSOPHY

Combat should challenge the player through:

* enemy behavior
* positioning
* timing
* animal choice
* ability usage
* weak points
* environmental awareness

rather than simply:

> enemies have huge HP.

---

# 57. CHIMERA DESIGN PHILOSOPHY

A Chimera should feel like:

> An ecosystem problem made into a living creature.

It should combine recognizable biological traits into something unstable.

Its behavior should change during the fight.

The player should feel that the Chimera is adapting.

---

# 58. RESTORATION DESIGN PHILOSOPHY

Restoration should not feel like:

> "Press 20 buttons to clean the map."

Instead:

1. Remove the major threat.
2. Repair something important.
3. Observe the ecosystem begin recovering.

This communicates that ecosystems have their own recovery processes.

---

# 59. WHAT IS CURRENTLY LOCKED

## Core

* Mobile platform
* Third-person 3D action RPG
* Asia-inspired ecological setting
* Environmental restoration theme
* Biological transformation concept
* Sterling communicates through radio
* DSEE overload origin
* Frog as starting form

---

## Transformation Progression

**Wetlands:**

Frog → Salamander → Water Monitor

**Rainforest:**

Wild Boar → Pangolin → Eagle

**Mountain:**

Tamaraw → Bear → Goat

---

## Progression

* Six attributes
* Species-specific levels
* Recommended Level 15 cap
* Genome after five attribute upgrades
* Three Ultimate paths
* Species-specific Genomes
* Legacy Genome system

---

## Wetlands

* Frog onboarding
* Mosquito encounter
* Invasive Rat
* Native Frog rescue
* Salamander Genome
* Salamander free experimentation
* Invasive Snake
* Water Monitor Genome
* Fallen tree obstacle
* Nutria colony
* Chimera territory
* Snail–Cane Toad Chimera
* Natural arena
* Invisible boundary
* Free species switching
* Three phases
* Health-threshold transitions
* Biological weak points
* Genome Core
* Habitat restoration
* Natural ecosystem recovery

---

## Rainforest

* Physical biome transition
* Legacy Genome selection
* Dense forest
* Wildlife observation
* Deforestation
* Active/illegal logging

---

# 60. CURRENTLY OPEN

The following should **not** be treated as final.

### Progression

* Exact XP curve
* Exact Attribute Point economy
* Exact number of Genomes per species
* Exact Ultimate values
* Final five-upgrade implementation

### Wetlands

* Exact Invasive Rat teaching structure
* Final death penalties

### Rainforest

* Exact logging-site gameplay
* Wild Boar transformation quest
* Final Wild Boar abilities and numbers
* Pangolin kit
* Eagle kit
* Eagle flight controls

### Mountain

* Tamaraw abilities
* Bear abilities
* Goat abilities
* Mountain quests
* Mountain Chimera

### Future Content

* Final three future genomes

---

# 61. DESIGN RULES FOR FUTURE DEVELOPMENT

These rules should be used whenever a new mechanic is proposed.

### Rule 1

Do not change a locked decision without explicitly identifying it as a proposed change.

### Rule 2

Do not accidentally turn an OPEN idea into a locked mechanic.

### Rule 3

Do not skip established transformation progression.

### Rule 4

Do not make every new animal a direct power upgrade.

### Rule 5

Do not introduce complex movement systems without a deliberate design reason.

### Rule 6

Do not overload mobile controls.

### Rule 7

Do not turn education into mandatory lectures.

### Rule 8

Let the environment demonstrate biological abilities whenever possible.

### Rule 9

Let players experiment after unlocking a new form.

### Rule 10

Keep Sterling as a radio guide rather than an omniscient narrator.

### Rule 11

Make ecological damage visible.

### Rule 12

Make restoration visibly change the world.

### Rule 13

Avoid hard counters between animal forms.

### Rule 14

Older animals must remain useful.

### Rule 15

Keep the game fast enough that players can make meaningful progress without excessive gaming time.

---

# 62. RECOMMENDED DEVELOPMENT ORDER

The next development priorities should be:

## Phase 1 — Wetlands Vertical Slice

Complete:

**Frog → Salamander → Water Monitor → Wetlands Chimera → Restoration**

This gives the game its first complete playable ecosystem.

---

## Phase 2 — Progression

Finalize:

* Level 1–15 XP
* Attribute Points
* Genome frequency
* Ultimate progression
* numerical balance

---

## Phase 3 — Rainforest Entry

Finalize:

* Legacy Genome transition
* Wild Boar transformation
* logging-site gameplay

---

## Phase 4 — Rainforest Forms

Develop:

* Wild Boar
* Pangolin
* Eagle
* flight controls

---

## Phase 5 — Rainforest Ecosystem

Develop:

* environmental quests
* invasive creatures
* Chimera
* restoration

---

## Phase 6 — Mountain

Develop:

* Tamaraw
* Bear
* Goat
* Mountain environmental problems
* Mountain Chimera
* restoration

---

# 63. MASTER GAME FLOW

The current overall game structure is:

**PROLOGUE**

Human player

↓

GenoMorph field test

↓

Pollutant interaction

↓

DSEE overload

↓

12 genomes discharge

↓

Invasive organisms absorb biological energy

↓

Invasive Chimeras emerge

↓

Player wakes as Frog

↓

**WETLANDS**

Frog onboarding

↓

Environmental investigation

↓

Mosquito

↓

Mosquito swarm

↓

Polluted ecosystem

↓

Invasive Rats

↓

Native Frog rescue

↓

Salamander Genome

↓

**SALAMANDER**

Free experimentation

↓

Deeper contaminated wetlands

↓

Invasive Snake

↓

Damaged water source

↓

Water Monitor Genome

↓

**WATER MONITOR**

Fallen tree / natural debris

↓

Nutria colony

↓

Massive disturbance

↓

Chimera territory

↓

**SNAIL–CANE TOAD CHIMERA**

Phase 1 — Frog / Mobility

↓

Phase 2 — Salamander / Toxic Territory

↓

Phase 3 — Water Monitor / Brutal Clash

↓

Genome Core

↓

Critical habitat restoration

↓

Wetlands recovery

↓

**RAINFOREST TRANSITION**

Wetland

↓

River/floodplain

↓

Forest edge

↓

Rainforest

↓

Legacy Genome selection

↓

**RAINFOREST**

Dense forest

↓

Wildlife displacement

↓

Deforestation

↓

Active logging site

↓

**WILD BOAR**

↓

**PANGOLIN**

↓

**EAGLE**

↓

Rainforest restoration

↓

**MOUNTAIN**

Tamaraw

↓

Bear

↓

Goat

↓

Mountain restoration

↓

Further ecosystems

↓

Future genomes/content

---

# 64. THE CORE IDENTITY OF GENOMORPH

At the center of the entire design is one idea:

> **The player does not become powerful by becoming something bigger. The player becomes powerful by becoming more adaptable.**

The Frog teaches mobility.

The Salamander teaches recovery and poison.

The Water Monitor teaches power and durability.

The Wild Boar teaches momentum.

The Pangolin teaches defense.

The Eagle introduces aerial possibilities.

Each ecosystem then asks the player to understand:

> **Which biological adaptation is appropriate for this situation?**

That is what should make GenoMorph different from a conventional action RPG.

---

## MASTER DESIGN STATUS

**Established foundation:** Strong
**Wetlands:** Highly developed
**Rainforest:** Early-to-mid development
**Mountain:** Early development
**Progression mathematics:** Needs finalization
**Future species:** Open
**Overall direction:** Established

This document should now be treated as the **master baseline** for our GenoMorph design discussions. When we continue, we should work from this structure and only modify sections when we explicitly decide to change them.
