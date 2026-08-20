# SM64 Modern Full Swift Twin — M33bb Handoff

Date: 2026-08-17

## Completed slice

M33bb creates `PyramidElevatorBehavior` and migrates
`bhvPyramidElevator` plus `bhvPyramidElevatorTrajectoryMarkerBall` through
`PyramidElevatorObjectBridge`, dispatch routes 55 and 56. Swift owns the
idle/start/constant/bottom state machine, canonical sine jolts, Mario platform
gate, and marker-active intent. The owner bridge owns parent relations,
end-of-frame marker deactivation, level-list position/velocity mutation, and
transform state.

## Validation

- New `script/test_pyramid_elevator.sh` Swift/C contract passes with fingerprint
  `0xdc476f3dc88152c3`.
- `script/test_behavior_dispatch_bridge.sh` exercises elevator start transition,
  marker parent route, marker deactivation, and deterministic unload behavior
  while preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xc23cbbd8f1da242a`, 534 rows, 98 Swift value/owner routes, and 436 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

436 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining non-kernel platform behavior queue, then execute the
complete 7,419-shard schema-4 ledger once runtime authority can launch on a
healthy AppKit host.
