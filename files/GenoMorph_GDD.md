## Game Design Document (GDD)

**Project Status:** Pre-Production / Working Design  
**Genre:** Action RPG  
**Perspective:** Third-Person 3D  
**Target Audience:** Teenagers and general players interested in action, animals, ecosystems, and environmental topics  
**Setting:** Asia-inspired ecosystem — exact location TBD  
**Core Themes:** Environmental restoration, biodiversity, adaptation, exploration, survival, scientific discovery

---

# Table of Contents

1. [Game Overview](#1-game-overview)
2. [Core Game Concept](#2-core-game-concept)
3. [Design Pillars](#3-design-pillars)
4. [Educational Purpose](#4-educational-purpose)
5. [Story](#5-story)
6. [The Ecological Collapse](#6-the-ecological-collapse)
7. [Dr. Alistair Sterling](#7-dr-alistair-sterling)
8. [The Player](#8-the-player)
9. [The GenoMorph Suit](#9-the-genomorph-suit)
10. [The Prologue](#10-the-prologue)
11. [The Wetlands Incident](#11-the-wetlands-incident)
12. [Invasive Chimeras](#12-invasive-chimeras)
13. [The First Transformation](#13-the-first-transformation)
14. [World Structure](#14-world-structure)
15. [Biomes](#15-biomes)
16. [Species Progression](#16-species-progression)
17. [Evolution System](#17-evolution-system)
18. [Species Leveling](#18-species-leveling)
19. [Attributes](#19-attributes)
20. [Genome System](#20-genome-system)
21. [Ultimate System](#21-ultimate-system)
22. [Stamina System](#22-stamina-system)
23. [Combat System](#23-combat-system)
24. [Death and Respawn](#24-death-and-respawn)
25. [Chimera System](#25-chimera-system)
26. [Wetlands Chimera](#26-wetlands-chimera)
27. [Wetlands Chimera Battle](#27-wetlands-chimera-battle)
28. [Wetlands Chimera Weak Points](#28-wetlands-chimera-weak-points)
29. [Wetlands Chimera Defeat](#29-wetlands-chimera-defeat)
30. [Environmental Restoration](#30-environmental-restoration)
31. [GenoMorph Database](#31-genomorph-database)
32. [Interactive Knowledge System](#32-interactive-knowledge-system)
33. [Sterling's Radio](#33-sterlings-radio)
34. [Wetlands Tutorial](#34-wetlands-tutorial)
35. [Existing Wetland Animal Models](#35-existing-wetland-animal-models)
36. [Wetlands Species](#36-wetlands-species)
37. [Frog](#37-frog)
38. [Frog Abilities](#38-frog-abilities)
39. [Frog Ultimate System](#39-frog-ultimate-system)
40. [Salamander](#40-salamander)
41. [Salamander Abilities](#41-salamander-abilities)
42. [Salamander Poison System](#42-salamander-poison-system)
43. [Salamander Ultimate System](#43-salamander-ultimate-system)
44. [Water Monitor](#44-water-monitor)
45. [Water Monitor Abilities](#45-water-monitor-abilities)
46. [Water Monitor Ultimate System](#46-water-monitor-ultimate-system)
47. [Wetlands Ultimate Summary](#47-wetlands-ultimate-summary)
48. [Frog to Salamander Evolution Quest](#48-frog-to-salamander-evolution-quest)
49. [Salamander to Water Monitor Evolution Quest](#49-salamander-to-water-monitor-evolution-quest)
50. [Wetlands to Rainforest Transition](#50-wetlands-to-rainforest-transition)
51. [Rainforest](#51-rainforest)
52. [Wild Boar](#52-wild-boar)
53. [Wild Boar Attributes](#53-wild-boar-attributes)
54. [Wild Boar Abilities](#54-wild-boar-abilities)
55. [Wild Boar Ultimate System](#55-wild-boar-ultimate-system)
56. [Wild Boar Exploration](#56-wild-boar-exploration)
57. [Wild Boar Weaknesses](#57-wild-boar-weaknesses)
58. [The Broken Forest](#58-the-broken-forest)
59. [Black Leopard](#59-black-leopard)
60. [Eagle](#60-eagle)
61. [Mountain](#61-mountain)
62. [Final Boss Concept](#62-final-boss-concept)
63. [Genome Roster](#63-genome-roster)
64. [Current Species Roster](#64-current-species-roster)
65. [Core Gameplay Loop](#65-core-gameplay-loop)
66. [Core Design Rules](#66-core-design-rules)
67. [Current Development Status](#67-current-development-status)
68. [Unresolved Design Questions](#68-unresolved-design-questions)

---

# 1. Game Overview

## Title

**GenoMorph**

## Genre

**Action RPG**

## Perspective

**Third-Person 3D**

The camera follows the player from behind and slightly above.

The camera can rotate around the player.

Camera distance and positioning can change depending on:

- Animal species
- Movement
- Combat
- Special abilities
- Flight or swimming

## World

GenoMorph takes place in a large interconnected ecosystem.

The world is divided into major environmental regions such as:

- Wetlands
- Rainforest
- Mountains
- Coral reef areas

The exact geographical location has not yet been finalized.

The setting is intended to feel inspired by Asian ecosystems.

---

# 2. Core Game Concept

GenoMorph is an Action RPG where the player uses a biological transformation suit to become different animal species.

The player's objective is to:

- Explore damaged ecosystems
- Recover scattered genomes
- Help native species
- Fight invasive creatures
- Defeat mutated Chimeras
- Restore damaged environments
- Learn about animals and ecosystems
- Discover the truth behind the ecological collapse

The player does not simply become stronger by using one character.

Instead, different animal forms provide different gameplay styles.

---

# 3. Design Pillars

GenoMorph is built around four major gameplay pillars.

## 3.1 Explore

Players explore interconnected ecosystems.

Exploration can reveal:

- Animals
- Plants
- Environmental objects
- Hidden locations
- Collectibles
- Genome fragments
- Research information
- Quest objectives

---

## 3.2 Transform

The player can transform into different animal species.

Every species has:

- Unique abilities
- Unique attributes
- Unique strengths
- Unique weaknesses
- Unique exploration capabilities
- Unique Ultimate paths

Species are not intended to be simple power upgrades.

---

## 3.3 Restore

The player gradually repairs damaged ecosystems.

The environment should visibly change as restoration progresses.

Examples:

- Dirty water becomes cleaner.
- Vegetation returns.
- Native wildlife returns.
- Invasive creatures become less common.
- Damaged areas become healthier.

---

## 3.4 Learn

The game teaches players about:

- Animal adaptations
- Ecosystems
- Food chains
- Invasive species
- Environmental damage
- Biodiversity
- Native species

Education is integrated into exploration and gameplay.

---

# 4. Educational Purpose

GenoMorph is a mixture of:

> **Fiction + Education**

Real animals and biological traits are used as inspiration.

However, gameplay can exaggerate real-world abilities when necessary for:

- Fun
- Combat balance
- Game progression
- Player readability

The educational target is primarily:

> **Teenagers**

The game should teach environmental concepts without feeling like a traditional textbook.

---

# 5. Story

The world of GenoMorph was once a thriving interconnected ecosystem.

Wetlands, rainforests, mountains, and coral reef environments were connected and supported one another.

Over decades, environmental destruction caused the ecosystem to collapse.

The disappearance of important native species created an imbalance that allowed invasive organisms to spread.

One scientist believed the ecosystem could still be restored.

That scientist was:

> **Dr. Alistair Sterling**

---

# 6. The Ecological Collapse

The ecosystem suffered from multiple environmental problems.

Major causes included:

- Industrial runoff
- Invasive species
- Deforestation
- Ocean acidification
- Electronic waste
- Pollution
- Habitat destruction

Native keystone species began to disappear.

As these species disappeared, invasive predators and other invasive organisms multiplied.

The ecosystem became increasingly unstable.

---

# 7. Dr. Alistair Sterling

**Dr. Alistair Sterling** is a biomedical engineer.

He believes ecosystems can recover if important native species are reintroduced.

Sterling spent:

> **11 years**

developing the GenoMorph Suit.

He designed the suit to allow a human to temporarily transform into animal forms using genetic information.

Sterling:

- Built the suit
- Understands the technology
- Knows the truth behind the experiment
- Wants to restore the environment
- Recruited the player

Sterling is located at a laboratory far away from the player.

The player communicates with Sterling:

> **Only through radio.**

---

# 8. The Player

The player character is:

- 18 years old
- Male
- A normal person with a normal personality
- Passionate about helping the environment

Sterling recruited the player because of a rare genetic compatibility.

The player has unusually high:

> **Neural plasticity**

This allows the GenoMorph Suit to transform the player's body into different animal forms without causing severe neurological damage.

Sterling already knows the player and specifically recruited him for the project.

The player trusts Sterling.

---

# 9. The GenoMorph Suit

The **GenoMorph Suit** is a biological transformation system created by Sterling.

The suit contains a genetic storage and transformation system called the:

> **DNA Engine / DSEE**

The system is capable of storing native animal genomes.

These genomes can then be used to transform the player.

The original field test was intended to demonstrate that the system could work outside the laboratory.

Instead, the test caused the main incident of the game.

---

# 10. The Prologue

The player begins the game in human form.

Human gameplay exists only during the prologue.

The prologue introduces:

- The player
- Sterling
- The GenoMorph Suit
- The environmental crisis
- The purpose of the project
- The field test

After the prologue, the player becomes primarily an animal character.

---

# 11. The Wetlands Incident

The first field test takes place in the:

> **Polluted Wetlands**

The area is heavily contaminated.

During the field test, environmental toxins interfere with the GenoMorph Suit.

A massive power surge occurs.

The DSEE becomes overloaded.

The system contains:

> **12 stored native genomes**

The overload causes all 12 genomes to be discharged into the surrounding ecosystem as raw biological energy.

The genomes become scattered throughout the world.

---

# 12. Invasive Chimeras

Local invasive species absorb the released genetic energy.

This causes them to mutate.

The resulting creatures are called:

> **Invasive Chimeras**

They are more aggressive and powerful than normal animals.

Each major biome has its own major Chimera.

---

# 13. The First Transformation

After the accident, the player wakes up.

The GenoMorph Suit is damaged.

Most transformation options are unavailable.

The only surviving transformation is the weakest and most fragile form:

> **Small Native Frog**

The player must survive and begin recovering the scattered genomes.

---

# 14. World Structure

GenoMorph uses a connected biome-based world.

The world should feel like one ecosystem rather than a collection of unrelated levels.

The player can revisit previously explored regions.

The current planned major biomes are:

1. Wetlands
2. Rainforest
3. Mountain

Additional biomes may be added later.

---

# 15. Biomes

## Wetlands

Species:

1. Frog
2. Salamander
3. Water Monitor

Progression:

> **Frog → Salamander → Water Monitor**

---

## Rainforest

Species:

1. Wild Boar
2. Black Leopard
3. Eagle

Progression:

> **Wild Boar → Black Leopard → Eagle**

Gameplay progression:

> **Power → Stealth → Flight**

---

## Mountain

Species:

1. Tamaraw
2. Bear
3. Goat

Progression:

> **Tamaraw → Bear → Goat**

The Mountain species have not yet been fully designed.

---

# 16. Species Progression

Species progression is not intended to be strict biological evolution.

Instead, it represents the player's access to increasingly compatible or advanced genomes.

A new animal should not simply be stronger than the previous one.

Each animal should provide a different gameplay experience.

For example:

- Frog = mobility/control
- Salamander = recovery/poison
- Water Monitor = durability/power
- Wild Boar = charge/power
- Black Leopard = planned stealth/mobility
- Eagle = planned flight

---

# 17. Evolution System

New species are unlocked through:

> **Evolution Quests**

The player does not automatically transform into the next species just because they reached a certain level.

Evolution Quests combine:

- Story
- Exploration
- Combat
- Environmental interactions
- Genome recovery

The player completes the quest and then gains access to the new animal.

---

# 18. Species Leveling

Each animal species has its own level.

Initial maximum level:

> **15**

The Level 15 cap may be increased in future updates.

Every species maintains its own progression.

For example:

```text
Frog Level 10
Salamander Level 6
Water Monitor Level 3
Wild Boar Level 1
```

Unlocking a new animal does not remove or replace previously unlocked animals.

---

# 19. Attributes

Every species has six main attributes:

1. Health
2. Attack Power
3. Stamina
4. Stamina Recovery
5. Cooldown Reduction
6. Health Recovery

---

## 19.1 Level-Up Rewards

A level-up does not necessarily provide exactly one attribute upgrade.

Depending on achievements and milestones, a level-up can award different amounts.

Examples:

* 1 upgrade
* 2 upgrades
* 3 upgrades
* 5 upgrades

The player chooses where to spend the upgrades.

---

# 20. Genome System

A Genome is earned after upgrading one attribute:

> **5 times**

Example:

```text
Health
↓
Upgrade 1
Upgrade 2
Upgrade 3
Upgrade 4
Upgrade 5
↓
Earn 1 Genome
```

The Genome belongs to the species that earned it.

A Frog Genome cannot be used on Salamander.

A Salamander Genome cannot be used on Water Monitor.

The exact rule for repeated groups of five upgrades has not yet been finalized.

---

# 21. Ultimate System

Every species has three Ultimate paths:

1. Attack
2. Defense
3. Agility

Only one Ultimate can be equipped at a time.

Genomes can be used to:

* Upgrade the selected Ultimate
* Switch to another Ultimate

Without a Genome, the player cannot change or upgrade the Ultimate.

Each Ultimate has:

* Level 1
* Level 2
* Level 3

The current Wetlands Ultimate baseline is:

> **8-second base duration**

Current assumed cooldown:

> **60 seconds**

Exact values can be changed during balancing.

---

# 22. Stamina System

Stamina is mainly used for high-effort movement and physical actions.

Normal movement does not consume stamina.

Current stamina rules:

| Action               | Stamina            |
| -------------------- | ------------------ |
| Normal movement      | No                 |
| Jump                 | Generally no       |
| Frog Splashdown Jump | Yes                |
| Basic Attack         | No                 |
| Sticky Tongue Whip   | No                 |
| Dodge/Evasion        | Yes                |
| Sprint/Fast movement | Yes                |
| Ultimate             | No — uses cooldown |

Exact stamina costs are still to be balanced.

---

# 23. Combat System

Every species has:

* Basic Attack
* Skill 1
* Skill 2
* Ultimate

Basic Attack, Skill 1, and Skill 2 are fixed abilities.

The Ultimate is customizable through the Genome system.

Combat is not required for every quest.

Some quests can focus more on:

* Exploration
* Restoration
* Investigation
* Environmental interaction

---

# 24. Death and Respawn

If the player's current animal dies:

1. The animal dies.
2. The player respawns at the last checkpoint.

Exact checkpoint and death penalties are not yet finalized.

---

# 25. Chimera System

Each major biome has its own Chimera.

During a Chimera battle, the player can switch between all species unlocked within that biome.

Example:

```text
Frog
 ↕
Salamander
 ↕
Water Monitor
```

Transformation has a cooldown.

This encourages strategic species switching.

The player should not simply stay in the strongest form.

Different species should be useful against different boss mechanics.

---

# 26. Wetlands Chimera

The Wetlands Chimera is:

> **Snail–Cane Toad Chimera**

It is a mutated creature created by the genome-energy accident.

It combines characteristics of a snail and cane toad and has become highly aggressive.

---

# 27. Wetlands Chimera Battle

The Wetlands Chimera uses:

> **Phases + Adaptive Behavior**

The boss reacts to the player's current animal.

---

## Phase 1 — Chase / Mobility

The boss focuses on chasing the player.

The Frog is especially useful because of:

* High mobility
* Jumping
* Evasion

---

## Phase 2 — Toxic Territory

The boss creates or uses dangerous toxic areas.

The Salamander becomes useful because of:

* Poison
* Recovery
* Survival

---

## Phase 3 — Brutal Clash

The boss becomes more physically aggressive.

The Water Monitor becomes useful because of:

* High Health
* High Attack Power
* Durability
* Heavy attacks

---

# 28. Wetlands Chimera Weak Points

The Chimera has temporary weak points.

The general sequence is:

```text
Boss performs major attack
        ↓
Attack finishes
        ↓
Boss becomes briefly vulnerable
        ↓
Weak point appears
        ↓
Player has short attack window
        ↓
Weak point disappears
```

Different animals can exploit weak points differently.

### Frog

Reaches the weak point quickly.

### Salamander

Applies poison to the weak point.

### Water Monitor

Deals heavy damage to the weak point.

This system encourages the player to switch animals strategically.

---

# 29. Wetlands Chimera Defeat

Defeating the Wetlands Chimera has two major consequences.

## 29.1 Wetland Restoration

Wetland Restoration Progress increases significantly.

The environment begins to recover.

Possible visible changes include:

* Cleaner water
* More vegetation
* Native animals returning
* Fewer invasive creatures
* Healthier wetland areas

---

## 29.2 Genome Core

The Chimera contains or drops a:

> **Genome Core**

Sterling analyzes the Genome Core.

The Core contains information that helps identify the location of other scattered genomes.

The next major destination is:

> **Rainforest**

---

# 30. Environmental Restoration

GenoMorph contains a:

> **Wetland Restoration Progress**

system.

The player can improve the ecosystem by completing environmental activities.

Possible activities include:

* Removing trash
* Cleaning polluted water
* Defeating invasive Chimeras
* Helping native animals
* Completing environmental quests
* Restoring plants
* Removing invasive species
* Collecting scientific data
* Finding lost genomes

The exact activity list is still being finalized.

---

# 31. GenoMorph Database

The player has a persistent:

> **GenoMorph Database**

The Database records educational discoveries.

Possible categories include:

* Species
* Ecosystems
* Invasive Species
* Environmental Problems
* Adaptations
* Food Chains
* Research
* Discoveries

The exact category structure is still being finalized.

---

# 32. Interactive Knowledge System

Players can interact with environmental objects.

Potential objects include:

* Plants
* Animals
* Trash
* Water
* Trees
* Rocks
* Coral
* Other environmental objects

Interacting with an object can provide educational information.

The information is then saved permanently in the:

> **GenoMorph Database**

For example:

```text
Player discovers plant
        ↓
Interact
        ↓
Learn information
        ↓
Information saved to Database
```

Currently, knowledge is educational/collectible only.

It does not directly affect gameplay.

---

# 33. Sterling's Radio

Sterling communicates with the player through radio.

The radio can be used for:

* Story information
* Mission instructions
* Environmental explanations
* Animal information
* Genome information
* Scientific explanations
* Warnings
* Guidance

Sterling is the player's primary source of scientific context.

---

# 34. Wetlands Tutorial

The Wetlands act as the main tutorial area.

The tutorial should gradually teach:

* Movement
* Jumping
* Basic Attack
* Skills
* Dodge
* Stamina
* Transformation
* Collecting
* Quests
* Database
* Radio
* Environmental interactions

The first tutorial enemy is:

> **Mosquito / Mosquito Swarm**

This introduces basic combat without immediately overwhelming the player.

---

# 35. Existing Wetland Animal Models

Existing 3D models include:

* Worm
* Rat
* Snake
* Tilapia
* Dalag
* Snail

Potential roles:

---

## Worm

Possible role:

* Neutral
* Helpful

Educational topics:

* Soil health
* Decomposition

---

## Rat

Possible role:

* Invasive enemy

Educational topics:

* Waste
* Pollution
* Invasive populations

---

## Snake

Possible role:

* Predator
* Neutral animal

Educational topics:

* Food chains
* Predator/prey relationships

---

## Tilapia

Possible role:

* Introduced/invasive species

Educational topics:

* Competition with native fish
* Introduced species

---

## Dalag

Possible role:

* Native species
* Rescue/protection objective

Educational topics:

* Native biodiversity

---

## Snail

Possible role:

* Neutral animal
* Quest-related animal
* Connection to Wetlands Chimera

Educational topics:

* Food chains
* Ecosystem relationships

These roles remain subject to refinement.

---

# 36. Wetlands Species

The current Wetlands roster is:

1. Frog
2. Salamander
3. Water Monitor

Progression:

> **Frog → Salamander → Water Monitor**

---

# 37. Frog

## Role

> **Agile Controller**

The Frog specializes in:

* Mobility
* Stamina
* Jumping
* Crowd Control
* Swimming
* Exploration

Weaknesses:

* Low Health
* Low durability
* Lower sustained damage

---

# 38. Frog Abilities

## Basic Attack — Webbed Lunge

A close-range melee attack.

Effects:

* Deals physical damage
* Damage scales with Attack Power
* No stamina cost

---

## Skill 1 — Sticky Tongue Whip

The Frog uses its tongue to pull targets toward itself.

Possible uses:

* Pull small enemies
* Pull light objects
* Crowd control
* Positioning

No stamina cost.

---

## Skill 2 — Splashdown Jump

The Frog performs a targeted leap.

Upon landing:

* Creates an AoE impact
* Damages nearby enemies

This ability consumes stamina.

---

# 39. Frog Ultimate System

## Attack — Toxic Trail

The Frog becomes highly toxic.

Base duration:

> **8 seconds**

Effects:

* Enemies near the Frog take damage
* Nearby enemies become poisoned
* Frog leaves a poisonous trail while moving
* Enemies touching the trail take damage
* Enemies touching the trail become poisoned
* The trail remains temporarily after the Frog moves away

The trail has its own shorter lifetime.

After the Ultimate ends:

> No new trail is created.

Existing trail sections can remain until their own lifetime expires.

### Genome Progression

#### Level 1

* 8-second duration
* Base poison damage

#### Level 2

* Increased poison damage
* Increased Ultimate duration

#### Level 3

* Further increased poison damage
* Further increased Ultimate duration

---

## Defense — Survival Frenzy

Base duration:

> **8 seconds**

Effects:

* Increased defense
* Increased damage resistance

The Frog has a visible semi-transparent protective bubble/aura.

The bubble communicates that the defensive Ultimate is active.

The bubble:

* Remains visible during the Ultimate
* Disappears when the Ultimate ends

Optional effect:

* Ripple effect when hit

The bubble is primarily a visual indicator of the defensive buff.

It is not intended to function as a literal shield that blocks attacks.

Genome upgrades increase:

* Defensive effectiveness
* Duration

---

## Agility — Swamp Runner

The Frog enters an enhanced agility state.

The original agility concept is retained.

Its purpose is to improve the Frog's mobility.

Exact numerical values remain subject to balancing.

---

# 40. Salamander

## Role

> **Recovery + Poison**

The Salamander specializes in:

* Health recovery
* Poison
* Sustained combat
* Survival

---

# 41. Salamander Abilities

## Basic Attack — Bite

A straightforward melee attack.

Effects:

* Physical damage
* No poison
* No stamina cost

---

## Skill 1 — Regenerative Skin

The Salamander restores health over time.

The player can:

* Move while recovering
* Continue fighting while recovering

---

## Skill 2 — Toxic Secretion

The Salamander creates a poisonous area.

Enemies inside can receive poison stacks.

---

# 42. Salamander Poison System

Poison deals damage over time.

Maximum:

> **3 stacks**

Stack structure:

```text
1 Stack = Poison Level 1
2 Stacks = Stronger Poison
3 Stacks = Maximum Poison
```

A fourth application does not create a fourth stack.

Instead:

> The poison duration is refreshed.

---

## Poison Application

The chosen application system is:

> **One stack per successful application/hit with a short interval.**

This prevents the player from instantly applying all three stacks.

The system rewards keeping enemies inside the poisonous area.

---

# 43. Salamander Ultimate System

## Attack — Toxic Predator

The player chose the buff-based version.

The Ultimate enhances the Salamander's existing abilities.

Base duration:

> **8 seconds**

### Bite

* Increased damage
* Faster attack speed

### Regenerative Skin

* Stronger recovery effect

### Toxic Secretion

* Increased poison effectiveness
* Potentially faster poison application

The Salamander enters a more aggressive state.

Genome upgrades improve:

* Offensive effectiveness
* Poison effectiveness
* Duration

---

## Defense — Regenerative Survivor

Base duration:

> **8 seconds**

The defensive design uses a similar visual language to Frog's Survival Frenzy.

Effects:

* Increased damage resistance
* Increased Health Recovery

Visual:

* Semi-transparent protective bubble

The bubble remains visible during the Ultimate and disappears afterward.

Optional effect:

* Ripple when hit

### Genome Progression

#### Level 1

* Base damage reduction
* Recovery enhancement

#### Level 2

* Increased damage reduction
* Increased Health Recovery
* Increased duration

#### Level 3

* Further increased damage reduction
* Further increased Health Recovery
* Further increased duration

---

## Agility — Toxic Adaptation

The original agility design is retained.

Effects include:

* Increased movement speed
* Faster stamina recovery
* Reduced dodge cost
* Shorter dodge cooldown
* Faster recovery after being hit

Exact values remain subject to balancing.

---

# 44. Water Monitor

## Role

> **Bruiser**

The Water Monitor focuses on:

* Power
* Durability
* Heavy physical attacks

It is not intended to be a pure tank.

---

# 45. Water Monitor Abilities

## Basic Attack — Claw Slash

A close-range claw attack.

Deals physical damage.

---

## Skill 1 — Tail Sweep

The Water Monitor performs a wide tail attack.

Effects:

* Wide attack area
* Moderate damage
* Knockback
* Cooldown
* Noticeable wind-up

Does not consume stamina.

---

## Skill 2 — Crushing Bite

A powerful single-target attack.

Effects:

* High damage
* Brief stagger
* Effective against strong enemies
* Useful against bosses

---

# 46. Water Monitor Ultimate System

## Attack — Crushing Maul

The attack follows:

> **Bite → Grab → One Massive Slam → AoE Impact**

The Water Monitor:

1. Bites the target.
2. Grabs the target.
3. Performs one massive slam into the ground.
4. Creates an AoE impact.

### Primary Target

The grabbed target receives:

* Very high damage
* Heavy stagger

### Nearby Targets

Nearby enemies receive:

* Lower damage
* Knockback

### Large Enemies / Bosses

If an enemy is too large to physically grab:

* The Water Monitor still performs the bite-and-slam motion.
* The enemy receives the intended damage and stagger.
* The enemy is not physically lifted.

Important:

> The attack is ONE massive slam.

It is not a repeated pounding attack.

---

## Defense — Iron Hide

The Water Monitor enters a defensive state.

Current Ultimate duration standard:

> **8 seconds**

The Ultimate focuses on increased durability and defensive strength.

Exact numerical values remain subject to balancing.

---

## Agility — Relentless Hunter

The Water Monitor enters an enhanced mobility/agility state.

The original concept is retained.

Exact numerical values remain subject to balancing.

---

# 47. Wetlands Ultimate Summary

| Species       | Attack             | Defense                   | Agility               |
| ------------- | ------------------ | ------------------------- | --------------------- |
| Frog          | **Toxic Trail**    | **Survival Frenzy**       | **Swamp Runner**      |
| Salamander    | **Toxic Predator** | **Regenerative Survivor** | **Toxic Adaptation**  |
| Water Monitor | **Crushing Maul**  | **Iron Hide**             | **Relentless Hunter** |

---

# 48. Frog to Salamander Evolution Quest

The first evolution quest should be relatively short.

Target duration:

> **10–15 minutes**

The purpose is to introduce the player to the Evolution Quest system.

---

## Quest Flow

### 1. Genome Signal

Sterling detects a Salamander genome.

### 2. Follow the Signal

The player follows the signal through the Wetlands.

### 3. Discover the Habitat

The player discovers a surviving Salamander habitat.

### 4. Learn About the Ecosystem

Sterling explains the habitat and its importance.

### 5. Deal With an Invasive Threat

The player handles an immediate environmental threat.

### 6. Recover the Genome

The player discovers the damaged Salamander genome.

### 7. Defend Stabilization

The player protects the area while the genome is stabilized.

### 8. Transformation

The player transforms:

> **Frog → Salamander**

### 9. Ability Tutorial

The player learns the Salamander's abilities.

### 10. Test the Form

The player gets a short opportunity to test the Salamander.

### 11. Quest Complete

The first evolution is complete.

The full restoration system does not need to be forced into this first evolution quest.

---

# 49. Salamander to Water Monitor Evolution Quest

The second Wetlands evolution focuses on:

> **Combat + Survival**

---

## Quest Flow

### 1. Genome Signal

Sterling detects the Water Monitor genome.

### 2. Travel Deeper

The player travels deeper into the Wetlands.

### 3. Stronger Enemies

Stronger invasive creatures appear.

### 4. Use Salamander Abilities

The player uses:

* Regeneration
* Poison
* Sustained combat

### 5. Discover Genome

The player discovers the Water Monitor genome.

### 6. Guardian Enemy

A powerful enemy protects the genome.

### 7. Defeat Guardian

The player defeats the enemy.

### 8. Transformation

The player transforms:

> **Salamander → Water Monitor**

### 9. Ability Tutorial

The player learns:

* Claw Slash
* Tail Sweep
* Crushing Bite

### 10. Quest Complete

The Water Monitor becomes available.

---

# 50. Wetlands to Rainforest Transition

The Wetlands and Rainforest are connected regions of the same world.

The transition should feel natural.

The recommended structure is:

```text
Wetlands Chimera defeated
        ↓
Wetland begins restoration
        ↓
Genome Core recovered
        ↓
Sterling analyzes Core
        ↓
Another genome signal detected
        ↓
Natural route discovered
        ↓
Player travels toward Rainforest
        ↓
Rainforest begins
```

The player should ideally physically travel from the Wetlands into the Rainforest instead of simply selecting another level.

---

# 51. Rainforest

Current progression:

> **Wild Boar → Black Leopard → Eagle**

Gameplay progression:

> **Power → Stealth → Flight**

This is based on gameplay design rather than biological evolutionary relationships.

---

# 52. Wild Boar

## Role

> **Charge / Power**

Wild Boar is an aggressive physical fighter.

Strengths:

* High physical damage
* High stamina
* Strong physical attacks
* Strong charging attacks
* Knockback
* Stagger
* Ability to break certain environmental obstacles

Wild Boar should not be a tank.

Water Monitor already fills the durable Bruiser role.

---

# 53. Wild Boar Attributes

| Attribute          | Priority  |
| ------------------ | --------- |
| Health             | High      |
| Attack Power       | Very High |
| Stamina            | Very High |
| Stamina Recovery   | Low       |
| Cooldown Reduction | Low       |
| Health Recovery    | Moderate  |

---

# 54. Wild Boar Abilities

## Basic Attack — Headbutt

Wild Boar attacks using its head.

Effects:

* Close-range physical damage
* Moderate damage
* Can slightly stagger smaller enemies
* No stamina cost

---

## Skill 1 — Tusk Strike

Wild Boar attacks forward using its tusks.

Effects:

* Higher damage than Headbutt
* Strong physical attack
* Can stagger enemies
* Slightly greater reach than Headbutt
* No stamina cost

---

## Skill 2 — Front Hoof Slam

Wild Boar raises its front body and slams both front feet into the ground.

Effects:

* Area-of-effect physical damage
* Impact around/in front of Wild Boar
* Knocks back smaller enemies
* Can stagger larger enemies
* Provides crowd control

The ability focuses on physical impact rather than another charge.

---

# 55. Wild Boar Ultimate System

## Attack — Wild Charge

Wild Boar lowers its head and charges forward at very high speed.

Effects:

* Heavy damage
* Smaller enemies are knocked away
* Larger enemies receive heavy damage
* Larger enemies receive strong stagger
* Player controls the direction of the charge

Wild Charge is the Wild Boar's signature offensive Ultimate.

---

## Wild Charge Genome Progression

### Level 1

* High damage charge
* Strong knockback against smaller enemies
* Heavy stagger against larger enemies
* Standard charge duration

### Level 2

* Increased damage
* Increased charge duration
* Stronger impact effect
* Improved knockback

### Level 3

* Further increased damage
* Longest charge duration
* Maximum knockback/stagger
* Powerful impact shockwave when charge ends
* Shockwave damages nearby enemies

---

# 56. Wild Boar Defense Ultimate

## Unstoppable

Wild Boar enters a state where it becomes extremely difficult to stop.

Effects:

* High damage resistance
* Strong stagger resistance
* Strong knockback resistance
* Cannot be easily interrupted by normal attacks
* Can continue attacking while taking hits

Core identity:

> **Wild Boar survives by refusing to be stopped.**

This makes it different from the other defensive Ultimates.

---

## Unstoppable Genome Progression

### Level 1

* Damage resistance
* Stagger resistance

### Level 2

* Greater damage resistance
* Complete knockback immunity
* Increased resistance to movement-impairing effects

### Level 3

* Maximum damage resistance
* Cannot be staggered
* Cannot be knocked back
* Attacks during the Ultimate deal slightly increased damage

---

# 57. Wild Boar Agility Ultimate

## Momentum Breaker

Wild Boar uses movement and momentum as its main source of agility.

Core concept:

> **Build momentum and use movement as an advantage.**

---

## Level 1

* Increased movement speed
* Faster acceleration
* Faster turning
* Increased stamina recovery
* Movement builds momentum

---

## Level 2

* Higher maximum momentum
* Maintaining momentum increases movement speed
* Colliding with smaller enemies deals damage
* Colliding with smaller enemies knocks them away
* Reduced stamina cost while moving

---

## Level 3

* Maximum momentum is reached faster
* Increased collision damage
* Increased collision knockback
* Momentum can be maintained through multiple enemy collisions
* Dodging at high momentum creates a short speed burst

---

# 58. Wild Boar Exploration

Wild Boar has two unique exploration abilities.

---

## Digging

Wild Boar can dig using its snout.

Possible uses:

* Find buried objects
* Find collectibles
* Find hidden items
* Discover hidden paths
* Locate genome-related objects

---

## Scent Tracking

Wild Boar can use its sense of smell to detect:

* Hidden animals
* Enemies
* Collectibles
* Quest targets
* Animal trails

This mechanic can also support the educational aspect.

Sterling can explain how real Wild Boars use their sense of smell.

---

# 59. Wild Boar Weaknesses

Wild Boar is powerful but has several weaknesses.

### Lower Agility

Wild Boar is less agile than Frog.

### Slower Turning

The player has less precise turning during movement.

### Low Stamina Recovery

Wild Boar can have high stamina but recovers it more slowly.

### Longer Cooldowns

Wild Boar abilities can have longer cooldowns.

### Limited Range

Wild Boar is primarily a melee fighter.

It is less effective at sustained ranged combat.

---

# 60. Wild Boar Identity

The overall identity is:

> **Power + Momentum + Exploration**

### Combat

* Strong physical attacks
* High stamina
* Strong charge
* Crowd control
* High damage

### Exploration

* Digging
* Scent Tracking
* Environmental obstacle breaking

---

# 61. Wild Boar vs Water Monitor

The two species should not feel like copies of each other.

## Water Monitor

Role:

> **Bruiser**

Focus:

* Durability
* Heavy damage
* Physical toughness

## Wild Boar

Role:

> **Charge / Power**

Focus:

* Momentum
* Stamina
* Aggressive movement
* Charging
* Exploration utility

---

# 62. The Broken Forest

The Wild Boar is unlocked through the Rainforest quest:

> **The Broken Forest**

The quest introduces:

* Rainforest
* Environmental damage
* Wild Boar
* Restoration
* Genome recovery

---

# 63. The Broken Forest — Quest Flow

## 1. Enter the Rainforest

Sterling guides the player through the newly discovered route from the Wetlands.

The player enters a heavily damaged part of the Rainforest.

---

## 2. Investigate the Damage

The player sees:

* Fallen trees
* Damaged vegetation
* Polluted areas
* Invasive species
* Signs of ecological collapse

Sterling explains the environmental damage.

---

## 3. Follow Wild Boar Tracks

The player discovers Wild Boar tracks.

The player follows them deeper into the forest.

Along the way, the player can:

* Interact with environmental objects
* Discover information
* Add information to the GenoMorph Database

---

## 4. Restore the Area

The player completes several small restoration tasks.

Potential tasks:

* Remove invasive plants
* Clear debris
* Defeat invasive animals
* Help trapped native wildlife

The area gradually becomes healthier.

---

## 5. Discover the Wild Boar

The player eventually discovers a surviving Wild Boar.

The Wild Boar has adapted to the damaged forest and uses the area as its territory.

This encounter introduces the player to Wild Boar behavior.

---

## 6. Discover the Genome

Sterling detects the Wild Boar genome.

The genome is partially damaged or affected by the environmental disturbance.

The player must reach and recover it.

---

## 7. Genome Stabilization

While the genome is being stabilized, an invasive creature attacks.

The player protects the area until Sterling completes stabilization.

---

## 8. Transformation

The GenoMorph Suit successfully absorbs the Wild Boar genome.

The player unlocks:

> **Wild Boar Transformation**

---

## 9. Wild Boar Tutorial

The player learns:

* Headbutt
* Tusk Strike
* Front Hoof Slam
* Digging
* Scent Tracking

The player gets a short opportunity to test the new form.

---

## 10. Quest Complete

The restored section becomes a healthier area of Rainforest.

The player can continue deeper into the Rainforest.

---

# 64. Black Leopard

Current planned progression:

> **Wild Boar → Black Leopard → Eagle**

The Black Leopard's intended general role is:

> **Stealth + Burst Damage + Mobility**

However, this is not yet finalized.

Potential design areas include:

* Stealth
* Ambush
* Pouncing
* Climbing
* Tracking
* Burst damage
* High mobility

The exact:

* Basic Attack
* Skill 1
* Skill 2
* Attack Ultimate
* Defense Ultimate
* Agility Ultimate
* Genome progression
* Exploration mechanics
* Attributes
* Weaknesses
* Evolution Quest

have not yet been designed.

---

# 65. Eagle

Current role:

> **Flight**

The Eagle is intended to be the third Rainforest species.

The exact design has not yet been established.

Potential future design areas:

* Flight mechanics
* Aerial combat
* Ranged attacks
* Dive attacks
* Air mobility
* Exploration
* Attack Ultimate
* Defense Ultimate
* Agility Ultimate
* Genome progression
* Attributes
* Evolution Quest

---

# 66. Mountain

Current progression:

> **Tamaraw → Bear → Goat**

The Mountain biome has not yet been fully designed.

Still needed:

* Species roles
* Attributes
* Basic attacks
* Skills
* Ultimates
* Genome progression
* Exploration abilities
* Evolution Quests
* Mountain Chimera
* Restoration system
* Mountain environment

---

# 67. Final Boss Concept

The current final boss concept is:

> **A giant mutated Chimera capable of transforming between different forms.**

This creates a final:

> **Transformation vs. Transformation**

battle.

Unlike normal Chimera battles, where only the player transforms, the final boss would also transform.

The exact boss design is not yet finalized.

Still needed:

* Boss forms
* Boss phases
* Attacks
* Weaknesses
* Transformation mechanics
* Story purpose
* Final encounter structure
* Ending

---

# 68. Genome Roster

The GenoMorph Suit originally contained:

> **12 native genomes**

All 12 genomes were released during the Wetlands accident.

Current base-game plan:

> **9 playable species/genomes**

The remaining:

> **3 genomes**

are reserved for future:

* Biomes
* Expansions
* Updates
* Additional content

---

# 69. Current Species Roster

| Biome      | Species 1 | Species 2     | Species 3     |
| ---------- | --------- | ------------- | ------------- |
| Wetlands   | Frog      | Salamander    | Water Monitor |
| Rainforest | Wild Boar | Black Leopard | Eagle         |
| Mountain   | Tamaraw   | Bear          | Goat          |

---

# 70. Current Species Roles

| Species       | Role                             |
| ------------- | -------------------------------- |
| Frog          | Agile Controller                 |
| Salamander    | Recovery + Poison                |
| Water Monitor | Bruiser                          |
| Wild Boar     | Charge / Power                   |
| Black Leopard | Stealth + Burst + Mobility — TBD |
| Eagle         | Flight — TBD                     |
| Tamaraw       | TBD                              |
| Bear          | TBD                              |
| Goat          | TBD                              |

---

# 71. Current Wetlands Progression

```text
Small Native Frog
       ↓
Evolution Quest
       ↓
Salamander
       ↓
Evolution Quest
       ↓
Water Monitor
       ↓
Wetlands Chimera
       ↓
Wetland Restoration
       ↓
Genome Core
       ↓
Rainforest
```

---

# 72. Current Rainforest Progression

```text
Wetlands
   ↓
Genome Core
   ↓
Rainforest
   ↓
The Broken Forest
   ↓
Wild Boar
   ↓
Black Leopard
   ↓
Eagle
```

---

# 73. Core Gameplay Loop

The intended gameplay loop is:

```text
Explore
   ↓
Discover Environmental Problems
   ↓
Complete Quests
   ↓
Fight / Avoid Invasive Creatures
   ↓
Recover Genomes
   ↓
Unlock New Animal Forms
   ↓
Level Species
   ↓
Earn Attribute Upgrades
   ↓
Earn Genomes
   ↓
Upgrade / Change Ultimate
   ↓
Restore Ecosystem
   ↓
Explore Further
   ↓
Encounter Chimera
   ↓
Switch Between Species
   ↓
Defeat Chimera
   ↓
Restore Biome
   ↓
Unlock Next Region
```

---

# 74. Transformation Gameplay Philosophy

Transformation should be an important strategic mechanic.

The player should not think:

> "This new animal is stronger, so I will always use it."

Instead, the player should think:

> "Which animal is best for this situation?"

Example:

### Frog

Best for:

* Fast movement
* Jumping
* Reaching weak points
* Crowd control
* Swimming

### Salamander

Best for:

* Recovery
* Poison
* Sustained combat

### Water Monitor

Best for:

* Heavy damage
* Durability
* Boss encounters
* Strong physical attacks

### Wild Boar

Best for:

* Charging
* Breaking obstacles
* Momentum
* High physical damage
* Digging
* Scent tracking

---

# 75. Biome Switching Rule

After finishing a biome, the player can bring:

> **Only one species from the previous biome**

into the next biome because of the damaged suit.

For example:

```text
Wetlands
Frog
Salamander
Water Monitor
        ↓
Rainforest
        ↓
Player chooses ONE Wetlands species to carry
```

The player can later return to the previous biome.

When returning, the player can change which previous-biome species is being carried.

This keeps older biomes relevant.

---

# 76. Chimera Switching Rule

During a Chimera fight, the player can switch among all species unlocked in that biome.

Example:

```text
Wetlands Chimera

Frog
 ↕
Salamander
 ↕
Water Monitor
```

This is separate from the rule for bringing one previous-biome species into a new biome.

---

# 77. Environmental Interaction Philosophy

Animals should interact with the environment according to their natural traits.

Examples:

### Frog

* Jump
* Swim
* Reach difficult areas

### Salamander

* Survive hazardous environments
* Use poison-related interactions

### Water Monitor

* Physical strength
* Heavy obstacles

### Wild Boar

* Dig
* Track scents
* Break certain obstacles

This helps make each transformation feel meaningful outside combat.

---

# 78. Educational Integration

Education should be integrated into normal gameplay.

Instead of stopping gameplay for a long lecture, information can be presented through:

* Short Sterling radio conversations
* Database entries
* Object interactions
* Environmental discoveries
* Animal encounters
* Quest dialogue
* Research collectibles

Example:

```text
Player finds Wild Boar tracks
        ↓
Interact
        ↓
Sterling explains scent tracking
        ↓
Database entry unlocked
```

---

# 79. Restoration Philosophy

Restoration should not feel like a simple progress bar.

The player should see evidence that their actions matter.

For example:

```text
Before Restoration

Dirty water
Dead vegetation
Few native animals
Many invasive species

        ↓

After Restoration

Cleaner water
Healthy vegetation
Returning native animals
Reduced invasive presence
```

The exact number of restoration stages has not yet been finalized.

---

# 80. Species Design Philosophy

Every species should answer three questions:

### 1. What is this animal good at?

Example:

> Frog = mobility

### 2. What is this animal bad at?

Example:

> Frog = low durability

### 3. Why would I choose this animal instead of another one?

Example:

> Frog can quickly reach places and control enemies where Water Monitor cannot.

This ensures that species remain strategically relevant.

---

# 81. Current Ultimate Design Philosophy

Ultimates are not necessarily completely separate attacks.

Depending on the species and Ultimate path, an Ultimate can be:

* A powerful attack
* A temporary enhanced state
* A defensive state
* A mobility state
* A new combat mechanic

Examples:

### Frog Attack

**Toxic Trail**

A new combat mechanic.

### Salamander Attack

**Toxic Predator**

Enhances existing abilities.

### Water Monitor Attack

**Crushing Maul**

A powerful physical attack.

### Wild Boar Attack

**Wild Charge**

A signature charge.

This variety is intentional.

---

# 82. Current Ultimate Path Philosophy

## Attack

Focus:

> Damage and offensive pressure

## Defense

Focus:

> Survival and resistance

## Agility

Focus:

> Mobility, movement, stamina, or positioning

Each species should interpret these paths differently according to its natural identity.

---

# 83. Current Design Principles

## Rule 1 — Species are not straight upgrades

A new species should provide a new playstyle.

---

## Rule 2 — Previous species remain useful

Unlocking a new animal does not make old animals obsolete.

---

## Rule 3 — Evolution requires quests

New species are unlocked through Evolution Quests.

---

## Rule 4 — Ultimates are customizable

Genomes allow the player to upgrade or change Ultimate paths.

---

## Rule 5 — Every species has independent progression

Levels and attributes belong to individual species.

---

## Rule 6 — Combat should encourage switching

Different species should be useful for different situations.

---

## Rule 7 — Restoration should be visible

The player should see the world become healthier.

---

## Rule 8 — Education should feel natural

Scientific information should be integrated into gameplay.

---

## Rule 9 — Real biology is inspiration

Animal abilities can be exaggerated for gameplay.

---

## Rule 10 — The world should feel connected

Biomes should feel like parts of one ecosystem.

---

# 84. Current Development Status

## Fully / Mostly Established

### Story

* Ecological collapse
* Sterling
* Player
* GenoMorph Suit
* DSEE
* 12 genomes
* Wetlands accident
* Invasive Chimeras

### World

* Third-person 3D
* Biome structure
* Connected-world philosophy
* Wetlands
* Rainforest
* Mountain

### Progression

* Species levels
* Level 15 initial cap
* Attributes
* Attribute upgrade system
* Genome system
* Ultimate paths
* Evolution Quests

### Wetlands

* Frog
* Salamander
* Water Monitor
* Abilities
* Ultimate systems
* Chimera
* Chimera phases
* Chimera weak points
* Restoration concept
* Evolution Quests
* Tutorial concept

### Rainforest

* Wild Boar
* Wild Boar attributes
* Wild Boar abilities
* Wild Boar Ultimate system
* Wild Boar exploration abilities
* Wild Boar weaknesses
* Wild Boar unlock quest
* Rainforest transition

---

# 85. Currently Paused At

The design process is currently paused at:

> **Black Leopard**

The next major design question is:

> **What should the Black Leopard's combat identity be?**

Current planned progression:

```text
Wild Boar
   ↓
Power / Charge
   ↓
Black Leopard
   ↓
Stealth / Burst / Mobility
   ↓
Eagle
   ↓
Flight
```

The Black Leopard should be designed to feel significantly different from Wild Boar.

---

# 86. Unresolved Design Questions

The following systems still need to be designed or finalized.

## World

* Exact Asian location
* Real country vs fictional region
* Exact world map
* World size
* Map structure
* Fast travel
* Loading zones
* NPC settlements

## Story

* Main story structure
* Main antagonist
* Full Chimera origin
* Sterling's deeper backstory
* Final story
* Ending

## Gameplay

* Dodge mechanics
* Enemy AI
* Enemy types
* Difficulty
* Checkpoints
* Respawn penalties
* Exact stamina values
* Exact cooldown values
* Exact damage values

## Progression

* Exact attribute numbers
* Exact level-up reward schedule
* Repeated Genome rewards
* Genome economy
* Ultimate upgrade costs

## Restoration

* Exact restoration percentage system
* Restoration stages
* Exact restoration activities
* Biome restoration rewards
* Whether restoration unlocks areas

## Database

* Exact categories
* Database UI
* Entry format
* Discovery rewards
* Research collectibles

## Rainforest

### Black Leopard

* Role
* Attributes
* Basic Attack
* Skill 1
* Skill 2
* Attack Ultimate
* Defense Ultimate
* Agility Ultimate
* Genome upgrades
* Exploration abilities
* Weaknesses
* Evolution Quest

### Eagle

* Role
* Attributes
* Combat
* Flight
* Exploration
* Ultimates
* Genome upgrades
* Evolution Quest

## Mountain

### Tamaraw

* Full design TBD

### Bear

* Full design TBD

### Goat

* Full design TBD

### Mountain Chimera

* Full design TBD

## Endgame

* Final boss
* Boss transformations
* Final area
* Final restoration state
* Ending
* Remaining three genomes
* Future biomes

---

# 87. Current Game Design Snapshot

## Core Premise

> A young environmentalist becomes trapped in animal form after an experimental genetic transformation suit malfunctions, releasing twelve native genomes into a damaged ecosystem. Guided only by radio communication from the scientist who created the suit, the player must recover the scattered genomes, defeat mutated invasive Chimeras, restore ecosystems, and uncover the truth behind the ecological collapse.

---

## Main Gameplay Fantasy

> **Explore the ecosystem. Transform into animals. Use their unique abilities. Restore the environment. Learn about nature. Recover the genomes.**

---

## Current Biome Progression

```text
                    GENOMORPH
                        |
              ┌─────────┴─────────┐
              |                   |
           WETLANDS           RAINFOREST
              |                   |
              |                   |
        Frog → Salamander     Wild Boar
              → Monitor            ↓
                                  Black Leopard
                                      ↓
                                    Eagle
                                      |
                                  MOUNTAIN
                                      |
                              Tamaraw → Bear
                                      → Goat
```

---

# 88. Current Wetlands Combat Summary

```text
FROG
Role: Agile Controller

Basic:
Webbed Lunge

Skill 1:
Sticky Tongue Whip

Skill 2:
Splashdown Jump

Attack Ultimate:
Toxic Trail

Defense Ultimate:
Survival Frenzy

Agility Ultimate:
Swamp Runner
```

```text
SALAMANDER
Role: Recovery + Poison

Basic:
Bite

Skill 1:
Regenerative Skin

Skill 2:
Toxic Secretion

Attack Ultimate:
Toxic Predator

Defense Ultimate:
Regenerative Survivor

Agility Ultimate:
Toxic Adaptation
```

```text
WATER MONITOR
Role: Bruiser

Basic:
Claw Slash

Skill 1:
Tail Sweep

Skill 2:
Crushing Bite

Attack Ultimate:
Crushing Maul

Defense Ultimate:
Iron Hide

Agility Ultimate:
Relentless Hunter
```

---

# 89. Current Rainforest Combat Summary

```text
WILD BOAR
Role: Charge / Power

Basic:
Headbutt

Skill 1:
Tusk Strike

Skill 2:
Front Hoof Slam

Attack Ultimate:
Wild Charge

Defense Ultimate:
Unstoppable

Agility Ultimate:
Momentum Breaker

Exploration:
Digging
Scent Tracking
```

```text
BLACK LEOPARD
Role:
Stealth / Burst / Mobility

Design:
TBD
```

```text
EAGLE
Role:
Flight

Design:
TBD
```

---

# 90. Design Checkpoint

The project should continue from:

> **Black Leopard — Combat Identity**

The next stage is to define the Black Leopard's:

1. Combat identity
2. Basic Attack
3. Skill 1
4. Skill 2
5. Attack Ultimate
6. Defense Ultimate
7. Agility Ultimate
8. Genome progression
9. Attributes
10. Weaknesses
11. Exploration abilities
12. Evolution Quest

---

# END OF CURRENT GDD
