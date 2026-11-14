# TIGER CITY 3D — City Builder: Invasion Strategy

## Core fantasy
Build and defend a prosperous capital city, expand a regional network of settlements, and strategically capture rival territories. The game should feel like a premium cinematic city-builder blended with a readable real-time strategy (RTS) campaign. The player is a city governor and commander, not a passive spectator.

## Camera, display, and controls
- The gameplay scene is landscape-only on phones and tablets. Entering the actual game requests Android landscape orientation; leaving the game restores the previous app orientation.
- Use a 3D free camera with 360-degree orbit, pinch zoom, drag pan, and a clear recenter button.
- City-building mode uses large touch targets and a contextual build tray.
- Battle mode uses a tactical overhead/angled camera with pinch zoom, drag pan, unit selection, move/attack commands, and a minimap.
- Keep HUD safe areas clear of the phone notch and system navigation.
- Do not force orientation on the Games catalogue or other TigerChat screens; only the game scene is landscape.

## World map and territories
- One central capital is the player's home city.
- Surround it with distinct rival towns and strategic regions connected by roads, rivers, bridges, hills, and resource routes.
- Each territory has a name, visual identity, population, prosperity, defenses, resources, and strategic value.
- Territories should be visible on a regional campaign map. Locked, neutral, allied, and enemy ownership must be visually distinct.
- Capture one adjacent territory at a time initially; later campaigns can unlock multiple fronts.
- Conquered towns become part of the player's regional network and can be developed, taxed, supplied, upgraded, and defended.

## Core gameplay loop
1. Develop the capital: zone residential, commercial, industrial, and civic areas; build roads, power, water, healthcare, education, logistics, and defenses.
2. Grow the economy: residents work, businesses produce income, services affect happiness, and supply chains move resources.
3. Scout neighboring territories: reveal enemy strength, terrain, routes, resources, and defensive structures.
4. Prepare a campaign: recruit and train units, stock food/fuel/materials, choose a route, and assign a commander.
5. Fight a real-time tactical battle in a dedicated 3D battlefield.
6. Win objectives to capture the territory; losing should cost units, supplies, time, and reputation.
7. Rebuild and integrate the captured town, then defend it against counterattacks.

## Battle design: visible, tactical, fair
- Battles take place in a dedicated 3D arena derived from the selected territory: streets, bridges, open fields, industrial yards, hills, or town centers.
- Show units moving, taking cover, firing, retreating, and interacting with terrain. Use readable effects and animations; avoid gore.
- Unit roles: infantry, engineers, scouts, armored vehicles, artillery, and logistics/support. Add air units only if performance and balance allow.
- Tactical choices: flanking, chokepoints, high ground, cover, bridges, supply lines, weather, and day/night visibility.
- Objectives: capture command posts, secure a bridge, hold a district, escort a supply convoy, disable a depot, or defend a position for a timed period.
- Use an accessible pause/speed control for single-player. AI opponents should telegraph intent and have adjustable difficulty.
- Battle outcome is based on unit composition, preparation, terrain, morale, supply, and player orders—not pay-to-win purchases.

## City and campaign consequences
- Damaged districts need repair and services before full recovery.
- Captured regions can provide resources, population, trade routes, and strategic staging points.
- Over-expansion increases upkeep, unrest, and supply strain.
- Diplomacy, trade, alliances, and ceasefires can be a later campaign layer; they should not block the first playable milestone.

## Visual direction: ultra-realistic cinematic
- Target realistic architecture, believable road materials, detailed terrain, physically based materials, high-quality lighting, shadows, reflections, atmospheric depth, day/night cycles, and weather.
- Build a strong African-inspired visual identity without reducing the world to stereotypes: contemporary skylines, varied neighborhoods, green belts, coastal/inland terrain, and locally grounded street details.
- Use scalable quality tiers, dynamic resolution, LODs, occlusion culling, texture streaming, baked lighting where appropriate, and pooled effects for Android performance.
- The current primitive/greybox prototype is only a gameplay blockout. It must not be presented as the final visual quality.
- The cover art should be a real rendered in-game city view once production assets exist, not an emoji/gradient placeholder.

## Modes and account
- First release: offline single-player campaign with local save, including city development and AI-controlled rival territories.
- Online features follow after authoritative server validation, anti-cheat, save synchronization, and reconnect handling are implemented.
- TigerChat account integration should pass a stable internal user ID and display username using a short-lived authenticated launch token. Never trust a client-supplied username as identity and never expose Supabase service-role secrets in the client.
- Offline play must remain possible after the initial account entitlement/profile check; define a safe local guest/cache policy for temporary network loss.

## First playable milestones
### M1 — Landscape city-builder foundation
- Unity project scaffold and playable production scene.
- Android landscape lock only while gameplay is active.
- 360-degree camera, zoom, pan, touch input, build palette, roads, and first building types.
- Local save/load and a stable 30 FPS target on agreed baseline Android hardware.

### M2 — Regional map and rival towns
- Capital plus at least three visually distinct neighboring territories.
- Territory ownership, scouting, resource yields, roads, and adjacency rules.
- Rival AI that develops and defends its town.

### M3 — First invasion battle
- One dedicated 3D battlefield with terrain, cover, capture points, and minimap.
- Infantry, scouts, engineers, and one vehicle class.
- Select/move/attack commands, basic enemy AI, battle result, casualties, and territory capture.
- Campaign consequences: resource rewards, repairs, garrison, and counterattack pressure.

### M4 — Cinematic polish and online expansion
- Production environment/vehicle/unit assets, animation, sound, lighting, effects, and quality settings.
- Profile-linked cloud saves and online play only after backend security and synchronization tests.
- Performance, thermal, battery, accessibility, and device compatibility passes.

## Acceptance criteria
- Entering gameplay switches to landscape; exiting returns to the prior TigerChat orientation.
- The city can be orbited 360 degrees, panned, and zoomed with touch.
- The regional map shows a central capital and multiple surrounding territories with readable ownership.
- The player can scout, prepare, enter a 3D battle, issue tactical orders, win/lose, and see ownership change.
- Captured territory affects city economy and can be defended.
- Offline campaign progress persists after closing and reopening the app.
- Performance and quality are validated on named Android devices before claiming the game is ready.
