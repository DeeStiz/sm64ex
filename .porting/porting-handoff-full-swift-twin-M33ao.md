# SM64 Modern Full Swift Twin — M33ao Handoff

Date: 2026-08-17

## Completed slice

M33ao migrates the reachable `bhvArrowLift` identity into the Swift owner
dispatcher. `SM64ArrowLiftBehavior` remains the value kernel for the exact
idle/away/back action gate, perpendicular movement yaw, 12-unit movement,
384-unit displacement clamp, and platform relation. `SM64ArrowLiftObjectBridge`
owns level-list registration, generation-safe lifetime, displacement storage,
platform input, record velocity/position/action/timer mutation, and transform
flags.

The behavior identity is `0x6268765f61726c66` (`bhv_arlf`) and dispatch route 42.

## Validation

- Existing `script/test_arrow_lift.sh` Swift/C value contract passes.
- `script/test_behavior_dispatch_bridge.sh` passes and exercises the ArrowLift
  identity, two-tick action transition, movement output, and owner record
  mutation while preserving the existing dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xbb2a460a474844f5`, 534 rows, 82 Swift value/owner routes, and 452 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `make abi-smoke`, strict regenerated
  Swift 6 Xcode Debug build, timebase audit, Metal 4 source contract, and
  `git diff --check` pass.

## Open evidence

The full behavior inventory is not closed: 452 reachable C adapters remain,
and route-shard execution is still incomplete. Native runtime promotion and
Metal validation/capture remain blocked by the host-wide LaunchServices
`-10827` boundary before `NSApplication`/engine startup. Physical visual,
thermal, device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the adapter queue with the next existing Swift kernel/owner seam,
then execute the complete 7,419-shard schema-4 ledger once runtime authority
can launch on a healthy AppKit host.
