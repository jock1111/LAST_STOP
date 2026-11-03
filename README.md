# LAST STOP — Milestone A Vertical Slice

This is a native Roblox Studio/Rojo project containing the first playable LAST STOP slice. Runtime geometry is source-controlled; the first visual-overhaul pass adds a detailed station concourse and elevator without unreviewed free models or third-party scripts.

## What is built

- A charcoal/cyan/red subway lobby, illuminated queue terminal, central elevator, working doors, and a floor display.
- Server-local matchmaking for one to twelve players, including solo starts and safe lobby waiting for late joiners.
- A server-authoritative state machine: `Boarding → Travel → Floor → Escape → Decision → Results`.
- Three deterministic, weighted room types without recent repeats: Medical Records, Flooded Laboratory, and Security Lockdown. Each uses working proximity-validated objective stations.
- One Stalker enemy using a server-side Patrol/Chase/Attack finite state machine with pathfinding, line-of-sight checks, and non-instant damage.
- The complete reward loop: each successful floor grants at-risk coins; each survivor independently chooses BANK or CONTINUE; BANK saves only that player’s coins and returns them safely to the lobby; death, disconnect, timeout, or missed elevator loses only at-risk coins.
- Persistent profile skeleton using `DataStoreService` with schema normalization, `UpdateAsync`, periodic saves, and shutdown saves. A failed datastore read starts a session-only fallback rather than trusting the client.
- Functional flashlight and server-validated, limited medkit; responsive mouse/touch/gamepad-capable HUD; short skippable first-session tutorial.
- Server-side remote schemas, rate limits, state checks, distance checks, and currency/objective ownership.

## Explorer hierarchy

```text
ReplicatedStorage
  Shared
    Config
      EconomyConfig
      FloorConfig
      GameConfig
      RemoteNames
    Util
      Maid
      RateLimiter
  Remotes                         (created by Bootstrap at runtime)
    RequestQueue
    RequestInteract               (reserved; current objectives use secure ProximityPrompts)
    RequestDecision
    RequestMedkit
    StateChanged
    Toast
ServerScriptService
  Bootstrap                       [Script]
  TestRunner                      [Script, Studio only]
  Services
    EconomyService
    EnemyService
    ExpeditionService
    FloorService
    InventoryService
    MatchmakingService
    ProfileService
  Tests
    VerticalSliceSpec
StarterPlayer
  StarterPlayerScripts
    ClientBootstrap               [LocalScript]
    Controllers
      HUDController
      InputController
Workspace                         (created at runtime)
  LastStopWorld
    Lobby
    ActiveExpedition
```

## Install and run

1. Install the Roblox Studio Rojo plugin and a compatible Rojo CLI.
2. In this folder, run `rojo serve default.project.json` and connect the Studio plugin to the displayed endpoint. Sync into a new Baseplate place.
3. Build a reproducible place with `rojo build default.project.json --output LAST_STOP_visual_m1_final.rbxlx`, open that file in Studio, and press Play. `Bootstrap` creates the world, remotes, HUD, and playable runtime geometry.
4. For manual placement instead of Rojo, recreate the hierarchy above and insert each matching `.lua` file as the indicated Script, LocalScript, or ModuleScript. Files ending `.server.lua` become Scripts; `.client.lua` becomes a LocalScript; all others are ModuleScripts.
5. To test persistent saves, publish to a private test experience and intentionally enable Studio API Services in Game Settings → Security. This project uses `LastStopProfile_v1`; use a separate test universe if real player data matters.

Studio was used for a solo smoke test on 2026-11-02: the project launched and reached Lobby → Travel → Floor. See `VISUAL_CHANGELOG.md` for scope and remaining verification.

## Visual-overhaul asset status

The project includes six locally stored CC0 Poly Haven material maps under `assets/polyhaven/`. They are **not uploaded or applied in Roblox Studio yet**, so the PBR portion of the visual overhaul is incomplete. Sources, licenses, filenames, and the required verification procedure are in `ART_ASSETS.md`; do not add unverified asset IDs.

## Core design decisions

`ExpeditionService` is the authority for every gameplay transition and reward. `HUDController` only renders snapshots it receives; it cannot award coins, complete objectives, damage enemies, or decide whether a player reached the elevator. `FloorService` exposes the requested reusable lifecycle: `Initialize(context)`, `Start()`, `ObjectiveProgress()`, `Complete()`, `Fail()`, and `Cleanup()`.

The current queue is deliberately server-local. It satisfies solo play and a 1–12 player vertical-slice run without marooning late joiners, but global queues, party invites, and private reservation are deferred to the core-launch matchmaking service.

## Milestone A checklist

| Feature | Implemented | Tested here | Status |
| --- | --- | --- | --- |
| Runtime lobby/elevator/queue terminal | Yes | No Studio runtime | Pending Studio test |
| 1–12 server-local queue | Yes | No Studio runtime | Pending Studio test |
| Three working objective floors | Yes | No Studio runtime | Pending Studio test |
| Stalker AI, pathfinding, non-instant hits | Yes | No Studio runtime | Pending Studio test |
| Objective/escape/bank/continue loop | Yes | No Studio runtime | Pending Studio test |
| Individual BANK outcomes | Yes | No Studio runtime | Pending Studio test |
| Profile persistence/fallback | Yes | No live DataStore | Pending published-place test |
| Basic HUD/tutorial/flashlight/medkit | Yes | No device matrix | Pending device tests |
| Pure reward/rate-limit automated smoke tests | Yes | Not executable without Studio | Pending Studio Play test |
| Cross-server parties/private matchmaking | No | — | Blocked until Milestone B |
| Revives/spectator/equipment beyond starter kit | No | — | Milestone B |
| Store, passes, developer products, receipts | No | — | Milestone C |

## Known limitations and next milestone

This is explicitly a vertical slice, not the full 20-floor launch. It does not yet have the other four enemy archetypes, all seven equipment items, party invitations, global matchmaking, missions, accessibility settings, localization tables, audio assets, purchases, or production analytics. The expected next step is Milestone B: extract each generated room into a reusable template module, add floors 4–10, implement the remaining enemy/equipment systems, parties, five safe random events, spectator mode, and device accessibility verification.

See [TEST_PLAN.md](TEST_PLAN.md) for reproducible Studio verification steps and [CONTENT_NOTES.md](CONTENT_NOTES.md) for the Milestone A publication-safe copy/concepts.
