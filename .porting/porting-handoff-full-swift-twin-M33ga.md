# SM64 Modern Full Swift Twin — M33ga Handoff

## Scope

M33ga migrates `bhvTowerDoor` as a Swift 6 surface collision route. The
owner preserves the first-frame `-0x4000` yaw correction, Mario-attack
explosion and particle intents, wall-explosion sound, zero-coin outcome, and
generation-safe retirement.

## Evidence

- Focused Swift/C tower-door fingerprint: `0xc556234e1d089035` from
  `script/test_tower_door.sh`.
- Behavior manifest: `0x431e12ef6be3c4bb`, 534 rows, 278 Swift value/owner
  routes, 256 explicit C adapters.
- Dispatch smoke verifies identity routing, first-frame yaw, attack effects,
  wall-explosion sound, and deactivation.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33ga-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining door, hidden-object, environment, and frontend families
while retaining the value/owner/C-oracle/dispatch/manifest/live-trace/
strict-build/Metal-contract evidence loop.
