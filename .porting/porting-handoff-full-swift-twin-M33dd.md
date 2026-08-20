# SM64 Modern Full Swift Twin — M33dd Handoff

Date: 2026-08-18

## Completed slice

M33dd adds the shared `WaveTrailBehavior` owner route (dispatch route 104) for
`bhvWaveTrail` and `bhvObjectWaveTrail`. Swift owns water-level placement,
two-tick animation cadence, alternate-frame deletion, shrink state, and the
Mario-only active-particle teardown.

## Validation

- `script/test_wave_trail.sh` passes with matching Swift/C fingerprint
  `0xb0261387b6fce0a1`.
- `script/test_behavior_dispatch_bridge.sh` verifies both identities,
  placement, and alternate-frame deletion with the existing dispatch
  fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x1df2437891d67125`, 534 rows, 164 Swift value/owner routes, and 370
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

370 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
