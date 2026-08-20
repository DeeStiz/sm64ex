# SM64 Modern Full Swift Twin — M33gs Handoff

## Scope

M33gs migrates `bhvClockHourHand` and `bhvClockMinuteHand` through one Swift
6 mechanical owner. It preserves the four-frame default-surface safety delay,
hour/minute roll velocities, painting detection, stop/fast/random/slow speed
thresholds, rotation updates, and the rotation stop edge.

## Evidence

- Focused Swift/C clock-arm fingerprint:
  `0xe2f9dc6a50eec264` from `script/test_clock_arm.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises both hand
  identities through the production bridge.
- Behavior manifest: `0x20925804d9638075`, 534 rows, 319 Swift value/owner
  routes, and 215 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gs-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and
visual/audio/controller/human parity acceptance remain open. The host
LaunchServices database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared` before `AppDelegate`/engine startup, so it is not
counted as game or Metal runtime evidence.

## Next

Continue the remaining compact mechanical and object families while retaining
the full Swift value → owner → C oracle → dispatch → manifest → live trace →
strict-build evidence loop.
