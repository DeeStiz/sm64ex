# SM64 Modern Full Swift Twin — M33fo Handoff

## Scope

M33fo migrates `bhvStar` through a Swift 6 collectible-star value/owner
route. The route preserves save-bit model selection between solid and
transparent stars, the 80×50 interaction hitbox, 0x800 yaw rotation, and
interaction-triggered retirement with reset semantics.

## Evidence

- Focused Swift/C collect-star fingerprint: `0x6c47433452c2fada`.
- Behavior manifest: `0x95d27cf7d81efa04`, 534 rows, 261 Swift value/owner
  routes, 273 explicit C adapters.
- `script/test_collect_star.sh` covers fresh, collected/transparent, and
  interacted/deletion paths with matching Swift/C fingerprints.
- Dispatch smoke verifies identity routing, model selection, rotation,
  hitbox/interaction behavior, and generation-safe retirement. Coverage,
  engine-runtime, live-route oracle, route-shard replay, timebase, Metal 4
  source, shell syntax, and hygiene gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fo-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining star spawn/cutscene, door/switch, and collision
families while preserving the value/owner/C-oracle/dispatch/manifest/live-
trace/strict-build/Metal-contract evidence loop.
