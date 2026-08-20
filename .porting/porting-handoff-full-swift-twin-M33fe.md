# SM64 Modern Full Swift Twin — M33fe Handoff

## Scope

M33fe migrates `bhvCannonBarrelBubbles` through a Swift 6 parent-aware value
and owner path. It preserves parent yaw/pitch propagation, barrel
distance/velocity approach, reset-to-parent behavior, water-bomb spawning, and
child launch parameters through the existing Swift water-bomb bridge.

## Evidence

- Focused Swift/C cannon-barrel bubbles fingerprint: `0xebed5a565204fb74`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xe84627a37d504123`, 534 rows, 236 Swift value/owner
  routes, 298 explicit C adapters.
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

Continue the remaining compact cannon/cloud/particle behaviors, then migrate
broader collision/global/environment behavior families. Keep every route behind
a fixed-width Swift/C contract, dispatch identity, manifest owner entry,
focused smoke, and full-gate rerun.
