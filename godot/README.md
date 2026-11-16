# TIGER CITY 3D — Godot Android migration prototype

This is a parallel migration experiment. The original Unity project and its PR are preserved unchanged.

## Why Godot
Godot is open source and does not require a Unity Personal license. The official Android editor can create, edit, and export projects on Android devices. The Android editor is experimental and its interface is not yet optimized for phones, so the workflow may be cumbersome on a small screen. See the [official Android editor guide](https://docs.godotengine.org/en/stable/tutorials/editor/using_the_android_editor.html).

## Current prototype
- Procedural 3D greybox city, central capital, and five rival districts.
- Basic building selection and tap-to-place using a ground-plane ray.
- Coins, recruitment, supplies, and abstract territory-capture loop.
- One-finger orbit, two-finger pinch zoom, mouse orbit and wheel zoom.
- Local save/load to `user://tiger_city_save.json`.
- Landscape-oriented viewport.

## Open on an Android phone
1. Install the official **Godot Engine Editor** Android app from the [Godot Android download page](https://godotengine.org/download/android/).
2. Download this repository branch as a ZIP: https://github.com/TigerChat-HQ/tiger-city-3d.tiger-city-3d/archive/refs/heads/migration/godot-android-prototype.zip
3. Extract it using your phone's file manager.
4. In Godot Android Editor, import/open the extracted `godot` folder (the folder containing `project.godot`).
5. Run the project to try the prototype.

The Android editor is experimental, has a touch UI that is not fully optimized, and may behave differently across devices. For Android export, install the matching export templates and configure an Android export preset in the editor. Godot's Android editor does not need the user to install Android SDK or OpenJDK for its Android export path. See the [official Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

## Validation and limitations
GitHub Actions has successfully imported and parsed the Godot project and exported a standalone Android debug APK. The APK package ID and signature were verified by CI, and artifact `TIGER-CITY-3D-Android-debug` was uploaded from run `43608570844`. This is a temporary CI debug signature, not a permanent release signing identity. The APK has not yet been installed or tested on a physical Android phone.

This remains an early greybox prototype, not a complete engine migration. Production visuals, robust placement collision/road checks, persistent campaign balancing, real-time combat, audio, accessibility, optimization, Android export configuration, signing, and testing remain outstanding.
