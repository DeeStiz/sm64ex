# SM64 Modern Full Swift Twin — M33dp Handoff

## Scope

M33dp migrates `bhvWhitePuffSmoke` into a Swift 6 value/owner route. The
route preserves the default-list ownership, 100-unit downward initialization
offset, injected randomized scale, texture animation state, and ten-frame
behavior-script lifetime.

## Evidence

- Focused Swift/C fingerprint: `0x026925e9e7f47060`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x1f5414cb8f690a82`, 534 rows, 180 Swift value/owner
  routes, 354 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33dp source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with `bhvWhitePuffSmoke2` and remaining compact flame/smoke routes,
then move into collision-heavy and global/environment adapters while keeping
per-route Swift/C fingerprints and full-gate reruns.
