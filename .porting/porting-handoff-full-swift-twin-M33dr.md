# SM64 Modern Full Swift Twin — M33dr Handoff

## Scope

M33dr migrates `bhvWhitePuffExplosion` into a Swift 6 value/owner route. The
route preserves the source parameterized fade modes, velocity/gravity update,
quadratic X/Z drag, upward velocity cap, scale evolution, and deletion timing.

## Evidence

- Focused Swift/C fingerprint: `0xa830d1da5d262cbe`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x27d99092c5da319c`, 534 rows, 182 Swift value/owner
  routes, 352 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dr source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with the remaining smoke/fuse routes, then move into collision-heavy
and global/environment adapters while keeping per-route Swift/C fingerprints
and full-gate reruns.
