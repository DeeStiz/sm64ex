# SM64 Modern Full Swift Twin — M33bv Handoff

Date: 2026-08-18

## Completed slice

M33bv adds `ActivatedBackAndForthPlatformBehavior` and an owner route for
`bhvActivatedBackAndForthPlatform`, dispatch route 75. Swift owns packed
parameter decoding, Mario activation/countdown, endpoint reversal, distance
fence, vertical/horizontal displacement, and yaw flip intent. The owner owns
level-list state and transform/velocity mutation.

## Validation

- New `script/test_activated_back_and_forth_platform.sh` Swift/C contract
  passes with fingerprint `0x905af2b0dc0f6d21`.
- `script/test_behavior_dispatch_bridge.sh` exercises activation, countdown,
  vertical movement, and owner position mutation through route 75.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x22a7174deef17aff`, 534 rows, 122 Swift value/owner routes, and 412 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

412 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining platform/hazard families, then close collision and
presentation consumers.
