# TIGER CITY 3D

TIGER CITY 3D is an Android-first 3D city-building and strategy game built with **Godot 4**. Godot is the only supported game engine for active development; Unity project files and Unity build workflows are not part of this development line.

## Current Godot milestone
- Procedural 3D city prototype with roads, buildings, districts, camera and touch controls.
- Building placement, coins, recruitment, supplies and local save/load.
- Campaign director with rival faction state, turn advancement and territory capture.
- Battlefield prototype with pathfinding, formations, battle units and tactical orders.
- Android export workflow, APK package/signature checks and emulator smoke-test workflow.
- Multiplayer-session and device/asset-profile modules are foundations only; they are not yet complete online PvP or automatic thermal management.

## Development status
This is still a prototype, not a finished or production release. The city and battlefield need production-quality assets, expanded gameplay, balancing, optimization and extensive device testing. A passing CI check or debug APK does not prove the game is fully functional or offline-tested on a physical phone.

## Build and validation
- Engine: Godot 4.4.1.
- Project folder: `godot/`.
- Open `godot/project.godot` in Godot.
- Headless validation and campaign/battle smoke tests run through `.github/workflows/godot-check.yml`.
- Android debug APK export and emulator launch checks run through `.github/workflows/tiger-city-android.yml`.
- Android package ID: `com.tigerchat.tigercity3d`.

The CI APK uses a temporary debug signing key and is for testing only. A permanent release signing key must be configured securely before publishing production updates.

## Mobile performance target
The initial target includes Android phones with 4 GB RAM. Start with Low graphics, conservative visible-unit limits and small texture variants; validate memory, frame rate, heat and battery use on physical devices before raising quality.

## Project layout
- `godot/`: Godot project, scene, gameplay scripts, tests and export preset.
- `scripts/`: Android emulator smoke test.
- `.github/workflows/`: Godot validation and Android build workflows.
- `PROJECT_COMPLETION_CHECKLIST.md`: evidence-based feature and release checklist.
- `STANDALONE_ANDROID.md`: standalone Android packaging notes.

All active feature work should branch from the Godot-only line so Unity history does not become a dependency of later Godot PRs.
