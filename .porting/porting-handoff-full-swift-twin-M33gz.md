# SM64 Modern Full Swift Twin — M33gz Handoff

## Scope

M33gz migrates `bhvPlaysMusicTrackWhenTouched` as a Swift 6 distance-gated
audio owner route. It preserves the strict 200-unit boundary, one-shot
puzzle-jingle edge, action latch, timer progression, and default-list
ownership.

## Evidence

- Focused Swift/C music-touch fingerprint:
  `0x931eddc04c6c6167` from `script/test_music_touch.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the route
  through the production bridge.
- Behavior manifest: `0xb50044bba999b59b`, 534 rows, 328 Swift value/owner
  routes, and 206 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gz-xcode` with `** BUILD SUCCEEDED **`.

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
