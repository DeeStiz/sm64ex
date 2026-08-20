# SM64 Modern Full Swift Twin — M33cg Handoff

Date: 2026-08-18

## Completed slice

M33cg adds `FloatingPlatformBehavior` and a shared generation-safe owner route
for `bhvWdwSquareFloatingPlatform`, `bhvWdwRectangularFloatingPlatform`, and
`bhvJrbFloatingPlatform` (dispatch route 86). Swift owns water-vs-floor home
height, Mario-on-platform tilt, float/velocity approach, sine bob timer, and
face-angle mutation. The owner stores the variant-specific water/floor inputs,
applies the surface transform, and preserves scheduler state across ticks.

## Validation

- `script/test_floating_platform.sh` passes with matching Swift/C fingerprint
  `0xe004d03fa0b6aaa0`.
- `script/test_behavior_dispatch_bridge.sh` verifies all three identities and
  water/floor route outputs with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x99c3328373e59344`, 534 rows, 141 Swift value/owner routes, and 393
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

393 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact platform/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
