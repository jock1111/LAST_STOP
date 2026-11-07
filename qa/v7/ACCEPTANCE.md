# LAST STOP V7 — First Session Experience acceptance

Branch: `v7-first-session-development`. Base: V6 commit `e8daad4` (verified stable baseline).
Canonical artifact: `LAST_STOP.rbxlx`. SHA-256: `325b4bff2a9c1627854117f19c14c2c95a6b14713046ec5f25bced8775c7b467`. Size: 3,079,641 bytes.
Offline build audit: **PASS**. 42 scripts, 61 bones, 2,017 prefab instances. `node tools/verify-build.mjs` confirms the saved place contains current source, prefabs, MaterialVariant and PBR definitions.

`master`, `v5-development`, and `v6-visual-development` were not modified. Nothing was published.

---

## Scope

V7 makes LAST STOP understandable, engaging, and rewarding during a player's first ten minutes. No gameplay systems were redesigned — the expedition state machine, BANK/CONTINUE risk-and-reward, Stalker AI, hazards, hidden loot, and three-floor rotation are all preserved. Server reward formulas are unchanged; no monetization was added.

---

## Phase 1 — First-time player onboarding

**New file:** `src/StarterPlayer/StarterPlayerScripts/Controllers/OnboardingController.lua`

Lightweight, optional, contextual onboarding delivered through a small FIFO tip queue:

| Tip | Trigger | Priority |
| --- | --- | --- |
| `start_expedition` | Lobby state (first time) | 1 |
| `boarding` | Boarding state | 2 |
| `objective_interact` | Floor state | 3 |
| `sprint` | Floor/Escape state | 4 |
| `heal` | Floor/Escape state | 5 |
| `coins_at_risk` | unbanked > 0 | 6 |
| `bank_continue` | Decision state | 7 |

Key fixes from review:
- **Tip queue**: Tips are enqueued and displayed one at a time (4s each), never overwriting each other or gameplay toasts. Higher-priority tips show first.
- **Returning-player detection**: A player who entered Floor but never secured coins (`banked == 0`) is still classed as returning. Session-local `hasEverFloored` flag is set on first Floor entry, so a player who played but never BANKED is not reclassified as brand-new.
- **Dismiss**: A "TUTORIALS OFF" button appears in the lobby for first-time players; clicking it disables all future tips for the session.

**Modified:** `ClientBootstrap.client.lua` — wires `OnboardingController` and the dismiss callback. `HUDController.lua` — adds the dismiss button and `ShowTutorialsButton()`.

---

## Phase 2 — Better mission navigation

**Objective progress feedback:** HUD mission panel shows `STAGE X / 5` alongside the floor name and current instruction. The 5-segment progress bar fills cyan as objectives complete.

**Wayfinder (fixed from review):** The previous implementation had incorrect directional math (dot product with world-up always yielded zero) and placed the arrow only 140px from center. Rewritten to use `Camera:WorldToViewportPoint()` for correct camera-space projection:
- Objective on-screen → wayfinder hidden
- Objective off-screen → cyan arrow clamped to the nearest screen edge, pointing toward the objective
- Objective behind camera → arrow points to the appropriate edge (top/bottom/left/right based on projected position)
- Zero-length vectors handled safely

**Stage 3 deterministic targeting:** Stage 3 has two synchronized controls (ControlA and ControlB). The wayfinder now guides deterministically to ControlA first (the first operator station), then ControlB once ControlA has been activated. Supports both solo and cooperative play.

**Interaction cue:** `HOLD E TO INTERACT` appears when within 14 studs of the current objective target.

**Escape urgency:** During Escape state, objective text reads `EXTRACTION OPEN. Return inside the elevator now.`

**Modified:** `HUDController.lua` (wayfinder, stage label, interact cue). `ObjectiveRoom.lua` (`CurrentObjectivePosition()` with deterministic Stage 3 logic). `ExpeditionService.lua` (state payload includes `objectiveStage`, `objectivePositionX/Y/Z`).

---

## Phase 3 — First reward loop

**Results breakdown (fixed from review):** The Results screen now shows a detailed breakdown that correctly distinguishes XP earned vs XP lost:

| Field | BANKED result | LOST result |
| --- | --- | --- |
| Coins secured this run | `COINS SECURED THIS RUN: N` | `COINS LOST: N` |
| Total secured balance | `TOTAL SECURED BALANCE: N` (cumulative) | `TOTAL SECURED BALANCE: N` (cumulative) |
| XP | `XP EARNED: N` (awarded) | `XP LOST: N` (forfeited, not earned) |
| Coins at risk this run | `COINS AT RISK THIS RUN: N` | `COINS AT RISK THIS RUN: N` |
| Hint | "Your haul is safe. Press BOARD EXPEDITION to descend again — deeper floors pay more." | "Unbanked coins and XP are lost on failure. Bank early to lock in progress." |

**Server changes (`ExpeditionService.lua`):**
- `_bankAndReturn`: sends `secured` (coins banked this run), `earned` (coins at risk this run), `xpEarned` (XP awarded). `banked` field is the cumulative balance after banking.
- `_eliminate`: sends `lost` (coins lost this run), `xpLost` (XP forfeited — NOT `xpEarned`, which was the bug). `banked` is the cumulative balance (unchanged).

**Server reward formulas (`EconomyService`) are unchanged.** Independent per-player BANK/CONTINUE decisions are preserved.

---

## Phase 4 — Fix waiting and information overload

**Queue countdown (fixed from review):** Replaced repeated toast spam (`"Elevator departs in Xs"` every second to ALL players) with a single nonintrusive countdown label (`ELEVATOR DEPARTS IN Xs`) shown only to queued players near the play button.

**MatchmakingService changes:**
- `_broadcastCountdown()` now iterates only `self._queue` (queued players), not `Players:GetPlayers()` (all players). Countdown disappears correctly for non-queued players.
- Countdown timing is unchanged (20 seconds, `LobbyQueueCountdown`). No design decision was made to alter timing — solo queue still has the full countdown, matching the code.

**Modified:** `MatchmakingService.lua`, `RemoteNames.lua` (added `QueueCountdown`), `Bootstrap.server.lua` (passes remotes), `HUDController.lua` (`setQueueCountdown`), `ClientBootstrap.client.lua` (wires remote).

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

| Flow | Result | Evidence |
| --- | --- | --- |
| Fresh profile → lobby | PASS | `v7-lobby-onboarding.jpg`, `v7-onboarding-tip.jpg` |
| Onboarding tip visible | PASS | `v7-onboarding-tip.jpg` |
| Queue → 20s countdown | PASS | `v7-queue-countdown.jpg` |
| Floor entry + STAGE tracker | PASS | `v7-floor-wayfinder.jpg` |
| Wayfinder off-screen objective | PASS | `v7-floor-wayfinder.jpg` |
| Interaction prompt near objective | PASS | `v7-interact-prompt.jpg` |
| Death → Results/LOST | PASS (real gameplay) | `v7-results-lost.jpg` |
| Re-queue after failure | PASS | Verified live — new expedition starts |
| BANKED results UI | PASS (UI rendering verified) | `v7-results-banked.jpg` |
| Normal camera transitions | PASS | Custom on Floor/Escape/Decision/Travel; Scriptable on Results — intended |
| Server-authoritative rewards | PASS | Server computes coins/XP; client only displays |

### Two-client multiplayer

**Not verifiable in this harness.** The Studio MCP `start_stop_play` tool exposes only solo Play. `TwoPlayerRecoverySpec` requires exactly two local clients, which the MCP does not support. Documented as a limitation, not claimed as a pass.

### First-session timing observations (local, diagnostic only)

Observed during Studio Play sessions:
- Lobby → expedition start: 20s countdown (solo queue does NOT start immediately — the code starts a countdown for every queue request; the earlier acceptance claim of immediate solo start was incorrect)
- Countdown → Floor: ~27s total (20s countdown + 7s travel)
- First objective interaction: reachable on all 3 floors (verified by GameplayRecoverySpec pathfinding)
- Floor completion → Decision: 25s decision window (GameConfig.DecisionSeconds)
- BANK → Results → lobby: immediate return, elevator re-opens

Data kept local; no analytics integration exists.

### Remaining limitations

- Two-client multiplayer unverified (MCP solo-only).
- Onboarding toasts are session-local; returning-player detection uses existing `banked > 0` profile data plus session-local `hasEverFloored` flag (no ProfileService schema changes).
- ProfileServiceSpec not run in unpublished Studio (DataStore hangs — expected).
- BANKED results captured via state injection (testing the actual HUD `showResults` code with realistic payload data) because objective completion could not be automated in the MCP Luau environment (`RBXScriptSignal:Fire` is restricted). The UI code path is identical whether data comes from real gameplay or injection.
- Three pre-existing `rbxassethash://` content warnings (identical to V5 baseline; unrelated to V7 assets).

---

## Screenshots

All captured via Studio `screen_capture` from live Play sessions (no posed/artificial positioning):

| File | Shows |
| --- | --- |
| `qa/v7/screenshots/v7-lobby-onboarding.jpg` | Lobby, first-time player, onboarding-eligible |
| `qa/v7/screenshots/v7-onboarding-tip.jpg` | Lobby with contextual onboarding tip toast |
| `qa/v7/screenshots/v7-queue-countdown.jpg` | Queue countdown label during 20s countdown |
| `qa/v7/screenshots/v7-floor-wayfinder.jpg` | Floor with STAGE X/5 tracker + off-screen wayfinder arrow |
| `qa/v7/screenshots/v7-interact-prompt.jpg` | Player near objective with `HOLD E TO INTERACT` cue |
| `qa/v7/screenshots/v7-results-lost.jpg` | True LOST results breakdown (real gameplay, death) |
| `qa/v7/screenshots/v7-results-banked.jpg` | BANKED results breakdown (UI rendering verified) |

---

## Files changed

| File | Change |
| --- | --- |
| `src/StarterPlayer/StarterPlayerScripts/Controllers/OnboardingController.lua` | NEW — tip queue, returning-player detection, dismiss |
| `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua` | Wire OnboardingController + QueueCountdown + dismiss |
| `src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua` | Stage label, fixed wayfinder, interact cue, results panel, countdown label, dismiss button |
| `src/ServerScriptService/Services/ExpeditionService.lua` | `objectivePositionX/Y/Z` in payload; `xpLost` (not `xpEarned`) on LOST; `secured`/`earned`/`xpEarned` on BANKED |
| `src/ServerScriptService/Services/MatchmakingService.lua` | Broadcast QueueCountdown only to queued players |
| `src/ServerScriptService/Services/ObjectiveRoom.lua` | `CurrentObjectivePosition()` with deterministic Stage 3 (ControlA first) |
| `src/ServerScriptService/Bootstrap.server.lua` | Pass remotes to MatchmakingService |
| `src/ReplicatedStorage/Shared/Config/RemoteNames.lua` | Added `QueueCountdown` remote |
| `LAST_STOP.rbxlx` | Rebuilt canonical place |

---

## Reproduction

```powershell
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

Open `LAST_STOP.rbxlx` in Studio, start Play, queue for an expedition. Onboarding tips fire contextually via the tip queue; the STAGE tracker, wayfinder, and countdown label appear during gameplay.
