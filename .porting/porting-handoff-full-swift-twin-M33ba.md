# SM64 Modern Full Swift Twin — M33ba Handoff

Date: 2026-08-17

## Completed slice

M33ba creates the `TTCCogBehavior` kernel and migrates `bhvTTCCog` through
`SM64TTCCogObjectBridge`, dispatch route 54. Swift owns shape/direction
initialization, slow/fast/stopped speed selection, random target approach,
and wrapped yaw output. The owner bridge owns explicit random target and
approach decisions, level-list registration, and yaw/angle-velocity record
mutation.

## Validation

- New `script/test_ttc_cog.sh` Swift/C contract passes with fingerprint
  `0xde2d825067cdae31`.
- `script/test_behavior_dispatch_bridge.sh` exercises the TTC cog identity,
  normal speed selection, yaw output, and owner record mutation while
  preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xf19ba271940de087`, 534 rows, 96 Swift value/owner routes, and 438 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

438 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining non-kernel platform behavior queue, then execute the
complete 7,419-shard schema-4 ledger once runtime authority can launch on a
healthy AppKit host.
