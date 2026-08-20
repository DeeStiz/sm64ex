# SM64 Modern Full Swift Twin — M33ds Handoff

## Scope

M33ds migrates `bhvSmoke` and `bhvBobombFuseSmoke` through a shared typed
Swift dust-smoke kernel. It preserves the one-frame behavior delay, native
velocity movement, smoke-timer deletion boundary, texture animation, fuse
offset/scale initialization, and separate default/unimportant object lists.

## Evidence

- Focused Swift/C fingerprint: `0x0149577f96a62f5b`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xad222b530f9b5d2d`, 534 rows, 184 Swift value/owner
  routes, 350 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ds source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue with remaining fuse/particle and flame routes, then move into
collision-heavy and global/environment adapters while keeping per-route
Swift/C fingerprints and full-gate reruns.
