# SM64 Modern Full Swift Twin — M33cb Handoff

Date: 2026-08-18

## Completed slice

M33cb adds `LllDrawbridgeBehavior` and a shared generation-safe owner route
for `bhvLllDrawbridgeSpawner` and `bhvLllDrawbridge` (dispatch route 81). The
value kernel preserves the signed 16-bit roll thresholds, 8-frame global-timer
cadence, action transitions, and sound intents. The owner bridge allocates
the two source-order surface halves at the default-list spawner boundary,
marks the spawner for end-of-frame unload, and dispatches the children on the
next surface tick in the same scheduler ordering as the C behavior.

## Validation

- `script/test_lll_drawbridge.sh` passes with matching Swift/C fingerprint
  `0x00a9bbb5dd67a85c`.
- `script/test_behavior_dispatch_bridge.sh` verifies both identities, parent
  allocation, deferred child dispatch, and spawner unload with the existing
  dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x93f173ac9312c2bf`, 534 rows, 131 Swift value/owner routes, and 403
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

403 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact platform/hazard families, then migrate the
collision-heavy routes and their shared collision-world owners.
