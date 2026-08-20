# SM64 Modern Full Swift Twin — M33hc Handoff

## Scope

M33hc migrates `bhvBetaBowserAnchor` as a Swift 6 Mario-relative collision
owner route. It preserves 30-unit vertical/300-unit forward placement,
debug-radius/height offsets, active hitbox values, and attack intent for
touched non-Mario objects.

## Evidence

- Focused Swift/C beta-anchor fingerprint:
  `0xbc3315ebf35944be` from `script/test_beta_bowser_anchor.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the route
  through the production bridge.
- Behavior manifest: `0xd3ae579b50c58226`, 534 rows, 332 Swift value/owner
  routes, and 202 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33hc-xcode` with `** BUILD SUCCEEDED **`.

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
