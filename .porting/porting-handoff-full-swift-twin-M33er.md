# SM64 Modern Full Swift Twin — M33er Handoff

## Scope

M33er migrates `bhvWallTinyStarParticle` and `bhvPoundTinyStarParticle`
through a shared Swift 6 value kernel and generation-safe owner bridge. It
preserves Mario-relative wall placement, pound offset/velocity, yaw-derived
movement, scale decay, animation state, and the ten-frame behavior lifetime.

## Evidence

- Focused Swift/C tiny-star particle fingerprint: `0xe8bb0b3e328ac784`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x7b4b957c07253729`, 534 rows, 215 Swift value/owner
  routes, 319 explicit C adapters.
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

Continue the remaining compact star/particle spawner family, then migrate
broader collision/global/environment behavior families. Keep every route behind
a fixed-width Swift/C contract, dispatch identity, manifest owner entry,
focused smoke, and full-gate rerun.
