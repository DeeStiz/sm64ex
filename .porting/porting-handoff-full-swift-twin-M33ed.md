# SM64 Modern Full Swift Twin — M33ed Handoff

## Scope

M33ed migrates `bhvBetaMovingFlamesSpawn` and `bhvBetaMovingFlames` through a
shared Swift 6 parent/child route. It preserves the eight-child action
sequence, phase-derived forward velocity, scale, texture animation, and
owning-list order.

## Evidence

- Focused Swift/C fingerprint: `0x4a67f01614ad0eaa`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x5033552c6044e54b`, 534 rows, 198 Swift value/owner
  routes, 336 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ed source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with Bowser flame spawners, fire-spitter, and small-Piranha routes
while keeping per-route Swift/C fingerprints and full-gate reruns.
