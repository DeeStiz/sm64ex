# SM64 Modern Full Swift Twin — M33bk Handoff

Date: 2026-08-17

## Completed slice

M33bk creates `WfSlidingPlatformBehavior` and migrates the used
`bhvWfSlidingPlatform` through `WfSlidingPlatformObjectBridge`, dispatch route
65. Swift owns initialization offsets, authored 10/15/20 speed selection,
explicit random initial timer, wait/extend/retract timer edges, 510-unit
endpoint snaps, yaw reversal, and fvel movement. The owner bridge owns
level-list timer/action/position/velocity/transform mutation.

## Validation

- New `script/test_wf_sliding_platform.sh` Swift/C contract passes with
  fingerprint `0xbc884548def390e0`.
- `script/test_behavior_dispatch_bridge.sh` exercises route 65, random-wait
  admission, start movement, endpoint snap, and retract yaw reversal.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x003984e3e42b8d6f`, 534 rows, 109 Swift value/owner routes, and 425 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

425 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining platform behavior families, then close collision,
presentation, and whole-engine authority consumers.
