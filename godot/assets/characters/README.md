# Character model import slots

The Godot scene now prefers imported, rigged glTF binary characters when these files are present:

- `civilian.glb` — rigged civilian with a looping walk animation.
- `soldier.glb` — rigged soldier with an idle animation and, ideally, locomotion/combat clips.

Place the files in this directory. The importer looks for an embedded `AnimationPlayer`, selects an animation whose name contains the requested action (case-insensitive), and falls back to the first embedded clip. If a file is absent or invalid, the current procedural character remains as a fallback.

## Asset requirements before shipping

- Prefer GLB/glTF 2.0 with embedded textures and a humanoid skeleton.
- Keep civilian and soldier skeletons consistent if sharing animation clips.
- Include at least idle, walk, run, and combat/weapon-ready animations for soldiers.
- Use physically based materials; keep texture maps embedded or copied beside the GLB.
- Optimize meshes and texture dimensions for Android; keep source/licence notes in `ASSET_CREDITS.md`.
- Confirm each asset's individual licence and redistribution rights before adding it to a public APK.

## Candidate animation source

Quaternius Universal Base Characters and Universal Animation Library are CC0, humanoid-rigged resources compatible with Godot. Their free downloadable pack variants may be stylized rather than photorealistic, so they are a rig/animation candidate, not a claim of photoreal character quality:

- https://quaternius.com/packs/universalbasecharacters.html
- https://quaternius.com/packs/universalanimationlibrary.html

No third-party character model is bundled by this integration commit yet. The procedural fallback remains active until the actual GLB files are added and tested in the Android build.
