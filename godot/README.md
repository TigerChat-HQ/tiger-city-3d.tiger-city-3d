# TIGER CITY 3D — Godot migration prototype

This is a parallel migration experiment. The original Unity project and its PR are preserved unchanged.

## Why Godot
Godot is open source and does not require a Unity Personal license. Its Android export workflow can produce APKs with matching Android export templates. The Android editor can also export projects directly from an Android device; see the official Godot Android export documentation.

## Current scope
- Procedural 3D greybox city and central capital.
- Five surrounding rival districts.
- Basic building placement, coins, recruitment, supplies, and abstract territory battles.
- Landscape-oriented mobile viewport.

## Important limitations
This is a first GDScript port of the existing Unity greybox prototype, not a complete migration. Touch camera controls, proper placement selection, persistent saves, real-time battles, production art, performance tuning, and APK export validation remain to be implemented. No APK has been built or device-tested yet.

Open this folder as a project in Godot 4.x. Use a Godot version compatible with the project configuration and install the matching Android export templates before exporting.
