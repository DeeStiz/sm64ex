# SM64 Modern Full Swift Twin — M33dj Handoff

Date: 2026-08-18

## Completed slice

M33dj adds the mist-particle family: `bhvMistParticleSpawner`,
`bhvWhitePuff1`, and `bhvWhitePuff2` (dispatch routes 110/109). Swift owns
parent flag clear/teardown, child allocation, puff-one offset/scale/opacity/
deletion, and puff-two animation lifetime.

## Validation

- `script/test_mist_particle.sh` passes with matching Swift/C fingerprint
  `0xe19d34136d15bfae`.
- `script/test_behavior_dispatch_bridge.sh` verifies parent allocation, both
  child effects, flag clear/teardown, and route identities with the existing
  dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x23bdc42d0f078b52`, 534 rows, 174 Swift value/owner routes, and 360
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

360 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
