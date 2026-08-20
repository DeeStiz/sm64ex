# SM64 Modern Full Swift Twin — M33du Handoff

## Scope

M33du migrates `bhvFlame` into a Swift 6 static interaction-bearing flame
route. It preserves level-list ownership, the 700% source scale, flame
interaction/hitbox configuration, interaction-status reset, and two-frame
texture animation.

## Evidence

- Focused Swift/C fingerprint: `0x4087c9da74b17dc2`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x4ac99b401bb68824`, 534 rows, 186 Swift value/owner
  routes, 348 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33du source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with `bhvSmallPiranhaFlame`, fire-spitter, and remaining flame routes,
then move into collision-heavy and global/environment adapters while keeping
per-route Swift/C fingerprints and full-gate reruns.
