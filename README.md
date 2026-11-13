# TIGER CITY 3D

A realistic 3D city-building game targeting Android.

## Vision
- Ultra-realistic cinematic 3D as the visual target, subject to Android performance budgets.
- Build homes, shops, offices, roads, and civic services.
- Vehicles, pedestrians, day/night lighting, weather, and a growing city economy.
- Offline-first gameplay; online multiplayer will be added only after synchronization and server security are implemented and tested.

## Current source milestone
- Procedural greybox city grid with roads, ground, buildings, sun lighting, and a camera.
- First building loop: choose a house, shop, or office; tap open ground to place it; coins are deducted.
- Local save/load uses Unity PlayerPrefs JSON.
- This is an early prototype, not a finished realistic game.

## Unity scene setup
1. Create a Unity 3D project.
2. Add an empty GameObject named `CityRoot` to a scene.
3. Add both `CityPrototype` and `CityBuildController` components to `CityRoot`.
4. Ensure the scene has a camera tagged `MainCamera`, or let `CityPrototype` create one.
5. Press Play. Select a building from the bottom toolbar and tap open ground to place it.
6. Use SAVE and LOAD to test local persistence.

## Known limitations
- The current visuals use built-in primitive geometry and the legacy Standard shader. They are greybox placeholders, not photorealistic assets.
- The first touch interaction uses Unity's legacy mouse input mapping; the final Android input system must be configured and device-tested.
- No complete Unity project scaffold, production assets, online multiplayer backend, or verified Android APK is included yet.
- Unity Editor version and Android build configuration must be pinned before configuring a cloud build pipeline.

## Validation status
Source files have been committed to GitHub. No Unity compilation, Play Mode test, Android device test, or APK build has been run yet.
