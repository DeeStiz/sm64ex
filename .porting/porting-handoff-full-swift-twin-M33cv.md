# SM64 Modern Full Swift Twin — M33cv Handoff

Date: 2026-08-18

## Completed slice

M33cv adds `WaterSplashSpawnerBehavior` and a generation-safe owner route for
`bhvWaterSplash` (dispatch route 100). Swift owns the source-ordered six-tick
droplet phase, three-droplet allocation per phase tick, five-tick animation
tail, active-particle teardown, and shared migrated droplet children.

## Validation

- `script/test_water_splash_spawner.sh` passes with matching Swift/C
  fingerprint `0x7e0113d5eed1ec4d`.
- `script/test_behavior_dispatch_bridge.sh` verifies parent allocation,
  shared droplet child effects, six-tick/five-tick teardown, and route identity
  with the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xd5036d8c20e8fdc6`, 534 rows, 158 Swift value/owner routes, and 376
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

376 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
