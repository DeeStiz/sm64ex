# SM64 Modern Full Swift Twin — M33by Handoff

Date: 2026-08-18

## Completed slice

M33by adds `LllRotatingHexagonalRingBehavior` and an owner route for
`bhvLllRotatingHexagonalRing`, dispatch route 78. Swift owns the ring action
machine, distance-independent Mario/platform transitions, canonical yaw
rotation, and volcano-flame spawn intent. The owner allocates the source C
fallback volcano-flame child explicitly; its behavior remains unmigrated.

## Validation

- New `script/test_lll_rotating_hexagonal_ring.sh` Swift/C contract passes with
  fingerprint `0xf6e1a2aa863378a4`.
- `script/test_behavior_dispatch_bridge.sh` exercises activation, spawn intent,
  parent rotation, and explicit child fallback through route 78.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x537be24a34b0d7be`, 534 rows, 126 Swift value/owner routes, and 408 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

408 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining hazard/platform families and the explicit volcano-flame
fallback, then close collision and presentation consumers.
