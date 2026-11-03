# Recovery V3 investigation and changes

Investigation began on branch visual-recovery-v3 at fddf7d476fb91978ff43e13a7bae15c2e562a16d. The only commit after the supplied baseline bbc0c34fc81ac41d4a2141d93e169bd394ab1efe was fddf7d4, “Add milestone 1 visual overhaul foundation.”

The old canonical LAST_STOP.rbxlx had not been rebuilt for the newer source. The M1 deliverable contained scripts that generated decor at runtime, not persistent environment templates. default.project.json did not map ServerStorage prefabs. Thus opening the old canonical file or syncing only script services could reproduce the original prototype. PBR downloads were unbound, with empty IDs.

The previous startup path was Bootstrap → FloorService:BuildWorld → runtime part construction. RoomRuntime:Start built generic room geometry. BuildWorld destroyed the whole LastStopWorld container. The recovery path is Bootstrap → FloorService:BuildWorld → saved Lobby/Elevator clones, followed by ExpeditionService → Room:Start → saved Hospital clone. Only LastStopWorld.Runtime is replaced; permanent templates and unrelated siblings survive.

## Concrete changes

- Four script-free editable source models: 537 lobby, 116 elevator, 805 hospital, and 40 Stalker instances (1,498 total). Runtime adds secure prompts, animation welds, and state attributes.
- Layered concourse: columns/flanges, plinths, coffers/beams, practical lights, service pipes/cable racks, platform edge/rails, recessed wall panels, benches, ticket barriers, queue terminal, printed signs/posters.
- Elevator: separate moving leaves, welded inset art, seals/jambs, warning stripes, floor display, threshold grooves, handrails, panel seams/bolts, buttons, ceiling louvres and lighting. Door generation guards prevent stale tween callbacks; obstruction checks postpone closure.
- Hospital: arrival foyer, corridor, four-bed ward with curtains/IVs/monitors, treatment/scanner room, archive shelving/binders, and connecting east loop. Preplaced medical records replace generic glowing stations. The imaging desk was moved after actual two-player testing found an obstructing monitor.
- Required markers are validated: EntranceSpawn, ElevatorSocket, ElevatorReturnZone, EnemySpawn, PatrolPaths, ObjectiveSockets, RoomBounds. There is no silent primitive-room fallback.
- Original Motor6D Stalker with asymmetrical shoulder, restraint straps, mask, fingers, dim eyes, Humanoid physics, server-owned network simulation, path waypoint following/repath, procedural gait and windup attack.
- Eight real CC0 image uploads, three saved MaterialVariants, tiled structural surfaces, practical lighting and restrained atmosphere. Runtime cannot read/write Plugin-protected material map properties; definitions live in the Rojo place, with offline consistency checks.
- Realistic lighting saved in the place; removed runtime writes to protected lighting settings. RespawnLocation/initial placement corrected. HUD inverse-scale layout keeps health/actions/build label on screen. Floor spawns use a four-column group grid.
- Existing economy, persistence fallback, remote validation/rate limits, late-join behavior, independent BANK/CONTINUE, and teardown retained. The live floor pool now focuses only Hospital.
- Automatic prefab lifecycle integration test, opt-in real two-client test including physical enemy movement/damage, and offline source/build audit.

## Before/after evidence

No baseline screenshot with a recorded camera CFrame was available in the supplied project or prior deliverables. Consequently an honest identical-camera before/after pair cannot be claimed. The four new screenshots are unedited Studio Play captures from the rebuilt canonical place. Camera CFrames were set through the client Command Bar for framing; no scene was separately rendered or generated. The earlier runtime-only scene can be recovered from the supplied baseline commit for a separate camera-matched comparison.

See qa/ACCEPTANCE.md for exact executed tests and remaining acceptance limits. Source and build inventories are reproducible using tools/verify-build.mjs; this document does not treat source edits alone as proof of visual acceptance.
