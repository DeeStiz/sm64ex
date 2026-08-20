# SM64 Modern Full Swift Twin — M33ge Handoff

## Scope

M33ge migrates `bhvRecoveryHeart` as a Swift 6 general-actor effect route.
The owner preserves 50-unit hitbox/hurtbox setup, Mario-overlap spin-speed
selection, one-shot heart-spin sound gating, off-overlap decay to the 400
minimum, 0x10000 spin accumulation, +4 heal pulses, and owner-thread yaw
updates.

## Evidence

- Focused Swift/C recovery-heart fingerprint: `0x286a983fa291efd2` from
  `script/test_recovery_heart.sh`.
- Behavior manifest: `0x3b36975f88532b9b`, 534 rows, 284 Swift value/owner
  routes, 250 explicit C adapters.
- Dispatch smoke verifies identity routing, overlap spin/sound, and yaw
  selection.
- `script/test_behavior_manifest.sh`, `script/test_behavior_dispatch_bridge.sh`,
  `script/test_engine_runtime.sh`, and `script/test_live_route_oracle.sh` pass.
- Route-shard replay, timebase audit, Metal 4 source contract, `zsh -n`, and
  `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33ge-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining frontend, environment, and hidden-switch families while
retaining the value/owner/C-oracle/dispatch/manifest/live-trace/strict-build/
Metal-contract evidence loop.
