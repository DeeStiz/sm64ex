# SM64 Modern Full Swift Twin — M33ca Handoff

Date: 2026-08-18

## Completed slice

M33ca adds `SquishablePlatformBehavior` and a generation-safe Swift owner
route for `bhvSquishablePlatform` (dispatch route 80). The value kernel owns
the canonical sine-derived Y scale and timer progression. The owner bridge
allocates surface-list objects, applies the scale and transform flags, and
prunes generation-safe registrations at unload.

## Validation

- `script/test_squishable_platform.sh` passes with matching Swift/C fingerprint
  `0x5ea6031146ab76b9`.
- `script/test_behavior_dispatch_bridge.sh` passes with the new route exercised
  and the existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xd90440569af0d7c0`, 534 rows, 129 Swift value/owner routes, and 405
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, shell
  syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

405 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact and collision-heavy platform/hazard families,
then expand parent/child and collision-world routes before closing the full
qualification matrix.
