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
3. Add `CityPrototype`, `CityBuildController`, and `TerritoryCampaignController` components to `CityRoot`.
4. Ensure the scene has a camera tagged `MainCamera`, or let `CityPrototype` create one.
5. Press Play. Select a building from the bottom toolbar and tap open ground to place it.
6. Use SAVE and LOAD to test local city persistence. The campaign panel lets you recruit soldiers, select rival regions, spend supplies, launch an invasion, and save captured territories locally.

## Known limitations
- The current visuals use built-in primitive geometry and the legacy Standard shader. They are greybox placeholders, not photorealistic assets.
- The first touch interaction uses Unity's legacy mouse input mapping; the final Android input system must be configured and device-tested.
- `CityOrbitCamera` adds one-finger orbit, two-finger pinch zoom and two-finger pan; desktop editor mouse drag/wheel are also supported.
- The camera requests landscape-only autorotation (both landscape directions) when gameplay starts; device behavior still needs Android build and device verification.
- The territory campaign is an early greybox: battles currently resolve from troop strength and random battle factors; the battlefield units and cover are visual placeholders, not yet controllable real-time combat.
- No complete Unity project scaffold, production assets, online multiplayer backend, or verified Android APK is included yet.
- Unity Editor is pinned to Unity 6.3 (`6000.3.28f1`) for the initial cloud-build setup; confirm this editor release is available in the Unity Build Automation dashboard before the first build.

## Project structure
- `Assets/Scripts/` contains prototype gameplay scripts, including the first territory campaign and invasion loop, plus the mobile orbit camera.
- `Assets/_Project/Scenes/` is reserved for production scenes.
- `Assets/_Project/Art/` contains models and textures.
- `Assets/_Project/Materials/`, `Prefabs/`, `UI/`, `Audio/`, and `Settings/` organize production assets.
- `Packages/manifest.json` defines Unity Package Manager dependencies.
- `ProjectSettings/ProjectVersion.txt` pins the editor version for cloud auto-detection.

## Android cloud build path
1. Open the Unity Cloud Dashboard and select this Unity project.
2. Open DevOps > Build Automation > Settings > Source control.
3. Select GitHub and authorize repository access. This repository is public, so read-only access is sufficient for a manual build; auto-build needs repository webhook permission.
4. Save the source-control settings, then create a build configuration for the `main` branch.
5. Choose Android, select Unity `6000.3.28f1` (or the exact version confirmed in the dashboard), and configure an APK build rather than an Android App Bundle for direct phone installation.
6. Start a build and check Build history. Download/install only after the build reports success.

Cloud build is not yet configured or tested. The project still needs a real Unity scene and a successful Unity import/compile before an APK can be expected.

## Validation status
Source files have been committed to GitHub. No Unity compilation, Play Mode test, Android device test, or APK build has been run yet.
