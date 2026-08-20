# SM64 Modern Full Swift Twin — M33cc Handoff

Date: 2026-08-18

## Completed slice

M33cc adds `IdleWaterWaveBehavior` and one generation-safe Swift owner route
for both `bhvIdleWaterWave` and `bhvObjectWaterWave` (dispatch route 82), while
preserving their distinct native loops. Idle waves copy Mario position and
water-level state and clear `ACTIVE_PARTICLE_IDLE_WATER_WAVE` on teardown;
object waves use the independent 16-frame global timer. The owner bridge
supports both default-list and unimportant-list instances, applies transform
flags, and removes deactivated records at the scheduler boundary.

## Validation

- `script/test_idle_water_wave.sh` passes with matching corrected Swift/C
  fingerprint `0xe94c75e5c75e93dd`.
- `script/test_behavior_dispatch_bridge.sh` verifies both identities, list
  routes, animation progression, and exact frame-16 removal with the existing
  dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x66ba4998c339725c`, 534 rows, 142 Swift value/owner routes, and 392
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

401 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact platform, environmental, and hazard families,
then migrate collision-heavy routes and their shared collision-world owners.
