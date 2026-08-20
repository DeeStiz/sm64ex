# SM64 Modern Full Swift Twin — M33gn Handoff

## Scope

M33gn migrates `bhvBreakableBox` and `bhvBreakableBoxSmall` through one Swift
6 value/owner route. The owner preserves the large-box attack break and coin
outcome, small-box hold/thrown/dropped transitions, landing/sliding effects,
break particles, lava/death handling, 810-frame flashing, 900-frame respawn
fence, source hitboxes, model/scale, and collision ownership.

## Evidence

- Focused Swift/C breakable-box fingerprint:
  `0x597e320f93b7a3b4` from `script/test_breakable_box.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises both large
  and small identities through the production bridge and break effects.
- Behavior manifest: `0xf02d6f930ce7fd3a`, 534 rows, 309 Swift value/owner
  routes, and 225 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild; the retained full
  trace replays exactly through the C oracle and rejects deliberate tamper.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gn-xcode` with `** BUILD SUCCEEDED **`.

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

Continue the remaining compact environment/collision families, preserving
source-level child/effect ownership and the full Swift value → owner → C
oracle → dispatch → manifest → live trace → strict-build evidence loop.
