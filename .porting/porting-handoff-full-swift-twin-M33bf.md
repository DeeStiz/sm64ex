# SM64 Modern Full Swift Twin — M33bf Handoff

Date: 2026-08-17

## Completed slice

M33bf creates `LLLSinkingPlatformBehavior` and one shared owner route for
`bhvLllSinkingRectangularPlatform` and `bhvLllSinkingSquarePlatforms`,
dispatch route 60. Swift owns the shared action helper, rectangular sinking
oscillation, square-platform pitch oscillation, and stable timer state. The
owner bridge owns the two behavior identities and level-list position/action/
pitch/transform mutation.

## Validation

- New `script/test_lll_sinking_platform.sh` Swift/C contract passes with
  fingerprint `0xa935cd578cd8061e`.
- `script/test_behavior_dispatch_bridge.sh` exercises both identities through
  the shared route and verifies rectangular displacement plus square pitch
  state.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x741771aa11ee90ab`, 534 rows, 103 Swift value/owner routes, and 431 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  strict regenerated Swift 6 Xcode Debug build, timebase audit, Metal 4 source
  contract, and source-diff/shell gates pass.

## Open evidence

431 reachable C adapters remain, and the 7,419-shard execution ledger is still
planned rather than fully executed. Native runtime promotion and Metal
validation/capture remain blocked by the host-wide LaunchServices `-10827`
boundary before `NSApplication`/engine startup. Physical visual, thermal,
device-loss, release, and human acceptance remain separate gates.

## Next action

Continue the remaining platform behavior queue, prioritizing shared families
that can be proven with independent Swift/C contracts and owner-thread routes.
