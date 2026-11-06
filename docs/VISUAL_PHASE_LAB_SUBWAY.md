# Visual Phase Plan: Flooded Laboratory & Abandoned Subway

**Branch:** `v6-visual-development` (continues from V6 acceptance commit `7b1f30e`)
**Goal:** Replace the current procedural Parts construction of `FloodedLaboratory` and `AbandonedSubway` with high-quality MeshParts, PBR materials, atmospheric lighting, and environmental storytelling — while preserving all gameplay logic, ProfileService protections, and the `V6 / VISUAL DEVELOPMENT` build identifier.

---

## 1. Current State Inventory

### Flooded Laboratory (`Pelagic` / `FloodedLaboratory`)
- **Geometry:** Entirely procedural `Part` construction in `Environment.BuildLaboratory()`
  - Basin floor: `Concrete` Part (94×1×110)
  - Flood water: `Glass` Part (90×0.16×106) with transparency/reflectance
  - Catwalks: 6 `Part` walkways + `floor-panel` MeshParts (12×0.8×12 grid)
  - Walls: `wall-window` / `wall` / `wall-detail` MeshParts (8×14×2.4)
  - Containment: 4 `container-tall` MeshParts + `Concrete` plinths + `Glass` cylinders
  - Rails: `rail` MeshParts along catwalk edges
  - Pipes: `pipe` / `pipe-bend` MeshParts on perimeter
  - Computers: `computer-system` / `computer-wide` MeshPairs
  - Ramps: `BasinAccessRamp` Parts (sloped)
  - Ceiling/beams: `Concrete` Parts + `StructuralBeam` Parts
  - Edge lights: Neon strips (`CatwalkEdgeLight`)
- **Materials:** `ChippedConcrete` (4 studs/tile), `PaintedSteel`, `MetalPlate`, `Glass`, `Neon`, built-in `Concrete`/`Metal`
- **Lighting:** Ceiling `PointLight`s (cyan/amber), containment cylinder lights, catwalk edge neon
- **Hazard:** Rising flood water (color shift), electrified water damage (Y < 1.8)
- **Markers:** EntranceSpawn (0,4,43), ElevatorSocket (0,0,63), EnemySpawn (0,5,-40), RoomBounds (96×20×130)

### Abandoned Subway (`Subway` / `AbandonedSubway`)
- **Geometry:** Entirely procedural `Part` construction in `Environment.BuildSubway()`
  - Track bed: `Concrete` Part (12×1×110) with PathfindingModifier "TrainTrack"
  - Platforms: 2× `Concrete` Parts (16×1×110) + `PlatformEdge` Metal Parts
  - Floor: `Concrete` Part (60×1×120)
  - Tunnel walls: 2× `Concrete` Parts (2×18×120)
  - Ceiling: `Concrete` Part (60×1×120)
  - Containers: 12× `container-tall` MeshParts (4×12×4)
  - Crossings: `Concrete` Part (60×1×8) + signage
  - Train: `Metal` Part car (11×8×40) + `Neon` headlight — moved by server `PivotTo`
  - Elevator bridge: `Part` (60×1×16)
- **Materials:** `Concrete` (built-in), `Metal`/`MetalPlate`, `Neon`, `Glass`
- **Lighting:** Platform `PointLight`s (warm amber), 24 stud range
- **Hazard:** Periodic train pass (16s period, 4s active), damage lane on track (X ±6.5)
- **Markers:** EntranceSpawn (-22,4,46), ElevatorSocket (0,0,62), EnemySpawn (-22,4,-40), RoomBounds (60×20×130)

### Reusable Mesh Assets (in `assets/prefabs/Environment.rbxmx`)
| Mesh Name | Use | Current Material |
|---|---|---|
| `floor-panel` | Lab catwalk decking | `PaintedSteel` |
| `wall` | Lab perimeter walls | `PaintedSteel` |
| `wall-window` | Lab walls with windows | `PaintedSteel` |
| `wall-corner` | (unused) | — |
| `wall-detail` | Lab detail panels | `PaintedSteel` |
| `rail` | Lab catwalk railings | `PaintedSteel` |
| `pipe` | Lab vertical pipes | `PaintedSteel` |
| `pipe-bend` | Lab pipe corners | `PaintedSteel` |
| `container` | (unused) | `PaintedSteel` |
| `container-tall` | Lab containment / Subway props | `PaintedSteel` |
| `computer-system` | Lab control consoles | `PaintedSteel` |
| `computer-wide` | Lab central terminal | `PaintedSteel` |
| `display-wall-wide` | (unused) | — |

### PBR MaterialVariants (MaterialService + `ArtTheme.Pbr`)
| Variant | Base | Maps | Current Use |
|---|---|---|---|
| `ChippedConcrete` | Concrete | Color/Normal/Roughness/Metalness | Lab basin (procedural), Hospital floors |
| `PaintedSteel` | Metal | Color/Normal/Roughness/Metalness | Most MeshParts, Hospital doors/panels |
| `MetalPlate` | Metal | Color/Normal/Roughness/Metalness | Lobby pockets, Elevator, thresholds, pipes |

---

## 2. Visual Direction & References

### Flooded Laboratory — "Pelagic / SUBLEVEL 06"
**Atmosphere:** Deep-sea research facility, partially flooded, bioluminescent contamination, failing life support.
- **Color palette:** Cyan/teal bioluminescence, steel blues, rusted amber warnings, void navy shadows
- **Key materials:** Corroded steel (ChippedConcrete variant), barnacled metal, frosted containment glass, flooded concrete
- **Lighting:** Submerged cyan glows, flickering amber emergency strips, containment cylinder cores, volumetric godrays through water surface
- **Story beats:** Pump restart → control sync → specimen extraction. Environmental cues: pressure doors, depth gauges, specimen logs, breach scars.

### Abandoned Subway — "The Last Train / NORTHBOUND"
**Atmosphere:** Cold War-era transit terminus, frozen in time, single track still live, signal relay the only way out.
- **Color palette:** Sodium-amber platform lights, signal cyan/green/red, rusted track steel, concrete grime, emergency white
- **Key materials:** Tile/concrete (ChippedConcrete), weathered steel rails, ceramic tile accents, vitreous enamel signs
- **Lighting:** Rhythmic platform pools, signal lamps, train headlight sweep, flickering fluorescent tubes, emergency strips
- **Story beats:** Relay retrieval → signal install → sync controls → case recovery → escape. Environmental cues: timetable posters, maintenance logs, "SERVICE SUSPENDED", personal effects on benches.

---

## 3. Asset Sourcing & Licensing

| Asset Type | Source | License | Action |
|---|---|---|---|
| **PBR Maps (existing)** | Poly Haven `chipped_concrete`, `metal_plate` | CC0 | **Reuse** — already uploaded, IDs in `ArtTheme` + `default.project.json` |
| **New PBR: Corroded Steel** | Poly Haven `rusted_metal`, `corroded_iron` | CC0 | Download 1k maps, upload via Asset Manager, create `CorrodedSteel` MaterialVariant |
| **New PBR: Ceramic Tile** | Poly Haven `ceramic_tiles`, `subway_tile` | CC0 | Download, upload, create `SubwayTile` MaterialVariant |
| **New PBR: Flooded Concrete** | Poly Haven `wet_concrete`, `moldy_concrete` | CC0 | Download, upload, create `FloodedConcrete` MaterialVariant |
| **New PBR: Barnacled Metal** | Poly Haven `barnacles`, `marine_growth` (alpha masks) | CC0 | Download, upload, create `BarnacledMetal` MaterialVariant (uses alpha for growth) |
| **Meshes: Lab Modules** | Authored in Blender → exported GLB | Original | Build modular kit: corridor segment, pump room, containment cell, control room, catwalk section, ramp |
| **Meshes: Subway Modules** | Authored in Blender → exported GLB | Original | Build modular kit: platform tile, tunnel arch, track bed, signal box, relay case, bench, poster frame, train car |
| **Meshes: Shared Props** | Authored in Blender → exported GLB | Original | Pressure doors, depth gauges, valve wheels, cable trays, conduit, lockers, timetable boards |
| **Audio: Ambience** | Freesound / BBC Sound Effects (CC0) | CC0 | Lab: pump hum, water drip, electrical buzz, containment hiss. Subway: distant rumble, fluorescent hum, dripping, wind tunnel |
| **Audio: Hazard** | Original / CC0 | CC0 | Lab: rising water, alarm klaxon. Subway: train horn, rail squeal, warning chime |

**Import workflow:**
1. Download source assets to `assets/polyhaven/` (maps) and `assets/blender/` (mesh `.blend` + exported `.glb`)
2. Import via Studio Asset Manager under project owner account
3. Record new image/mesh IDs in `ART_ASSETS_V4.md` (append)
4. Add MaterialVariants to `ArtTheme.Pbr` and `default.project.json` MaterialService
5. Rebuild with `tools/build-prefabs.mjs` → `rojo build` → verify with `tools/verify-build.mjs`

---

## 4. MeshPart & PBR Implementation Plan

### 4.1 Flooded Laboratory — Modular Kit

| Module | Mesh Parts | MaterialVariant | Approx. Triangles | Notes |
|---|---|---|---|---|
| `lab_corridor_straight` | floor, ceiling, 2 walls, 2 window walls | `CorrodedSteel` / `FloodedConcrete` | ~2.5k | 12×4×12 studs, tiles to grid |
| `lab_corridor_corner` | same, 90° bend | same | ~2.8k | |
| `lab_pump_room` | pump bases, pipe manifold, control console, grating floor | `CorrodedSteel`, `BarnacledMetal` | ~4k | Pump A (west) / Pump B (east) |
| `lab_containment_cell` | cylinder frame, glass tank, plinth, instrument panel | `CorrodedSteel`, `FloodedConcrete`, `Glass` (custom) | ~3.5k | 4× per run (seeded positions) |
| `lab_control_room` | raised floor, server racks, central terminal, wall screens | `CorrodedSteel`, `PaintedSteel` | ~3k | Control A / Control B sync point |
| `lab_catwalk_section` | grating deck, rail posts, top rail, cable tray | `BarnacledMetal`, `CorrodedSteel` | ~1.8k | 12-stud modules, snaps to grid |
| `lab_ramp` | sloped grating, side rails, transition lip | `BarnacledMetal` | ~1.2k | Basin access at (±30, ±32) |
| `lab_pressure_door` | door leaf, frame, hydraulic actuator, window | `CorrodedSteel`, `Glass` | ~1.5k | Animated via TweenService (future) |
| `lab_prop_valve` | valve wheel, stem, flange | `BarnacledMetal` | ~0.8k | Scatter on pipes |
| `lab_prop_gauge` | depth/pressure gauge face, housing | `PaintedSteel`, `Glass` | ~0.6k | Scatter on walls |
| `lab_prop_cable_tray` | tray segments, covers, droops | `CorrodedSteel` | ~0.5k | Run along ceilings |

**Placement strategy:** Keep `Environment.BuildLaboratory()` as the authoritative layout function. Replace procedural `Part` calls with `Environment.Mesh()` calls that clone from `ServerStorage.LastStopAssets.Environment` (new folder). Preserve all marker positions, hazard logic, patrol paths, and objective coordinates exactly.

### 4.2 Abandoned Subway — Modular Kit

| Module | Mesh Parts | MaterialVariant | Approx. Triangles | Notes |
|---|---|---|---|---|
| `subway_platform_tile` | tile deck, tactile strip, drain channel | `SubwayTile`, `ChippedConcrete` | ~1.2k | 4×16 studs, 27 tiles per platform |
| `subway_tunnel_arch` | vaulted ceiling, wall bases, cable recesses | `FloodedConcrete`, `ChippedConcrete` | ~2.5k | 16-stud segments, 7 per side |
| `subway_track_bed` | rails, ties, ballast, drainage | `CorrodedSteel`, `ChippedConcrete` | ~1.8k | 16-stud segments, PathfindingModifier preserved |
| `subway_crossing` | tactile pavers, rail gap covers, sign bases | `SubwayTile`, `MetalPlate` | ~1k | North crossing at Z=-46 |
| `subway_signal_box` | cabinet, relay rack, indicator lamps, lever frame | `PaintedSteel`, `CorrodedSteel` | ~2.2k | South signal box (Power objective) |
| `subway_platform_console` | console desk, relay slot, screen, keypad | `PaintedSteel`, `CorrodedSteel` | ~1.5k | North platform (Fuse objective) |
| `subway_train_car` | carbody, bogies, windows, headlight, marker lights | `CorrodedSteel`, `Glass`, `Neon` (emissive) | ~4k | Server-moved, ~500 parts budget |
| `subway_bench` | seat slats, frame, armrests, ads | `PaintedSteel`, `Wood` (custom) | ~0.8k | Scatter on platforms |
| `subway_poster_frame` | frame, glass, poster texture (decal) | `MetalPlate`, `Glass` | ~0.5k | "SERVICE SUSPENDED", timetable |
| `subway_locker` | door bank, vents, handle | `PaintedSteel` | ~0.6k | Service areas |
| `subway_valve` | trackside valve, pressure gauge | `CorrodedSteel` | ~0.5k | Scatter on tunnel walls |
| `subway_cable_tray` | tray, conduit, junction boxes | `CorrodedSteel` | ~0.4k | Ceiling runs |

**Placement strategy:** Same as Lab — `Environment.BuildSubway()` remains authoritative. Replace `Part` construction with `Environment.Mesh()` clones. The train model becomes a `MeshPart` assembly (car + bogies) but retains `PrimaryPart` + `PivotTo` movement. All markers, hazard timing (`SubwayCycle`), and objective coordinates unchanged.

### 4.3 New MaterialVariants to Define

```lua
-- ArtTheme.Pbr additions
CorrodedSteel = {
    BaseMaterial = Enum.Material.Metal,
    StudsPerTile = 4,
    ColorMap = "rbxassetid://NEW_ID",
    NormalMap = "rbxassetid://NEW_ID",
    MetalnessMap = "rbxassetid://NEW_ID",
    RoughnessMap = "rbxassetid://NEW_ID",
},
FloodedConcrete = {
    BaseMaterial = Enum.Material.Concrete,
    StudsPerTile = 4,
    ColorMap = "rbxassetid://NEW_ID",
    NormalMap = "rbxassetid://NEW_ID",
    MetalnessMap = "rbxassetid://80777076182700",  -- reuse black metalness
    RoughnessMap = "rbxassetid://NEW_ID",
},
SubwayTile = {
    BaseMaterial = Enum.Material.Concrete,
    StudsPerTile = 8,  -- larger tile read
    ColorMap = "rbxassetid://NEW_ID",
    NormalMap = "rbxassetid://NEW_ID",
    MetalnessMap = "rbxassetid://80777076182700",
    RoughnessMap = "rbxassetid://NEW_ID",
},
BarnacledMetal = {
    BaseMaterial = Enum.Material.Metal,
    StudsPerTile = 3,
    ColorMap = "rbxassetid://NEW_ID",        -- base corroded steel
    NormalMap = "rbxassetid://NEW_ID",       -- barnacle height
    MetalnessMap = "rbxassetid://NEW_ID",    -- varied metalness
    RoughnessMap = "rbxassetid://NEW_ID",
},
-- Custom Glass for containment (lower reflectance, slight tint)
ContainmentGlass = {
    BaseMaterial = Enum.Material.Glass,
    StudsPerTile = 1,
    ColorMap = "",  -- none
    NormalMap = "",
    MetalnessMap = "",
    RoughnessMap = "",
}
```

---

## 5. Lighting & Atmosphere

### 5.1 Flooded Laboratory

| Element | Implementation | Budget |
|---|---|---|
| **Global** | `Lighting.Ambient = Color3.fromRGB(12, 18, 22)`, `OutdoorAmbient = Color3.fromRGB(8, 12, 16)` | — |
| **Fog** | `Lighting.FogStart = 40`, `FogEnd = 140`, `FogColor = Color3.fromRGB(10, 20, 28)` | — |
| **Ceiling grid** | 7×7 `PointLight` (cyan, range 30, brightness 1.2, shadows off) at Y=13, Z=-48..48 | 49 lights |
| **Containment cores** | 4× `PointLight` (cyan, range 23, brightness 1.8, shadows off) at cylinder centers | 4 lights |
| **Catwalk edge** | Existing neon strips (`CatwalkEdgeLight`) — keep, ensure `HazardIndicator` attribute | — |
| **Pump rooms** | 2× `SpotLight` (amber, range 18, angle 60°, brightness 2) aimed at pump consoles | 2 lights |
| **Control rooms** | 2× `PointLight` (white, range 14, brightness 1.5) at Control A/B | 2 lights |
| **Water caustics** | `SurfaceLight` on `FloodWater` part (cyan, range 60, brightness 0.4) — client-only via `LightingService` | 1 light |
| **Volumetric beams** | `Beam` particles from ceiling lights down to water surface (cyan, transparency 0.85) | ~20 beams |
| **Power flicker** | Existing `PowerFlicker` attribute → tween all lab lights 0.3× brightness for 1.6s | Scripted |

**Total runtime lights:** ~60 (well under 128 limit for Future lighting)

### 5.2 Abandoned Subway

| Element | Implementation | Budget |
|---|---|---|
| **Global** | `Lighting.Ambient = Color3.fromRGB(18, 16, 12)`, `OutdoorAmbient = Color3.fromRGB(12, 10, 8)` | — |
| **Fog** | `Lighting.FogStart = 30`, `FogEnd = 120`, `FogColor = Color3.fromRGB(24, 22, 18)` | — |
| **Platform pools** | Existing 14×2 `PointLight` (warm amber, range 24, brightness 1.6) — keep, add subtle flicker | 28 lights |
| **Signal lamps** | 3× `SpotLight` per signal box (cyan/green/red, range 8, angle 30°, brightness 2.5) | 6 lights |
| **Train headlight** | `SpotLight` on train `Headlight` part (white, range 60, angle 25°, brightness 3) — moves with train | 1 light |
| **Train marker lights** | 2× `PointLight` (red rear, white front, range 12, brightness 1) on train car | 2 lights |
| **Fluorescent tubes** | `SurfaceLight` on tunnel arch segments (cool white, range 16, brightness 0.8) — 14 segments | 14 lights |
| **Emergency strips** | Neon `Part` strips at platform edges (existing `PlatformEdge` amber) — keep | — |
| **Distant tunnel** | `PointLight` at Z=-100 and Z=100 (dim amber, range 40, brightness 0.5) | 2 lights |

**Total runtime lights:** ~53

### 5.3 Shared Atmosphere Systems

- **Particle emitters:** Lab — water drips (basin), steam vents (pipes), bioluminescent motes (water). Subway — dust motes (platform), rail dust (track), breath puffs (cold).
- **Sound zones:** `SoundService` reverb zones per room template. Lab: `ReverbType = "ConcertHall"` (wet). Subway: `ReverbType = "Tunnel"` (long tail).
- **Dynamic music:** Existing elevator/stalker music — add floor-specific stems (Lab: low synth drone; Subway: rhythmic industrial) crossfaded on `FloorTheme` attribute.

---

## 6. Environmental Storytelling

### 6.1 Flooded Laboratory

| Location | Story Element | Implementation |
|---|---|---|
| **Entrance airlock** | Pressure door with depth gauge reading "−600m" | `lab_pressure_door` + `lab_prop_gauge` |
| **West pump room** | Logbook: "Pump A bearing failure. 14 days overdue maintenance." | `SurfaceGui` on console desk (decal texture) |
| **East pump room** | Flooded tool locker, wrench fused to valve | `subway_locker` variant + `lab_prop_valve` welded |
| **Containment cells** | Specimen ID tags: "SPEC-734-PELAGIC", "SPEC-735-PELAGIC" | `SurfaceGui` on cylinder glass (decal) |
| **Central terminal** | Last entry: "Flood breach Sector 4. Seal failed. Evacuation denied." | `computer-wide` screen decal |
| **Catwalk junctions** | Depth markers every 12 studs: "−580m", "−592m", "−604m" | `Sign` on rail posts (amber) |
| **Basin floor (underwater)** | Submerged equipment, cable trays, fallen grating | `lab_prop_cable_tray` + `container` meshes at Y=-3 |
| **Specimen (objective)** | Sealed canister with biohazard trefoil, frost on glass | Custom `MeshPart` with `ContainmentGlass`, `PointLight` inside |

### 6.2 Abandoned Subway

| Location | Story Element | Implementation |
|---|---|---|
| **North platform** | "LAST TRAIN / NORTHBOUND / NOT IN SERVICE" (existing sign) | Keep + add timetable poster frame |
| **Platform benches** | Personal effects: folded newspaper, abandoned bag, coffee thermos | `subway_bench` + small prop meshes (non-colliding) |
| **Track bed** | Maintenance cart derailed, tools scattered | `container` mesh on side, prop tools |
| **Signal box (south)** | Relay slot empty, log: "Awaiting relay from north. Train timer active." | `subway_signal_box` console `SurfaceGui` |
| **Crossing (Z=-46)** | "USE MARKED CROSSINGS / CLEAR TRACK ON WARNING" (existing) | Keep + add tactile paver texture |
| **Tunnel walls** | Soot streaks, water stains, cable fire scarring | Decal textures on `subway_tunnel_arch` |
| **Relay case (objective)** | Heavy shielded case, "SIGNAL RELAY / LIVE CIRCUIT" stencil | Custom `MeshPart` with `PaintedSteel`, `SurfaceGui` |
| **Train car** | Interior visible through windows: torn seats, emergency hammer | `subway_train_car` window `Glass` with interior decal |

---

## 7. Performance Budgets

| Metric | Target | Measurement |
|---|---|---|
| **Total triangles (Lab)** | ≤ 180k | `Workspace:GetDescendants()` filter `MeshPart` → sum `TriangleCount` |
| **Total triangles (Subway)** | ≤ 150k | Same |
| **Draw calls (Lab)** | ≤ 180 | `Stats.Render` → DrawCalls in Play |
| **Draw calls (Subway)** | ≤ 150 | Same |
| **Texture memory** | ≤ 120 MB | `Stats.Texture` → TextureMemory |
| **Runtime lights** | ≤ 64 per floor | `Lighting:GetChildren()` filter `Light` |
| **Parts (Lab)** | ≤ 2,500 | `Workspace:GetDescendants()` count `BasePart` |
| **Parts (Subway)** | ≤ 2,200 | Same |
| **Script activity** | ≤ 2% | `Stats.Script` → Activity % |
| **Physics sleep** | ≥ 90% parts asleep | `Stats.Physics` → Sleeping % |
| **Client FPS (desktop)** | ≥ 60 @ 1080p | `Stats.Frame` → FPS in 3-cycle test |
| **Client FPS (mobile)** | ≥ 30 @ 720p | Test via device emulation |

**Optimization levers:**
- Merge static meshes by MaterialVariant (Studio `MeshPart` → `Merge` or Blender pre-merge)
- Use `RenderFidelity = "Automatic"` on all MeshParts
- `CollisionFidelity = "Box"` or `"Hull"` on non-walkable props
- `CanTouch = false` on all non-interactive geometry
- `StreamingEnabled = true` (already set) with `ModelStreamingMode = "Atomic"` on floor models
- LOD: distant tunnel/platform meshes → `RenderFidelity = "Performance"` at >80 studs

---

## 8. QA & Acceptance Criteria

### 8.1 Automated Checks (extend `qa/v6/runtime_harness.server.lua`)

| Check | Description |
|---|---|
| `LabMeshCount` | Lab floor model has ≥ 150 MeshParts, 0 procedural Parts for architecture |
| `SubwayMeshCount` | Subway floor model has ≥ 120 MeshParts, 0 procedural Parts for architecture |
| `LabMaterialVariants` | All Lab MeshParts use `CorrodedSteel`, `FloodedConcrete`, `BarnacledMetal`, `ContainmentGlass`, `PaintedSteel` |
| `SubwayMaterialVariants` | All Subway MeshParts use `SubwayTile`, `FloodedConcrete`, `ChippedConcrete`, `CorrodedSteel`, `PaintedSteel`, `MetalPlate` |
| `LabLightingBudget` | ≤ 64 active lights on Lab floor |
| `SubwayLightingBudget` | ≤ 64 active lights on Subway floor |
| `LabTriangles` | Lab floor total triangles ≤ 180k |
| `SubwayTriangles` | Subway floor total triangles ≤ 150k |
| `LabFogAtmosphere` | Lab `Lighting.FogColor` ≈ (10,20,28), `FogEnd` ≈ 140 |
| `SubwayFogAtmosphere` | Subway `Lighting.FogColor` ≈ (24,22,18), `FogEnd` ≈ 120 |
| `LabStoryProps` | ≥ 8 story `SurfaceGui`/decal elements found on Lab floor |
| `SubwayStoryProps` | ≥ 8 story `SurfaceGui`/decal elements found on Subway floor |
| `LabHazardVisuals` | Flood water color shifts on `HazardPhase` (Safe→Warning→Active) |
| `SubwayHazardVisuals` | Train headlight moves, signal lamps cycle, track hazard strips glow on `Warning`/`Active` |
| `LabAudioZone` | Lab has `SoundGroup` with reverb, ambient loop playing |
| `SubwayAudioZone` | Subway has `SoundGroup` with reverb, ambient loop playing |
| `ObjectiveCoordsPreserved` | All 6 objective target positions per floor match `ObjectiveRoom.lua` exactly |
| `MarkerPositionsPreserved` | All marker CFrames match `EnvironmentService.lua` exactly |
| `PatrolPathsPreserved` | Patrol point positions match `EnvironmentService.lua` exactly |
| `TrainTimingPreserved` | `SubwayCycle.Period`=16, `WarningStart`=8, `ActiveStart`=12, `Damage`=25 |
| `FloodTimingPreserved` | Lab hazard cycle 18s, Active >14s, Warning 10-14s |

### 8.2 Visual Regression (screenshots)

| Capture | Camera CFrame | Acceptance |
|---|---|---|
| `lab_entrance.jpg` | EntranceSpawn looking down main corridor | Modular corridors, depth gauges, fog |
| `lab_pump_west.jpg` | Pump A room, console visible | Pump machinery, logbook, amber spot |
| `lab_containment.jpg` | Central containment ring (0,4,0) | 4 cylinders, cyan cores, catwalk grid |
| `lab_control.jpg` | Control room terminal | Server racks, central screen, sync prompt |
| `lab_catwalk.jpg` | Catwalk edge looking across basin | Grating, rails, neon edge, water caustics |
| `lab_specimen.jpg` | Specimen objective (seeded position) | Sealed canister, biohazard decal, frost |
| `subway_north_platform.jpg` | EntranceSpawn looking south | Platform tile, tactile strip, posters, benches |
| `subway_track.jpg` | Track bed from crossing | Rails, ballast, signal lamps, tunnel arch |
| `subway_signal_box.jpg` | South signal box interior | Relay rack, empty slot, log decal |
| `subway_train.jpg` | Train car at platform (Warning phase) | Headlight sweep, marker lights, interior |
| `subway_relay_case.jpg` | Relay case objective (seeded) | Shielded case, stencil, proximity prompt |
| `subway_elevator_bridge.jpg` | Bridge to return elevator | Dark tunnel mouth, emergency strips |

All captures: `screen_capture` from final Studio Play session, real HUD, `V6 / VISUAL DEVELOPMENT` footer.

### 8.3 Gameplay Regression

- Run `GameplayRecoverySpec` on both floors (live navigation, objectives, extraction, patrol)
- Run `TrainHazardSpec` on Subway (warning, pass, platform, above-track cases)
- Three-cycle live expedition test per floor (board → floor → return)
- Verify indicator state machine unchanged (OPEN/TRAVEL/CLOSED colors, generation guard)
- Verify ProfileService session-only behavior (unpublished Studio)

---

## 9. Implementation Sequence

| Phase | Tasks | Est. Time |
|---|---|---|
| **0. Asset Prep** | Download Poly Haven maps, author Blender kits, export GLBs, import to Studio, record IDs | 1-2 days |
| **1. MaterialVariants** | Add 4 new variants to `ArtTheme.Pbr` + `default.project.json`, rebuild, verify | 0.5 day |
| **2. Lab Geometry** | Replace `BuildLaboratory()` Part calls with `Environment.Mesh()` clones, preserve all markers/hazards | 1-2 days |
| **3. Subway Geometry** | Replace `BuildSubway()` Part calls with `Environment.Mesh()` clones, preserve train movement/markers | 1-2 days |
| **4. Lighting/Atmosphere** | Implement fog, light grids, volumetric beams, particle emitters, sound zones per floor | 1 day |
| **5. Story Props** | Place decals, SurfaceGuis, custom objective meshes, scatter props per story beats | 0.5-1 day |
| **6. QA Harness Extension** | Add 20 new automated checks to `runtime_harness.server.lua` | 0.5 day |
| **7. Acceptance Run** | Rebuild, Studio Play, run full automated + visual + gameplay regression, capture screenshots | 0.5 day |
| **8. Commit/Push** | Stage source, rebuilt place, prefabs, QA evidence, commit `v6-visual-development` | 0.5 day |

**Total estimate:** 6-10 days

---

## 10. Constraints & Guardrails

- **No gameplay changes:** `ObjectiveRoom.lua`, `FloorService.lua`, `SubwayCycle.lua`, `FloorConfig.lua` — read-only except for visual-only additions (decals, particles, sounds).
- **No ProfileService changes:** Session-only fallback remains; published DataStore behavior unchanged.
- **Build identifier:** `BUILD = "V6 / VISUAL DEVELOPMENT"` stays in `FloorService.lua`.
- **Branch hygiene:** All work on `v6-visual-development`; `v5-development` and `master` untouched.
- **No publish:** Acceptance is local Studio only. Cross-experience asset permissions verified separately.
- **Prefab source of truth:** `tools/build-prefabs.mjs` generates `assets/prefabs/*.rbxmx` → `rojo build` → `LAST_STOP.rbxlx`. Never hand-edit the `.rbxlx`.
- **Untracked scratch preserved:** `.agents/`, `.headroom/`, `qa/v6/backup-*`, `scripts/`, `tools/debug*.cjs`, `tools/inspect-*.cjs`, `tools/patch-dump.cjs` remain untracked.

---

## 11. Next Immediate Steps

1. **Create asset acquisition list** with exact Poly Haven URLs and target MaterialVariant names.
2. **Author Blender modular kits** for Lab and Subway (separate `.blend` files in `assets/blender/`).
3. **Import first batch** (CorrodedSteel, FloodedConcrete maps) → create MaterialVariants → test in Studio.
4. **Replace one Lab module** (e.g., `lab_corridor_straight`) as proof-of-concept, verify marker alignment.
5. **Scale to full floors** once POC validates triangle budget, lighting, and marker preservation.

---

*Prepared 2026-11-05. This plan is the single source of truth for the Laboratory/Subway visual phase. All implementation decisions reference this document.*