# SM64 Modern Full Swift Twin — M33dq Handoff

## Scope

M33dq migrates `bhvWhitePuffSmoke2` into a Swift 6 value/owner route. The
route preserves injected random X/Z placement, forward-velocity movement,
unbounded gravity integration, texture animation, unimportant-list ownership,
and the seven-frame behavior-script lifetime.

## Evidence

- Focused Swift/C fingerprint: `0xe495eac58d877d0b`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x836c9e309f8ea9f7`, 534 rows, 181 Swift value/owner
  routes, 353 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dq source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with the remaining compact smoke/flame routes, then move into
collision-heavy and global/environment adapters while keeping per-route
Swift/C fingerprints and full-gate reruns.
