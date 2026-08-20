# SM64 Modern Full Swift Twin — M33ch Handoff

Date: 2026-08-18

## Completed slice

M33ch adds `SlidingPlatform2Behavior` and a generation-safe owner route for
`bhvSlidingPlatform2` (dispatch route 87). Swift owns packed parameter
decoding, horizontal/vertical variant selection, endpoint clamping, speed
reversal, timer cadence, and position operations. The owner preserves the
source home position, applies movement/transform fields, and retains
generation-safe state across ticks.

## Validation

- `script/test_sliding_platform_2.sh` passes with matching Swift/C fingerprint
  `0xeb26a71e2cef7135`.
- `script/test_behavior_dispatch_bridge.sh` exercises the route with the
  existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x66ba4998c339725c`, 534 rows, 142 Swift value/owner routes, and 392
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

392 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact platform/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
