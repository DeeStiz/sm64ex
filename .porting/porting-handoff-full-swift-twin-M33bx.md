# SM64 Modern Full Swift Twin — M33bx Handoff

Date: 2026-08-18

## Completed slice

M33bx adds `DddMovingPoleBehavior` and an owner route for the BITFS cage’s
`bhvDddMovingPole` child, dispatch route 77. Swift owns the parent-copy
position/face/move-angle reducer; the owner bridge owns stable parent linkage,
pole-list registration, and level-list transform mutation. The BITFS cage
spawner now allocates its pole child through this bridge.

## Validation

- New `script/test_ddd_moving_pole.sh` Swift/C contract passes with fingerprint
  `0xa0f4cd2e9d31d0bd`.
- `script/test_behavior_dispatch_bridge.sh` exercises cage plus pole route
  ordering and parent-copy output.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x62ab368424ec515b`, 534 rows, 125 Swift value/owner routes, and 409 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

409 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining child/platform/hazard families, then close collision and
presentation consumers.
