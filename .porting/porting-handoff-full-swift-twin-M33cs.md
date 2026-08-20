# SM64 Modern Full Swift Twin — M33cs Handoff

Date: 2026-08-18

## Completed slice

M33cs adds `WindBehavior` and a generation-safe owner route for `bhvWind`
(dispatch route 98). Swift owns explicit random placement, pitch/yaw
initialization, forward-velocity movement, face-angle jitter, opacity/scale
state, and the ten-tick lifetime.

## Validation

- `script/test_wind.sh` passes with matching Swift/C fingerprint
  `0x11aada993961bfdf`.
- `script/test_behavior_dispatch_bridge.sh` verifies wind movement, opacity,
  and identity routing with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xb89cf9fffa4283bf`, 534 rows, 155 Swift value/owner routes, and 379
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

379 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
