# SM64 Modern Full Swift Twin — M33ew Handoff

## Scope

M33ew migrates `bhvMistCircParticleSpawner` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves the 20-child mist table, 20-unit Y
offset, randomized scale/forward velocity/yaw, white-puff explosion child
ownership, active-particle flag clearing, and one-frame parent delay.

## Evidence

- Focused Swift/C mist-circle spawner fingerprint: `0x8b836f6e24508c9b`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x1164b7a306c15cec`, 534 rows, 223 Swift value/owner
  routes, 311 explicit C adapters.
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

Continue remaining compact cloud/particle behaviors, then migrate broader
collision/global/environment behavior families. Keep every route behind a
fixed-width Swift/C contract, dispatch identity, manifest owner entry, focused
smoke, and full-gate rerun.
