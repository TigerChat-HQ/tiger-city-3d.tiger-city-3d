# Rigged character assets

The Android CI build now generates and imports these character scenes before Godot's asset import/export step:

- `soldier.glb`: high-fidelity human anatomy base, fatigue uniform, tactical vest, helmet, combat boots, rifle, 65-bone game rig and the Ara shooter/combat animation set.
- `civilian_01.glb`, `civilian_02.glb`, `civilian_03.glb`: three distinct rigged civilian appearances with walk/run clips.

The generated models are based on the CC0 MakeHuman character dataset via Ara 3D Gen. The source generator uses photo-based skin textures, clothing normal maps, rigged humanoid geometry and an export pipeline for Godot-compatible GLB. The Android workflow downloads the generator and MakeHuman source assets, builds the characters, copies the GLBs into this folder, then imports and packages them into the APK. No runtime internet access is needed.

## Animation mapping

- City pedestrians: `Walk` (looped); game movement controls translation.
- Soldiers moving: `Run` (looped); game movement controls translation.
- Soldiers holding position: `Rifle idle (low ready)` (looped).
- Soldiers engaging: `Rifle fire (single)` (one-shot); damage remains controlled by the battle simulation.
- The imported rig also includes other locomotion, shooter, hit, fall/death and melee clips for later gameplay wiring.

The loader chooses clips by name and enables looping for idle/locomotion. If a generated model is missing, the existing procedural fallback remains available.

## Build and performance

The generator uses the medium character detail tier for the repeated mobile units (approximately 30–40k triangles per human); this balances anatomy and skin/clothing detail against the cost of rendering many skinned soldiers on Android. This is not a claim of film-grade photorealism. Final visual acceptance still requires inspection on the target phone, frame-rate/thermal profiling and tuning of shadows, texture memory and LODs.

## Licensing and provenance

- Generator code: Ara 3D Gen, MIT.
- Character source data: MakeHuman assets, CC0 1.0.
- Generated character exports: permitted for commercial and non-commercial use under the upstream asset terms.
- CI copies the upstream MakeHuman CC0 notice to `MAKEHUMAN-CC0-LICENSE.txt`.

Upstream project and documentation:
- https://github.com/TuriaArt/3d-gen-TU
- https://github.com/TuriaArt/3d-gen-TU/blob/main/scripts/ASSETS_LICENSE.txt
- https://creativecommons.org/publicdomain/zero/1.0/

Do not replace these with low-poly/stylized assets for the production visual target without explicit approval.
