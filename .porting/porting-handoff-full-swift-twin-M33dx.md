# SM64 Modern Full Swift Twin — M33dx Handoff

## Scope

M33dx migrates `bhvFlameBowser` and `bhvFlameLargeBurningOut` through a shared
Swift 6 Bowser-flame kernel. It preserves movement and phase wobble, landing
and burning-out state, scale decay, flame interaction state, and the migrated
black-smoke-upward teardown child.

## Evidence

- Focused Swift/C fingerprint: `0xdf08caf0976be19c`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xd3013583bb59dced`, 534 rows, 190 Swift value/owner
  routes, 344 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dx source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with blue flame groups and remaining fire-spitter/small-Piranha
flame routes, then move into collision-heavy and global/environment adapters
while keeping per-route Swift/C fingerprints and full-gate reruns.
