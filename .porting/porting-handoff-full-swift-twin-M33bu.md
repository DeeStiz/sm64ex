# SM64 Modern Full Swift Twin — M33bu Handoff

Date: 2026-08-17

## Completed slice

M33bu adds `LllRotatingFireBarBehavior` and a parent route for
`bhvLllRotatingBlockWithFireBars`, dispatch route 74. Swift owns distance
activation, fixed -0x100 rotation, and six/eight flame allocation intent. The
owner bridge allocates the two authored flame bars through the shared
parent-relative flame bridge and preserves source-order child traversal and
deletion.

## Validation

- New `script/test_lll_rotating_fire_bar.sh` Swift/C contract passes with
  fingerprint `0x98c415f26aa73548`.
- `script/test_behavior_dispatch_bridge.sh` exercises parent activation,
  eight-flame allocation, rotation, distance exit, and flame deletion.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xb7856fd3537dd26d`, 534 rows, 121 Swift value/owner routes, and 413 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

413 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining LLL hazard and platform families, then close collision and
presentation consumers.
