# SM64 Modern Full Swift Twin — M33bo Handoff

Date: 2026-08-17

## Completed slice

M33bo creates `FerrisWheelPlatformBehavior` and a parent/child owner route for
`bhvFerrisWheelAxle` and `bhvFerrisWheelPlatform`, dispatch route 69. Swift
owns canonical parent-relative platform transforms and velocity derivation for
all four authored child indices. The owner bridge owns axle allocation,
source-order child creation, stable parent links, and level-list transform/
velocity mutation.

## Validation

- New `script/test_ferris_wheel_platform.sh` Swift/C contract passes with
  fingerprint `0x642ceeb84fd3cb93`.
- `script/test_behavior_dispatch_bridge.sh` exercises axle plus four children,
  shared identity routing, source-order effects, and parent-relative positions.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x91b63014605cd752`, 534 rows, 115 Swift value/owner routes, and 419 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

419 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining multi-child platform/hazard families, then close collision,
presentation, and whole-engine authority consumers.
