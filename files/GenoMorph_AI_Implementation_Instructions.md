# GENOMORPH — IMPLEMENTATION INSTRUCTIONS FOR AN AI CODING AGENT

**Give this entire file to the AI (Claude Code, Cursor, etc.) doing the implementation work, as its first message or system context.** It is written to be followed literally. Do not let the agent skip to later phases, invent missing mechanics, or treat draft numbers as final.

**Stack:** Godot + C#.
**Scope of this document:** Phase 1 (Core Combat) and Phase 2 (Adaptive Progression System) only. Do not implement Phase 3 onward (Salamander, species switching, Water Monitor, Rainforest, Mountain) until explicitly told to — those depend on systems this document doesn't cover yet and have their own unresolved design questions.

---

## 0. RULES THE AGENT MUST FOLLOW THROUGHOUT

1. Read this entire document before writing any code.
2. **Never overwrite a LOCKED decision.** Everything marked LOCKED below is settled — implement it as stated, don't redesign it.
3. **Never invent a missing mechanic.** Everything marked OPEN below is genuinely undecided — stub it out, make it configurable/tunable, and flag it back to the human rather than guessing a value and treating it as final.
4. **Treat DRAFT numbers as placeholders, not final balance.** Expose them as easily-tunable values (exported variables, a config resource, etc.) — don't hardcode them deep in logic.
5. **Use data-driven values wherever possible** — see the data models in §3. Don't hardcode per-species numbers into behavior scripts.
6. **Keep species base data separate from species progression state** (see §3) — these are two different data structures for a reason: base data doesn't change at runtime, progression does.
7. **Keep shared player resources (Health, Stamina, Ultimate Charge) separate from per-species progression** — Health/Stamina/Ultimate Charge belong to the Volunteer as a whole, not to any one animal form. This matters even though species-switching itself is a Phase 4 feature not covered here — build the data separation now so it doesn't need retrofitting later.
8. **Use a reusable enemy architecture** — the Mosquito should be built as a base Enemy class/scene that a Rat, Snake, etc. can extend later, not a one-off script.
9. Ask the human for a decision only when an unresolved (OPEN) choice would materially change how something plays — don't ask about trivial implementation details.
10. Do not treat this document's suggestions as locked just because they're written down — if something says DRAFT or OPEN, it stays flexible.
11. **Report implementation status after each milestone** (each numbered step in §4 and §5) — a short summary of what was built and what's still open, not just "done."

---

## 1. WHERE THE PROJECT ACTUALLY STANDS RIGHT NOW

Don't rebuild what already exists. As of this handoff:

**Already implemented:**
- Frog model/form, third-person camera, movement
- Frog's Basic Attack, Skill 1, Skill 2 (as animations/input hookups — see §6 for what they should mechanically do if not already wired)
- Mosquito model and animation assets
- Some Phase 1 combat core: player health tracking, base enemy logic skeleton, a mosquito lunge behavior, a damage calculation script

**Immediate next task, in priority order:** Complete the Frog-vs-Mosquito combat loop using the existing Mosquito model/animations. Everything in §4 below should be understood as "finish this," not "start from zero."

---

## 2. CORRECTIONS TO APPLY — DO NOT USE THE OLD VERSION

Some formulas exist in older design documents in a form that has since been **corrected by explicit design decision**. If the agent has access to `Complete_Design_Specification.md` directly, override these two specific points — everything else in that file is still accurate:

### 2.1 Genome milestone formula — CORRECTED
**Old/incorrect (do not implement):** `GenomeMilestones = floor(Upgrades / 5)` — a flat formula with no escalation.
**Correct, current formula:** Genomes cost AP on an escalating curve, both within a single Genome AND across repeated Genomes in the same attribute. See §5.4 for the full table. This was a genuine late-stage design correction — if you see the flat formula anywhere, it's stale.

### 2.2 AP-per-level — CONFIRMED, use as-is
`Total AP = (CurrentLevel - 1) × 2`, i.e., flat +2 AP per level starting at Level 2, for **28 AP total at Level 15**. This one was already correct in the spec — no change needed, just confirming it explicitly since it was cross-checked against a conflicting draft elsewhere.

---

## 3. DATA MODELS (build these first, before any behavior logic)

```
SpeciesData (static, per-species, does not change at runtime):
    speciesID
    speciesName
    baseHealth
    baseAttackPower
    baseStamina
    baseStaminaRecovery
    baseCooldown
    baseHealthRecovery
    basicAttack (reference/ID)
    skill1 (reference/ID)
    skill2 (reference/ID)
    attackUltimate (reference/ID)
    defenseUltimate (reference/ID)
    agilityUltimate (reference/ID)

SpeciesProgression (per-species, per-player, changes at runtime):
    speciesID
    isUnlocked
    currentXP
    currentLevel
    unspentAdaptationPoints
    healthUpgradeCount
    attackPowerUpgradeCount
    staminaUpgradeCount
    staminaRecoveryUpgradeCount
    cooldownReductionUpgradeCount
    healthRecoveryUpgradeCount
    genomesEarned
    genomesSpent
    genomesAvailable
    attackUltimateLevel
    defenseUltimateLevel
    agilityUltimateLevel
    equippedUltimateCategory
```

For Phase 1-2 scope, you only need **Frog's** SpeciesData populated. Build SpeciesProgression to be generic/reusable so it works for any future species without changes.

---

## 4. PHASE 1 — CORE COMBAT (build in this order)

### Step 1: Player Health
- A shared Health resource (not per-species — see rule #7 above).
- Exact base value: **OPEN** — implement as a configurable/exported value, ask the human before finalizing a number if it matters for testing.

### Step 2: Base Enemy (reusable architecture)
- Build a base Enemy class/scene with: health, a detection system, a movement/chase behavior, an attack behavior, a hit-reaction response, and a death sequence.
- This should be generic enough that Rat, Snake, Nutria (Phase 3+) can extend it later without rewriting the core loop.

### Step 3: Enemy AI (state machine)
LOCKED state machine, applies to Mosquito and should generalize to future enemies:
```
Idle → Detect Player → Chase → Attack → Recover → Chase (loop)
(Any state) → Dead
```

### Step 4: Mosquito (concrete implementation of the base Enemy)
- **Detection:** configurable `DetectionRadius`. On player entry: `Target = Player`, `State = Chase`. Immediately hostile, no warning telegraph. Exact radius: OPEN.
- **Chase:** simple flight toward player using `MoveSpeed` and `PreferredAttackDistance` — explicitly do NOT build a full flight simulation. Exact move speed/attack range: OPEN.
- **Attack (Bite):** sequence is: attack begins → wind-up animation → bite/contact frame → damage window opens → apply damage once → damage window closes → recovery → cooldown → repeat.
  - **Critical implementation detail:** apply damage via an Animation Event/Notify fired exactly at the bite contact frame. Do NOT apply damage at attack-state entry. Do NOT leave the hitbox active for the whole animation duration.
  - Single-hit protection logic (implement exactly):
    ```
    HasAppliedDamage = false  (reset each time the attack begins)
    at the contact frame:
        if target valid AND HasAppliedDamage == false AND PlayerDamageCooldown == false:
            ApplyDamage()
            HasAppliedDamage = true
    ```
  - Damage: ~10 (DRAFT/tunable). Exact attack cooldown: OPEN.
- **Death:** at `CurrentHealth <= 0` → `State = Dead` → stop AI → stop attacking → disable attack hitbox → play death animation → deactivate/destroy after animation completes.
- **HP:** ~100 (DRAFT/tunable).

### Step 5: Frog vs Mosquito (the actual combat loop)
- Wire up Frog's existing Basic Attack, Skill 1, Skill 2 against the Mosquito using the damage formula in §5.3 below.
- Damage numbers: display on successful hit, as whole numbers (round only for display — keep internal float precision, e.g. compute 12.6 internally, show "13").
- No random critical hits — ever. This is LOCKED across the whole combat system, not just this fight.
- Player hit reaction: a brief flinch only. Player remains controllable. Do NOT implement a stun-lock or disable movement.
- Player damage cooldown: after the player takes a hit, briefly ignore further incoming hits. Exact duration: OPEN.
- No universal player-attack-interruption rule exists — don't invent one (e.g., don't assume getting hit cancels the player's current attack unless told to).

**Testing requirement before calling this step done:** test with 1 Mosquito (verify every behavior above works cleanly), then 2 (verify overlapping attacks/cooldowns behave correctly), then 3 (verify the player stays responsive and the fight feels fair, not overwhelming).

### Step 6: Interaction System
- A generic "Interact" action the player can trigger near designated objects/points. This will be reused for investigation clues, genome discovery, and other future interactions — build it generic, not Mosquito/Q01-specific.

### Step 7: Investigation Card (UI)
- A UI element that appears when the player investigates an environmental clue. Design content of *what* it says is not this document's scope — build the UI system/container first.

### Step 8: Quest/Objectives System
- Needs to support: an active objective, a visible waypoint that points to a *general area* rather than an exact forced path (this is an explicit design requirement, not a nice-to-have — see the actual Q01 flow in the game design doc for why), and quest completion triggering rewards (XP, per Phase 2).

### Step 9: Q01 Environment
- Build the actual space: starting area (safe, no combat) → investigation point(s) → Mosquito encounter → Mosquito swarm → rat-disturbance discovery point.
- Note: Q01 has a genuine player-choice branch built in — the player can choose which of several environmental clues to investigate first, and whichever one they pick first is the one that advances the quest. Build the investigation-point system to support more than one valid starting clue, not just a single hardcoded path.

### Step 10: Sterling Radio System
- A system for triggering voice-line/dialogue radio barks at scripted moments (reacting to investigation, reacting to the Mosquito encounter, etc.). Content of the lines is a writing task, not a coding task — build the trigger/playback system.

### Step 11: Complete Q01
- Integration milestone: all of the above working together as one continuous playable sequence, matching the beat-by-beat flow described in the game design documentation.

---

## 5. PHASE 2 — ADAPTIVE PROGRESSION SYSTEM

### Step 12: XP
- Formula: `currentXP += XPReward` — simple accumulation across level thresholds.
- XP curve (per-level XP required) and enemy/quest XP reward values are all DRAFT/tunable — implement as data, not hardcoded constants. See the Progression Economy document for current best-guess values if you need something to test against.

### Step 13: Level
- Level range: 1-15. Level cap of 15 is DRAFT/WORKING, not fully final — but safe to build against for now.

### Step 14: AP (Attribute Points)
- **Note on naming:** call this "AP" or "Attribute Points" in code/variables. Do NOT name anything "Attack Power" as "AP" — that stat should be called `ATK` or `AttackPower` explicitly, to avoid collision. This distinction matters for anyone reading the codebase later.
- Formula: `TotalAP = (CurrentLevel - 1) × 2` — flat +2 AP per level, starting at Level 2. 28 AP total at Level 15. **This is LOCKED, confirmed correct — implement exactly this, not a tiered/variable rate.**

### Step 15: Attributes
- Six attributes: Health, Attack Power (ATK — see naming note above), Stamina, Stamina Recovery, Cooldown Reduction, Health Recovery.
- Generic attribute formula: `Base × (1 + 0.05 × Upgrades)` — linear 5% boost per upgrade point spent.
- Cooldown Reduction formula specifically: `BaseCooldown × (1 - 0.03 × Upgrades)` — linear 3% reduction per upgrade (different formula shape than the others — don't apply the generic +5% formula to Cooldown Reduction).
- Attribute upgrade caps: OPEN — not finalized. Don't hardcode an arbitrary cap; make it configurable.

### Step 16: Adaptation Screen (UI)
- The UI where the player spends AP on attribute upgrades. Should show current upgrade counts per attribute and let the player commit AP to one at a time.

### Step 17: Genome System — USE THE CORRECTED FORMULA (see §2.1)
- A Genome is earned per attribute independently — Genomes from Health upgrades are separate from Genomes from Attack Power upgrades, etc.
- **Escalating cost, both within one Genome and across repeated Genomes in the same attribute:**

  | Genome # (same attribute) | Per-upgrade-step AP costs (5 steps) | Total AP for this Genome |
  |---:|---|---:|
  | 1st | 1, 1, 2, 2, 3 | 9 |
  | 2nd | 1, 1, 3, 3, 4 | 12 |
  | 3rd | 2, 2, 4, 4, 6 | 18 |
  | 4th | 3, 3, 5, 5, 8 | 24 |

  Implement this as a lookup/formula that scales the base 5-step shape `[1,1,2,2,3]` by roughly ×1.4 per repeat within the same attribute — don't hardcode just the first row and assume the rest follow the old flat `floor(Upgrades/5)` rule.
- A Genome belongs to the species it was earned on — it cannot transfer to a different species (e.g., a Frog Genome cannot be spent on Salamander).
- Track `genomesEarned`, `genomesSpent`, `genomesAvailable` separately per the data model in §3.

### Step 18: Ultimate Progression
- Three paths per species: Attack, Defense, Agility. Three levels per path (1→2→3), no skipping.
- Only one Ultimate path equipped/active at a time per species.
- Spending a Genome either levels up the currently-equipped path, or switches to a different path (which then starts back at Level 1 on that new path). **No free switching from a menu — it always costs a Genome.** This is LOCKED.
- Ultimate progression state does NOT reset when switching species (not relevant until Phase 4, but store the data now per the SpeciesProgression model so it doesn't need retrofitting).
- Exact numerical effects of each Ultimate: OPEN — for Phase 1-2 scope you likely don't need Ultimate *effects* implemented yet, just the progression/unlocking data layer (which path is equipped, what level it's at, Genome cost to advance).

---

## 6. FROG'S ABILITY SPECIFICS (for reference while building Step 5)

If Frog's abilities aren't already fully wired mechanically (only animations/input may exist):

- **Basic Attack — Webbed Lunge:** close-range melee, damage scales with Attack Power, no stamina cost.
- **Skill 1 — Sticky Tongue Whip:** pulls small enemies/objects toward the Frog (crowd control / positioning tool) — this is NOT a healing or eating mechanic, despite what an outdated prologue script once implied. No stamina cost.
- **Skill 2 — Splashdown Jump:** targeted leap, AoE damage on landing. Costs stamina.
- Damage multipliers (DRAFT): Basic Attack ×1.00, Skill 1 ×1.50, Skill 2 ×1.80, all multiplying `FinalAttackPower`.
- Damage formula: `FinalDamage = FinalAttackPower × AbilityMultiplier`. No universal enemy Defense stat exists for normal enemies — don't add one.

---

## 7. THINGS EXPLICITLY OUT OF SCOPE FOR THIS PHASE

Do not implement, even if related content exists in the wider design docs:
- Salamander, Water Monitor, or any species beyond Frog
- Species switching (Phase 4)
- Rat, Snake, Nutria, or any enemy beyond Mosquito (though the base Enemy architecture should be generic enough to support them later without rework)
- The Chimera boss fight
- Rainforest or Mountain content
- Dodge, sprint, or swim mechanics — these are deliberately undecided globally and are meant to be decided per-biome/per-system when that content is actually built, not assumed now

If a design question comes up that touches any of these, flag it rather than making an assumption.

---

*Compiled from `Complete_Design_Specification.md` §57-112 (Mosquito spec, combat design, adaptive progression, technical data models, locked/open decision tables, implementation roadmap) with corrections applied from later design decisions — see `GenoMorph_Consistency_Review_Log.md` and `GenoMorph_Progression_Economy_v0.3.md` for the reasoning behind §2's corrections.*
