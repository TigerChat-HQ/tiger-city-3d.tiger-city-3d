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
- A starter Unity scene and bootstrap script now attach the prototype city/build/campaign controllers at runtime.
- An Android APK GitHub Actions workflow is included; it requires valid Unity license secrets before it can run successfully.
- This is an early prototype, not a finished realistic game.

## Unity scene
Open `Assets/Scenes/TigerCityPrototype.unity` with Unity `6000.3.28f1`. The scene's `TigerCityBootstrap` adds `CityPrototype`, `CityBuildController`, and `TerritoryCampaignController` to its root object. Press Play to generate the greybox city. The camera is created by the city prototype.

## Known limitations
- The current visuals use built-in primitive geometry and the legacy Standard shader. They are greybox placeholders, not photorealistic assets.
- The first touch interaction uses Unity's legacy mouse input mapping; Android touch behavior must be tested on a device.
- `CityOrbitCamera` adds one-finger orbit, two-finger pinch zoom and two-finger pan; desktop editor mouse drag/wheel are also supported.
- The camera requests landscape-only autorotation (both landscape directions) when gameplay starts; device behavior still needs Android build and device verification.
- The territory campaign is an early greybox: battles currently resolve from troop strength and random battle factors; battlefield units and cover are visual placeholders, not yet controllable real-time combat.
- No production assets, online multiplayer backend, verified Android APK, or successful Unity compilation is included yet.

## Android APK build with GitHub Actions
Workflow: `.github/workflows/android-build.yml`.

Before running it, add these repository Actions secrets under **Settings → Secrets and variables → Actions**:
- `UNITY_LICENSE`: the Unity license file contents for the account/license permitted to use this project.
- `UNITY_EMAIL`: Unity account email.
- `UNITY_PASSWORD`: Unity account password (only if required by the selected GameCI licensing flow).

Then open **Actions → Unity Android APK → Run workflow** on branch `feat/city-invasion-strategy`. The workflow targets Android APK (not AAB) using Unity `6000.3.28f1` and uploads the APK as a workflow artifact if the build succeeds. Do not publish the license or credentials in repository files or chat.

If the Unity license is not valid for the runner, the selected Unity editor version is unavailable, or Unity reports project/import/compiler errors, the workflow will fail and its logs must be reviewed before retrying.

## Validation status
The initial scene/build workflow scaffold is committed to the feature branch. No Unity import/compile, Play Mode test, Android device test, or APK build has yet been run. The first CI run is still pending Unity license secrets and verification of the runner's Unity version support.
