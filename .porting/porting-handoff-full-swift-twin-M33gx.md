# SM64 Modern Full Swift Twin — M33gx Handoff

## Scope

M33gx migrates `bhvBooInCastle` as a Swift 6 room/opacity owner route. It
preserves the 12-star gate, room-1 appearance, opacity 180, 2× scale,
1,000-unit laugh transition, home-target movement, opacity fade past Z=-5000,
and cross-room reset.

## Evidence

- Focused Swift/C castle-Boo fingerprint:
  `0x87a7c25160ed3ec6` from `script/test_boo_in_castle.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the route
  through the production bridge.
- Behavior manifest: `0x79d7d43594c341c7`, 534 rows, 326 Swift value/owner
  routes, and 208 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gx-xcode` with `** BUILD SUCCEEDED **`.

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

Continue the remaining compact object and mechanical families while retaining
the full Swift value → owner → C oracle → dispatch → manifest → live trace →
strict-build evidence loop.
