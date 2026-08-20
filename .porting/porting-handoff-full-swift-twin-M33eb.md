# SM64 Modern Full Swift Twin — M33eb Handoff

## Scope

M33eb migrates `bhvKoopaShellFlame` into a Swift 6 unimportant-list
shell-flame route. It preserves injected random initialization,
forward/gravity movement, scale decay, animation, and floor/timer teardown.

## Evidence

- Focused Swift/C fingerprint: `0x363cfed54163fc8d`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x6c4a89957bee4e86`, 534 rows, 195 Swift value/owner
  routes, 339 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33eb source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with Bowser flame spawners, Beta moving flames, fire-spitter, and
small-Piranha routes while keeping per-route Swift/C fingerprints and
full-gate reruns.
