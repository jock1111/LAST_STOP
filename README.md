# LAST STOP — Recovery V3

Open **LAST_STOP.rbxlx** in Roblox Studio and start Play. The bottom-left label must read **RECOVERY V3 / AUTHORED HOSPITAL**. This is the single current runnable place. Local files named visual_m1 or RECOVERY_V3_QA/FINAL/TESTED are obsolete development snapshots; do not launch them. Earlier builds remain in Git history.

This slice contains an authored subway concourse, working elevator, hospital with three medical records, and an original articulated Stalker. The live pool deliberately contains only the hospital. Models use editable Roblox parts, joints, signage, and imported PBR materials. The Stalker is a Motor6D rig with procedural animation; it is not a skinned external mesh or a borrowed Toolbox asset.

## Build and sync

The source of truth is src/, assets/prefabs/, tools/build-prefabs.mjs, and default.project.json. The place is generated. With Node.js and Rojo installed:

```powershell
node tools/build-prefabs.mjs
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

The deterministic authoring script writes four script-free editable .rbxmx models. For live sync, run `rojo serve default.project.json`, connect the official Rojo Studio plugin, and sync the **whole project**, including ServerStorage and MaterialService. Use a separate development place if the current Studio place contains unrelated work. Incorporate model edits into the authoring source; manual edits to generated prefabs are overwritten at rebuild.

Close an already-open old copy before reopening a rebuilt file. Studio retains an in-memory snapshot; Git pull and disk rebuild do not refresh it. To update a published game, open this file, verify the build label, and publish to the intended existing experience/place. GitHub pushes do not publish Roblox.

## Startup and permanent assets

```text
ServerStorage.LastStopAssets
  Lobby
  Elevator
  Stalker
  Floors.Hospital
MaterialService
  ChippedConcrete
  PaintedSteel
  MetalPlate
Workspace.LastStopWorld
  Runtime
    Lobby.CentralElevator
    ActiveExpedition.Hospital
```

Bootstrap creates services/remotes and calls FloorService:BuildWorld(), cloning Lobby and Elevator. ExpeditionService:_beginNextFloor() creates a room; Room:Start() clones Hospital and connects named record props to secure objective logic. Missing templates/markers fail with actionable errors. BuildWorld replaces only Runtime; source templates and unrelated siblings survive. PBR definitions are saved in the place because their properties require Studio/plugin capability; runtime only assigns existing variants.

The server owns queue membership, active-player checks, objective distance/line-of-sight/idempotency, targeting/damage, escape regions, and rewards. Survivors independently BANK or CONTINUE. Late joins wait in the lobby. Profiles use UpdateAsync and session-only fallback when an unpublished place has no DataStore access.

## Validation

See [qa/ACCEPTANCE.md](qa/ACCEPTANCE.md), [ART_ASSETS.md](ART_ASSETS.md), and [VISUAL_CHANGELOG.md](VISUAL_CHANGELOG.md) for evidence and limitations.

Studio Play automatically runs pure logic/security and prefab lifecycle tests. For the two-player integration test, start **Test → Start Test Session → Server and Clients**, add exactly two clients, and execute in the **server** Command Bar with Ctrl+Enter:

```lua
require(game.ServerScriptService.Tests.TwoPlayerRecoverySpec)()
```

Use a fresh local session before entering the normal queue. Restart Play after this test: its fixture deliberately replaces the runtime world and then tears down its own expedition. This test uses real local Players and gameplay services, shortened phase timings, and disposable in-memory profiles. It checks navigation paths, physical Stalker movement, 15-point windup damage, records/duplicate rejection, escape regions, independent BANK/CONTINUE, accounting, two floor clones, and teardown. It teleports players for interaction assertions; it is not a fully manual controller playthrough and does not test live persistent balances.

Persistent-save acceptance requires a separate private test universe with Studio API Services intentionally enabled. Live saves, published-experience texture permissions, reduced-quality mobile hardware, and 12-client performance remain unverified.
