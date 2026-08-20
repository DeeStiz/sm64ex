# SM64 Modern Full Swift Twin — M33db Handoff

Date: 2026-08-18

## Completed slice

M33db adds `PiranhaPlantWakingBubbleBehavior` and a generation-safe owner
route for `bhvPiranhaPlantWakingBubbles` (dispatch route 102). Swift owns
explicit initial yaw/forward/vertical velocity inputs, fvel movement, and the
ten-frame unimportant-child lifetime.

## Validation

- `script/test_piranha_waking_bubble.sh` passes with matching Swift/C
  fingerprint `0xeedc64c08e2c2ae2`.
- `script/test_behavior_dispatch_bridge.sh` verifies initial movement, route
  identity, and ten-frame teardown with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x11c82b5f755f1c1c`, 534 rows, 161 Swift value/owner routes, and 373
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

373 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
