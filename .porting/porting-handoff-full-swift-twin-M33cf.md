# SM64 Modern Full Swift Twin — M33cf Handoff

Date: 2026-08-18

## Completed slice

M33cf adds `TumblingBridgeBehavior` and a shared generation-safe owner route
for `bhvWfTumblingBridge`, `bhvBbhTumblingBridge`, `bhvLllTumblingBridge`,
and `bhvTumblingBridgePlatform` (dispatch route 85). Swift owns the parent
action/visibility/variant reducer and child roll/pitch acceleration, gravity,
floor exit, and parent-exit deletion. The owner allocates nine source-order
platform children, keeps parent links, and preserves spawner-before-surface
scheduler ordering. It also removes the prior incorrect manifest mapping of
LLL tumbling children to the Bully bridge.

## Validation

- `script/test_tumbling_bridge.sh` passes with matching Swift/C fingerprint
  `0x8a7c746dcafb01e0`.
- `script/test_behavior_dispatch_bridge.sh` verifies all four identities,
  nine-child allocation, distance hiding, activation, and parent-exit deletion
  with the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xae5502809f33c0a7`, 534 rows, 138 Swift value/owner routes, and 396
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

396 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact platform/environment/hazard families, then
migrate collision-heavy routes and their shared collision-world owners.
