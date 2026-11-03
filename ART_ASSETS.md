# LAST STOP art manifest — Recovery V3

The four original models are authored by tools/build-prefabs.mjs and saved under assets/prefabs/. No downloaded model, copied paid-game content, or Toolbox script is included. The models are local source assets and need no Roblox model upload IDs.

| Prefab | Permanent Studio path | Instances | Source |
| --- | --- | ---: | --- |
| Lobby.rbxmx | ServerStorage.LastStopAssets.Lobby | 537 | Original project authoring |
| Elevator.rbxmx | ServerStorage.LastStopAssets.Elevator | 116 | Original project authoring |
| Hospital.rbxmx | ServerStorage.LastStopAssets.Floors.Hospital | 805 | Original project authoring |
| Stalker.rbxmx | ServerStorage.LastStopAssets.Stalker | 40 | Original Motor6D rig and procedural animations |

All eight 1024×1024 maps below were uploaded through Studio Asset Manager under **gakez007** on 2026-11-03. Each import showed success and appeared in the account inventory. IDs were read from that inventory. Import copies are in assets/roblox-upload/; originals and packed ARM sources remain in assets/polyhaven/.

| Filename | Roblox image ID | Saved target property |
| --- | ---: | --- |
| chipped_concrete_diff_1k.jpg | 80959961009929 | MaterialService.ChippedConcrete.ColorMap |
| chipped_concrete_nor_gl_1k.jpg | 80291856302301 | MaterialService.ChippedConcrete.NormalMap |
| chipped_concrete_rough_1k.png | 77587300776452 | MaterialService.ChippedConcrete.RoughnessMap |
| chipped_concrete_metal_1k.png | 80777076182700 | MaterialService.ChippedConcrete.MetalnessMap; PaintedSteel.MetalnessMap |
| metal_plate_diff_1k.jpg | 137105055040989 | MaterialService.MetalPlate.ColorMap; PaintedSteel.ColorMap |
| metal_plate_nor_gl_1k.jpg | 72038388556893 | MaterialService.MetalPlate.NormalMap; PaintedSteel.NormalMap |
| metal_plate_rough_1k.png | 88399395045423 | MaterialService.MetalPlate.RoughnessMap; PaintedSteel.RoughnessMap |
| metal_plate_metal_1k.png | 91150503292713 | MaterialService.MetalPlate.MetalnessMap |

Sources: [Poly Haven chipped_concrete](https://polyhaven.com/a/chipped_concrete) and [Poly Haven metal_plate](https://polyhaven.com/a/metal_plate). Both use [CC0](https://polyhaven.com/license), permitting modification, redistribution, and commercial Roblox use. Attribution is voluntary. The roughness/metalness PNGs were extracted from the ARM green/blue channels. PaintedSteel reuses the black concrete metalness for its nonmetallic paint layer. Packed ARM files are retained as source data, not bound to a Roblox map slot. No emissive map is claimed.

Concrete tiles at 8 studs; steel at 5. Prefab parts carry a PbrMaterial StringValue. The runtime applies saved variants to the clones. Structural surfaces use ChippedConcrete. PaintedSteel covers painted doors/panels/columns; MetalPlate covers exposed plates, thresholds, and pipes. Cloth, rubber, plastic, glass, warning stripes, and lettering use built-in materials and authored geometry.

The build audit checks map IDs against ArtTheme and the built place. The real Play screenshots show applied surface textures and normal detail, especially the elevator close-up. Newly combined MaterialVariants emitted temporary generated-representation/cache warnings during startup; those are retained in the logs. No claim is made that local screenshots verify permissions/moderation in a different account or published universe. Cross-experience permission checks remain outstanding.

To reimport for another owner: Asset Manager → Import → select all eight files in assets/roblox-upload → choose the intended creator → Start Import. Record the new image IDs. Update both ArtTheme.Pbr and default.project.json MaterialService properties, rebuild, run the audit, and inspect Play after image moderation/material generation finishes. Never invent IDs or simply assume copied files have uploaded.
