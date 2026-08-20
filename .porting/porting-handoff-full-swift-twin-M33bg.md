# SM64 Modern Full Swift Twin — M33bg Handoff

Date: 2026-08-17

## Completed slice

M33bg creates `WfRotatingWoodenPlatformBehavior` and migrates
`bhvWfRotatingWoodenPlatform` through `WfRotatingWoodenPlatformObjectBridge`,
dispatch route 61. Swift owns the wait/spin action machine, 60/126 timer
edges, 0x100 yaw velocity, wrapped yaw mutation, and sound intent. The owner
bridge owns generation-safe registration and level-list action/timer/yaw/
transform mutation.

## Validation

- New `script/test_wf_rotating_wooden_platform.sh` Swift/C contract passes with
  fingerprint `0x9ee1260bc3fb16f6`.
- `script/test_behavior_dispatch_bridge.sh` exercises the wait-to-spin and
  spin-to-wait transitions, yaw mutation, and sound intent through route 61.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xada02ba6c34cea39`, 534 rows, 104 Swift value/owner routes, and 430 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, strict regenerated Swift 6 Xcode
  Debug build, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

430 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining platform behavior queue, prioritizing compact
value/owner families and then multi-child/collision-heavy routes.
