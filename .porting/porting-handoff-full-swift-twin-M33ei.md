# SM64 Modern Full Swift Twin — M33ei Handoff

## Scope

M33ei migrates `bhvFlamethrower` into a Swift 6 parent route. It preserves
activation/spit action timing, parameterized child velocity/lifetime,
target-yaw updates, and migrated FlamethrowerFlame ownership.

## Evidence

- Focused Swift/C fingerprint: `0x41c0251022573e33`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xf33d9e1691980eff`, 534 rows, 203 Swift value/owner
  routes, 331 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ei source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with remaining global/collision-heavy routes and complete shard
qualification while keeping per-route Swift/C fingerprints and full-gate
reruns.
