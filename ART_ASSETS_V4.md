# V4 asset provenance and reproduction

The selected visual direction is industrial research transit, with teal task lighting, warm emergency accents and worn PBR steel/concrete. This direction was chosen during implementation from the user's broad brief.

## Imported environment meshes

Kenney's Space Station Kit is CC0. Eighteen selected GLBs, its palette texture and original license are retained under assets/vendor/kenney-space-station/. The source kit is available at the following link. [Kenney Space Station Kit](https://kenney.nl/assets/space-station-kit)

The selected assembly is assets/imports/Environment.glb. The actual Studio-imported, uploaded MeshParts are saved in assets/prefabs/Environment.rbxmx. They include wall/window panels, floor panels, bed, computers, containers, rails, pipes and a ramp. EnvironmentService clones these uploaded mesh instances. Structural meshes use the saved PBR material variants, while furniture retains the imported palette texture.

## Skinned Stalker and authored clips

The source is **3D Horror Game Monster**, authored by HorrorGameMaker.com and distributed under CC0 through OpenGameArt. The original author README is retained under assets/vendor/horror-game-maker/. Its optional credit is provided here. [Source and license declaration](https://opengameart.org/content/3d-horror-game-monster)

The selected source includes Idle, Walk and Run FBXs plus the black color variant. The import has 6,772 vertices and 61 Roblox bones. The saved prefab has a SurfaceAppearance with color, normal and roughness maps.

| Asset | Roblox ID |
| --- | --- |
| Skinned mesh | 79662703056041 |
| Color map | 139290702449907 |
| Normal map | 96470019773943 |
| Roughness map | 129007056108561 |

tools/fetch-v4-assets.py downloads the original CC0 archives into ignored .cache-v4/. tools/prepare-v4-imports.py converts the selected content with Blender. tools/bake-stalker-motion.py retargets global FBX deformation against the Studio-imported Roblox bind pose, then emits compressed local bone CFrames. Separate clip modules respect Studio's 200,000-character Source assignment limit. CreatureController interpolates clips at 30 Hz and skips distant creatures. The original R6 prefab provides the invisible physics carrier and navigation contract.

assets/imports/Stalker.glb, StalkerNormal.png, StalkerRoughness.png and stalker-motion.json preserve the converted source. Reimporting under another Roblox owner requires recording that owner's uploaded IDs and updating the saved prefab.

## PBR environment materials

The previously uploaded eight Poly Haven 1K material maps are reused. Their source, CC0 license, IDs and saved MaterialVariant properties are retained in the historical V3 manifest. [PBR map manifest](ART_ASSETS.md)

## Original audio

tools/synthesize-v4-audio.py generates the six original WAVs in assets/audio/. Uploaded sound IDs are configured in Shared/SoundAssets.lua. These tracks were synthesized for this project.

| Track | Roblox ID |
| --- | --- |
| TransitDrone | 111719135928872 |
| FloodAmbience | 73385949712266 |
| StalkerBreath | 112213193709708 |
| StalkerThreat | 113812695023212 |
| ElevatorTravel | 100114017015233 |
| ObjectiveChime | 106002252115800 |

## Saved assets and runtime boundaries

All six prefabs are script-free. Gameplay code comes from src/. Asset upload IDs reference actual Studio imports. The canonical build includes the imported prefabs and PBR definitions under ServerStorage and MaterialService. Runtime code assigns existing material variants because their definition properties require Studio/plugin capability.

Studio instance-based ContentProvider preloads and real screenshots are recorded in qa/v4/. Published-experience permission and moderation verification remains outstanding.
