# SM64 Modern Full Swift Twin — M33gl Handoff

## Scope

M33gl migrates the hidden-one-up family as one Swift 6 value/owner route:
`bhvHidden1up`, `bhvHidden1upTrigger`, `bhvHidden1upInPole`,
`bhvHidden1upInPoleTrigger`, and `bhvHidden1upInPoleSpawner`. The owner
preserves trigger-count gating, hidden/reveal/tangible transitions, the
37-frame rise and sparkle cadence, away/toward-Mario movement, 30-frame
disappearance, trigger consumption, and the pole spawner's one-up plus two
trigger child allocation.

## Evidence

- Focused Swift/C hidden-one-up fingerprint:
  `0x471482b44d925ead` from `script/test_hidden_one_up.sh`.
- Dispatch smoke fingerprint remains `0x681ceb2358bf2e21`; it exercises hidden
  and trigger identities plus the three-child pole-spawner allocation through
  the production dispatch bridge.
- Behavior manifest: `0x9e5ba7d19c0efce1`, 534 rows, 302 Swift value/owner
  routes, and 232 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild with the new owners;
  the retained full live trace continues to replay exactly through the C
  oracle and deliberate tamper rejection.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gl-xcode` with `** BUILD SUCCEEDED **`.

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

Continue the compact environment and collision families, prioritizing source
behaviors with one owner-thread state machine and explicit child/effect
intent. Keep each route on the Swift value → owner → C oracle → dispatch →
manifest → live trace → strict build loop, and keep full-game shard and native
GUI gates separate until the host LaunchServices boundary is repaired.
