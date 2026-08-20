# SM64 Modern Full Swift Twin — M33bm Handoff

Date: 2026-08-17

## Completed slice

M33bm creates `LllSinkingRockBlockBehavior` and migrates
`bhvLllSinkingRockBlock` through `LllSinkingRockBlockObjectBridge`, dispatch
route 67. Swift owns the shared stepped-on oscillation helper: canonical
124-unit angle approach, -110-unit sine offset, endpoint detection, and home-Y
projection. The owner bridge owns level-list angle/position/graph/transform
mutation.

## Validation

- New `script/test_lll_sinking_rock_block.sh` Swift/C contract passes with
  fingerprint `0xe8e181158c7912cf`.
- `script/test_behavior_dispatch_bridge.sh` exercises idle and Mario-on
  sinking through route 67 and verifies record position mutation.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x9b98f7335cf79a94`, 534 rows, 112 Swift value/owner routes, and 422 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

422 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the LLL octagonal mesh and remaining platform/hazard families, then
close collision and presentation consumers.
