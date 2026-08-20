# SM64 Modern Full Swift Twin — M33cx Handoff

Date: 2026-08-18

## Completed slice

M33cx extends the shared `WaterSplashBehavior` owner route (dispatch route 96)
to `bhvObjectWaterSplash`, the unimportant six-frame splash emitted by
small-water-wave and bubble consumers. Swift owns the child animation/lifetime
and attaches spawned object splashes through the generation-safe bridge.

## Validation

- `script/test_water_splash.sh` passes with matching Swift/C fingerprint
  `0xca741cdc72052b3d` for bubble, droplet, and object splash variants.
- `script/test_behavior_dispatch_bridge.sh` verifies the object-splash identity
  and small-water-wave child attachment with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xa846fa6aa355aa39`, 534 rows, 159 Swift value/owner routes, and 375
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

375 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
