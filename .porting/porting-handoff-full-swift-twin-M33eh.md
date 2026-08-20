# SM64 Modern Full Swift Twin — M33eh Handoff

## Scope

M33eh migrates `bhvFirePiranhaPlant` into a Swift 6 global-state flame actor
route. It preserves hide/grow actions, the active-plant cap, variant scales,
attack/death-spin handling, animation-frame spit, and migrated small-Piranha
flame parameters.

## Evidence

- Focused Swift/C fingerprint: `0x93bc09750aba7202`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x51c07e3cec989886`, 534 rows, 202 Swift value/owner
  routes, 332 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33eh source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with remaining global/collision-heavy flame routes and shard
qualification while keeping per-route Swift/C fingerprints and full-gate
reruns.
