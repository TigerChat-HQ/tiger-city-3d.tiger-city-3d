# TIGER CITY 3D — Godot Android prototype

The active Android-friendly branch is built with Godot 4; the player does not need Unity Editor on the phone.

## Current implementation
- Mobile renderer, filmic environment, procedural sky, directional shadows and surface noise.
- Android CI fetches 1K CC0 photogrammetry PBR sets for asphalt, concrete and paving stones from ambientCG and packages them into the APK. Local editor runs without running the asset-fetch step use procedural fallbacks.
- Generated city blocks with facade glazing, rooftop plant details, street markings, raised curbs and streetlights.
- Better-proportioned pedestrian meshes and civilian cars.
- City economy, services, production, delivery routes, recruitment, building placement and local save/load.
- Graphics presets: Low (30 FPS cap, 72% 3D render scale, no MSAA/shadows), Medium (40 FPS cap, 86% scale, 2x MSAA and shadows) and High (60 FPS cap, full 3D scale, 2x MSAA, shadows and glow).
- Saved graphics preference, adjustable visible civilian/soldier counts by quality, and an automatic sustained-frame-load guard that lowers quality under prolonged frame-time pressure.
- Offline-first single-player prototype: gameplay and local save/load do not require a runtime network connection; generated character assets and PBR resources are packaged at build time.
- Tactical battle scene with equipped infantry, defensive earthworks, armoured tank props, advance/hold/retreat orders, and a visible air-support flyover.
- Territory capture rewards coins, food, supplies and records total loot.

## Important visual-quality note
The city and military assets in this prototype are generated from basic 3D meshes and procedural materials. They are not yet photorealistic production assets. To reach the requested ultra-realistic standard, the project still needs authored high-detail PBR building/vehicle/character models, detailed terrain and road textures, proper skeletal character animation, VFX, audio, LODs and performance profiling. Do not describe this prototype as ultra-realistic or finished until those assets are integrated and visually checked on target Android devices.

## Android build and verification
GitHub Actions performs headless Godot project import/script parsing and an Android debug APK export. CI debug signing is temporary and is not a permanent release signing identity. The APK must be installed and tested on a physical Android device for touch, landscape, thermals, frame rate, save/load and offline behavior.

## Still to complete
- Production-grade PBR assets and animation for city, people, vehicles, aircraft and military units.
- Interactive tanks, helicopters, aircraft and naval units; current tank models are battlefield props and air support is a flyover strike.
- Real neighboring factions with persistent territory ownership, defensive AI and a campaign map.
- Robust combat tactics, pathfinding, formations, cover, line of sight and destructible environments.
- Complete offline-first campaign, optional authenticated multiplayer and two-device PvP testing.
- Android device QA and stable release signing.

## Mobile performance and thermal limitation

The automatic guard currently uses sustained frame-time pressure as a load/heat proxy. Godot's portable GDScript API does not expose Android battery temperature/thermal status, so this build does not claim to read the phone's actual temperature. A native Android thermal-status bridge and physical-device thermal testing are still required for true temperature-triggered quality changes. The Low profile is the conservative starting point for 4 GB RAM devices; actual RAM use and frame rate must be profiled on the target phone.
