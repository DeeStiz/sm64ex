# SM64 Modern Full Swift Twin — M33dy Handoff

## Scope

M33dy migrates `bhvBlueFlamesGroup` as a Swift 6 16-frame parent route. It
preserves even-tick three-flame bursts, 0x5555 yaw spacing, scale decay,
migrated bouncing-flame child ownership, and parent teardown.

## Evidence

- Focused Swift/C fingerprint: `0xbae357f5c46332c3`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xa6a655f1e291de66`, 534 rows, 191 Swift value/owner
  routes, 343 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dy source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with remaining blue/Bowser flame variants and fire-spitter/Piranha
flame routes, then move into collision-heavy and global/environment adapters
while keeping per-route Swift/C fingerprints and full-gate reruns.
