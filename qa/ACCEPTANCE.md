Current acceptance is recorded in [v6/ACCEPTANCE.md](v6/ACCEPTANCE.md).

Earlier reports: [v5/ACCEPTANCE.md](v5/ACCEPTANCE.md), [v4/ACCEPTANCE.md](v4/ACCEPTANCE.md). The report below is archived V3 evidence.

# Recovery V3 acceptance — 2026-11-03

Canonical artifact: **LAST_STOP.rbxlx**. Build label: **RECOVERY V3 / AUTHORED HOSPITAL**. SHA-256: `3e492f78a34f43c543eab16bc5ad2587f781d8c8efb7da20d637869dd0701711`.

## Executed checks

| Check | Result and scope |
| --- | --- |
| Rojo build + offline audit | PASS. 1,498 script-free prefab instances; saved map IDs match ArtTheme and place. |
| Studio automatic tests | PASS. Existing deterministic reward/rate-limit/security logic and two-round PrefabLifecycleSpec. |
| Two actual local clients | PASS on the unmodified canonical build. Server Command Bar invoked TwoPlayerRecoverySpec. |
| Navigation | PASS. Pathfinding routes from arrival to all three record approaches on both rounds. |
| Interactions | PASS. Real active Players, range/line-of-sight checks, used-record rejection, three-objective completion. |
| Enemy | PASS. Humanoid moved over 2 studs physically; real player lost 15 health after attack windup. |
| Return and decisions | PASS. Both real players entered return region; first BANKed 80 coins while second CONTINUEd with 80 at risk. Second BANKed accumulated 172; first remained at 80. |
| Cleanup | PASS. First clone destroyed before second floor; second clone destroyed at teardown; ServerStorage sources and unrelated sibling sentinel preserved. |
| Persistence | NOT VERIFIED. Local unpublished place used the expected session-only fallback. Test accounting profiles were disposable memory. |
| Hardware/performance | Desktop Studio inspected. Reduced graphics/mobile hardware and 12-player load are NOT VERIFIED. |
| Published permissions | NOT VERIFIED in a published universe or different owner account. Eight uploads succeeded; actual bound materials are visible locally. |

Final engine log: [final-studio-log.txt](final-studio-log.txt). Screenshot proof: [final-two-player-pass.png](screenshots/final-two-player-pass.png). Earlier diagnostic failures and the imaging desk fix are retained in studio-integration-log.txt; they are not described as passing tests.

The integration test uses actual local clients and actual gameplay services with shortened test timings, navigation assertions, and teleports for interaction/escape checks. It is not a fully manual keyboard/gamepad playthrough. Restart Play after this opt-in fixture, which deliberately rebuilds the runtime world.

## Real Play captures

The PNGs are direct, unedited Windows captures of Roblox Studio Play mode. Editor chrome, HUD, and build label remain visible. Client Command Bar camera CFrames were used only for framing. The hospital/encounter simulation was paused for composition; no asset or pose was replaced for the images. The hospital/encounter captures use a fresh normal game session after the integration fixture was stopped.

- 01-lobby-wide.png: lobby after two-player results, camera (8,10,28) toward (0,6,-16), FOV 75.
- 02-elevator-close.png: open lobby elevator, camera (4,6,-6) toward (0,6,-27), FOV 65.
- 03-hospital-wide.png: hospital patient ward, camera (-10,8,700) toward (-24,4,705), FOV 80.
- 04-corridor-stalker.png: live corridor and original Stalker.

No baseline screenshot with a recorded camera transform was supplied or found. Therefore no camera-matched before image is fabricated. qa/source-audit.json reports exact XML inventories: both the supplied baseline and prior canonical file were 69,451 bytes with **zero authored Models, Parts, or MaterialVariants**. The recovery file is 1,661,045 bytes with four Models, 1,065 Parts, six Motor6Ds, and three MaterialVariants before runtime cloning.

## Limits and remaining work

The Stalker is an original articulated part rig with procedural motion, not an externally skinned mesh or uploaded animation clip. The environment is authored editable Roblox geometry; it is not represented as a photoreal asset pack.

Temporary material-generation/cache warnings appeared after upload/new variant combinations. Local rendering confirms applied texture detail, especially in the elevator close-up; it does not validate all maps under every published ownership/permission configuration. Source images, exact IDs, licenses, and reimport instructions are in ART_ASSETS.md.

No published game was overwritten during this recovery. Publishing the current place, persistent DataStore acceptance, cross-experience material permissions, and hardware performance testing remain separate verification steps.
