# SM64 Modern Full Swift Twin — M33at Handoff

Date: 2026-08-17

## Completed slice

M33at migrates `bhvTTCMovingBar` through
`SM64TTCMovingBarObjectBridge`, dispatch route 47. The existing
`SM64TTCMovingBarBehavior` kernel owns initialization, delay/stopped-timer
gates, pull-back/extend/retract actions, offset/speed evolution, random pause
and fakeout inputs, and perpendicular move yaw. The owner bridge owns copied
state, behavior settings, home-relative position projection, velocity
derivation, action/timer reset boundaries, and level-list record mutation.

Random values are explicit owner inputs with deterministic defaults in this
focused route; live RNG trace injection remains part of the later full-route
qualification gate.

## Validation

- Existing `script/test_ttc_moving_bar.sh` Swift/C value contract passes with
  fingerprint `0x189e979eb38062a6`.
- `script/test_behavior_dispatch_bridge.sh` exercises the TTC identity,
  timer-crossing transition, pull-back speed, perpendicular yaw, and owner
  record mutation while preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0xf0db08da233c763c`, 534 rows, 89 Swift value/owner routes, and 445 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

445 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining TTC/platform kernel queue, then execute the complete
7,419-shard schema-4 ledger once runtime authority can launch on a healthy
AppKit host.
