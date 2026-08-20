# SM64 Modern Full Swift Twin — M33dg Handoff

Date: 2026-08-18

## Completed slice

M33dg adds the shared `WaterParticleBehavior` owner route (dispatch route 106)
for `bhvSmallParticle`, `bhvSmallParticleSnow`, and
`bhvSmallParticleBubbles`. Swift owns initialization offsets/phases, per-tick
movement and oscillating scale, variant lifetime, water-crossing deletion, and
object-water-splash child attachment.

## Validation

- `script/test_water_particle.sh` passes with matching Swift/C fingerprint
  `0xbfefc9eb63220ccb`.
- `script/test_behavior_dispatch_bridge.sh` verifies all three identities,
  movement/scale variants, and shared route identity with the existing dispatch
  fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x0fa5bee7f6536d0e`, 534 rows, 169 Swift value/owner routes, and 365
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

365 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
