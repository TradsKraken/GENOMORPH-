# GENOMORPH — START HERE

If you are an AI assistant (or a new collaborator) picking up this project for the first time, read this file first. It tells you what's current, what's superseded, and where to find things. This file itself is not game design content — it's a map.

---

## 1. Read order

1. **This file** (you're here).
2. `GenoMorph_Master_GDD_v1.2.md` — the current master design baseline. High-level: story, world, design philosophy, pillars, species roles, system overviews.
3. `Complete_Design_Specification.md` — the technical/numeric companion. LOCKED implementation details: exact formulas, enemy stats, combat rules, state machines. Treat this as the source of truth for *numbers and mechanics*, the Master GDD as the source of truth for *design intent and narrative*.
4. `GenoMorph_Progression_Economy_v0.3.md` — the worked-out XP/AP/Genome/ATK numeric economy. This is newer and more detailed than anything in the two files above on this specific topic (progression math).
5. `GenoMorph_Consistency_Review_Log.md` — a decision log from an earlier design-consistency review. Explains *why* certain things changed, resolves conflicts between older files, and lists what's still genuinely open. Read this if something looks inconsistent — it was probably already found and either fixed or deliberately deferred.

---

## 2. Which files are current vs. superseded

This project has accumulated several design documents over time, written at different points, some now outdated in specific places. **No single file is entirely wrong** — but several older files contain individual facts that have since been corrected. Do not assume a file is fully authoritative just because it's long or looks formal.

| File | Status |
|---|---|
| `GenoMorph_Master_GDD_v1.2.md` | **Current.** Supersedes the plain `GenoMorph_Master_GDD.md` (if that file still exists in the project, treat the v1.2 version as replacing it). |
| `Complete_Design_Specification.md` | **Current** for technical/numeric LOCKED details, with two known exceptions — see §3 below. |
| `GenoMorph_Progression_Economy_v0.3.md` | **Current.** This is the newest and most detailed source for progression numbers (XP, AP, Genome cost). Where it conflicts with an older file on progression math, this file wins. |
| `PROLOGUE_v1.1.md` | **Current.** Supersedes the original `PROLOGUE.md` — the opening gameplay beat was rewritten to fix a controls/mechanics error. If both exist in the project, use the v1.1 version. |
| `GenoMorph_GDD.md` (the older, non-"Master" GDD) | **Partially superseded.** Still useful for some ability/kit details (its Frog kit description matches what's now also in the Master GDD), but do NOT trust its progression-math claims — see §3. |
| `GenoMorph_Adaptive_Progression_System.md` | **Mostly current** for the AP-per-level rule specifically (see §3), but superseded by the Progression Economy doc for anything about Genome cost. |
| `Genomorph_Paper.docx` | **Superseded / not canon.** This describes an earlier, different prototype (top-down camera, different engine, only 4 species) built for an unrelated school research project. Do not use it for species roster, camera perspective, or any mechanical detail. It has no bearing on the current design. |
| `GenoMorph_Quest_Flow.md` | Still broadly useful for quest-structure philosophy; no known conflicts found, but wasn't exhaustively cross-checked against every other file. |

---

## 3. Known resolved conflicts (don't re-litigate these)

These were found as genuine contradictions between files and have already been decided. If you notice them again, don't flag them as new problems — just apply the resolution:

- **Mountain species order:** `GenoMorph_Master_GDD.md` (old) and other files disagreed on whether Tamaraw→Bear→Goat's *order* was locked. **Resolved:** the roster (those 3 species) is locked; the order is NOT. Reflected in v1.2.
- **AP-per-level:** An earlier progression draft used a tiered rate; `GenoMorph_Adaptive_Progression_System.md` states a flat, correct rule: **+2 AP per level, 28 AP total by Level 15**. **Resolved:** flat rate is correct. Reflected in Progression Economy v0.3.
- **Repeated-Genome cost:** `GenoMorph_GDD.md` said this was unfinalized; `Complete_Design_Specification.md` stated a flat formula with no escalation. **Resolved:** cost escalates for repeated Genomes in the same attribute (~40% more per repeat). This supersedes Complete_Design_Specification's flat formula on this one specific point — everything else in that file is still current. Full table in Progression Economy v0.3 §4.1.
- **Frog's kit missing from the Master GDD:** Salamander and Water Monitor had full ability/Ultimate write-ups; Frog didn't. **Resolved:** copied in from Complete_Design_Specification §34-35, now in Master GDD v1.2 §17.5.1.
- **Prologue's opening gameplay beat:** Used PC controls (`[SPACEBAR]`, `[MOUSE 1]`) and an invented "tongue-heal" ability that didn't exist in Frog's real kit. **Resolved:** rewritten in PROLOGUE_v1.1.md to use mobile HUD highlighting and Frog's real abilities (Sticky Tongue Whip, Webbed Lunge).

Full reasoning for all of these is in the Consistency Review Log if you need it.

---

## 4. Genuinely open items (real design decisions still needed)

Unlike §3, these are NOT resolved — they're honest gaps where a decision hasn't been made yet. Don't guess an answer and present it as fact; flag it as open if asked, or ask the person directly.

- **Frog's Q02 quest ("Investigate the Disturbance") non-linearity:** The person wants quest structure to feel less linear. It was determined that Q02's current LOCKED flow is a single thread (all clues point to the same Rat colony) — making it genuinely forkable requires inventing a *second, distinct* environmental problem, not just reordering. Not designed yet.
- **Rainforest Ultimates:** Wild Boar has three named-only Ultimates (Wild Charge, Unstoppable, Momentum Breaker) with no described effects. Pangolin and Eagle have no Ultimates designed at all.
- **Mountain species identity:** Tamaraw, Bear, and Goat have no gameplay identity defined yet (role, strengths, weaknesses) — deliberately left open per the person's choice, not to be filled in without asking.
- **Movement mechanics** (dodge, sprint, swim, climb, etc.): Deliberately left undecided globally; to be decided case-by-case as each biome/system is actually built, not as a blanket ruling.
- **Coral Reef's 3 species:** Confirmed as a DLC biome, but which 3 species it contains is not yet decided.

---

## 5. How this project likes to work (process notes for an AI assistant)

- The person wants **Wetlands finished first** before Rainforest/Mountain get serious development — but is fine with *light, non-locked* brainstorming on those biomes in parallel.
- When two design docs conflict, **don't assume either one is automatically right** — flag it and ask, the way the Consistency Log's resolved items were handled. Don't apply a blanket "newest file wins" or "most detailed file wins" rule.
- The person has a clear stated aversion to over-linear quest design (see open item above) — keep this in mind if proposing new quest content.
- "AP" always means Attribute Points (the spendable progression currency). The combat stat is "ATK" (Attack Power). Don't let these collide.
- New design decisions, once made, should get written into the actual documents (not left only in chat) — this project treats its .md files as the persistent memory, and expects updates to be reflected there, ideally with a changelog note explaining what changed and why (see how Master GDD v1.2 and PROLOGUE_v1.1 do this).

---

*This file was generated as part of a documentation handoff. If significant new decisions get made after this file was written, it should be updated to reflect them — it's only useful if it stays current.*
