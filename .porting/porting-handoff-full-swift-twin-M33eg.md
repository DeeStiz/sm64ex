# SM64 Modern Full Swift Twin — M33eg Handoff

## Scope

M33eg migrates `bhvFireSpitter` into a Swift 6 owner route. It preserves idle
activation, scale grow/shrink timing, target-yaw updates, and migrated
small-Piranha flame spawn parameters.

## Evidence

- Focused Swift/C fingerprint: `0xa87862255ff5485c`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xec619dd0099ccd45`, 534 rows, 201 Swift value/owner
  routes, 333 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33eg source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with remaining flame spawner/physics routes and collision-heavy/global
adapters while keeping per-route Swift/C fingerprints and full-gate reruns.
