# SM64 Modern Full Swift Twin — M33br Handoff

Date: 2026-08-17

## Completed slice

M33br adds `WfTowerPlatformGroupBehavior` and a parent spawner route for
`bhvTowerPlatformGroup`, dispatch route 71. Swift owns the group height/action
machine; the owner bridge allocates the authored six solid/sliding children
and final elevator child in source order through the existing owner bridges,
then fences the group for end-of-frame teardown.

## Validation

- New `script/test_wf_tower_platform_group.sh` Swift/C contract passes with
  fingerprint `0x0f916f8c7ed47f32`.
- `script/test_behavior_dispatch_bridge.sh` verifies height-triggered group
  transition, seven child allocations, existing child-route effects, and
  parent unload.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x7473d9a4b5f2c752`, 534 rows, 118 Swift value/owner routes, and 416 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

416 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining multi-child platform/hazard families, then close collision,
presentation, and whole-engine authority consumers.
