# SM64 Modern Full Swift Twin — M33bh Handoff

Date: 2026-08-17

## Completed slice

M33bh creates `RotatingOctagonalPlatformBehavior` and migrates
`bhvOctagonalPlatformRotating` through `RotatingOctagonalPlatformObjectBridge`,
dispatch route 62. Swift owns the authored collision/speed initializer table
and fixed yaw-step reducer. The owner bridge owns behavior-parameter packing,
generation-safe registration, and level-list yaw/angle-velocity/transform
mutation.

## Validation

- New `script/test_rotating_octagonal_platform.sh` Swift/C contract passes with
  fingerprint `0xf57874338637fe3a`.
- `script/test_behavior_dispatch_bridge.sh` exercises both authored speed
  directions through route 62 and verifies wrapped yaw/velocity mutation.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xe1a207e118c55001`, 534 rows, 105 Swift value/owner routes, and 429 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

429 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining platform behavior queue, then move into multi-child,
collision-heavy, and whole-engine route closure.
