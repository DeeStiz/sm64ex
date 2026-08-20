# SM64 Modern Full Swift Twin — M33ez Handoff

## Scope

M33ez migrates `bhvUnusedFakeStar` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves continuous 0x100 pitch/yaw
increments, position/transform ownership, and update cadence.

## Evidence

- Focused Swift/C unused-fake-star fingerprint: `0xd7d190b7a3d2c103`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x6590caef8ca5630e`, 534 rows, 227 Swift value/owner
  routes, 307 explicit C adapters.
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
