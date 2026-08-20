# SM64 Modern Full Swift Twin — M33cr Handoff

Date: 2026-08-18

## Completed slice

M33cr adds `BubbleMaybeBehavior` and a generation-safe owner route for
`bhvBubbleMaybe` (dispatch route 97). Swift owns authored initial offsets,
per-tick random movement inputs, sinusoidal billboarding scale, phase/rate
progression, and the 60-frame child lifetime. The water-air bubble owner now
attaches all 30 spawned children to this route.

## Validation

- `script/test_bubble_maybe.sh` passes with matching Swift/C fingerprint
  `0xa62ff9e3ae021fcc`.
- `script/test_behavior_dispatch_bridge.sh` verifies direct bubble-maybe
  output, route identity, and all 30 water-air-bubble child attachments with
  the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x61d0a1e40da60504`, 534 rows, 154 Swift value/owner routes, and 380
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

380 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact water/environment/hazard family, then migrate
collision-heavy routes and shared collision-world owners.
