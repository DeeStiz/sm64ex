# SM64 Modern Full Swift Twin — M33ek Handoff

## Scope

M33ek migrates `bhvDirtParticleSpawner` and `bhvSnowParticleSpawner` through a
shared Swift 6 one-shot particle route. It preserves delay/teardown, parent
particle-flag clearing, source particle tables, and four allocated white-puff
child records.

## Evidence

- Focused Swift/C fingerprint: `0x23f36bdf5e01a3e6`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xe9cf7cd0e0b46401`, 534 rows, 206 Swift value/owner
  routes, 328 explicit C adapters.
- Engine-runtime and full live-route oracle replay pass for the integrated
  dispatch source set.
- Strict Xcode build with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` passes after the M33ek source addition.
- `git diff --check` and `zsh -n script/*.sh` pass.

## Open gates

Native runtime promotion, physical device rendering, Metal GPU
validation/capture, performance and thermal evidence, release signing, and
human parity acceptance remain open.

## Next

Continue compact particle/ambient routes and then broader global/collision
adapters while keeping per-route Swift/C fingerprints and full-gate reruns.
