# GENOMORPH — PROGRESSION ECONOMY (First-Pass Draft v0.3)

**Status:** DRAFT — scaffolding for Phase 2, to be tuned against real Wetlands playtesting.
**v0.3 change:** Resolved the repeated-Genome-cost conflict (formerly open item #16) — decided as escalating, not flat. See §4.1.
**v0.2 change:** Corrected AP-per-level to match a LOCKED rule found in `GenoMorph_Adaptive_Progression_System.md` (flat +2 AP/level, not the tiered rate originally drafted here). See §3.
**Target constraint:** A player should reach Level 15 on a single species in **under 1 hour** of normal, non-grinding play.

---

## 1. Design Basis

- AP comes from **both** level-up rewards **and** quest/milestone rewards (per your call).
- Genome cost (5 upgrades in one attribute) should feel **escalating** — cheap to start specializing, pricier to fully commit (per your call).
- The whole curve is sized against a realistic single-species content budget (tutorial combat + 1–2 enemy encounters + investigations + 1–2 quests + a shared Chimera phase), not an idealized formula — an earlier draft at 2x this size didn't fit inside actual Wetlands content, so this version is scaled down accordingly.

---

## 2. XP Curve (Level 1 → 15)

Formula: `XP_to_next(level) = 12 × 1.16^(level-1)`, rounded.

| Level | XP to next level | Cumulative XP |
|------:|------------------:|---------------:|
| 1  | 12 | 12  |
| 2  | 14 | 26  |
| 3  | 16 | 42  |
| 4  | 19 | 61  |
| 5  | 22 | 83  |
| 6  | 25 | 108 |
| 7  | 29 | 137 |
| 8  | 34 | 171 |
| 9  | 39 | 210 |
| 10 | 46 | 256 |
| 11 | 53 | 309 |
| 12 | 61 | 370 |
| 13 | 71 | 441 |
| 14 | 83 | 524 |
| **15** | — | **524 total** |

**Reference XP sources** (placeholder values — tune once real enemy/quest data exists):

| Source | XP |
|---|---:|
| Small enemy (mosquito, single rat) | 3 |
| Medium enemy (snake, nutria) | 8 |
| Investigation / clue found | 5 |
| Small quest/milestone (e.g. Frog rescue) | 40 |
| Major milestone (genome discovery, Chimera phase clear) | 100 |

A realistic single-species arc (≈15 small kills, 5 medium kills, 10 investigations, 2 small quests, 1 major milestone) yields roughly the 400–550 XP needed — i.e., **content-paced**, not grind-paced.

---

## 3. Attribute Points (AP)

**Correction (v0.1 → v0.2):** The original draft here used a tiered leveling rate (+2 for levels 1–5, +1 for levels 6–15, totaling 20 AP). That conflicted with a LOCKED rule found in `GenoMorph_Adaptive_Progression_System.md`: a **flat +2 AP per level**, for a stated total of **28 AP at Level 15**. The flat/LOCKED rule wins — numbers below are corrected accordingly.

### A. Level-up AP (LOCKED)
**+2 AP per level, levels 2–15 (14 level-ups) = 28 AP total from leveling alone.**

### B. Quest/Milestone AP (Wetlands-scale example, still DRAFT)
| Milestone | AP |
|---|---:|
| Native Frog Rescue | 3 |
| Salamander Genome discovered | 3 |
| Water Monitor Genome discovered | 3 |
| Nutria colony cleared | 2 |
| Chimera defeated | 5 |

**Total from milestones (full Wetlands arc): 16 AP**

**Grand total AP available per species (Wetlands-scale content): ~44 AP** (28 leveling + 16 quest)

---

## 4. Genome Cost (Escalating)

A Genome = 5 upgrades in the **same** attribute. Rather than a flat 1-AP-per-upgrade cost (which would make Genomes feel identical every time), each successive upgrade **within the same attribute** costs more:

| Upgrade # (same attribute) | AP cost |
|---|---:|
| 1st | 1 |
| 2nd | 1 |
| 3rd | 2 |
| 4th | 2 |
| 5th (→ Genome earned) | 3 |
| **Total for 1st Genome in that attribute** | **9 AP** |

With ~44 AP available across a full species arc, a player can:
- Rush **one** attribute to its first Genome fairly early (9 AP), **or**
- Spread points across 2–3 attributes for a more balanced build without reaching a Genome as fast — a real playstyle choice, matching the Frog A/Frog B example in the Master GDD (§11.1).

Getting a **second** Genome in a *different* attribute costs another 9 AP baseline (same 5-step curve resets per attribute) — so with 44 total AP, **up to ~4 Genomes** are earnable across a full single-species arc if a player commits most of their points to specialization, which feels appropriately "high specialization by Level 13–15" per the existing Level Purpose table.

### 4.1 Repeated Genomes in the SAME attribute — RESOLVED (was open conflict #16)

**Decision: escalating, not flat.** A 2nd, 3rd, etc. Genome earned from the *same* attribute costs progressively more than the previous one — each subsequent Genome's 5-step cost curve scales up by ~40% per repeat:

| Genome # (same attribute) | Per-step costs | Total AP for this Genome | Cumulative AP spent in this one attribute |
|---:|---|---:|---:|
| 1st | 1, 1, 2, 2, 3 | 9  | 9  |
| 2nd | 1, 1, 3, 3, 4 | 12 | 21 |
| 3rd | 2, 2, 4, 4, 6 | 18 | 39 |
| 4th | 3, 3, 5, 5, 8 | 24 | 63 |

Against the ~44 AP total budget per species arc, this makes the tradeoff real: fully committing to a **2nd Genome in one attribute (21 AP)** eats nearly half the entire arc's AP, while spreading across **3-4 different attributes' first Genomes** (9 AP each) stays the more efficient path. This directly reinforces "adaptation over raw power" — tunnel-visioning one stat is possible but costly, while breadth is naturally rewarded. A 3rd or 4th Genome in one attribute (39-63 AP) is essentially out of reach within a single playthrough's arc, which is appropriate — true hyper-specialization should likely require NG+/endgame grinding, not be reachable in a first pass.

This resolves the conflict between `GenoMorph_GDD.md` ("not yet finalized") and `Complete_Design_Specification.md` (flat formula, no escalation) — **the flat formula is now superseded** by this escalating model.

---

## 5. Open Items Still Needing a Decision

This draft resolves the *shape* of the curve but leaves some values as placeholders:

- Exact enemy/quest XP values above are illustrative — need real numbers once Wetlands enemies are finalized.
- Ultimate Level 1/2/3 costs (in Genomes) are not modeled yet — recommend: 1 Genome per Ultimate level within a chosen path, and 1 additional Genome to switch paths (per Master GDD §13.1), but exact numbers are open.
- This is calibrated for **one species arc** (~Wetlands-scale). Rainforest/Mountain species may need their own recalibration once their content volume (quest count, encounter count) is known — don't assume this table transfers unchanged.
- The ~40%-per-repeat escalation rate in §4.1 is a first-pass guess, not playtested — may need tuning once real Wetlands sessions are observed.

---

## 6. ATK Stat Curve (connects this economy to the Combat Damage Formula)

`Complete_Design_Specification.md` locks the combat damage formula (`FinalDamage = ATK × AbilityMultiplier`, no enemy Defense stat) and drafts enemy HP values, but never states what the ATK stat actually equals at a given level or how AP invested in the Attack attribute converts into ATK. This section proposes that missing link.

**Note on naming:** "AP" below always means **Attribute Points** (the spendable currency from Section 3). The combat stat is written out as **ATK** to avoid collision — see conversation note.

### Base ATK growth (no AP invested)
```
Base ATK(level) = 15 + 4 × (level - 1)
```

### AP → ATK conversion
```
+6 ATK per AP point invested in the Attack attribute
```

| Level | Base ATK (0 AP in Attack) | ATK w/ 1 full Genome in Attack (9 AP) |
|------:|---------------------------:|----------------------------------------:|
| 1  | 15 | 69  |
| 5  | 31 | 85  |
| 10 | 51 | 105 |
| 15 | 71 | 125 |

### Sanity check against locked/draft enemy HP (Frog, Basic Attack, no AP invested)

| Enemy | HP | Hits to kill @ Lvl 1 | Hits to kill @ Lvl 8 | Hits to kill @ Lvl 15 |
|---|---:|---:|---:|---:|
| Mosquito | 100 | 6.7 | 2.3 | 1.4 |
| Rat | 180 | 12.0 | 4.2 | 2.5 |
| Snake | 300 | 20.0 | 7.0 | 4.2 |
| Nutria | 450 | 30.0 | 10.5 | 6.3 |
| Colony Defender | 1500 | 100.0 | 34.9 | 21.1 |

This shape roughly matches the story's difficulty ramp — Mosquito is a real tutorial threat at Level 1 and trivial by Level 15 (older enemies stop mattering, matching Design Rule 14's spirit for enemies too), while Colony Defender stays a genuine fight throughout. **This has not been checked against Skill 1/Skill 2 multipliers or against non-Frog species' multipliers — those need their own pass once each species' full kit is confirmed.**

### Open items in this section
- Only modeled against **Frog**. Salamander/Water Monitor multipliers exist in Complete_Design_Specification but weren't cross-checked here.
- Player Damage Cooldown duration is explicitly OPEN/TUNABLE in the spec — not modeled.
- This assumes AP-to-ATK conversion is **flat and linear** (+6 per point) — no diminishing/increasing returns considered yet; worth revisiting once real playtesting happens.

---

*This document is a starting scaffold for Phase 2 (Recommended Development Order, Master GDD §62). Numbers are expected to shift once tested against actual Wetlands gameplay.*
