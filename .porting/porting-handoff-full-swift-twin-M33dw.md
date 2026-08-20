# SM64 Modern Full Swift Twin — M33dw Handoff

## Scope

M33dw migrates `bhvFlameBouncing` into a Swift 6 self-contained flame route.
It preserves fixed forward speed, gravity motion, texture cadence, flame
interaction state, and timer/Bowser/floor deletion guards.

## Evidence

- Focused Swift/C fingerprint: `0x4fd248c09d17fc44`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x1054f76a59f135e0`, 534 rows, 188 Swift value/owner
  routes, 346 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dw source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with Bowser/blue flame variants and fire-spitter routes, then move
into collision-heavy and global/environment adapters while keeping per-route
Swift/C fingerprints and full-gate reruns.
