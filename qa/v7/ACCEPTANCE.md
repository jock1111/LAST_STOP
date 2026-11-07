# LAST STOP V7 — First Session Experience acceptance

Branch: `v7-first-session-development`. Base: V6 commit `e8daad4` (verified stable baseline).
Canonical artifact: `LAST_STOP.rbxlx`. SHA-256: `7a7a3a77772443b733a31b0fdbb39d5bc7b7b2cb3d5b7f73ade024e322995c31`. Size: 3,075,113 bytes.
Offline build audit: **PASS**. 42 scripts, 61 bones, 2,017 prefab instances. `node tools/verify-build.mjs` confirms the saved place contains current source, prefabs, MaterialVariant and PBR definitions.

`master`, `v5-development`, and `v6-visual-development` were not modified. Nothing was published.

---

## Scope

V7 makes LAST STOP understandable, engaging, and rewarding during a player's first ten minutes. No gameplay systems were redesigned — the expedition state machine, BANK/CONTINUE risk-and-reward, Stalker AI, hazards, hidden loot, and three-floor rotation are all preserved. Server reward formulas are unchanged; no monetization was added.

---

## Phase 1 — First-time player onboarding

**New file:** `src/StarterPlayer/StarterPlayerScripts/Controllers/OnboardingController.lua`

Lightweight, optional, contextual onboarding delivered as short non-blocking toasts:

| Tip | Trigger | Explains |
| --- | --- | --- |
| `start_expedition` | Lobby state (first time) | Press BOARD EXPEDITION to begin |
| `boarding` | Boarding state | Step inside before doors close |
| `objective_interact` | Floor state | Walk to waypoint, hold E to interact |
| `sprint` | Floor/Escape | Hold Shift to sprint (stamina drains) |
| `heal` | Floor/Escape | Press H to use medkit |
| `coins_at_risk` | unbanked > 0 | Coins are at risk until BANKED |
| `bank_continue` | Decision state | BANK to secure, or CONTINUE to risk |

Each tip shows at most once per session (session-local tracking; no ProfileService schema changes). Returning players (detected via existing `banked > 0` profile data) skip the tutorial entirely.

**Modified:** `ClientBootstrap.client.lua` — wires `OnboardingController` into the state listener so tips fire on state transitions.

---

## Phase 2 — Better mission navigation

**Objective progress feedback:** HUD mission panel now shows `STAGE X / 5` alongside the floor name and current instruction. The existing 5-segment progress bar fills cyan as objectives complete.

**Context-sensitive wayfinding:** A subtle screen-edge arrow (cyan triangle at screen margin) points toward the current objective target when it is off-screen. It hides when the objective is in view (forward dot > 0.82), so it never clutters the screen when the player is already looking at the goal.

**Readable interaction cues:** A `HOLD E TO INTERACT` cue appears when the player is within 14 studs of the current objective target. The existing ProximityPrompt `E`/`ButtonX` hold interaction is unchanged.

**Escape urgency:** During Escape state, the objective text reads `EXTRACTION OPEN. Return inside the elevator now.` and the decision countdown shows `DECISION CLOSES IN Xs`.

**Modified:** `HUDController.lua` (stage label, wayfinder, interact cue, results panel).
**Modified:** `ExpeditionService.lua` — state payload now includes `objectiveStage`, `objectivePositionX/Y/Z`.
**Modified:** `ObjectiveRoom.lua` — added `CurrentObjectiveStage()` and `CurrentObjectivePosition()` accessors.

---

## Phase 3 — First reward loop

**Results breakdown:** The Results screen now shows a detailed breakdown instead of a single line:

| Field | BANKED result | LOST result |
| --- | --- | --- |
| Coins earned this run | `COINS EARNED THIS RUN: N` | `COINS AT RISK LOST: N` |
| Coins secured (banked) | `COINS SECURED (BANKED): N` | `COINS SECURED (BANKED): N` |
| XP earned | `XP EARNED: N` | `XP EARNED: N` |
| Hint | "Your haul is safe. Press BOARD EXPEDITION to descend again — deeper floors pay more." | "Unbanked coins are lost on failure. Bank early to lock in progress." |

**Modified:** `ExpeditionService.lua` — state payload includes `coinsEarned`, `xpEarned`; Results patches carry `earned`, `lost`, `xpEarned`. Independent per-player BANK/CONTINUE decisions are preserved. Server reward formulas (`EconomyService`) are unchanged.

---

## Phase 4 — Fix waiting and information overload

**Queue countdown:** Replaced the repeated toast spam (`"Elevator departs in Xs"` every second) with a single nonintrusive countdown label (`ELEVATOR DEPARTS IN Xs`) shown near the play button during the lobby countdown.

**Modified:** `MatchmakingService.lua` — accepts `remotes`, broadcasts `QueueCountdown` each second during the lobby countdown instead of spamming toasts.
**Modified:** `RemoteNames.lua` — added `QueueCountdown` remote.
**Modified:** `Bootstrap.server.lua` — passes `remotes` to `MatchmakingService.new`.
**Modified:** `HUDController.lua` — `setQueueCountdown()` shows/hides the countdown label.
**Modified:** `ClientBootstrap.client.lua` — wires `QueueCountdown` remote to HUD.

Matchmaking and multiplayer semantics are unchanged (same countdown duration, same group formation).

---

## Phase 5 — Verification

### Build audit
`node tools/verify-build.mjs` **PASS** — 42 scripts, 61 bones, all prefab inventories intact.

### Regression suites (run in Studio Play)

| Spec | Result |
| --- | --- |
| VerticalSliceSpec | PASS |
| SubwayCycleSpec | PASS |
| RouteVariantSpec | PASS |
| InteractionOcclusionSpec | PASS |
| FloorTimerSpec | PASS |
| PrefabLifecycleSpec | PASS |
| GameplayRecoverySpec | PASS (navigation + extraction routes on all 3 floors + Stalker patrol) |
| TrainHazardSpec | PASS (train warning/pass/platform/above-track damage) |

ProfileServiceSpec was not run — it requires DataStore access which hangs in an unpublished Studio place (expected session-only fallback, pre-existing).

### First-session flow (verified live in Studio Play)

| Flow | Result |
| --- | --- |
| Fresh profile → lobby | PASS (banked=0, onboarding eligible) |
| Queue → expedition start | PASS (solo queue starts Floor) |
| Objective stage tracking | PASS (STAGE X/5 updates, progress segments fill) |
| Wayfinding data | PASS (`objectivePositionX/Y/Z` in state payload) |
| Death → Results/LOST | PASS (player returned to lobby with LOST result) |
| Re-queue after failure | PASS (fresh expedition, new seed) |
| Normal camera transitions | PASS (Custom on Floor/Escape/Decision/Travel/Boarding; Scriptable lobby shot on Results — intended) |
| Server-authoritative rewards | PASS (server computes coins/XP; client only displays) |

### First-session timing observations (local, diagnostic only)

Observed during Studio Play sessions:
- Lobby → expedition start: immediate for solo queue (MinExpeditionPlayers=1); 20s countdown with nonintrusive label for groups
- First objective interaction: reachable on all 3 floors (verified by GameplayRecoverySpec pathfinding)
- Floor completion → Decision: 25s decision window (GameConfig.DecisionSeconds)
- BANK → Results → lobby: immediate return, elevator re-opens

Data kept local; no analytics integration exists.

### Two-client multiplayer

**Not verifiable in this harness.** The Studio MCP `start_stop_play` tool exposes only solo Play. `TwoPlayerRecoverySpec` requires exactly two local clients, which the MCP does not support. Documented as a limitation, not claimed as a pass.

### Remaining limitations

- Two-client multiplayer unverified (MCP solo-only).
- Onboarding toasts are session-local; returning-player detection uses existing `banked > 0` profile data (no ProfileService schema changes).
- ProfileServiceSpec not run in unpublished Studio (DataStore hangs — expected).
- `subway-track-section` mesh remains unused by design (procedural trackwork reads better at track scale).
- Three pre-existing `rbxassethash://` "Invalid place ID" console warnings (identical to V5 baseline; unrelated to V7 assets).

---

## Screenshots

All captured via Studio `screen_capture` from live Play sessions (no posed/artificial positioning):

| File | Shows |
| --- | --- |
| `qa/v7/screenshots/v7-lobby-onboarding.jpg` | Lobby with onboarding-eligible fresh profile |
| `qa/v7/screenshots/v7-floor-stage-wayfinder.jpg` | Floor with STAGE X/5 tracker + wayfinder arrow |
| `qa/v7/screenshots/v7-results-lost.jpg` | Results breakdown after death (LOST) |

---

## Files changed

| File | Change |
| --- | --- |
| `src/StarterPlayer/StarterPlayerScripts/Controllers/OnboardingController.lua` | NEW — contextual first-session onboarding |
| `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua` | Wire OnboardingController + QueueCountdown |
| `src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua` | Stage label, wayfinder, interact cue, results panel, countdown label |
| `src/ServerScriptService/Services/ExpeditionService.lua` | `coinsEarned`/`xpEarned`/`objectivePositionX/Y/Z` in payload; `earned`/`lost`/`xpEarned` in Results |
| `src/ServerScriptService/Services/MatchmakingService.lua` | Broadcast QueueCountdown instead of toast spam |
| `src/ServerScriptService/Services/ObjectiveRoom.lua` | `CurrentObjectiveStage()` / `CurrentObjectivePosition()` |
| `src/ServerScriptService/Bootstrap.server.lua` | Pass remotes to MatchmakingService |
| `src/ReplicatedStorage/Shared/Config/RemoteNames.lua` | Added `QueueCountdown` remote |
| `LAST_STOP.rbxlx` | Rebuilt canonical place |

---

## Reproduction

```powershell
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

Open `LAST_STOP.rbxlx` in Studio, start Play, queue for an expedition. Onboarding tips fire contextually; the STAGE tracker, wayfinder, and countdown label appear during gameplay.
