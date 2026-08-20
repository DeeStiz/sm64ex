# SM64 Modern Full Swift Twin — M33aq Handoff

Date: 2026-08-17

## Completed slice

M33aq migrates `bhvSeesawPlatform` through
`SM64SeesawPlatformObjectBridge`, dispatch route 44. The existing
`SM64SeesawPlatformBehavior` kernel owns the exact platform relation gate,
canonical angle rotation, signed pitch-velocity update and clamp,
return-to-zero oscillator, and rocking-sound intent. The owner bridge owns
the copied float pitch velocity, collision-model behavior byte, level-list
registration, platform relation input, record mutation, and transform flags.

## Validation

- Existing `script/test_seesaw_platform.sh` Swift/C value contract passes with
  fingerprint `0x84664f609b940e32`.
- `script/test_behavior_dispatch_bridge.sh` exercises the seesaw identity,
  shared route selection, pitch update, and owner record mutation while
  preserving the dispatch fingerprint.
- `script/test_behavior_manifest.sh` passes with fingerprint
  `0x4a137cf8b4a93c53`, 534 rows, 86 Swift value/owner routes, and 448 explicit
  C adapters.
- `script/test_behavior_coverage.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, `make -j8`, strict regenerated Swift 6 Xcode Debug build,
  route replay, timebase audit, Metal 4 source contract, and `git diff --check`
  pass.

## Open evidence

448 reachable C adapters remain, and route-shard execution is incomplete.
Native runtime promotion and Metal validation/capture remain blocked by the
host-wide LaunchServices `-10827` boundary before `NSApplication`/engine
startup. Physical visual, thermal, device-loss, release, and human acceptance
remain separate gates.

## Next action

Continue the remaining Swift-kernel-backed platform queue, then execute the
complete 7,419-shard schema-4 ledger once runtime authority can launch on a
healthy AppKit host.
