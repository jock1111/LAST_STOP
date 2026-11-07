# LAST STOP V6 acceptance — 2026-11-05

Branch: `v6-visual-development`. Build label: **V6 / VISUAL DEVELOPMENT**.

Canonical artifact: **LAST_STOP.rbxlx**. SHA-256: `b7ada2dddc1789e50cbc69c4c3f8cbe69cd4cca452ae68a22c1a2fc4b0cfffdd`. Size: 3,061,767 bytes.

Offline build audit: **PASS**. 41 scripts, 61 bones, 2,017 prefab instances (Lobby 557, Elevator 131, Hospital 951, Stalker 40, Environment 53, StalkerSkin 285). `node tools/verify-build.mjs` confirms the saved place contains the current source, prefab, MaterialVariant and PBR definitions.

## Milestone 2 — generated meshes, normal camera, active-train capture (2026-11-05)

### New generated mesh assets

Eight meshes were generated in Studio (`generate_mesh`) and committed to `assets/prefabs/Environment.rbxmx` via `tools/add-generated-meshes.mjs` (idempotent; each is a `<name>_Node` Model wrapping one MeshPart, matching the Kenney import layout):

| Mesh | Used for |
| --- | --- |
| `containment-vessel` | Laboratory containment cells (replaces box frame + glass cylinder) |
| `specimen-canister` | 24 staged canisters on catwalks + plinth clusters |
| `pump-machine` | West/east pump objectives at `(±37, 3, 38)` |
| `research-console` | Control room consoles (replaces `computer-wide` hero pieces) |
| `subway-train-car` | The hazard train (replaces box car, windows and bogies) |
| `station-bench` | Platform benches (replaces slab benches) |
| `signal-post` | Six signal posts at platform ends and the crossing |
| `subway-track-section` | Available in the library (trackwork is procedural rails/sleepers/ballast) |

`Environment.Mesh()` now scans library descendants for a MeshPart by name so both the `_Node`-wrapped Kenney assets and the generated models resolve.

### Laboratory upgrades

- Containment cells are corroded pressure vessels with glowing cores rising out of the floodwater.
- Flood water has a dark under-layer (`FloodWaterDeep`) for real depth plus translucent `LightShaft` volumes.
- Handrails on the central catwalk; support columns and pipe collars rise from the basin floor.
- Steam vents, bioluminescent motes, drips, edge lights retained; pump status lamps added.

### Subway upgrades

- Real trackwork: gravel ballast, two running rails and 27 concrete sleepers on the track bed.
- The hazard train is the generated `subway-train-car` mesh (non-uniform Z stretch to ~44 studs) with roof pods, headlight spot and marker lights; `TrainHazardSpec` still passes.
- Platform screen walls (`wall` mesh, `ChippedConcrete`), ceiling beams, lamp cages, wall-wash strips, signal posts and station benches.
- Containers moved from `x=±16` to `x=±27` against the tunnel walls; lockers re-spaced to clear them.

### Normal player camera

Root cause of the black normal-camera view: after expedition/respawn transitions `camera.CameraSubject` could reference a stale humanoid, parking `camera.Focus` under the floor. `HUDController:EnsureGameplayCamera()` now re-seats the live humanoid on Floor/Escape/Decision/Boarding/Travel snapshots whenever the focus is implausibly far from the head. Verified in Play on both floors: `CameraType.Custom`, subject = live humanoid, focus at head height, no obstruction — no Scriptable override or QA camera lock.

### Evidence this milestone

- Build: `node tools/verify-build.mjs` PASS (SHA above).
- Regressions in Play: `GameplayRecoverySpec` PASS, `TrainHazardSpec` PASS (via `QA_V6_Control` "regressions").
- Live mesh census: Laboratory spawned 4 `containment-vessel`, 3 `research-console`, 24 `specimen-canister`, 2 `pump-machine`; Subway spawned 1 `subway-train-car`, 6 `station-bench`, 6 `signal-post`.
- Screenshots (player-height and composed): `screenshots/lab-v6-normal.jpg`, `lab-v6-meshes.jpg`, `lab-v6-containment.jpg`, `lab-v6-pumps.jpg`, `lab-v6-catwalk.jpg`, `subway-v6-normal.jpg`, `subway-v6-platform.jpg`, `subway-v6-track.jpg`, `subway-v6-train-active.jpg`, `subway-v6-train-active2.jpg` (the last two captured while `HazardPhase == "Active"`, `TrainZ ≈ 110`).

Note: `execute_luau` runs in a separate VM with its own `require` cache, so runtime weight overrides must be applied inside the server VM (the QA harness was patched in-place for the Subway run); the shipped `FloorConfig` is unchanged.

## Milestone 3 — final quality and gameplay validation (2026-11-05)

### Defect fixes

- **Signal lamps**: the three `SignalLamp` parts were all spawned at `CFrame.new(24, 6, 38)` — identical position. They are now `SignalLamp1/2/3` spaced 1.4 studs apart across the signal-box face (`x = 22.6 / 24.0 / 25.4`, `y = 5.6`, `z = 37.9`) in red / amber / green order.
- **Train ends**: the generated `subway-train-car` mesh can present open/notched end faces. Both ends now carry a procedural fascia — proud cab-face panel, windshield/glass band and destination blind — so the consist reads as a closed railcar from every angle. The headlight SpotLight was also moved to the **leading (+Z) end** and aimed down the track; previously it sat on the trailing end. Red marker light is on the rear, white on the front.

### Train during Active hazard phase

Captured while `HazardPhase == "Active"` with the train genuinely pivoting (`TrainZ` swept −86 → +130 local, ~54 studs/s):

- `screenshots/subway-v6-train-side.jpg` — side/three-quarter from the west platform at `trainZ ≈ 0` (world z ≈ 700).
- `screenshots/subway-v6-train-front34.jpg` — front three-quarter at `trainZ ≈ −74` (world z ≈ 626), close to the leading fascia/headlight.
- `screenshots/subway-v6-train-rear34.jpg` — rear quarter at `trainZ ≈ −60`.
- `screenshots/subway-v6-train-active.jpg` / `subway-v6-train-active2.jpg` — earlier Active-phase frames.

### Normal camera across transitions

Verified without Scriptable overrides on both floors:

| Transition | Result |
| --- | --- |
| Expedition spawn → Floor (Lab & Subway) | `CameraType.Custom`, live humanoid subject, focus at head height, no obstruction |
| Death → Results/LOST → lobby | `FrameLobby` Scriptable concourse shot (intended) |
| Re-queue → Floor (2nd expedition) | Custom restored |
| Decision / Escape / Travel state payloads | Custom maintained |
| Results/BANKED payload | Scriptable lobby shot (intended) |

**Tooling caveat discovered**: every `execute_luau` client call makes the Studio MCP harness reset `camera.CameraType` to `Scriptable` afterwards (console: *"The execute_luau changed camera type. Resetting…"*). A camera read as Scriptable immediately after a luau call is a QA artifact, not a game state — firing a Floor `StateChanged` restored Custom instantly. All camera verdicts above were taken on the call immediately following each transition.

### Performance (real measurements, `RunService.Heartbeat` sampling, 6 s windows)

| Floor | Quality | Avg FPS | Avg frame | p95 | p99 |
| --- | --- | --- | --- | --- | --- |
| AbandonedSubway | Automatic | 60 | 17 ms | 18–19 ms | 20 ms |
| AbandonedSubway | Level01 (reduced) | 60 | 17 ms | 18 ms | 20 ms |
| FloodedLaboratory | Automatic | 60 | 17 ms | 21 ms | 26 ms |
| FloodedLaboratory | Level01 (reduced) | 60 | 17 ms | 19 ms | 24 ms |

Both floors are vsync-bound at 60 FPS even at the lowest quality level; the Laboratory is marginally heavier (water surface, light shafts, particles) but still has ~3 ms of p99 headroom. Quality level was set via `settings().Rendering.QualityLevel` and restored to `Automatic` after each run.

### Mesh asset audit

All eight generated meshes exist in `ServerStorage.LastStopAssets.Environment` as `<name>_Node` Models wrapping a MeshPart with valid `MeshId`/`TextureID` content:

| Mesh | MeshId | Live uses (Subway run) | Live uses (Lab run, milestone 2) |
| --- | --- | --- | --- |
| `specimen-canister` | `rbxassetid://95792177258500` | 0 (lab-only) | 24 |
| `containment-vessel` | `rbxassetid://71376769722129` | 0 (lab-only) | 4 |
| `pump-machine` | `rbxassetid://87119713783145` | 0 (lab-only) | 2 |
| `research-console` | `rbxassetid://76438650829671` | 0 (lab-only) | 3 |
| `subway-train-car` | `rbxassetid://75278130929878` | 1 | — |
| `station-bench` | `rbxassetid://113924694873821` | 6 | — |
| `signal-post` | `rbxassetid://71593920777017` | 6 | — |
| `subway-track-section` | `rbxassetid://134933032983834` | 0 | 0 |

`subway-track-section` is **unused by design**: the 20-stud generation produced a ~1.8×2×1.1 stud mesh that would need extreme non-uniform stretching, so the track is built procedurally (ballast, twin rails, 27 sleepers) which reads better at track scale. The asset remains in the library for future use. The other lab-only meshes show 0 uses on the Subway floor simply because that floor doesn't spawn them.

Ownership: all eight were generated through Studio `generate_mesh` under the logged-in account and publish as `rbxassetid://` content; they load and render in local Play (verified by live census and screenshots). Published ownership/permissions can only be fully verified after a publish, which was not performed.

### Regression suites (this build)

`GameplayRecoverySpec` PASS, `TrainHazardSpec` PASS via `QA_V6_Control` "regressions" on the Laboratory run; `node tools/verify-build.mjs` PASS (SHA above). Studio Output shows only the three pre-existing `rbxassethash://` "Invalid place ID" warnings — identical hashes appear in the archived V5 baseline console, so they predate this work and are unrelated to the new meshes (which use `rbxassetid://`).

### Two-client multiplayer

**Not verifiable in this harness.** The Studio MCP `start_stop_play` tool only exposes solo Play (`is_start`); there is no "Start Server and Players" multi-client mode, and `TwoPlayerRecoverySpec` requires exactly two local clients. Two-player objectives, independent rewards, enemy behavior and recovery-after-death remain covered only by the spec's fixture logic and prior archived evidence — a real limitation, not a pass.

### Remaining limitations (updated)

- Two-client multiplayer unverified (see above).
- `subway-track-section` mesh unused (procedural trackwork instead).
- Train fascia is procedural dressing over the generated mesh; the mesh's own end caps may still be visible at glancing angles.
- Reduced-graphics test used `QualityLevel.Level01`; hardware/mobile coverage unchanged.
- The three `rbxassethash://` content warnings are pre-existing (V5 baseline) and unrelated to V6 assets.
- Persistence/DataStore remains session-only in unpublished Studio play.

## Scope

This pass is a visual-development pass over the Lobby, Elevator, Hospital, Flooded Laboratory, and Abandoned Subway. It does not rewrite gameplay, profiles, objectives, matchmaking or the Stalker AI. The build identifier, ProfileService protections and existing runtime paths are preserved.

### Indicator state machine

- `INDICATOR_TRAVEL_COLORS` now references a real `cyan` (`Color3.fromRGB(92, 210, 202)`); every indicator color is a valid `Color3`.
- Travel animation tasks carry a generation and re-check `_indicatorMode == TRAVEL` on every tick. A stale travel loop can no longer overwrite a newer OPEN/CLOSED state, display string or dot colors.
- Dot/ring lookups tolerate missing optional parts.
- The lobby display, three dots and three rings are driven only through the shared color table.

### Lobby and Elevator

- `MainStationSign` moved from `y=13.2` to `y=16.7`, size `26 × 2.8 × .35`. At the old position it covered the floor display at `y=14.85` and the travel dots at `y=14.02`.
- The redundant runtime `DEEP ACCESS / B0 CONCOURSE` plaque that sat behind the display bezel was removed. The boarding wayfinding below the doors is the single elevator label.
- The open-door capture now shows `LAST STOP` and the amber/dark dot row from the lobby instead of a blank sign.

### Hospital

- Privacy curtains use a frosted `SmoothPlastic` panel (`7.9 × 5.8 × .08`, transparency `.42`), five shallow pleats and a weighted hem. The previous `Fabric` weave read as moss/waterfall at panel scale.
- Bed undercarriages use plain `Metal` instead of the rusted `PaintedSteel` diamond plate.
- Blankets are matte `SmoothPlastic` with a stitched stripe; pillows are matte `SmoothPlastic` so the fabric weave no longer reads as a stone slab.
- The discharge warning moved to the east corridor wall at local `(6.55, 5.5, -8)`, yaw `90`, size `8 × 1.2 × .1`. It no longer overlaps the overhead wayfinding.
- `ChippedConcrete` is 4 studs per tile so the floor reads as a continuous poured surface rather than a coarse grid.

### Flooded Laboratory (Pelagic / FloodedLaboratory)

- Basin floor uses `FloodedConcrete` PBR (wet concrete maps, 3 studs/tile) for a darker, wetter read.
- Flood water surface uses `ContainmentGlass` tint with caustic `SurfaceLight` for godray effect.
- Walkway grating uses `floor-panel` MeshParts with `FloodedConcrete` PBR.
- Perimeter walls use `wall` / `wall-window` / `wall-corner` MeshParts with `CorrodedSteel` PBR.
- Containment cells use `container-tall` MeshParts with `CorrodedSteel` PBR, frosted glass cylinders, and specimen ID tags (`SPEC-734-PELAGIC`, `SPEC-735-PELAGIC`).
- Catwalk railings use `rail` MeshParts with `CorrodedSteel` PBR.
- Perimeter pipes use `pipe` / `pipe-bend` MeshParts with `CorrodedSteel` PBR.
- Recovery ramps use `stairs-ramp` MeshParts with `CorrodedSteel` PBR.
- Control computers use `computer-system` / `computer-wide` MeshParts with `PaintedSteel` PBR.
- Pressure doors use `door-double` MeshParts with `CorrodedSteel` PBR.
- Depth gauges on perimeter walls tell the story: `−600m` to `−672m`.
- Equipment crates use `container` MeshParts with `CorrodedSteel` PBR.
- Steam vent particle emitters on pipe junctions.
- Bioluminescent mote particles in the water volume.
- Water drip particle emitters from ceiling beams.

### Abandoned Subway (Subway / AbandonedSubway)

- Track bed uses `FloodedConcrete` PBR for a darker, wetter read.
- Platforms use `FloodedConcrete` PBR with amber edge strips (`MetalPlate` PBR).
- Tunnel walls and ceiling use `FloodedConcrete` PBR.
- Container-tall props along tunnel walls use `CorrodedSteel` PBR.
- Level crossing uses `FloodedConcrete` PBR with tactile pavers.
- Signal box uses `CorrodedSteel` PBR with cyan/green/red indicator lamps.
- Benches on both platforms use `CorrodedSteel` PBR frames with wood seats.
- Poster frames on platform walls use `MetalPlate` PBR with "SERVICE SUSPENDED" decals.
- Lockers in service areas use `CorrodedSteel` PBR.
- Trackside valves use `CorrodedSteel` PBR.
- Cable trays along tunnel ceiling use `CorrodedSteel` PBR.
- Train car uses `CorrodedSteel` PBR with glass windows, bogies, headlight spotlight, and marker lights.
- Dust motes in the tunnel air.
- Rail dust particles near the track bed.

## Automated Studio evidence

Raw structured result: [qa-results-lab-subway.json](qa-results-lab-subway.json). Final Output log: [studio-console-subway.txt](studio-console-subway.txt).

The QA harness is inserted into the live Studio place only; it is not part of the Rojo source tree. It forced the Laboratory and Subway templates to weight 100 **in the live session only** so the visual captures and regression runs all exercised the same floor. The source `FloorConfig` was not changed.

| # | Check | Result |
| --- | --- | --- |
| 1 | Runtime lobby present | PASS |
| 2 | Laboratory template forced for visual run | PASS |
| 3 | Elevator display/doors/zone | PASS |
| 4 | Three indicator dots and rings | PASS |
| 5 | OPEN display text | PASS (`QA OPEN`) |
| 6 | OPEN indicator mode | PASS (`open`) |
| 7 | OPEN dot colours | PASS (`amber,dark,dark`) |
| 8 | OPEN colours are Color3 | PASS |
| 9 | OPEN doors displaced from closed | PASS (`left=9.80 right=9.80`) |
| 10 | TRAVEL display text | PASS (`QA TRAVEL`) |
| 11 | TRAVEL indicator mode | PASS (`travel`) |
| 12 | TRAVEL chase changes colours | PASS (`amber,cyan,amber -> amber,amber,amber`) |
| 13 | TRAVEL colours are Color3 | PASS |
| 14 | TRAVEL palette only amber/cyan | PASS (`amber,amber,amber`) |
| 15 | TRAVEL doors closed | PASS (`left=0.00 right=0.00`) |
| 16 | Race A display preserved | PASS (`QA RACE OPEN`) |
| 17 | Race A mode open | PASS (`open`) |
| 18 | Race A steady colours | PASS (`amber,dark,dark`) |
| 19 | Race B display preserved | PASS (`QA RACE CLOSED B`) |
| 20 | Race B mode travel | PASS (`travel`) |
| 21 | Race B colours are Color3 | PASS |
| 22 | Lobby restored to idle | PASS (`B0 / CONCOURSE`) |
| 23 | GameplayRecoverySpec | PASS |
| 24 | TrainHazardSpec | PASS |

`GameplayRecoverySpec` exercised live navigation/physics routes on all authored rooms, the extraction route and a 60-second Stalker patrol. `TrainHazardSpec` exercised the warning, pass, platform and above-track damage cases without profile writes. ProfileService session-only warnings are expected in an unpublished Studio place and are excluded from the error check.

## Live gameplay evidence

The Laboratory and Subway floors were tested with the QA harness forcing their respective templates to weight 100. Both floors passed all 24 checks and both regression specs.

| Floor | Template | Checks | Regressions | Console Errors |
| --- | --- | --- | --- | --- |
| Laboratory | `FloodedLaboratory` | 24/24 PASS | GameplayRecoverySpec PASS, TrainHazardSpec PASS | 0 |
| Subway | `AbandonedSubway` | 24/24 PASS | GameplayRecoverySpec PASS, TrainHazardSpec PASS | 0 |

The Laboratory spawn was `pivot (0, 0, 700)` and the player arrived at approximately `(-4.5, 3.9, 740)`. The Subway spawn was `pivot (0, 0, 700)` and the player arrived at approximately `(-26.5, 2.8, 743)`.

## Visual evidence

All images are direct `screen_capture` JPEGs from the final Studio Play sessions. They include the real HUD and `V6 / VISUAL DEVELOPMENT` footer. Client camera CFrames were used only for framing; no asset, pose or UI text was replaced.

### Laboratory captures

All Laboratory screenshots were captured from **inside the room** with the camera positioned below the ceiling (Y=16) and above the floor. The camera was locked via `RunService.RenderStepped` to prevent the game's camera system from overriding the position. Each canonical frame was pixel-sampled and raycast-checked where noted.

| Capture | View | Verification | File Size |
| --- | --- | --- | --- |
| [lab-cylinder-fresh.jpg](screenshots/lab-cylinder-fresh.jpg) | Containment cell from `(0,6,700)` toward `(-25,4,673)`; glass cylinder, plinth, specimen tag. | Raycast hit `container-tall` at `(-22.2, 4.2, 676)`; 442 KB JPEG. | 442 KB |
| [lab-containment-fresh.jpg](screenshots/lab-containment-fresh.jpg) | Containment/control sightline from `(0,6,720)` toward `(0,3,673)`; cylinders, catwalk grid, central console. | Raycast hit `computer-wide` at `(0, 2.0, 657.1)`; 404 KB JPEG. | 404 KB |
| [lab-catwalk-fresh.jpg](screenshots/lab-catwalk-fresh.jpg) | Catwalk edge from `(-6,4,700)` toward `(0,-1,700)`; grating, rails, neon edge, water caustics. | Raycast hit `floor-panel` at `(-1.2, 0, 700)`; 491 KB JPEG. | 491 KB |
| [lab-control-fresh.jpg](screenshots/lab-control-fresh.jpg) | Control console from `(0,6,672)` toward `(0,2,648)`; `computer-wide`, side computers, pressure doors. | Raycast hit `computer-wide` at `(0, 3.5, 657.1)`; 312 KB JPEG. | 312 KB |
| [lab-pump-fresh.jpg](screenshots/lab-pump-fresh.jpg) | West pump room from `(-31,5,744)` toward `(-37,3,736)`; pump machinery, computer-system, crates. | Raycast hit `computer-system` at `(-36.4, 3.2, 736.8)`; 405 KB JPEG. | 405 KB |
| [lab-entrance-fresh.jpg](screenshots/lab-entrance-fresh.jpg) | Entrance/elevator wall from `(0,6,738)` toward `(0,3,758)`; doors, back wall, return zone. | Raycast hit `BackWall` at `(0, 1.0, 771.0)`; 334 KB JPEG. | 334 KB |

### Subway captures

All Subway screenshots were captured from **inside the room** with the camera positioned below the ceiling (Y=13) and above the floor. The camera was locked via `RunService.RenderStepped` to prevent the game's camera system from overriding the position. The platform frame was raycast-checked; all canonical frames were pixel-sampled.

| Capture | View | File Size |
| --- | --- | --- |
| [subway-platform-view.jpg](screenshots/subway-platform-view.jpg) | West platform from `(0,6,720)` toward `(-22,2,720)`; platform edge, containers, tactile strip. Raycast hit `container-tall` at `(-14, 3.45, 720)`. | 255 KB |
| [subway-track-view.jpg](screenshots/subway-track-view.jpg) | Track bed from `(0,3,0)` toward `(0,2,-50)`; rails, ballast, signal lamps, tunnel arch. | 440 KB |
| [subway-signal-view.jpg](screenshots/subway-signal-view.jpg) | Signal box from `(24,4,45)` toward `(24,2,40)`; relay rack, indicator lamps. | 336 KB |
| [subway-bridge-view.jpg](screenshots/subway-bridge-view.jpg) | Elevator bridge from `(0,4,750)` toward `(0,2,762)`; dark tunnel mouth, emergency strips. | 269 KB |
| [subway-wide-view.jpg](screenshots/subway-wide-view.jpg) | Wide view from `(0,10,760)` toward `(0,2,600)`; both platforms, track, tunnel arch. | 329 KB |

**Pixel verification:** luminance sampling found every canonical frame has more than 30% of sampled pixels and more than 20% of the center region above luminance 16. The Subway signal and wide frames are intentionally low-key but are not black; they still contain lit geometry and HUD. Earlier `*-inside.jpg` / `*-proper.jpg` / `*-view.jpg` diagnostic frames are retained in `screenshots/` but the tables above are the canonical acceptance set.

**Note:** The train is parked outside the room bounds (Z=-200 when not active) and moves only during the Active hazard phase. A dedicated train screenshot was not captured because the train is not visible from inside the room during Safe/Warning phases. The train's headlight and marker lights are visible during the Active phase when it passes through the track bed.

Before/after diagnostic frames are retained in `screenshots/` for the curtain, blanket, bed frame, station-sign occlusion and discharge-sign fixes. They are diagnostic evidence, not the canonical acceptance set.

## Limitations

- **Two-client gameplay is not verified on this build.** The Studio MCP exposes only solo `start_stop_play` (`is_start`); `TwoPlayerRecoverySpec` requires exactly two local clients. The prior V3 two-client result is archived evidence and is not a V6 build result. The single-client three-cycle test and the two regression specs are the V6 gameplay evidence.
- **Persistence is not verified.** The unpublished Studio place uses the expected session-only ProfileService fallback. Published DataStore behavior remains a separate acceptance step.
- **Hardware coverage is desktop Studio only.** Reduced graphics, mobile and 12-player load are not verified.
- **Published material permissions are not re-verified.** PBR variants render in local Studio; cross-experience asset permissions and published ownership remain separate checks.
- **The Stalker is still an articulated part rig**, not a skinned mesh or uploaded animation clip.
- **The privacy curtains read as frosted isolation panels** rather than soft cloth. This is the chosen containment-ward art direction after the `Fabric` weave proved unreadable at panel scale.
- **The Laboratory and Subway now combine generated meshes with the existing Kenney library.** Eight Studio-generated assets (`containment-vessel`, `specimen-canister`, `pump-machine`, `research-console`, `subway-train-car`, `station-bench`, `signal-post`, `subway-track-section`) were added to `Environment.rbxmx`; trackwork, water, catwalks and lighting remain procedural/PBR dressing.
- **Normal-camera verification is live on both floors** (`CameraType.Custom`, live humanoid subject, head-height focus). Composed `screen_capture` frames with explicit `camera_position`/`look_at_position` were used for milestone-2 detail shots; the canonical player view itself was verified without any camera override.
- **The train was captured during `HazardPhase == "Active"`** (`subway-v6-train-active*.jpg`, `TrainZ ≈ 110` local). It remains parked at Z=-200 during Safe/Warning by design.

No publish was performed. `v5-development` and `master` were not modified.

## Reproduction

```powershell
node tools/build-prefabs.mjs
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

Then open `LAST_STOP.rbxlx` in Studio, insert `qa/v6/runtime_harness.server.lua` as `ServerScriptService.QA_V6_Harness` (or `runtime_harness_lab.server.lua` / `runtime_harness_subway.server.lua` for floor-specific runs), start Play, and run the client helpers in `qa/v6/` (`run_regressions.lua`, `repeat_cycles.lua`, `return_to_lobby.lua`, `finish_harness.lua`).
