# GenoMorph Visual Style Reference

This document serves as the central source of truth for the game's core UI aesthetics, ensuring consistency across all menus, HUD elements, and diegetic displays.

## The Suit HUD Theme
The overarching design language for GenoMorph's UI is "field-built biological suit instrumentation." It should look functional, capable, and slightly improvised. It is **not** a generic fantasy RPG interface, nor is it a pristine, sleek sci-fi holographic display.

### 1. Signature Accent Color
- **Warm Golden-Yellow**: `#F2C94C`
- **Inactive/Off State**: `#777777` (Muted Mid-Gray)
- *Usage*: Yellow is the single signature HUD accent color used across all elements (active UI states, highlights, glowing borders, active text, quests). It reads clearly as a "suit indicator light" signaling that something is active. The inactive gray should be used to denote when a system or tracker is off or empty.

### 2. Panel Backgrounds
- **Deep Teal-Black**: `#12201C`
- *Usage*: Used for all floating UI panels (Investigation Cards, Objective prompts, Menus). Usually rendered with slight transparency (e.g., 85%-95% opacity) to prevent totally blocking the game world.

### 3. Typography
- **Primary Data Font**: Clean, slightly technical sans-serif.
- *Examples*: `Rajdhani`, `Orbitron`, `Consolas`, or other system-level monospace/technical fonts.
- *Usage*: Used for all UI data readouts, objective text, and logs. It reinforces the "instrumentation" aesthetic rather than a storybook look. Titles and labels are typically written in ALL CAPS or Sentence case depending on context (e.g. `DIRECTIVE`, but sentence case for descriptive body text).

### 4. Shape & Form
- UI elements should be **corner-anchored or modular**, avoiding full-width marquee banners that dominate the top of the screen.
- **Persistent HUD Elements (e.g. Quests):** No background panel or fill of any kind. These elements should consist of floating text with a small decorative vertical accent mark (e.g., 3px wide). Legibility is achieved entirely via a strong text drop shadow (e.g., `Color(0, 0, 0, 0.85)` with a 2px vertical offset and 6px outline size).
- **Pop-up Menus (e.g. Investigation Card):** These may use the dark teal-black PanelContainer to separate them from the environment.
