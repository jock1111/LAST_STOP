# Studio Test Plan — Milestone A

Run these in a private test place after syncing the project. Open **View → Output**. In Studio Play, `TestRunner` should print `[LAST STOP] Vertical-slice pure logic tests passed.` before the manual tests below. A failure is an implementation failure, not a passing test.

## Reproducible manual checks

| Scenario | Procedure | Expected result | Current status |
| --- | --- | --- | --- |
| Solo first session | Play with one client; press PLAY; interact with all three glowing stations; enter the marked return elevator; choose BANK. | The run moves through each state; coins appear as at-risk then become secured once; first escape adds its documented 50-coin bonus. | Pending |
| 2 / 6 / 12 players | Test tab → Clients and Servers, set each player count; queue all players. | At most 12 enter one run; each player receives HUD snapshots; objective progress is shared. | Pending |
| Mixed bank/continue | Two clients finish a floor; one chooses BANK, one CONTINUE. | The banker returns to the lobby with saved coins; the continuer gets a new floor carrying their at-risk coins. | Pending |
| Decision timeout | Do not vote after escape. | Each non-voter defaults to BANK, preserving the shown at-risk amount. | Pending |
| Missed elevator | Finish objective, leave one player outside SafeRegion when countdown ends. | Only that player loses at-risk coins and returns to lobby; players inside proceed to decision. | Pending |
| Death/disconnect holding loot | Take damage or stop a client during a floor after completion. | Player loses at-risk coins; the remaining group continues or ends cleanly if empty. | Pending |
| Simultaneous banking | Have all clients press BANK within the same second. | Each profile mutation is server-side, each player receives one result, no duplicate coins. | Pending |
| Stalker path blocked | In a Studio copy of the room, place a temporary wall across a direct route. | The enemy attempts a path; fallback is movement attempt only, never an instant kill or a server error. | Pending |
| Remote spam | From the client command bar, fire `RequestDecision`/`RequestMedkit` repeatedly. | Requests beyond 10 in two seconds are rejected; no state or currency changes occur. | Pending |
| Corrupt profile | In a test datastore, write malformed/missing values for a test key. | The profile normalizer provides non-negative defaults; session stays playable. | Pending |
| Datastore outage | Disable Studio API Services or induce a DataStore error. | Warning appears; a session profile is used; no client can spoof a balance. | Pending |
| Mobile HUD | Studio device emulator: phone and tablet profiles. | HUD panels remain visible, PLAY/medkit/decision buttons are touchable. | Pending |
| Gamepad | Studio emulator or controller: use proximity prompt and Button Y for medkit. | Prompts work and Button Y requests a medkit server-side. | Pending |

## Intentionally deferred scenarios

Revive-at-door-close, purchase retry/duplicate receipt, spectator, global-party rejoin, all other equipment, storage migrations beyond the initial normalizer, streaming transitions, low-FPS profiling, performance budgets, and purchase-policy validation depend on features not shipped in Milestone A. They are **not tested** and must not be reported as complete.

## Acceptance log template

For each test run, record the private-place URL, date, Studio version, client/server count, seed printed by `ExpeditionService`, test result, relevant Output lines, and a short screen recording for failures. The logged seed allows the same weighted sequence to be reproduced in a later QA run.
