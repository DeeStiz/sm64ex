# SM64 Modern Full Swift Twin — M33cz Handoff

Date: 2026-08-18

## Completed slice

M33cz adds `BubbleParticleSpawnerBehavior` and a generation-safe owner route
for `bhvBubbleParticleSpawner` (dispatch route 101). Swift owns the explicit
delay, bubble particle-flag clear, parent deactivation, and child allocation;
the spawned `bhvSmallWaterWave` is attached to its existing Swift owner.

## Validation

- `script/test_bubble_particle_spawner.sh` passes with matching Swift/C
  fingerprint `0x5bd294135d7f1822`.
- `script/test_behavior_dispatch_bridge.sh` verifies delayed parent spawn,
  particle-flag/deactivation state, child attachment, and route identity with
  the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xabe0f97b38b74f78`, 534 rows, 160 Swift value/owner routes, and 374
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

374 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
