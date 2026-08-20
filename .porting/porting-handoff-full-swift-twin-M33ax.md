# SM64 Modern Full Swift Twin — M33ax Handoff

Date: 2026-08-17

## Completed slice

M33ax migrates `bhvTTCElevator` through
`SM64TTCElevatorObjectBridge`, dispatch route 51. The existing
`SM64TTCElevatorBehavior` kernel owns speed selection, random direction and
move-time selection, gravity, endpoint clamping, timer reset, and position
output. The owner bridge owns authored peak height, copied direction/move-time
state, explicit random inputs, level-list registration, and vertical
position/velocity record mutation.

## Validation

- Existing `script/test_ttc_elevator.sh` Swift/C value contract passes with
  fingerprint `0xf5fec77dc56be959`.
- `script/test_behavior_dispatch_bridge.sh` exercises the TTC elevator
  identity, velocity/position step, endpoint-ready state, and owner record
  mutation while preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x6705ed97d56f0810`, 534 rows, 93 Swift value/owner routes, and 441 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

441 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining TTC/platform kernel queue, then execute the complete
7,419-shard schema-4 ledger once runtime authority can launch on a healthy
AppKit host.
