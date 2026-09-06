# GENOMORPH — CONSISTENCY REVIEW LOG (Session 1)

This log captures decisions and open follow-ups from the consistency-review pass across the project's design docs. Treat this as a companion to the Master GDD / Complete_Design_Specification — it records *what was decided in conversation* and *what still needs work*, not new locked canon by itself.

---

## DECISIONS MADE

### 1. Paper vs. GDD family
`Genomorph_Paper.docx` (top-down, Godot/C#, 4 species, Valencia National High School research project) is a **superseded prototype**. The GDD family (Master GDD, Complete_Design_Specification, Quest Flow, Prologue) is the real, current direction. Do not treat the Paper's specifics (species roster, camera, engine) as canon going forward.

### 2. Camera perspective
**Both third-person AND top-down are real, player-toggleable views** — not a which-one-wins decision. The Master GDD's "Perspective: Third-person ↔ top-down" control entry is correct as written; this was a genuine hybrid design, not a leftover.

### 3. Coral Reef
Confirmed as the home for all **3 future/DLC genome slots** — Coral Reef will be a 3-species biome (mirroring the Wetlands/Rainforest/Mountain pattern), planned as **post-launch/DLC**, not base-game scope.
**Action needed:** Write this explicitly into Master GDD §7.4 / §60 (Future Content) — currently only implied by the Prologue's worldbuilding, not stated as a roadmap decision anywhere.

### 4. Prologue control prompts — RESOLVED
The `[SPACEBAR] to Leap` / `[MOUSE 1] to Feed` PC-style prompts in `PROLOGUE.md`'s opening gameplay beat were wrong — contradicted the locked mobile touch-only control scheme everywhere else.
**Action taken:** Rewrote the beat using real mobile UX (HUD highlighting the joystick and the actual on-screen **Skill 1**/**Attack** buttons), not a find-and-replace of the old labels. See `PROLOGUE.md` changelog for details.

### 5. Movement mechanics (dodge/sprint/swim/etc.)
Stay **unconfirmed/OPEN**, decided **case-by-case per biome** as each is actually built — not a global ruling now. Conditional clauses (e.g., Salamander's Agility Ultimate mentioning dodge) should stay flagged as "pending: dodge decision, owned by Wetlands combat implementation," not resolved prematurely.

### 6. Rainforest/Mountain development approach
**Sequential build, parallel light-documentation**: Wetlands stays the build priority (per Master GDD's own Phase 1→2→3 order), but loose/non-locked brainstorming on Rainforest and Mountain content is fine to do alongside it, so those sections aren't OPEN purely by neglect.

### 7. Mountain species identity (Tamaraw/Bear/Goat)
Stay **fully open** — no rough identity direction wanted yet. **Additionally: the species ORDER (Tamaraw→Bear→Goat) is also not final**, not just their kits/identities. Treat this sequence as unconfirmed, unlike Wetlands (Frog→Salamander→Water Monitor) and Rainforest (Wild Boar→Pangolin→Eagle), which remain locked.

### 8. Frog's Prologue tongue mechanic vs. real kit — RESOLVED
The Prologue's "tap to feed, tongue snaps out, instantly heals" beat did not match any real Frog ability. Frog's actual LOCKED kit (Complete_Design_Specification.md §34) is:
- Basic Attack: **Webbed Lunge**
- Skill 1: **Sticky Tongue Whip** (pull small enemies/objects — NOT a heal)
- Skill 2: **Splashdown Jump** (targeted AoE landing damage)

**Action taken:** Rewrote the beat to demonstrate the real kit — Sticky Tongue Whip pulls the Mosquito in, Webbed Lunge finishes it — instead of the invented heal-on-eat action. Combined with the control-prompt fix (#4) in one rewrite pass, since both lived in the same beat.

### 9. Source authority: Complete_Design_Specification.md vs. Master GDD
`Complete_Design_Specification.md` is confirmed as the **updated source** — it contains fully LOCKED content (e.g., Frog's named kit, the damage formula, enemy HP table) that is simply *missing* from the Master GDD, which was supposed to be the "consolidated baseline" but isn't fully consolidated.
**Ruling:** No blanket precedence — conflicts are resolved **case-by-case**, flagged individually as found. (First resolved case: Frog's kit — Complete_Design_Specification wins, Master GDD needs the section copied in.)
**Action needed:** Master GDD is missing Frog's full ability/ultimate section (has Salamander and Water Monitor's, not Frog's). Should be copied in from Complete_Design_Specification §34-35 for internal consistency.

### 10. "AP" naming collision
**AP** = Attribute Points (spendable progression currency) ONLY, going forward.
**ATK** = the Attack Power combat stat (from Complete_Design_Specification's damage formula), always spelled out or abbreviated as ATK, never AP.
This applies to this conversation and any docs/code produced from it — worth carrying into official documentation to avoid downstream confusion (design docs, UI labels, code variable names).

### 11. Non-linearity — scope narrowed
Confirmed the "too linear" complaint is specifically about **quest structure within a biome** (not biome order, not species order — both stay locked). Further narrowed to: apply **reorderable player choice** (Option B) to the **front half of each species section** (the "investigate/discover the problem" beats), not the transformation/genome-unlock payoff beats, which should stay consistent.
**Key constraint discovered:** The existing "parallel-feeling" encounters (Rat, Snake) are NOT actually parallel — Rat happens as Frog and unlocks Salamander; Snake happens as Salamander and unlocks Water Monitor. The transformation chain is a skill-gate (each animal solves the next problem), so cross-species reordering would break the core "adaptation not power" thesis. Reorderable choice must live **within** a single species' section, not across species.

### 12. AP-per-level: flat rate wins over tiered draft
`GenoMorph_Adaptive_Progression_System.md` LOCKS a flat **+2 AP per level** (levels 2–15, 14 level-ups = **28 AP total** from leveling), stated explicitly with the "28 total points at Level 15" figure. This conflicted with the tiered rate (+2 for levels 1–5, +1 for 6–15 = 20 AP) originally drafted in the Progression Economy doc.
**Decision:** Flat +2/level is correct; the tiered draft was wrong. **Action taken:** Progression Economy doc corrected — grand total AP per species arc is ~44 (28 leveling + 16 quest/milestone), not ~36. Genome affordability recalculated accordingly.

### 13. Repeated-Genome cost — RESOLVED (was unresolved conflict #16)
**Decision: escalating, not flat.** A 2nd, 3rd, etc. Genome earned from the *same* attribute costs progressively more than the previous one (~40% more per repeat, applied to the same 1-1-2-2-3 step shape). Full cost table in `GenoMorph_Progression_Economy_v0.3.md` §4.1. This supersedes `Complete_Design_Specification.md`'s flat formula (`floor(Upgrades/5)`, no escalation) and resolves `GenoMorph_GDD.md`'s "not yet finalized" note — both docs' claims on this specific point should now be treated as superseded by this decision.
**Design rationale:** A full 2nd Genome in one attribute (21 AP) eats nearly half the ~44 AP per-arc budget, making tunnel-vision specialization costly while breadth (multiple first-Genomes across different attributes) stays efficient — reinforces "adaptation over raw power." 3rd/4th Genomes in one attribute (39-63 AP) are effectively out of reach in a single arc, appropriately reserved for NG+/endgame.

---

## OPEN FOLLOW-UPS (not resolved — needs future work)

### A. Coral Reef → Master GDD write-in
Write Coral Reef's DLC status into Master GDD §7.4/§60 formally (see Decision #3).

### B. Prologue opening beat rewrite — DONE
See Decisions #4 and #8 above. Both fixed in one pass on `PROLOGUE.md`.

### C. Master GDD consolidation gap
Frog's ability/ultimate section needs to be copied into the Master GDD from Complete_Design_Specification §34-35 (see Decision #9). **Possible broader issue:** this may not be the only content that's LOCKED in Complete_Design_Specification but missing from the "consolidated" Master GDD — a broader audit was suggested but not performed this session.

### D. Full ATK/combat-formula cross-check
The ATK-per-level curve drafted in `GenoMorph_Progression_Economy_v0.2.md` §6 was only checked against **Frog's** multipliers and enemy HP. Salamander and Water Monitor's multipliers (and their own attribute priorities, which weight ATK differently — e.g., Water Monitor prioritizes Health/Attack "Very High," Salamander prioritizes Health Recovery) have not been cross-checked against this curve. Needs its own pass.

### E. Quest-structure non-linearity — needs new content, not just reordering
**Key finding:** Frog's Q02 ("Investigate the Disturbance") as currently written is **one single thread** — damaged vegetation, burrows, traces, and displaced wildlife all point toward the same rat colony, not two separate problems. Making it genuinely forkable requires **inventing a second, distinct environmental problem** (e.g., a different pollution source or a different displaced-animal situation using a different invasive species or a pure environmental puzzle) that converges back on the same Salamander-unlock destination.
**Status:** Deliberately not designed yet — logged as a concrete task for a future session, once appetite exists to add real new content (not just restructure existing beats). The same pattern (need a genuine second thread, not just reordering) likely applies if this approach is extended to Salamander's or Water Monitor's sections too.

---

## NUMERIC ARTIFACT PRODUCED THIS SESSION
See `GenoMorph_Progression_Economy_v0.3.md` (separate file) for:
- XP curve to Level 15 (~524 total XP, sized to realistic single-species content, not idealized grind)
- AP economy (~44 AP per species arc: 28 from LOCKED flat leveling rate + 16 from quest/milestones)
- Escalating Genome cost model: 9 AP for a species' 1st Genome in an attribute, 12 AP for a 2nd Genome in that SAME attribute, 18 AP for a 3rd, 24 AP for a 4th (all fully resolved, no remaining conflicts)
- ATK-per-level curve + AP→ATK conversion, sanity-checked against locked enemy HP values (Frog only)

All numeric conflicts found during this review are now resolved. No open numeric contradictions remain as of this log's last update.

---

*Compiled from a consistency-review conversation. Cross-reference against Master GDD v1.2, Complete_Design_Specification.md, and Progression Economy v0.3 for full context on each item.*
