# SM64 Modern Full Swift Twin — M33as Handoff

Date: 2026-08-17

## Completed slice

M33as migrates `bhvRotatingPlatform` through
`SM64RotatingPlatformObjectBridge`, dispatch route 46. The existing
`SM64RotatingPlatformBehavior` kernel owns the idle/spin action machine, signed
high behavior-byte speed semantics, timer transitions, yaw wrapping, and loop
sound intent. The owner bridge owns level-list registration, behavior-byte
storage, action/timer reset boundaries, yaw/angle-velocity record mutation, and
transform flags.

## Validation

- Existing `script/test_rotating_platform.sh` Swift/C value contract passes
  with fingerprint `0x8d77ef02524f8933`.
- `script/test_behavior_dispatch_bridge.sh` exercises the rotating identity,
  high-byte speed conversion, yaw output, and owner record mutation while
  preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x082601bf1f2b759d`, 534 rows, 88 Swift value/owner routes, and 446 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

446 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining Swift-kernel-backed platform queue, then execute the
complete 7,419-shard schema-4 ledger once runtime authority can launch on a
healthy AppKit host.
