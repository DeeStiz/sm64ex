# SM64 Modern Full Swift Twin — M33ap Handoff

Date: 2026-08-17

## Completed slice

M33ap migrates the shared elevator behavior family through
`SM64ElevatorObjectBridge`. The route covers `bhvRrElevatorPlatform`,
`bhvHmcElevatorPlatform`, and `bhvMeshElevator` with dispatch route 43.
`SM64ElevatorBehavior` owns the exact action/timer/platform gate, signed
vertical approach, authored bottom/top/midpoint bounds, and sound/shake
intents. The owner bridge owns level-list registration, authored metadata,
Mario/platform relation input, record position/velocity/action/timer mutation,
and transform flags.

## Validation

- Existing `script/test_elevator_behavior.sh` Swift/C value contract passes.
- `script/test_behavior_dispatch_bridge.sh` exercises all three elevator
  identities, shared route selection, two-unit vertical approach, and owner
  record mutation while preserving the existing dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x77f38abae15f38c7`, 534 rows, 85 Swift value/owner routes, and 449 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

449 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the existing Swift-kernel/platform adapter queue, then execute the
complete 7,419-shard schema-4 ledger once runtime authority can launch on a
healthy AppKit host.
