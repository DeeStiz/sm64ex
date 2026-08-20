# SM64 Modern Full Swift Twin — M33hb Handoff

## Scope

M33hb migrates `bhvGrandStar` as a Swift 6 cutscene/interaction owner route.
It preserves appearance sparkle/audio edges, 70-frame appearance timing,
launch/arc phases, home-height landing handoff, rotation, 2× scale/graph
offset policy, tangibility, and interaction retirement.

## Evidence

- Focused Swift/C Grand Star fingerprint:
  `0x4ee77eda1fde3209` from `script/test_grand_star.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the route
  through the production bridge.
- Behavior manifest: `0x67dbbe01b5bc53ae`, 534 rows, 331 Swift value/owner
  routes, and 203 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33hb-xcode` with `** BUILD SUCCEEDED **`.

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
