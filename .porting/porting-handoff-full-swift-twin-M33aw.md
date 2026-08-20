# SM64 Modern Full Swift Twin — M33aw Handoff

Date: 2026-08-17

## Completed slice

M33aw migrates `bhvTTCPendulum` through
`SM64TTCPendulumObjectBridge`, dispatch route 50. The existing
`SM64TTCPendulumBehavior` kernel owns acceleration direction, angle/velocity
oscillation, delay and sound timers, random acceleration/delay inputs, and
render roll. The owner bridge owns copied state, level-list registration,
pitch/roll and angle-velocity record mutation, and transform flags.

## Validation

- Existing `script/test_ttc_pendulum.sh` Swift/C value contract passes with
  fingerprint `0x04a7d453b291ca30`.
- `script/test_behavior_dispatch_bridge.sh` exercises the TTC pendulum
  identity, first oscillator step, roll output, and owner record mutation while
  preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x8614e92b657db1d0`, 534 rows, 92 Swift value/owner routes, and 442 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

442 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining TTC/platform kernel queue, then execute the complete
7,419-shard schema-4 ledger once runtime authority can launch on a healthy
AppKit host.
