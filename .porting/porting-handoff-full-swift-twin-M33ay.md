# SM64 Modern Full Swift Twin — M33ay Handoff

Date: 2026-08-17

## Completed slice

M33ay migrates `bhvTTCRotatingSolid` through
`SM64TTCRotatingSolidObjectBridge`, dispatch route 52. The existing
`SM64TTCRotatingSolidBehavior` kernel owns turn timing, vertical reset,
symmetric roll approach, number-of-turns progression, and alert/click sound
intents. The owner bridge owns copied rotation/sound state, authored side
count, level-list registration, and roll/vertical/angle-velocity record
mutation.

## Validation

- Existing `script/test_ttc_rotating_solid.sh` Swift/C value contract passes
  with fingerprint `0xa75c9000a7214bb7`.
- `script/test_behavior_dispatch_bridge.sh` exercises the TTC rotating-solid
  identity, click/turn boundary, roll output, and owner record mutation while
  preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x5b42304f8eac6fcf`, 534 rows, 94 Swift value/owner routes, and 440 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

440 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining TTC/platform kernel queue, then execute the complete
7,419-shard schema-4 ledger once runtime authority can launch on a healthy
AppKit host.
