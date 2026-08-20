# SM64 Modern Full Swift Twin — M33dc Handoff

Date: 2026-08-18

## Completed slice

M33dc adds `PiranhaPlantBubbleBehavior` and a generation-safe owner route for
`bhvPiranhaPlantBubble` (dispatch route 103). Swift owns source-relative
parent transform, idle/grow-shrink/burst action states, active-radius/sleeping
gates, scale curve, and 15 waking-bubble children.

## Validation

- `script/test_piranha_plant_bubble.sh` passes with matching Swift/C
  fingerprint `0xc251b628ccd714f3`.
- `script/test_behavior_dispatch_bridge.sh` verifies source-relative transform,
  grow scale, burst transition, 15-child allocation, and route identity with
  the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x588d15204cce5953`, 534 rows, 162 Swift value/owner routes, and 372
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

372 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
