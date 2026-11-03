# LAST STOP — V4 Containment

A cooperative Roblox horror expedition with a persistent transit hub, an industrial hospital and a flooded laboratory. Open **LAST_STOP.rbxlx** in Roblox Studio and press Play. The build marker is **V4 CONTAINMENT**.

## Play

Board the elevator from the concourse terminal or the **BOARD EXPEDITION** button. Complete five milestones, return to the elevator during extraction, then independently choose **BANK** or **CONTINUE**.

- **Saint Orin Hospital** has a recoverable power cell, installation, paired containment controls, an archive case and return delivery. Alarmed corridor discharge forces detours through the wards.
- **Pelagic Laboratory** has seed-ordered pumps, paired controls, a sealed specimen and return delivery. Raised catwalks protect players from periodic electrical floodwater hazards.
- Controls require two distinct operators while teammates are active. Solo players receive a longer synchronization window. Dropped/dead/disconnected carriers reopen the pickup.
- The Stalker patrols, investigates sprint noise, pursues visible players and searches their last known position. Its attack has a visible windup and rechecks range and sight before damage.
- PC uses WASD, Shift to sprint, E to hold interactions and H for a medkit. Gamepad and touch prompts, a RUN touch button and a medkit button are included.

The interface shows the current objective, milestone progress, carrying status, vitals, stamina, secured coins, at-risk coins and hazard warnings.

## Build

Requires Node.js and Rojo.

```powershell
node tools/build-prefabs.mjs
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

The authoring script regenerates the four original editable base prefabs. The imported environment and skinned creature prefabs are preserved under assets/prefabs/. Rojo assembles all source, prefabs and saved PBR material definitions into the canonical place.

For live sync, run `rojo serve default.project.json` and sync the whole project with the official Studio Rojo plugin. Close an old in-memory copy before opening a rebuilt file.

## Art and sound

The environments combine imported Kenney CC0 meshes with the existing authored architecture and uploaded Poly Haven PBR maps. The creature uses a CC0 skinned model, retargeted Idle/Walk/Run clips and uploaded color/normal/roughness maps. Six original synthesized audio tracks provide transit, laboratory, creature and objective sound.

Asset provenance, IDs and reproduction tools are recorded in [ART_ASSETS_V4.md](ART_ASSETS_V4.md). Studio evidence and acceptance scope are in [qa/v4/ACCEPTANCE.md](qa/v4/ACCEPTANCE.md).

## Multiplayer and persistence

The server owns expedition membership, objective ordering, hold duration, distance, line of sight, enemy targeting, damage, extraction, sprint stamina and rewards. Clients request actions and display replicated state. BANK/CONTINUE remains independent per survivor. Late joins wait in the lobby. Existing profile schema, UpdateAsync saving and session-only fallback are preserved.

Studio automatically runs the pure-logic/security and prefab lifecycle tests. For the isolated integration test, start exactly two local clients, select the **server** Command Bar and run with Ctrl+Enter.

```lua
require(game.ServerScriptService.Tests.TwoPlayerRecoverySpec)()
```

Restart the test session afterward. It uses disposable in-memory profiles and isolated floor geometry.

## Delivery scope

The place is built for local Studio play. Publishing to Roblox and verifying the uploaded asset permissions in the intended published experience are separate from the GitHub delivery. Live DataStore round trips, physical mobile devices and twelve-client performance have not been verified. Capture conditions and any emulator results are recorded in the acceptance report.
