# SM64 Modern Full Swift Twin — M33ex Handoff

## Scope

M33ex migrates `bhvSparkleParticleSpawner` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves parent particle-flag clearing,
injected random offsets, graph Y offset, twelve-frame animation progression,
and deactivation.

## Evidence

- Focused Swift/C sparkle-particle spawner fingerprint: `0x2d4912f8fbe7cefb`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xc2d37cbcc480fe53`, 534 rows, 224 Swift value/owner
  routes, 310 explicit C adapters.
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
