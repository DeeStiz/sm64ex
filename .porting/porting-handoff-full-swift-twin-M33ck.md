# SM64 Modern Full Swift Twin — M33ck Handoff

Date: 2026-08-18

## Completed slice

M33ck adds `RotatingExclamationMarkBehavior` and a generation-safe
parent-linked owner route for `bhvRotatingExclamationMark` (dispatch route 90).
Swift owns the authored 0x800 yaw increment and parent-action lifetime rule.
The owner retains the stable parent link, applies transform fields, and
removes the child when the exclamation box leaves action 1.

## Validation

- `script/test_rotating_exclamation_mark.sh` passes with matching Swift/C
  fingerprint `0x64ad5ae55aeff75d`.
- `script/test_behavior_dispatch_bridge.sh` verifies active yaw progression
  and parent-action deletion with the existing dispatch fingerprint
  `0x681ceb2358bf2e21`.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xda36fd8ed3111498`, 534 rows, 146 Swift value/owner routes, and 388
  explicit C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, `script/test_route_shard_replay.sh`,
  `script/test_timebase_audit.sh`, `script/test_metal4_contract.sh`, changed
  shell syntax checks, `git diff --check`, and the regenerated strict Swift 6
  Xcode Debug build pass.

## Open evidence

388 reachable C adapters remain, and the 7,419-shard execution ledger is
still planned rather than fully executed. Native runtime promotion and live
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining compact hazard/environment families, then migrate
collision-heavy routes and shared collision-world owners.
