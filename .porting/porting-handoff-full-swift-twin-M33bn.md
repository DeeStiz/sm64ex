# SM64 Modern Full Swift Twin — M33bn Handoff

Date: 2026-08-17

## Completed slice

M33bn creates `LllMovingOctagonalMeshBehavior` and migrates
`bhvLllMovingOctagonalMeshPlatform` through
`LllMovingOctagonalMeshObjectBridge`, dispatch route 68. Swift owns both
authored movement tables, sequence/timer transitions, Mario-gated command 4,
approach-to-speed, yaw projection, fvel X/Z movement, and stepped-on vertical
offset/rotation state. The owner bridge owns level-list state and transform/
velocity mutation.

## Validation

- New `script/test_lll_moving_octagonal_mesh.sh` Swift/C contract passes with
  fingerprint `0x196e000b71f0f852`.
- `script/test_behavior_dispatch_bridge.sh` exercises route 68 initialization,
  sequence state, yaw command, and owner position mutation.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x472e722cd491e91c`, 534 rows, 113 Swift value/owner routes, and 421 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

421 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining platform/hazard families, then close collision,
presentation, and whole-engine authority consumers.
