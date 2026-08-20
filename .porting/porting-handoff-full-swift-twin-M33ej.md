# SM64 Modern Full Swift Twin — M33ej Handoff

## Scope

M33ej migrates `bhvCelebrationStarSparkle` into a Swift 6 unimportant-list
sparkle route. It preserves 15-unit vertical movement, graph offset,
animation advance, and frame-12 teardown.

## Evidence

- Focused Swift/C fingerprint: `0x3c269d00bc387018`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xbefee66c4ae7d794`, 534 rows, 204 Swift value/owner
  routes, 330 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ej source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with compact non-flame particle/ambient routes and then broader
global/collision-heavy adapters while keeping per-route Swift/C fingerprints
and full-gate reruns.
