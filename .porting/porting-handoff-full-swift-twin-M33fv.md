# SM64 Modern Full Swift Twin — M33fv Handoff

## Scope

M33fv migrates `bhvHiddenAt120Stars` through a Swift 6 surface/global gate.
The owner route preserves the 120-star threshold, 4,000-unit collision-distance
admission, collision-model load intent, and grate deactivation.

## Evidence

- Focused Swift/C cannon-grate fingerprint: `0x3da0a8473d7acb17`.
- Behavior manifest: `0x5a4277aae5c1d649`, 534 rows, 269 Swift value/owner
  routes, 265 explicit C adapters.
- `script/test_castle_cannon_grate.sh` covers below-threshold and threshold
  behavior with matching Swift/C fingerprints.
- Dispatch smoke verifies identity routing and 120-star deactivation.
  Coverage, engine-runtime, live-route oracle, route-shard replay, timebase,
  Metal 4 source, shell syntax, and hygiene gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fv-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue door/switch and remaining collision/effect families while preserving
the value/owner/C-oracle/dispatch/manifest/live-trace/strict-build/Metal-
contract evidence loop.
