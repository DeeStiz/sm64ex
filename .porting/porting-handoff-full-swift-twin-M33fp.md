# SM64 Modern Full Swift Twin — M33fp Handoff

## Scope

M33fp migrates `bhvStarSpawnCoordinates` through a Swift 6 level-list
trajectory route. It preserves star/transparent model selection, intro/rise/
fall/landed motion, canonical home-vector yaw and velocities, the 30-frame
sine rise, sparkle-spawner children, environment/star-appears intents,
time-stop enable/clear boundaries, tangible landing, and interaction
retirement.

## Evidence

- Focused Swift/C star-spawn fingerprint: `0x75b6cafe102b8788`.
- Behavior manifest: `0x4dc4d53de25a4410`, 534 rows, 262 Swift value/owner
  routes, 272 explicit C adapters.
- `script/test_star_spawn_coordinates.sh` covers initialization, intro, rise,
  rise-to-fall transition, landing/tangibility, time-stop clear, deletion, and
  matching Swift/C fingerprints.
- Dispatch smoke verifies identity routing, transparent-star state, intro
  transform, time-stop ownership, and sparkle-child-capable owner setup.
  Coverage, engine-runtime, live-route oracle, route-shard replay, timebase,
  Metal 4 source, shell syntax, and hygiene gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fp-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining spawned-star/no-level-exit, hidden-star, door/switch,
and collision families while preserving the value/owner/C-oracle/dispatch/
manifest/live-trace/strict-build/Metal-contract evidence loop.
