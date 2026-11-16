# TIGER CITY 3D

TIGER CITY 3D is a mobile-first 3D city-builder and territory strategy game. The unfinished Unity-only prototype is being migrated to a browser-native Three.js client so development and Android packaging can run through GitHub Actions without Unity Editor on the player's phone.

## Current playable prototype
- Three.js 3D city scene with touch orbit, zoom, roads, trees, lighting and procedural buildings.
- Build houses, shops, offices and barracks by selecting a tool and tapping open ground.
- Coins, population and army counters; barracks recruit troops.
- First animated battle/conquest demonstration with a victory state and loot.
- Local save/load and basic offline play after app assets have been installed.
- Capacitor Android wrapper and GitHub Actions debug APK workflow.

## Run
```sh
npm install
npm run dev
```

## Android build
GitHub Actions installs dependencies, builds the Three.js game, generates the Capacitor Android wrapper and uploads a debug APK artifact. This path does not require Unity Editor on the user's phone.

## Roadmap to the full game
- Tactical real-time combat with player-issued orders, persistent neighboring factions and territory control.
- Multiple troop classes, commanders, air force, navy, defensive installations and enemy counterattacks.
- Deep city economy, utilities, citizens, traffic, weather and day/night cycle.
- Robust IndexedDB saves, offline asset precaching and real-device QA.
- Online accounts and synchronized multiplayer only after server-side authorization and two-account end-to-end testing.
- Optimized original 3D assets and performance profiling on target Android devices.

## Honest status
This is an early playable prototype scaffold, not a finished or store-ready game. The current battle is a prototype demonstration, not a complete war simulation. APK workflow success and physical Android device testing must be verified independently; no device verification is claimed.
