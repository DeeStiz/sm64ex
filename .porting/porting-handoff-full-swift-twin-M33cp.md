# SM64 Modern Full Swift Twin — M33cp Handoff

Date: 2026-08-18

## Completed slice

M33cp adds `WaterMist2Behavior` and a generation-safe owner route for
`bhvWaterMist2` (dispatch route 95). Swift owns the authored water-level
placement and opacity derivation; the owner preserves the object home
transform and unimportant-list lifecycle.

## Validation

- `script/test_water_mist_2.sh` passes with matching Swift/C fingerprint
  `0x5b484a3470865f4c`.
- `script/test_behavior_dispatch_bridge.sh` verifies water-level placement and
  opacity output with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x295dd78f53930cf1`, 534 rows, 151 Swift value/owner routes, and 383
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

383 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact water/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
