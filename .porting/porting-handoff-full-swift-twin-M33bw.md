# SM64 Modern Full Swift Twin — M33bw Handoff

Date: 2026-08-18

## Completed slice

M33bw adds `BitfsSinkingPlatformBehavior` and a shared owner route for
`bhvBitfsSinkingPlatforms` and `bhvBitfsSinkingCagePlatform`, dispatch route
76. Swift owns the authored platform/cage sine offsets and timer progression;
the owner owns level-list position mutation and the explicit cage parameter.
The cage’s `bhvDddMovingPole` child remains a separate fail-closed C seam.

## Validation

- New `script/test_bitfs_sinking_platform.sh` Swift/C contract passes with
  fingerprint `0x958fce35c8bc9b45`.
- `script/test_behavior_dispatch_bridge.sh` exercises both identities through
  route 76 and verifies platform/cage position outputs.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x7e4ea872ef81327a`, 534 rows, 124 Swift value/owner routes, and 410 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `script/test_live_route_oracle.sh full`, route-shard replay, strict
  regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and `git diff --check` pass.

## Open evidence

410 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue remaining platform/hazard and child seams, then close collision and
presentation consumers.
