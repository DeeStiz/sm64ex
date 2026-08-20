# SM64 Modern Full Swift Twin — M33av Handoff

Date: 2026-08-17

## Completed slice

M33av migrates `bhvTTCTreadmill` through
`SM64TTCTreadmillObjectBridge`, dispatch route 49. The existing
`SM64TTCTreadmillBehavior` kernel owns deterministic master election, shared
surface speed, random target/timer selection, approach, and forward velocity.
The owner bridge owns shared master/surface state, per-treadmill target timing,
explicit random inputs, level-list registration, and forward-velocity record
mutation.

## Validation

- Existing `script/test_ttc_treadmill.sh` Swift/C value contract passes with
  fingerprint `0xd19867880b32d14f`.
- `script/test_behavior_dispatch_bridge.sh` exercises master election, shared
  surface speed, forward velocity, and owner record mutation while preserving
  the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xcd9afab7d4c3ba50`, 534 rows, 91 Swift value/owner routes, and 443 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

443 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining TTC/platform kernel queue, then execute the complete
7,419-shard schema-4 ledger once runtime authority can launch on a healthy
AppKit host.
