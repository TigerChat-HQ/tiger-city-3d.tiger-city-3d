# War systems integration status

This branch contains Godot 4 campaign and battlefield modules connected to the active prototype scene and covered by smoke tests. They remain prototype systems, not a finished strategy/combat implementation. Multiplayer and device-profile helpers are scaffolding and are not yet integrated into live gameplay.

## Added modules
- `campaign_director.gd`: persistent campaign state, faction economy, rival target scoring, turn advancement, territory ownership and objective tracking.
- `battlefield_systems.gd`: AStarGrid2D path queries, line/column/wedge/circle formation destinations, physics-ray line of sight, cover search, destructible-object health and basic land/air/sea movement helpers, distance-based visibility.
- `multiplayer_session.gd`: ENet host/join/leave lifecycle and peer events. This is connection scaffolding only; it does not yet replicate game state, authenticate players, reconcile authority or provide matchmaking/PvP.
- `device_asset_profiles.gd`: memory/display-based tier selection and optional 256/512/1K texture-variant lookup. Texture variants must be authored and included in the project; existing assets are not automatically resized.

## Still required before claiming completion
1. Attach CampaignDirector and BattlefieldSystems to the active game scene and connect territory, battle, unit and save/load events.
2. Add a real navigation bake/grid obstacle registration pipeline and path-following steering/collision avoidance for each unit.
3. Add authoritative multiplayer RPCs for state snapshots, commands, combat, territory, reconnection, anti-cheat validation, and test with two independent Android devices.
4. Add Android native thermal-status integration using a Godot Android plugin/bridge, then test actual thermal throttling on target hardware. GDScript frame-time heuristics are not a battery-temperature sensor.
5. Author and import low/medium/high texture atlases, mesh LOD variants and production-grade character/building/vehicle assets. The profile helper only selects existing variants.
6. Create proper animated and drivable land, air and naval prefabs with physics, weapons, damage, controls and camera/audio feedback. Current movement helper is a prototype transform update, not a complete vehicle simulation.
7. Add destruction meshes/debris/physics/VFX/audio and test performance on 4 GB RAM devices.
8. Complete a multi-mission campaign with branching objectives, save migration, faction diplomacy, victory/defeat and balancing.

## Mobile constraints
For a 4 GB RAM target, begin with Low quality, small visible-unit caps, 256/512 texture variants and aggressive LOD. Profile peak RAM, frame time, thermal state and storage on the actual target phone before raising defaults.
