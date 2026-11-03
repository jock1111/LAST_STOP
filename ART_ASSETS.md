# LAST STOP art asset manifest

This manifest intentionally records only assets with verified sources and Roblox upload status. No guessed or borrowed Roblox asset IDs are used.

| Asset | Local source file | Source / creator | License | Target usage | Roblox asset ID | Studio verification |
| --- | --- | --- | --- | --- | --- | --- |
| Chipped concrete albedo | `assets/polyhaven/chipped_concrete/chipped_concrete_diff_1k.jpg` | [Poly Haven — chipped_concrete](https://polyhaven.com/a/chipped_concrete), community asset library | [CC0](https://polyhaven.com/license) | Concourse floor, concrete station walls | Not uploaded | Import-ready; not applied until a user-authorized Studio upload provides an ID |
| Chipped concrete normal (OpenGL) | `assets/polyhaven/chipped_concrete/chipped_concrete_nor_gl_1k.jpg` | Poly Haven | CC0 | `ChippedConcrete` MaterialVariant normal map | Not uploaded | Import-ready |
| Chipped concrete ARM | `assets/polyhaven/chipped_concrete/chipped_concrete_arm_1k.jpg` | Poly Haven | CC0 | Source map (R = AO, G = roughness, B = metalness) | Not uploaded | Source preserved |
| Chipped concrete roughness | `assets/polyhaven/chipped_concrete/chipped_concrete_rough_1k.png` | Derived losslessly from the Poly Haven ARM green channel | CC0 derivative | `ChippedConcrete` MaterialVariant roughness map | Not uploaded | 1024×1024 grayscale; import-ready |
| Chipped concrete metalness | `assets/polyhaven/chipped_concrete/chipped_concrete_metal_1k.png` | Derived losslessly from the Poly Haven ARM blue channel | CC0 derivative | `ChippedConcrete` MaterialVariant metalness map | Not uploaded | 1024×1024 grayscale; import-ready |
| Metal plate albedo | `assets/polyhaven/metal_plate/metal_plate_diff_1k.jpg` | [Poly Haven — metal_plate](https://polyhaven.com/a/metal_plate), community asset library | [CC0](https://polyhaven.com/license) | Elevator panels, floor plates, service hardware | Not uploaded | Import-ready; not applied until a user-authorized Studio upload provides an ID |
| Metal plate normal (OpenGL) | `assets/polyhaven/metal_plate/metal_plate_nor_gl_1k.jpg` | Poly Haven | CC0 | `MetalPlate` MaterialVariant normal map | Not uploaded | Import-ready |
| Metal plate ARM | `assets/polyhaven/metal_plate/metal_plate_arm_1k.jpg` | Poly Haven | CC0 | Source map (R = AO, G = roughness, B = metalness) | Not uploaded | Source preserved |
| Metal plate roughness | `assets/polyhaven/metal_plate/metal_plate_rough_1k.png` | Derived losslessly from the Poly Haven ARM green channel | CC0 derivative | `MetalPlate` MaterialVariant roughness map | Not uploaded | 1024×1024 grayscale; import-ready |
| Metal plate metalness | `assets/polyhaven/metal_plate/metal_plate_metal_1k.png` | Derived losslessly from the Poly Haven ARM blue channel | CC0 derivative | `MetalPlate` MaterialVariant metalness map | Not uploaded | 1024×1024 grayscale; import-ready |

Downloaded: 2026-11-02. Asset configuration lives in `src/ReplicatedStorage/Shared/ArtTheme.lua`. Its map fields are deliberately blank until final asset IDs are owned by the Roblox experience account and verified in Studio.

## Required final import step

Upload the selected maps through the project's Roblox Studio Asset Manager, record the resulting image asset IDs here, set the corresponding `ArtTheme.Pbr` fields, then verify a MaterialVariant on actual lobby and elevator parts under neutral lighting and in a Play session. The maps must not be described as applied before that verification.
