# SM64 Modern Full Swift Twin — M33ha Handoff

## Scope

M33ha migrates `bhvMessagePanel` and `bhvSignOnWall` through one Swift 6
text-surface owner. It preserves 150×80 text hitboxes, interaction
type/subtype, per-tick interaction reset, and the Message Panel versus wall
sign collision-load distinction.

## Evidence

- Focused Swift/C text-surface fingerprint:
  `0xcbdcbe39fe5d7123` from `script/test_text_surface.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises both text
  identities through the production bridge.
- Behavior manifest: `0xb37f15ffad58b15f`, 534 rows, 330 Swift value/owner
  routes, and 204 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33ha-xcode` with `** BUILD SUCCEEDED **`.

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
