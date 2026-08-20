# SM64 Modern Full Swift Twin — M33eq Handoff

## Scope

M33eq migrates `bhvPurpleParticle` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves unimportant-list ownership,
randomized initial forward/vertical velocities, yaw-derived X/Z movement, and
the ten-frame behavior-script lifetime.

## Evidence

- Focused Swift/C purple-particle fingerprint: `0xc2a3e2f7dce0356f`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xd9cca3003843c4d1`, 534 rows, 213 Swift value/owner
  routes, 321 explicit C adapters.
- Engine-runtime smoke and full live-route oracle replay pass; C replay matches
  Swift and the expected divergence fixture still reports `first_divergence=3`.
- Route-shard replay, timebase audit, Metal 4 source contract, strict Xcode
  build with `SWIFT_VERSION=6` and `SWIFT_STRICT_CONCURRENCY=complete`, shell
  syntax, and `git diff --check` pass.

## Open gates

Native runtime promotion, physical-device rendering, GPU validation/capture,
performance and thermal evidence, release signing, and human parity acceptance
remain open. The host LaunchServices database rejects even known system app
opens with `kLSNoExecutableErr (-10827)`; the supplied app crash is in
`HIServices` during `NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining compact star/particle family, then migrate broader
collision/global/environment behavior families. Keep every route behind a
fixed-width Swift/C contract, dispatch identity, manifest owner entry, focused
smoke, and full-gate rerun.
