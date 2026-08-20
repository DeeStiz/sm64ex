# SM64 Modern Full Swift Twin — M33cu Handoff

Date: 2026-08-18

## Completed slice

M33cu extends the shared `ShallowWaterWaveBehavior` owner route (dispatch
route 99) to `bhvShallowWaterSplash`. Swift owns the separate shallow-splash
particle flag and 18-droplet allocation while retaining the wave route's
shared droplet owner and delayed parent teardown.

## Validation

- `script/test_shallow_water_wave.sh` passes with matching Swift/C fingerprint
  `0x2ba834e809509a34` for both five-droplet wave and 18-droplet splash cases.
- `script/test_behavior_dispatch_bridge.sh` verifies both identities, parent
  allocation, shared droplet child effects, and route identity with the
  existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x8ddf16913fde2860`, 534 rows, 157 Swift value/owner routes, and 377
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

377 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
