# SM64 Modern Full Swift Twin — M33gm Handoff

## Scope

M33gm extends the shared hidden-one-up Swift 6 value/owner route with the
regular `bhv1Up`, `bhv1upWalking`, `bhv1upRunningAway`, `bhv1upSliding`, and
`bhv1upJumpOnApproach` identities. The owner preserves stationary collection,
37-frame appearance/rise, walking timeout, away movement, approach gates,
sparkle cadence, tangible transitions, and disappearance fences.

## Evidence

- Expanded focused Swift/C hidden-one-up fingerprint:
  `0x33249b91023d6e53` from `script/test_hidden_one_up.sh`.
- Dispatch smoke fingerprint: `0x681ceb2358bf2e21`; it exercises all five
  regular identities and the existing hidden/trigger/spawner identities.
- Behavior manifest: `0xcca6724933d0cf63`, 534 rows, 307 Swift value/owner
  routes, and 227 explicit C adapters.
- `script/test_behavior_coverage.sh` passes with 57 opcode classes and 547
  native callbacks inventoried.
- Engine-runtime and live-route oracle scripts rebuild with the expanded owner;
  the retained full trace continues exact C replay and deliberate tamper
  rejection.
- Route-shard replay, timebase audit, Metal 4 source contract, shell syntax,
  and `git diff --check` pass.
- Regenerated strict Swift 6/macOS 27 Debug build passes in
  `build/sm64-modern-m33gm-xcode` with `** BUILD SUCCEEDED **`.

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

Continue with the next compact collision/environment family, preserving the
source behavior's child/effect ownership and adding every identity to the
same Swift value → owner → C oracle → dispatch → manifest → live trace →
strict-build loop.
