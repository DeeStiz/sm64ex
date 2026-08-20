# SM64 Modern Full Swift Twin — M33ce Handoff

Date: 2026-08-18

## Completed slice

M33ce adds `VolcanoSoundLoopBehavior` and a generation-safe owner route for
`bhvVolcanoSoundLoop` (dispatch route 84). The value kernel owns the
persistent `SOUND_ENV_DRONING1` sound intent. The owner bridge tracks the
default-list object and emits one explicit sound effect per native tick while
preserving scheduler/unload semantics.

## Validation

- `script/test_volcano_sound_loop.sh` passes with matching Swift/C fingerprint
  `0x0000000000000001`.
- `script/test_behavior_dispatch_bridge.sh` exercises the route with the
  existing dispatch fingerprint `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xdfbac15995e813e9`, 534 rows, 135 Swift value/owner routes, and 399
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

399 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining compact environmental/hazard families and then migrate
collision-heavy routes with their shared collision-world owners.
