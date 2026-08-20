# SM64 Modern Full Swift Twin — M33bz Handoff

Date: 2026-08-18

## Completed slice

M33bz adds `LllFloatingWoodBridgeBehavior` and a parent/child owner route for
`bhvLllFloatingWoodBridge` and `bhvLllWoodPiece`, dispatch route 79. Swift
owns distance-triggered bridge actions and oscillating wood-piece position/
timer state. The owner bridge allocates the three source-order pieces, keeps
stable parent links, and applies parent-action deletion/unload.

## Validation

- New `script/test_lll_floating_wood_bridge.sh` Swift/C contract passes with
  fingerprint `0x57cd8e848459e5bd`.
- `script/test_behavior_dispatch_bridge.sh` verifies bridge activation, three
  child allocations, distance exit, and child deletion.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xeb5ad8f5ba75bf12`, 534 rows, 128 Swift value/owner routes, and 406 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

406 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining bridge/platform/hazard families, then close collision and
presentation consumers.
