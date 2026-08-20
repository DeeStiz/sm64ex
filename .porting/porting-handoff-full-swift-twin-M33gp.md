# SM64 Modern Full Swift Twin — M33gp Handoff

## Scope

M33gp migrates `bhvOrangeNumber` as a Swift 6 counter/effect owner route. It
preserves behavior-byte animation selection, the 26-unit initial rise,
2-unit gravity, -21/14 bounce clamp, 35-frame sparkle/expiry edge, and
golden-sparkle child ownership.

## Evidence

- Focused Swift/C orange-number fingerprint:
  `0xf40a1d75f5001d52` from `script/test_orange_number.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the route
  through the production behavior bridge.
- Behavior manifest: `0x1dbb88a3ad5f3973`, 534 rows, 311 Swift value/owner
  routes, and 223 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gp-xcode` with `** BUILD SUCCEEDED **`.

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

Continue the remaining compact object/environment families while retaining
the complete Swift value → owner → C oracle → dispatch → manifest → live
trace → strict-build evidence loop.
