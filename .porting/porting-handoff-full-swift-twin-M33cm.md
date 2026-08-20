# SM64 Modern Full Swift Twin — M33cm Handoff

Date: 2026-08-18

## Completed slice

M33cm adds `ObjectBubbleBehavior` and a generation-safe owner route for
`bhvObjectBubble` (dispatch route 92). Swift owns the water-boundary test and
splash spawn intent. The owner marks the bubble for end-of-frame removal and
emits explicit unmigrated `bhvBubbleSplash` fallback children.

## Validation

- `script/test_object_bubble.sh` passes with matching Swift/C fingerprint
  `0xe71868dec0bbb6e3`.
- `script/test_behavior_dispatch_bridge.sh` verifies water crossing, splash
  allocation, and removal with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x322382a5b2bd8398`, 534 rows, 148 Swift value/owner routes, and 386
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

386 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact water/environment/hazard families, then migrate
collision-heavy routes and shared collision-world owners.
