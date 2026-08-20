# SM64 Modern Full Swift Twin — M33fn Handoff

## Scope

M33fn migrates `bhvActSelectorStarType` through a Swift 6 default-list visual
route. The reducer preserves unselected size decay/clamp and yaw reset,
selected size growth/clamp and 0x800 yaw pulse, 100-coin yaw-only rotation,
timer cadence, and owner-thread transform updates.

## Evidence

- Focused Swift/C act-selector fingerprint: `0x2514df42b8a6e2f6`.
- Behavior manifest: `0x88465bc1acfdd074`, 534 rows, 260 Swift value/owner
  routes, 274 explicit C adapters.
- `script/test_act_selector_star_type.sh` covers all three selector modes,
  size clamps, yaw updates, timer increments, and matching Swift/C fingerprints.
- Dispatch smoke verifies identity routing and selected-star transform output.
  Coverage, engine-runtime, live-route oracle, route-shard replay, timebase,
  Metal 4 source, shell syntax, and hygiene gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fn-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining act-selector parent, star/door/switch, and collision
families while preserving the value/owner/C-oracle/dispatch/manifest/live-
trace/strict-build/Metal-contract evidence loop.
