# SM64 Modern Full Swift Twin — M33ct Handoff

Date: 2026-08-18

## Completed slice

M33ct adds `ShallowWaterWaveBehavior` and a generation-safe owner route for
`bhvShallowWaterWave` (dispatch route 99). Swift owns the parent particle flag
lifecycle, five-droplet allocation, explicit water-level/velocity child
inputs, and delayed parent deactivation while reusing the migrated droplet
owner for each child.

## Validation

- `script/test_shallow_water_wave.sh` passes with matching Swift/C fingerprint
  `0x156c000b5e160bc7`.
- `script/test_behavior_dispatch_bridge.sh` verifies parent allocation,
  shared droplet child effects, flag clearing, delayed deactivation, and route
  identity with the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xc629435cdbd7af78`, 534 rows, 156 Swift value/owner routes, and 378
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

378 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
