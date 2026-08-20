# SM64 Modern Full Swift Twin — M33ar Handoff

Date: 2026-08-17

## Completed slice

M33ar migrates `bhvSwingPlatform` through
`SM64SwingPlatformObjectBridge`, dispatch route 45. The existing
`SM64SwingPlatformBehavior` kernel owns initialized accumulated angle, signed
speed update, render-facing roll truncation, and angle-velocity output. The
owner bridge owns copied angle/speed state, level-list registration, roll and
angle-velocity record mutation, and transform flags.

## Validation

- Existing `script/test_swing_platform.sh` Swift/C value contract passes with
  fingerprint `0xc38755874141aa35`.
- `script/test_behavior_dispatch_bridge.sh` exercises the swing identity,
  route selection, first signed speed step, and owner record mutation while
  preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x8e4dacee8f942e1d`, 534 rows, 87 Swift value/owner routes, and 447 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

447 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining Swift-kernel-backed platform queue, then execute the
complete 7,419-shard schema-4 ledger once runtime authority can launch on a
healthy AppKit host.
