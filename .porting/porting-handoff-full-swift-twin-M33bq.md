# SM64 Modern Full Swift Twin — M33bq Handoff

Date: 2026-08-17

## Completed slice

M33bq creates `CheckerboardPlatformBehavior` and a shared parent/child owner
route for `bhvCheckerboardElevatorGroup` and `bhvCheckerboardPlatformSub`,
dispatch route 70. Swift owns the child action cycle, wait/move/rotate phases,
pitch and velocity state; the owner bridge owns variant-authored speeds/scales,
child positions, source-order allocation, parent linkage, and group teardown.

## Validation

- New `script/test_checkerboard_platform.sh` Swift/C contract passes with
  fingerprint `0x83f074a0cb0df5ce`.
- `script/test_behavior_dispatch_bridge.sh` exercises group plus two children,
  source-order child actions, shared route identity, and parent unload.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x5c59bdccfb75ec63`, 534 rows, 117 Swift value/owner routes, and 417 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

417 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining multi-child platform/hazard families, then close collision,
presentation, and whole-engine authority consumers.
