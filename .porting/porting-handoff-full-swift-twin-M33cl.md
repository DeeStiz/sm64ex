# SM64 Modern Full Swift Twin — M33cl Handoff

Date: 2026-08-18

## Completed slice

M33cl adds `WaterAirBubbleBehavior` and a generation-safe owner route for
`bhvWaterAirBubble` (dispatch route 91). Swift owns the first-30-frame
intangible rise, forward-velocity approach, Mario-facing yaw, scale pulse,
random-jitter inputs, water-boundary teardown, interaction teardown, sound
intent, and 30-child bubble spawn intent. The owner emits explicit unmigrated
`bhvBubbleMaybe` children and prunes bubble state at the scheduler boundary.

## Validation

- `script/test_water_air_bubble.sh` passes with matching Swift/C fingerprint
  `0xef59d871e236c6d8`.
- `script/test_behavior_dispatch_bridge.sh` verifies interaction teardown and
  30-child allocation with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x86d580387f6d1293`, 534 rows, 147 Swift value/owner routes, and 387
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

387 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact water/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
