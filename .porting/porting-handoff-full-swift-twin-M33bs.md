# SM64 Modern Full Swift Twin — M33bs Handoff

Date: 2026-08-17

## Completed slice

M33bs adds `LllRotatingHexagonalPlatformBehavior` and an owner route for
`bhvLllRotatingHexagonalPlatform`, dispatch route 72. Swift owns the authored
behavior-script yaw step and angle-velocity intent; the owner owns level-list
move/face-angle and transform mutation.

## Validation

- New `script/test_lll_rotating_hexagonal_platform.sh` Swift/C contract passes
  with fingerprint `0xb3d0e00436eb7273`.
- `script/test_behavior_dispatch_bridge.sh` exercises fixed-step yaw wrapping
  through route 72.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x79587f713ecf2614`, 534 rows, 119 Swift value/owner routes, and 415 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

415 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining LLL flame/parent and platform/hazard families, then close
collision and presentation consumers.
