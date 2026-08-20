# SM64 Modern Full Swift Twin — M33cn Handoff

Date: 2026-08-18

## Completed slice

M33cn adds `WaterDropletBehavior` and a generation-safe owner route for
`bhvWaterDroplet` (dispatch route 93). Swift owns gravity, water re-entry,
timeout and invalid-water teardown, interaction deletion, and splash-child
intent. The owner preserves unimportant-list lifecycle and emits explicit
unmigrated `bhvWaterDropletSplash` fallback children.

## Validation

- `script/test_water_droplet.sh` passes with matching Swift/C fingerprint
  `0x0dc920f91610be97`.
- `script/test_behavior_dispatch_bridge.sh` verifies gravity, water re-entry,
  splash allocation, and removal with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x2515d7250f7168b3`, 534 rows, 149 Swift value/owner routes, and 385
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

385 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact water/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
