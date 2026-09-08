# GENOMORPH — DEVELOPMENT PROMPT: Q01 INVESTIGATION SYSTEM (Environmental Clue Choice)

**Give this to whoever/whatever is implementing this feature** — a coding AI, or read it yourself as a design brief. It covers both the underlying system and the UI, since this feature is small enough that the two can't really be separated.

**Context this fills in:** the design docs establish that in Q01, the player "chooses something to investigate" from multiple environmental clues, and "clues are presented differently depending on what was selected" — but never specify what that actually means. This document makes that concrete, filling a real gap (see `GenoMorph_Consistency_Review_Log.md`, open item on Q01 investigation content) rather than changing anything already locked.

---

## 1. WHAT THIS FEATURE ACTUALLY IS

At the start of Q01, the player — freshly in control, still learning to move as Frog — is in a safe starting area with **three distinct environmental clues** visible at different points in the space:

1. **Polluted water** (a stagnant, discolored pool with a chemical sheen)
2. **Damaged vegetation** (dead/blackened reeds, a patch of scorched or wilted plant life)
3. **Human debris** (a piece of trash, a rusted pipe, or similar sign of past human activity)

These are per §17.2 of the Master GDD — this document doesn't invent the three clues, it designs what happens when the player interacts with each.

The player can walk up to any of these first. Whichever one they reach and investigate first is the one that plays out — the other two remain in the world, investigable later, but don't block or gate anything (per the "optional discoveries" philosophy already locked elsewhere in the design: small, non-blocking, rewarding curiosity without punishing whoever skips them).

**Important scope boundary:** per the source doc, "the first investigated clue advances the quest" — meaning all three clues funnel to the *same* next beat (Sterling reacts → Mosquito appears). This is NOT a structural branch that changes where the story goes. It's a **flavor/characterization choice** — what the player learns about *why* the wetland died changes depending on what they look at first. Do not build this as a gameplay-altering fork; that would contradict the source spec.

---

## 2. WHAT EACH CLUE SHOULD ACTUALLY TEACH THE PLAYER

Grounding each clue's content in the Prologue's own established causes of the wetland's collapse (industrial runoff/eutrophication and invasive species, per `PROLOGUE.md` §2) keeps this consistent with the story already told:

### Clue A — Polluted Water
**What the player sees:** a stagnant pool, oily discoloration, a faint chemical shimmer, maybe a few dead fish floating at the edge.
**Investigation Card content (short, in Sterling's voice via radio + card text):** ties directly to industrial runoff and eutrophication — the algal bloom that suffocated the water. This is the clue that best explains *why the water itself looks wrong.*
**Sterling's reaction line (radio bark, short):** something like *"That water shouldn't be that color. Test it if you can — I want that data."* (placeholder line, not final writing)

### Clue B — Damaged Vegetation
**What the player sees:** a patch of blackened, wilted, or unnaturally bent reeds and plant life, distinctly different from the healthier growth elsewhere in the starting area.
**Investigation Card content:** ties to the compounding ecological collapse — plants dying doesn't just mean plants are gone, it means the animals that depended on them lost food and shelter. This is the clue that best explains the *knock-on* nature of ecosystem collapse (matches Sterling's own stated worldview: "every species is a tool, every adaptation is a solution" — seeing its absence is the inverse lesson).
**Sterling's reaction line:** something like *"This isn't natural die-off. Something's been sitting here a long time."*

### Clue C — Human Debris
**What the player sees:** a rusted pipe fragment, degraded plastic, or similar — small, not a dump site, just enough to read as "people did this, or people left this behind."
**Investigation Card content:** the human dimension — this collapse wasn't purely natural, it has a traceable human cause, tying back to the Prologue's "it was not a pristine wilderness untouched by humans... but the balance held, then the holding stopped."
**Sterling's reaction line:** something like *"...Yeah. That tracks. This didn't happen by accident."*

**All three converge here:** regardless of which was picked, Sterling's dialogue transitions into the same next line, functionally acknowledging what was found and setting up the Mosquito's appearance. Only the specific flavor line differs.

---

## 3. INTERACTION FLOW (step by step)

1. Player is in the starting area, free to move (already established — no change here).
2. As the player gets near a clue (proximity trigger, not a hard walk-into-it collision), a subtle world-space prompt appears above/near the object — see UI spec below.
3. Player presses the existing, already-LOCKED **Interact** button (per Master GDD §14 — do not invent a new input for this).
4. The **Investigation Card** UI appears (this is a system already named in the implementation roadmap — Step 7, "Investigation Card" — this feature is what that step was always meant to build content for).
5. Card shows: a short title, 1-2 sentences of in-world description, then closes automatically or on a tap-to-continue.
6. Sterling's radio bark plays, timed to either overlap the card or immediately follow it (not simultaneous with dialogue-log text if that would visually collide — see UI notes).
7. Card dismisses. Small XP/reward per the "optional discoveries" system (exact amount: draft, see Progression Economy doc — this specific reward isn't itemized there yet, treat as a small optional-discovery-tier reward, roughly in line with other minor discovery rewards).
8. If this was the player's FIRST investigated clue this session: quest progresses (Sterling's bigger reaction, Mosquito appears — this part is already scripted per §17.4, not new).
9. If the player investigates a SECOND or THIRD clue afterward (before or after the Mosquito fight — player's choice): same Investigation Card flow plays, same small reward, but does NOT re-trigger quest progression (that already happened on the first one). These become simple optional lore/flavor beats.

---

## 4. UI SPECIFICATION

### 4.1 Design language to match (don't invent a new one)
This UI needs to feel like it belongs to the **GenoMorph Suit's HUD** — a piece of survival/scientific equipment the Volunteer is wearing, not a generic game menu. Ground every visual choice in that: this is biological/scientific instrumentation on a body-worn suit in a swamp, not a fantasy RPG parchment scroll and not a sleek sci-fi spaceship computer either — it should feel a little improvised, field-built, functional. Sterling is a biomedical engineer working from a home workshop, not a mega-corporation — the suit should look capable but not flashy.

### 4.2 World-space proximity prompt (before opening the card)
- A small icon or subtle glow appears above the clue object once the player is close enough to interact — NOT before, to avoid cluttering the screen with icons for objects still far away.
- Icon should read clearly at a glance on a small mobile screen: a simple, high-contrast glyph (e.g., a magnifying glass or a scan-line icon) rather than detailed art that won't read at small size.
- Pairs with the existing **Interact** button prompt — reuse whatever visual convention (button icon + label, e.g. a small "Interact" chip) is already used elsewhere for the Interact button, don't invent a second convention for this one feature.
- Subtle pulse/glow animation to draw the eye — matches the same "HUD highlights X" language already used in the Prologue's rewritten gameplay beat (the joystick pulse, the Skill 1 button glow) — this creates a consistent visual vocabulary across the whole opening: the suit highlights things it wants the player to notice.

### 4.3 The Investigation Card itself
**Layout concept (mobile-first, portrait):**
```
┌─────────────────────────────────┐
│                                   │
│         [ small icon/scan        │
│           graphic here ]          │
│                                   │
│   CONTAMINATED WATER              │  <- short title, sentence case,
│                                   │     not all-caps (per general
│   A chemical sheen coats the      │     UI writing guidance)
│   surface. Dead fish drift        │
│   near the edge. Whatever         │
│   caused this happened            │
│   more than once.                 │
│                                   │
│                     [ tap to      │
│                       continue ]  │
└─────────────────────────────────┘
```
- Appears as an overlay near the bottom third of the screen (mobile — keeps the player's view of the environment mostly unobstructed, and keeps thumb-reach comfortable if there's any tap target).
- Semi-transparent dark background panel behind the text for legibility against a bright swamp environment — but NOT a full-screen dim/pause, since combat/movement should still feel "live," matching the design principle that Q01's investigation doesn't stop the world.
- Small icon or simple line-art representing the specific clue (a water-drop-with-warning-mark icon for polluted water, a wilted-leaf icon for vegetation, a debris/fragment icon for human debris) — keep these as a matched icon set, not three different visual styles.
- Title in sentence case, short (3-4 words max) — avoid the all-caps-label tell.
- Body text: 1-2 sentences maximum. This is a HUD readout a suit would generate, not a paragraph — write it like clipped field-analysis text, not narration.
- Dismissal: tap anywhere on the card, or auto-dismiss after a few seconds if the player moves away — don't force a hard stop.

### 4.4 Color and type direction (concrete, not vague)
Since this needs to feel like suit instrumentation:
- **Base palette:** a muted, slightly desaturated swamp-adjacent palette so the HUD doesn't fight the environment — something like a deep teal-black panel background (`#12201C` range) with a bioluminescent-green or pale amber readout color for text and icons (`#8FD9B8` or `#E8C97A` range — pick ONE as the primary HUD accent and use it consistently across ALL suit UI, not just this feature, so Investigation Cards, the Adaptation screen, and other HUD elements feel like one coherent instrument reading out different data).
- **Type:** a clean, slightly technical/monospaced-leaning sans-serif for data readouts (title, body) — reinforces "this is instrumentation," not decoration. Avoid anything ornate or fantasy-styled.
- **Avoid:** rounded "app card" aesthetics with soft drop shadows (reads as generic mobile UI, not diegetic suit tech), and avoid a pure sci-fi "holographic blue" look — that's a different, more polished-tech aesthetic than a scrappy home-workshop suit warrants.

### 4.5 Consistency requirement
Whatever palette/type choices get made here should become the **base visual language for the whole suit HUD** going forward — the movement joystick highlight, the Skill 1/Attack button glows from the Prologue rewrite, the Adaptation screen (Phase 2), and future Investigation Cards in Rainforest/Mountain should all read as the same piece of equipment, not different UI kits stitched together. Recommend building this as a small shared UI theme/style resource in Godot (a shared Theme resource) rather than styling each screen independently.

---

## 5. WHAT'S DELIBERATELY LEFT OPEN

Being upfront about what this document does NOT decide, since it shouldn't be treated as more final than it is:

- **Exact reward XP value** for investigating a clue — treat as a small placeholder (matching other optional-discovery rewards) until the Progression Economy doc is updated with a specific number for this.
- **Exact dialogue lines** — the Sterling reaction lines above are placeholder/illustrative, not final writing. A writer should pass over these.
- **Whether all three clues are visible/reachable from the very first frame of control**, or whether some are slightly more hidden/require a bit of exploration — not specified in the source doc, left as an implementation/level-design choice.
- **Icon art style specifics** — direction is given (simple, high-contrast, matched set) but final art is not this document's job.

---

*This document fills a gap explicitly left open in `GenoMorph_Master_GDD_v1.2.md` §17.3 ("possible environmental clues are presented differently... " with no further detail given) and connects it to the already-planned but previously-empty "Investigation Card" system named in `Complete_Design_Specification.md`'s implementation roadmap (Step 7). Nothing here overrides a LOCKED decision — see `GenoMorph_Consistency_Review_Log.md` for the reasoning trail.*
