# TIGER CITY 3D — Godot Android prototype

The active Android-friendly branch is built with Godot 4; the player does not need Unity Editor on the phone.

## Current implementation
- Mobile renderer, filmic environment, procedural sky, directional shadows and surface noise.
- Generated city blocks with facade glazing, rooftop plant details, street markings, raised curbs and streetlights.
- Better-proportioned pedestrian meshes and civilian cars.
- City economy, services, production, delivery routes, recruitment, building placement and local save/load.
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
