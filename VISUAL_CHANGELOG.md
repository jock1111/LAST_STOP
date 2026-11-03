# Visual overhaul changelog

## Milestone 1 — lobby / elevator foundation (in progress)

### Built

- Added a centralized `ArtTheme` palette: navy, steel, worn concrete, cyan signage, amber safety markings, and alarm red.
- Rebuilt the runtime station shell into a multi-layered concourse: layered flooring, rail trench and sleepers, platform edge, ceiling beams/ribs, service lamps, structural walls, recessed panels, columns, vents, pipe runs, cable-like hardware, benches, ticket gates, waste bins, maintenance barriers, and route signage.
- Added a separate elevator detail model: threshold, outer frame, door header, ceiling fixtures, floor inlays, indicator housing, call/emergency panel, and safety stripes while retaining the server-owned door tween contract and invisible gameplay regions.
- Added restrained Future lighting, atmosphere, color correction, and bloom in `Bootstrap.server.lua`.
- Made the HUD scale from viewport dimensions and added restrained panel strokes rather than changing the game-state interface contract.
- Added a guarded MaterialVariant pipeline (`PbrMaterialService`) and tagged major lobby concrete/metal surfaces. It configures only complete, verified map sets from `ArtTheme.Pbr`, so empty placeholders cannot introduce broken asset dependencies.
- Hardened expedition teardown against a Studio player-removal race that previously produced `LoadCharacter: Failed spawn player, player not in world` after stopping a play session.

### Verified in Roblox Studio on 2026-11-02

- Rojo built `LAST_STOP_visual_m1.rbxlx` and an unlocked test copy successfully.
- The test build launched in Studio.
- Solo queue progressed through `LOBBY → TRAVEL → FLOOR (Depth 1)` and displayed the existing objective HUD.
- Studio used the session-only profile fallback because this local place cannot access DataStores; that is expected.

### Not complete / deliberately not claimed

- The six CC0 Poly Haven maps are downloaded and documented, but none has been uploaded to Roblox. Therefore no `MaterialVariant` maps are visible in Studio yet.
- The current floor templates and Stalker are still the existing vertical-slice implementations. Hospital, flooded-lab, lockdown, and enemy overhaul work remain future milestones.
- The return-to-lobby player-removal race was patched after the above run; it needs one clean follow-up Studio run before it is marked verified.
- No performance or mobile-device measurements have been collected.
