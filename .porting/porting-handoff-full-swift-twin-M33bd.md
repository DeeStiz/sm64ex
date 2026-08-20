# SM64 Modern Full Swift Twin — M33bd Handoff

Date: 2026-08-17

## Completed slice

M33bd creates `StaticCheckeredPlatformBehavior` and migrates
`bhvStaticCheckeredPlatform` through `StaticCheckeredPlatformObjectBridge`,
dispatch route 58. Swift owns the debug mode reducer: reset, set-angle,
continuous velocity, and rotate modes. The owner bridge owns copied debug-row
inputs and level-list angle/velocity/transform mutation, so the Swift path
does not read C's process-global `gDebugInfo`.

## Validation

- New `script/test_static_checkered_platform.sh` Swift/C contract passes with
  fingerprint `0x753404c234d2e779`.
- `script/test_behavior_dispatch_bridge.sh` exercises route 58 and mode-3
  angle/velocity mutation while preserving the existing dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x63f91b2c8ee1dd97`, 534 rows, 100 Swift value/owner routes, and 434 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, strict regenerated Swift 6 Xcode
  Debug build, and source-diff/shell gates pass.

## Open evidence

434 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining platform behavior queue, prioritizing live gameplay
platforms and preserving an independent Swift/C contract plus owner route for
each slice.
