# SM64 Modern Full Swift Twin — M33co Handoff

Date: 2026-08-18

## Completed slice

M33co adds `WaterMistBehavior` and a generation-safe owner route for
`bhvWaterMist` (dispatch route 94). Swift owns authored initial/random
translation inputs, forward movement, opacity decay, scale derivation, and
lifetime teardown. The owner preserves unimportant-list lifecycle and
transform state.

## Validation

- `script/test_water_mist.sh` passes with matching Swift/C fingerprint
  `0xa7d3721a6c9c17b8`.
- `script/test_behavior_dispatch_bridge.sh` verifies movement/opacity output
  with the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xb144d755397d76eb`, 534 rows, 150 Swift value/owner routes, and 384
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

384 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact water/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
