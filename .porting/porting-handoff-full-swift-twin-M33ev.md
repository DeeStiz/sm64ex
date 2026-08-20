# SM64 Modern Full Swift Twin — M33ev Handoff

## Scope

M33ev extends the tree-particle family with `bhvTreeSnow` and
`bhvLeafParticleSpawner` through Swift 6 value/owner paths. It preserves shared
phase/gravity motion, level-gated snow/leaf selection, random spawn thresholds
and scale/velocity fields, active-particle flag clearing, child ownership,
one-frame delay, and parent teardown.

## Evidence

- Focused Swift/C fingerprints: `0xf6ce7660d6866f67` and
  `0x3b7b1c095b691cea`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xf451324f263a831e`, 534 rows, 222 Swift value/owner
  routes, 312 explicit C adapters.
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
