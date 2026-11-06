# LAST STOP V6 acceptance — 2026-11-05

Branch: `v6-visual-development`. Build label: **V6 / VISUAL DEVELOPMENT**.

Canonical artifact: **LAST_STOP.rbxlx**. SHA-256: `7aea639c982ab8122d7dbbf7439943a1e7407d1bbe6e07183c5eaf3ddc3a3fdd`. Size: 2,962,931 bytes.

Offline build audit: **PASS**. 41 scripts, 61 bones, 2,001 prefab instances (Lobby 557, Elevator 131, Hospital 951, Stalker 40, Environment 37, StalkerSkin 285). `node tools/verify-build.mjs` confirms the saved place contains the current source, prefab, MaterialVariant and PBR definitions.

## Scope

This pass is a visual-development pass over the Lobby, Elevator and Hospital. It does not rewrite gameplay, profiles, objectives, matchmaking or the Stalker AI. The build identifier, ProfileService protections and existing runtime paths are preserved.

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

## Automated Studio evidence

Raw structured result: [qa-results-final.json](qa-results-final.json). Final Output log: [studio-console-final.txt](studio-console-final.txt).

The QA harness is inserted into the live Studio place only; it is not part of the Rojo source tree. It forced the Hospital template to weight 100 **in the live session only** so the visual captures and three-cycle run all exercised the same floor. The source `FloorConfig` was not changed.

| # | Check | Result |
| --- | --- | --- |
| 1 | Runtime lobby present | PASS |
| 2 | Hospital template forced for visual run | PASS |
| 3 | Elevator display/doors/zone | PASS |
| 4 | Three indicator dots and rings | PASS |
| 5 | OPEN display text | PASS (`QA OPEN`) |
| 6 | OPEN indicator mode | PASS (`open`) |
| 7 | OPEN dot colours | PASS (`amber,dark,dark`) |
| 8 | OPEN colours are Color3 | PASS |
| 9 | OPEN doors displaced from closed | PASS (`left=9.80 right=9.80`) |
| 10 | TRAVEL display text | PASS (`QA TRAVEL`) |
| 11 | TRAVEL indicator mode | PASS (`travel`) |
| 12 | TRAVEL chase changes colours | PASS (`amber,amber,amber -> amber,cyan,amber`) |
| 13 | TRAVEL colours are Color3 | PASS |
| 14 | TRAVEL palette only amber/cyan | PASS (`amber,cyan,amber`) |
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
| 25 | No unexpected Output errors | PASS (`0 error(s)`) |

`GameplayRecoverySpec` exercised live navigation/physics routes on all authored rooms, the extraction route and a 60-second Stalker patrol. `TrainHazardSpec` exercised the warning, pass, platform and above-track damage cases without profile writes. ProfileService session-only warnings are expected in an unpublished Studio place and are excluded from the error check.

## Live gameplay evidence

Three real matchmaking/expedition cycles ran through the client `RequestQueue` remote on the final build:

| Cycle | Before | Boarding | Floor | Floor doors | Return |
| --- | --- | --- | --- | --- | --- |
| 1 | `B0 / CONCOURSE` | `BOARD NOW`, dots `amber,dark,dark`, doors `±14.57` | `Hospital`, `DESCENDING`, chase dots | `±4.78` | `LAST STOP`, dots `amber,dark,dark`, doors `±14.58` |
| 2 | `LAST STOP` | `BOARD NOW`, dots `amber,dark,dark`, doors `±14.58` | `Hospital`, `DESCENDING`, chase dots | `±4.78` | `LAST STOP`, dots `amber,dark,dark`, doors `±14.58` |
| 3 | `LAST STOP` | `BOARD NOW`, dots `amber,dark,dark`, doors `±14.58` | `Hospital`, `DESCENDING`, chase dots | `±4.78` | left on floor for screenshots |

The Hospital spawn was `pivot (0, 0, 700)` and the player arrived at approximately `(-4.5, 3.0–4.0, 725)`. The door values are world-space X positions; `±14.58` is fully open and `±4.78` is the closed center gap. The chase samples show all amber/cyan permutations while `DESCENDING`, then the idle state returns to `amber,dark,dark`.

## Visual evidence

All images are direct `screen_capture` JPEGs from the final Studio Play session. They include the real HUD and `V6 / VISUAL DEVELOPMENT` footer. Client camera CFrames were used only for framing; no asset, pose or UI text was replaced.

| Capture | View |
| --- | --- |
| [lobby-accept.jpg](screenshots/lobby-accept.jpg) | Lobby from `(22,10,26)` toward `(-4,4,-14)`; elevator display and station sign visible. |
| [elevator-open-accept.jpg](screenshots/elevator-open-accept.jpg) | Open elevator from `(0,9,-2)` toward `(0,9,-16.45)`; `LAST STOP` and amber/dark dot row visible. |
| [elevator-display-accept.jpg](screenshots/elevator-display-accept.jpg) | Close display view from `(0,11,-5)` toward `(0,14.6,-15.44)`. |
| [elevator-indicators-accept.jpg](screenshots/elevator-indicators-accept.jpg) | Close dot/ring view from `(0,10,-6)` toward `(0,14.5,-15.4)`. |
| [hospital-ward-accept.jpg](screenshots/hospital-ward-accept.jpg) | Patient ward from `(-8,6.5,690)` toward `(-24,3,701)`; frosted curtains, clean beds, monitors. |
| [hospital-ward-west-accept.jpg](screenshots/hospital-ward-west-accept.jpg) | Ward lengthwise from `(-33,7,700)` toward `(-13,4,697)`; central ward and corridor connection. |
| [hospital-corridor-accept.jpg](screenshots/hospital-corridor-accept.jpg) | Central corridor from `(0,7,724)` toward `(0,4,668)`; wayfinding, hazard lane, Stalker. |
| [hospital-foyer-accept.jpg](screenshots/hospital-foyer-accept.jpg) | Arrival foyer from `(8,7,739)` toward `(-2,4,727)`; desk, player, Stalker. |
| [hospital-elevator-closed-accept.jpg](screenshots/hospital-elevator-closed-accept.jpg) | Closed return elevator from `(0,5,735)` toward `(0,5,743)`; call panel. |
| [hospital-discharge-sign-accept.jpg](screenshots/hospital-discharge-sign-accept.jpg) | East corridor wall from `(-2,5.5,692)` toward `(6.55,5.5,692)`; discharge warning clear of overhead signs. |

Before/after diagnostic frames are retained in `screenshots/` for the curtain, blanket, bed frame, station-sign occlusion and discharge-sign fixes. They are diagnostic evidence, not the canonical acceptance set.

## Limitations

- **Two-client gameplay is not verified on this build.** The Studio MCP exposes only solo `start_stop_play` (`is_start`); `TwoPlayerRecoverySpec` requires exactly two local clients. The prior V3 two-client result is archived evidence and is not a V6 build result. The single-client three-cycle test and the two regression specs are the V6 gameplay evidence.
- **Persistence is not verified.** The unpublished Studio place uses the expected session-only ProfileService fallback. Published DataStore behavior remains a separate acceptance step.
- **Hardware coverage is desktop Studio only.** Reduced graphics, mobile and 12-player load are not verified.
- **Published material permissions are not re-verified.** PBR variants render in local Studio; cross-experience asset permissions and published ownership remain separate checks.
- **The Stalker is still an articulated part rig**, not a skinned mesh or uploaded animation clip.
- **The privacy curtains read as frosted isolation panels** rather than soft cloth. This is the chosen containment-ward art direction after the `Fabric` weave proved unreadable at panel scale.

No publish was performed. `v5-development` and `master` were not modified.

## Reproduction

```powershell
node tools/build-prefabs.mjs
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

Then open `LAST_STOP.rbxlx` in Studio, insert `qa/v6/runtime_harness.server.lua` as `ServerScriptService.QA_V6_Harness`, start Play, and run the client helpers in `qa/v6/` (`run_regressions.lua`, `repeat_cycles.lua`, `return_to_lobby.lua`, `finish_harness.lua`).
