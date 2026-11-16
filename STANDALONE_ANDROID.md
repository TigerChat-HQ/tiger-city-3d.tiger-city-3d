# Standalone Android app

TIGER CITY 3D is being built as its own Android application. It does not require TigerChat, a browser, or a WebView to launch.

## Android build

The workflow `.github/workflows/tiger-city-android.yml` exports a standalone ARM64 debug APK using Godot 4.4.1. It creates a temporary CI-only debug keystore, validates the package ID and APK signature, and uploads the APK as a GitHub Actions artifact.

Package ID: `com.tigerchat.tigercity3d`

App name: `TIGER CITY 3D`

Orientation: landscape, configured in `project.godot`.

The CI debug APK is for installation/testing only. It is not a production release and is not signed with a permanent publisher key. A permanent private release keystore must be created and stored as protected repository secrets before publishing updates, so future APKs can update the same installed app.

## Current gameplay status

This standalone packaging milestone does not mean the game is finished. The current Godot scene is still a greybox prototype. Realistic city assets, animated citizens and traffic, a full economy, and visible real-time battlefield gameplay remain planned development work. No device test is claimed until the APK is installed and tested on a physical Android phone.
