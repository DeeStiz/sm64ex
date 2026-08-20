# SM64 Modern Full Swift Twin — M33di Handoff

Date: 2026-08-18

## Completed slice

M33di adds `BreathParticleSpawnerBehavior` and a generation-safe owner route
for `bhvBreathParticleSpawner` (dispatch route 108). Swift owns eight
source-ordered water-mist child spawns, breath-particle flag clear, delayed
parent teardown, and shared mist ownership.

## Validation

- `script/test_breath_particle_spawner.sh` passes with matching Swift/C
  fingerprint `0x7acd5b1c686e6243`.
- `script/test_behavior_dispatch_bridge.sh` verifies parent/child allocation,
  shared mist effects, flag clear, delayed teardown, and route identity with
  the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x9b7f64537a1a69fd`, 534 rows, 171 Swift value/owner routes, and 363
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

363 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
