# SM64 Modern Full Swift Twin — M33dz Handoff

## Scope

M33dz migrates `bhvBlueBowserFlame` and `bhvFlameFloatingLanding` through
shared Swift 6 parent/child routes. It preserves blue-flame growth,
gravity/phase movement, landing child selection, and migrated Bowser/blue-group
teardown paths.

## Evidence

- Focused Swift/C fingerprint: `0x63916908579630a5`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x0b2b3f11f032d140`, 534 rows, 193 Swift value/owner
  routes, 341 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dz source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with remaining blue/Bowser flame spawners and fire-spitter/Piranha
flame routes, then move into collision-heavy and global/environment adapters
while keeping per-route Swift/C fingerprints and full-gate reruns.
