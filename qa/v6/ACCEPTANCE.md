# LAST STOP V6 acceptance — 2026-11-05

Branch: `v6-visual-development`. Build label: **V6 / VISUAL DEVELOPMENT**.

Canonical artifact: **LAST_STOP.rbxlx**. SHA-256: `a9a4b6ee6138cceb827999cf13c8f323a24e8d96b1ce00aa3b9a706c1a2b1fe4`. Size: 2,985,421 bytes.

Offline build audit: **PASS**. 41 scripts, 61 bones, 2,001 prefab instances (Lobby 557, Elevator 131, Hospital 951, Stalker 40, Environment 37, StalkerSkin 285). `node tools/verify-build.mjs` confirms the saved place contains the current source, prefab, MaterialVariant and PBR definitions.

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

All Laboratory screenshots were captured from **inside the room** with the camera positioned below the ceiling (Y=16) and above the floor. The camera was locked via `RunService.RenderStepped` to prevent the game's camera system from overriding the position.

| Capture | View | File Size |
| --- | --- | --- |
| [lab-containment-inside.jpg](screenshots/lab-containment-inside.jpg) | Containment ring from `(0,6,720)` toward `(0,3,673)`; four cylinders, cyan cores, specimen tags. | 422 KB |
| [lab-catwalk-inside.jpg](screenshots/lab-catwalk-inside.jpg) | Catwalk edge from `(-6,4,700)` toward `(0,-1,700)`; grating, rails, neon edge, water caustics. | 509 KB |
| [lab-control-inside.jpg](screenshots/lab-control-inside.jpg) | Control room from `(0,5,655)` toward `(0,2,655)`; central terminal, computers, pressure doors. | 185 KB |
| [lab-entrance-inside.jpg](screenshots/lab-entrance-inside.jpg) | Entrance from `(0,6,745)` toward `(0,3,700)`; pressure doors, depth gauges, catwalk grid. | 472 KB |
| [lab-pump-inside.jpg](screenshots/lab-pump-inside.jpg) | West pump room from `(-37,4,730)` toward `(-37,2,738)`; pump machinery, crates, steam vents. | 228 KB |

### Subway captures

All Subway screenshots were captured from **inside the room** with the camera positioned below the ceiling (Y=13) and above the floor. The camera was locked via `RunService.RenderStepped` to prevent the game's camera system from overriding the position.

| Capture | View | File Size |
| --- | --- | --- |
| [subway-platform-proper.jpg](screenshots/subway-platform-proper.jpg) | North platform from `(-22,5,750)` toward `(-22,2,700)`; platform tile, tactile strip, posters, benches. | 407 KB |
| [subway-track-proper.jpg](screenshots/subway-track-proper.jpg) | Track bed from `(0,2,-30)` toward `(0,2,-60)`; rails, ballast, signal lamps, tunnel arch. | 425 KB |
| [subway-signal-proper.jpg](screenshots/subway-signal-proper.jpg) | Signal box from `(24,4,45)` toward `(24,2,40)`; relay rack, indicator lamps. | 342 KB |
| [subway-bridge-proper.jpg](screenshots/subway-bridge-proper.jpg) | Elevator bridge from `(0,4,750)` toward `(0,2,762)`; dark tunnel mouth, emergency strips. | 273 KB |
| [subway-wide-proper.jpg](screenshots/subway-wide-proper.jpg) | Wide view from `(0,8,720)` toward `(0,2,650)`; both platforms, track, tunnel arch. | 280 KB |

**Note:** The train is parked outside the room bounds (Z=-200 when not active) and moves only during the Active hazard phase. A dedicated train screenshot was not captured because the train is not visible from inside the room during Safe/Warning phases. The train's headlight and marker lights are visible during the Active phase when it passes through the track bed.

Before/after diagnostic frames are retained in `screenshots/` for the curtain, blanket, bed frame, station-sign occlusion and discharge-sign fixes. They are diagnostic evidence, not the canonical acceptance set.

## Limitations

- **Two-client gameplay is not verified on this build.** The Studio MCP exposes only solo `start_stop_play` (`is_start`); `TwoPlayerRecoverySpec` requires exactly two local clients. The prior V3 two-client result is archived evidence and is not a V6 build result. The single-client three-cycle test and the two regression specs are the V6 gameplay evidence.
- **Persistence is not verified.** The unpublished Studio place uses the expected session-only ProfileService fallback. Published DataStore behavior remains a separate acceptance step.
- **Hardware coverage is desktop Studio only.** Reduced graphics, mobile and 12-player load are not verified.
- **Published material permissions are not re-verified.** PBR variants render in local Studio; cross-experience asset permissions and published ownership remain separate checks.
- **The Stalker is still an articulated part rig**, not a skinned mesh or uploaded animation clip.
- **The privacy curtains read as frosted isolation panels** rather than soft cloth. This is the chosen containment-ward art direction after the `Fabric` weave proved unreadable at panel scale.
- **The Laboratory and Subway use existing mesh assets** (`floor-panel`, `wall`, `wall-window`, `wall-corner`, `rail`, `pipe`, `pipe-bend`, `container`, `container-tall`, `computer-system`, `computer-wide`, `door-double`, `stairs-ramp`) rather than newly authored Blender modules. The visual quality is improved through PBR materials, lighting, particles, and storytelling, but the geometry is still composed of the existing mesh library.
- **Visual verification was performed with camera locked inside the room.** The game's camera system (`HUDController`) overrides camera position when the player is in Floor state. Screenshots were captured by setting `camera.CameraType = Scriptable` and locking the CFrame via `RunService.RenderStepped` for 2-3 seconds. This ensures the camera stays inside the room below the ceiling and above the floor.
- **The train is not visible in static screenshots.** The train is parked at Z=-200 (outside room bounds) during Safe/Warning phases and only enters the room during the Active hazard phase. A dedicated train screenshot would require capturing during the Active phase when the train is passing through the track bed.

No publish was performed. `v5-development` and `master` were not modified.

## Reproduction

```powershell
node tools/build-prefabs.mjs
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

Then open `LAST_STOP.rbxlx` in Studio, insert `qa/v6/runtime_harness.server.lua` as `ServerScriptService.QA_V6_Harness` (or `runtime_harness_lab.server.lua` / `runtime_harness_subway.server.lua` for floor-specific runs), start Play, and run the client helpers in `qa/v6/` (`run_regressions.lua`, `repeat_cycles.lua`, `return_to_lobby.lua`, `finish_harness.lua`).
