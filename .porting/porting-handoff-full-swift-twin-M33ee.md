# SM64 Modern Full Swift Twin — M33ee Handoff

## Scope

M33ee migrates `bhvBowserFlameSpawn` into a Swift 6 trajectory-table spawner
route. It preserves Bowser-relative placement, frame-window gating, yaw/pitch
derivation, and migrated moving/growing-flame child spawning.

## Evidence

- Focused Swift/C fingerprint: `0xdbcb4efd79313efe`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x6a01c5d4e36c5c56`, 534 rows, 199 Swift value/owner
  routes, 335 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ee source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with fire-spitter and small-Piranha routes while keeping per-route
Swift/C fingerprints and full-gate reruns.
