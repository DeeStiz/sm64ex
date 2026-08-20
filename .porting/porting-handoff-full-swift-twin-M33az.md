# SM64 Modern Full Swift Twin — M33az Handoff

Date: 2026-08-17

## Completed slice

M33az creates the `TTC2DRotatorBehavior` kernel and migrates
`bhvTTC2DRotator` through `SM64TTC2DRotatorObjectBridge`, dispatch route 53.
Swift owns canonical signed yaw approach, turn timing, target/increment
updates, random direction timers, hand/cog initialization, and angle velocity.
The owner bridge owns explicit random inputs, level-list registration, and
face-yaw/angle-velocity record mutation.

## Validation

- New `script/test_ttc_2d_rotator.sh` Swift/C contract passes with fingerprint
  `0x86f4ab9de3f5c3ab`.
- `script/test_behavior_dispatch_bridge.sh` exercises the 2D rotator identity,
  target increment, timer reset, and owner yaw mutation while preserving the
  dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x4dab77e5a10ebf1d`, 534 rows, 95 Swift value/owner routes, and 439 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

439 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining non-kernel platform behavior queue, then execute the
complete 7,419-shard schema-4 ledger once runtime authority can launch on a
healthy AppKit host.
