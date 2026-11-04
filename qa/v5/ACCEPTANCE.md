# LAST STOP V5 development-build acceptance

## Build and preservation

The tested development build contains the permanent fixes in commits `d66ae81` and `aaeac75`. The canonical `LAST_STOP.rbxlx` has 40 project scripts and 2,684,067 bytes.

SHA256 `1645abebcde6b63e5e6294013f0fb34823ccf80bdb1dd16d63032f4563d4e174`

The build sequence completed successfully before final Studio testing.

```text
node tools/build-prefabs.mjs
rojo build default.project.json --output LAST_STOP.rbxlx
node tools/verify-build.mjs
```

The final rebuilt file was reopened in Studio. All 40 loaded project sources matched their permanent `src/` files. Offline verification was repeated after gameplay testing. Multiplayer teardown left the Edit place with the same 40 matching scripts and zero temporary QA scripts. See [offline verification](final-offline-verification.json), [loaded-source audit](final-loaded-source-audit.json), and [post-test Edit audit](final-post-test-edit-source-audit.json).

The original Studio document and intermediate unsaved documents were preserved in `outputs/v5-studio-safety-2026-11-03/` beside this checkout. The original snapshot is `LAST_STOP_V5_before_fixes_1793754953688.rbxlx`. Its SHA256 remains `f096a7da91e3e02b2193d04e0336140d1adce0216410498780558f77650061b7`. Later binary snapshots preserve the documents before the occlusion, extraction, and timer rebuilds. The user's `.agents/` directory remains outside these commits.

## Permanent fixes

- Stalker arrival protection uses an 18-second grace period and an 18-stud protected arrival radius. Target selection and damage enforcement run on the server.
- Patrol recovery respects listening pauses and the originating navigation state. Navigation costs discourage flooded basins and train tracks. Laboratory rescue ramps provide an exit from the basin.
- HUD startup and respawn request authoritative state. Cached result snapshots restore the Results screen and boarding control.
- The lobby QueueConsole prompt has an accessible anchor. Subway arrival, crossings, and the relay-case socket are on reachable platforms.
- Train hazards have a four-second warning, a maximum of 25 damage once per pass, swept full-car damage bounds, vertical limits, and non-colliding visual cars.
- Objective interactions ignore character and NPC bodies during line-of-sight checks while retaining wall, hold-duration, and distance validation. Hidden-stash positions use world coordinates.
- Laboratory and Subway return elevators face the playable room.
- Deferred floor timeout and enemy-spawn callbacks verify the originating room, preserving later CONTINUE floors.

## Test method

Testing used two actual Roblox Studio local clients and a local server through `StudioTestService:ExecuteMultiplayerTestAsync(2, "V5_FINAL_SCHEDULED")`.

The successful final three-floor run used client `83f55656-0768-44d9-8808-9d19194838bb` as Player2, the primary objective carrier, and client `8d7dcdf5-1617-480c-8a21-158d7493bceb` as Player1, the second operator. Server ID was `c3e0bf6a-5621-456b-bbed-a6b44054ae87`. The reopened Edit instance is `36e415e4-e9bd-4362-afb1-e62e0102ec49`.

Traversal was automated through ordinary Humanoid movement, normal jumping, the existing sprint and medkit remotes, and actual ProximityPrompt holds. Characters followed physical paths through the floors. The game's ordinary boarding, travel, extraction, and lobby-return transitions handled transfers. Enemy AI, health, hazards, objective holds, timers, carrying penalties, and reward calculations remained active.

A temporary server Script selected Hospital, Laboratory, and Subway in a deterministic order. QA helper files live in this directory, outside the Rojo project. Test teardown removed their runtime instances. Regression fixtures separately used assisted positioning and isolated profiles for targeted assertions.

## Final results

| Check | Result | Evidence |
| --- | --- | --- |
| All nine regression suites | PASS | [40-script results](final-regression-40-script.json) |
| Hospital physical traversal and all objectives | PASS, both clients extracted and continued with 90 coins each | [three-floor run](final-three-floor-expedition.json) |
| Flooded Laboratory pumps, two-person controls, specimen delivery, extraction | PASS, both continued with 193 coins each | [three-floor run](final-three-floor-expedition.json) |
| Subway relay, installation, two-person controls, case delivery, extraction | PASS, both reached the decision | [three-floor run](final-three-floor-expedition.json) |
| Independent BANK and CONTINUE | PASS, Player2 BANKed 360 while Player1 continued with 310 at risk and zero banked | [decision and loss accounting](final-independent-decisions-and-loss.json) |
| Elimination and reward isolation | PASS, forced elimination lost the continuer's 310 while the banker's 360 remained secured | [decision and loss accounting](final-independent-decisions-and-loss.json) |
| Death, new Character, Results recovery, requeue | PASS, three controlled Boarding-death cycles per client, six total | [death-cycle traces](final-death-respawn-requeue.json) |
| Authoritative stale-HUD recovery | PASS, deliberately hidden boarding control restored by RequestState in Results, repeated in all six cycles | [resync](final-state-resync.json), [cycles](final-death-respawn-requeue.json) |
| Accessible lobby QueueConsole | PASS, walked from the lobby, checked unobstructed line of sight, triggered the real prompt, entered the next expedition | [terminal expedition](final-queue-console-new-expedition.json) |
| Another complete expedition after recovery tests | PASS, both completed Hospital and BANKed, final balances 450 and 140 | [terminal expedition](final-queue-console-new-expedition.json) |
| Visible mesh assets and PBR fetch status | PASS for tested assets, 70 actual MeshPart instances preloaded and all eight material-map IDs reached Success | [asset probe](final-assets.json) |
| Four gameplay audio assets | PASS, both client consoles reported loaded true for all four | [runtime console](final-runtime-console.json) |
| Final source/build consistency | PASS, 40 matching project scripts, clean temporary-test teardown | [post-test audit](final-post-test-edit-source-audit.json) |

The nine suites are VerticalSliceSpec, SubwayCycleSpec, RouteVariantSpec, PrefabLifecycleSpec, InteractionOcclusionSpec, FloorTimerSpec, TrainHazardSpec, GameplayRecoverySpec, and TwoPlayerRecoverySpec. Targeted coverage includes cooperative identity checks, carrier loss, solo fallback, independent rewards, train timing and bounded damage, 18 objective navigation routes, three extraction routes, and a 60-second patrol observation. That patrol reached 47.3 studs from its start and sampled 18 listening pauses. The live train regression recorded one 25-damage hit during its tested pass. See [regression console](final-40-script-regression-console.json).

The final three-floor run completed 5/5 progress on every floor. The primary player's observed health fell during Hospital and Laboratory encounters and recovered through ordinary game behavior and available medkit use. Both clients survived Subway. The primary BANK total is 90 + 103 + 117 floor coins plus the 50-coin first-escape bonus. The next expedition awarded that player another 90, producing 450. The second player's first successful BANK awarded 90 + 50, producing 140.

## Screenshots and logs

- [Hospital scene](final-hospital.jpg), [Laboratory arrival](final-laboratory-arrival.jpg), and [Subway scene](final-subway.jpg) are actual Studio captures of this 40-script build.
- [360-coin BANK](final-banked-360.jpg) and [final-build 140-coin BANK](final-banked-140.jpg) show the successful final HUD results. Their background 3D viewport is blank, so their evidence is limited to the HUD.
- The original requested [140-coin BANK screenshot](banked-140-coins.jpg) is preserved. It came from an earlier assisted run. The new final-build 140 screenshot provides an additional independently recorded result.
- [Laboratory CONTINUE](final-laboratory-continue.jpg) and [Laboratory HUD](final-laboratory-hud.jpg) show UI state during the final testing period. They have limited 3D visual evidence.
- [Final server and client Output logs](final-runtime-console.json) include the expected unpublished-place DataStore warning. The tested place has PlaceId 0 and uses session-only profiles.

## Failed attempts and coverage limits

Earlier evidence remains in this directory for traceability. The authoritative successful traversal is `final-three-floor-expedition.json`. Files named `final-regression-results.json` and `final-regression-ff43b26c*` describe earlier build stages. Use `final-regression-40-script.json` for the delivered build.

Early final-build traversal attempts exposed QA-driver limitations. A three-stud navigation agent could reject narrow ward routes. A waypoint approach caught a door jamb. Background clients delivered zero RenderStep callbacks, requiring normal movement updates on Heartbeat. A control-refresh race stopped one driver after its teammate completed the control. That idle player was subsequently eliminated. A later manual resumption consumed the floor timer. Those failures are saved in the attempt, driver-diagnostic, helper-race, and resumption-timeout JSON files. The chained final run completed all three floors after these helper corrections.

The intermittent death HUD soft-lock did not reproduce. Six controlled cycles plus the recorded natural deaths provide bounded regression coverage. The result does not establish that every timing condition is resolved.

Live persisted DataStore save/load round trips remain unverified because this local place is unpublished. Session reward accounting passed. Physical traversal covered the recorded route selections. Exhaustive physical coverage across every procedural seed remains unverified.

The raw material-URI preload callbacks include initial Failure values, while all eight later asset-fetch statuses are Success. Actual MeshPart dependency callbacks succeeded. Retain both stages when reviewing the asset probe.

Computer Use was stopped by the user with physical Escape during foreground-window inspection. Native UI automation stopped at that point. The remaining verification used MCP and Git. A manual keyboard-only playthrough and additional foreground-render captures remain unverified. Automated physical traversal and the earlier rendered scene captures are recorded above.

Delivery targets `v5-development`. The recorded remote master commit is `a69dc95e7ab6d51a026eb93167d7446a04bc3dbb`.
