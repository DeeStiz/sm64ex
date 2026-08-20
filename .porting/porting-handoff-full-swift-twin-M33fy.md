# SM64 Modern Full Swift Twin — M33fy Handoff

## Scope

M33fy migrates `bhvStarDoor` as a Swift 6 paired surface route. The owner
preserves interaction and neighbor activation, the 16-frame opening move, the
31-frame open hold, the 16-frame close move, reset semantics,
tangible/intangible transitions, room-gated visibility, collision-load intent,
and open/close sound and rumble edges.

## Evidence

- Focused Swift/C star-door fingerprint: `0x216079c2c53c04c5` from
  `script/test_star_door.sh`.
- Behavior manifest: `0x995600ba4bfbc8ca`, 534 rows, 275 Swift value/owner
  routes, 259 explicit C adapters.
- Dispatch smoke verifies identity routing, paired neighbor activation,
  opening sound timing, and room-visibility/intangible behavior.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33fy-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining door, cap-switch, hidden-object, and environment
families while retaining the value/owner/C-oracle/dispatch/manifest/live-trace/
strict-build/Metal-contract evidence loop.
