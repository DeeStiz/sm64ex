# SM64 Modern Full Swift Twin — M33gv Handoff

## Scope

M33gv migrates `bhvBooCage` as a Swift 6 parent-linked state-machine route.
It preserves in-boo parent transform copying, death-triggered falling, the
initial 60-unit velocity, sparkle and landing effects, ground tangibility,
Mario entry, the 100-frame transition, source hitbox values, and lifecycle
ownership.

## Evidence

- Focused Swift/C Boo-cage fingerprint:
  `0x4a2b92235e4bf5a3` from `script/test_boo_cage.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises the route
  through the production bridge.
- Behavior manifest: `0xf93f70eef4023093`, 534 rows, 323 Swift value/owner
  routes, and 211 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gv-xcode` with `** BUILD SUCCEEDED **`.

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
