# SM64 Modern Full Swift Twin — M33au Handoff

Date: 2026-08-17

## Completed slice

M33au migrates `bhvTTCSpinner` through
`SM64TTCSpinnerObjectBridge`, dispatch route 48. The existing
`SM64TTCSpinnerBehavior` kernel owns speed selection, random direction and
pause behavior, timer reset, and wrapped face-pitch output. The owner bridge
owns copied direction/change-timer state, explicit random inputs, level-list
registration, pitch/angle-velocity record mutation, and transform flags.

## Validation

- Existing `script/test_ttc_spinner.sh` Swift/C value contract passes with
  fingerprint `0x40d3eedffaef914d`.
- `script/test_behavior_dispatch_bridge.sh` exercises the TTC spinner identity,
  speed selection, pitch output, and owner record mutation while preserving the
  dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x7ed1b7c2e5861512`, 534 rows, 90 Swift value/owner routes, and 444 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

444 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining TTC/platform kernel queue, then execute the complete
7,419-shard schema-4 ledger once runtime authority can launch on a healthy
AppKit host.
