# SM64 Modern Full Swift Twin — M33be Handoff

Date: 2026-08-17

## Completed slice

M33be creates `BBHTiltingTrapPlatformBehavior` and migrates
`bhvBbhTiltingTrapPlatform` through `BBHTiltingTrapPlatformObjectBridge`,
dispatch route 59. Swift owns the US tilt reducer: Mario-on-platform cosine
velocity, return-to-horizontal clamp, the 3,000-unit/16-frame grace window,
and action selection. The owner bridge owns the platform relation and
level-list action/timer/pitch/transform mutation.

## Validation

- New `script/test_bbh_tilting_trap_platform.sh` Swift/C contract passes with
  fingerprint `0x6c6afec03d0d021f`.
- `script/test_behavior_dispatch_bridge.sh` exercises route 59, Mario-on
  cosine tilt, release grace behavior, and pitch mutation while preserving the
  existing dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x93f9b63f3b188fb4`, 534 rows, 101 Swift value/owner routes, and 433 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, strict regenerated Swift 6 Xcode
  Debug build, and source-diff/shell gates pass.

## Open evidence

433 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining live platform behavior queue, with independent Swift/C
contracts and owner-thread routes for each behavior family.
