# SM64 Modern Full Swift Twin — M33bl Handoff

Date: 2026-08-17

## Completed slice

M33bl creates `WdwExpressElevatorBehavior` and a shared owner route for
`bhvWdwExpressElevator` and its static `bhvWdwExpressElevatorPlatform`
identity, dispatch route 66. Swift owns the express elevator action/timer
machine, -20/+10 movement, home clamp, Mario platform gate, and sound intent;
the static identity is an explicit no-op. The owner bridge owns level-list
action/timer/position/velocity/transform mutation.

## Validation

- New `script/test_wdw_express_elevator.sh` Swift/C contract passes with
  fingerprint `0x87df032d5fc88546`.
- `script/test_behavior_dispatch_bridge.sh` exercises both identities through
  route 66 and verifies start, descent, and static no-op behavior.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x9f8914cb7d696934`, 534 rows, 111 Swift value/owner routes, and 423 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

423 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining platform and hazard families, then close collision,
presentation, and whole-engine authority consumers.
