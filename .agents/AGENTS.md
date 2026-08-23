# Versioning Rules

- Every time you make an update to the game or fulfill a user request that involves modifying the game's code or assets, you MUST increment the version number in `project.godot` (under `[application]` -> `config/version`).
- Use Semantic Versioning (e.g., `0.1.0`, `0.1.1`, `0.2.0`).
- **CRITICAL RULE**: Do NOT reach version `1.0.0` or higher until the user EXPLICITLY states that the game is finished. Keep the major version at `0` (e.g. `0.x.y`) during all development phases until the user's final declarations.
