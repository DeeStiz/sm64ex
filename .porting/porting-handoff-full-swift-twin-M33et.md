# SM64 Modern Full Swift Twin — M33et Handoff

## Scope

M33et migrates `bhvPunchTinyTriangle` and `bhvTriangleParticleSpawner`
through shared Swift 6 value/owner paths. It preserves Mario-relative triangle
placement, injected yaw/velocity seeds, scale and animation decay,
active-particle flag clearing, child allocation, one-frame delay, and parent
teardown.

## Evidence

- Focused Swift/C fingerprints: `0xf6800ccb09272913` and
  `0x34c0be5cd8a031e1`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xed6eb6fed67479dc`, 534 rows, 219 Swift value/owner
  routes, 315 explicit C adapters.
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

Continue remaining compact particle/star behaviors, then migrate broader
collision/global/environment behavior families. Keep every route behind a
fixed-width Swift/C contract, dispatch identity, manifest owner entry, focused
smoke, and full-gate rerun.
