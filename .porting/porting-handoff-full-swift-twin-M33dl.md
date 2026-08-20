# SM64 Modern Full Swift Twin — M33dl Handoff

Date: 2026-08-18

## Completed slice

M33dl adds `TweesterSandParticleBehavior` and a generation-safe owner route
for `bhvTweesterSandParticle` (dispatch route 111). Swift owns explicit initial
random placement/facing, upward motion, yaw/forward-velocity growth, scale,
and the 16-frame lifetime.

## Validation

- `script/test_tweester_sand_particle.sh` passes with matching Swift/C
  fingerprint `0xff9a37ed90d8f611`.
- `script/test_behavior_dispatch_bridge.sh` verifies movement, scale, lifetime,
  and route identity with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xe44e4e266f95fcdc`, 534 rows, 175 Swift value/owner routes, and 359
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

359 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
