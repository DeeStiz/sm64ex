# SM64 Modern Full Swift Twin — M33ci Handoff

Date: 2026-08-18

## Completed slice

M33ci adds `SmallWaterWaveBehavior` and a generation-safe owner route for
`bhvSmallWaterWave` (dispatch route 88). Swift owns the script/native +7 rise,
sine scale values, angle progression, water-level deactivation, interaction
deletion, and 60-frame script retirement. The owner emits the explicit
unmigrated splash child when the native loop crosses water level. This pass
also corrects the earlier idle/object water-wave conflation: idle waves now
copy Mario position/water level and clear `ACTIVE_PARTICLE_IDLE_WATER_WAVE`,
while object waves retain their independent 16-frame timer loop.

## Validation

- `script/test_small_water_wave.sh` passes with matching Swift/C fingerprint
  `0x3d732d26085342da`.
- `script/test_idle_water_wave.sh` passes with corrected fingerprint
  `0xe94c75e5c75e93dd`.
- `script/test_behavior_dispatch_bridge.sh` verifies small-wave rise,
  water-crossing splash allocation, and corrected idle/object routes with the
  existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xcdc77a2c5de41780`, 534 rows, 143 Swift value/owner routes, and 391
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

391 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact water/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
