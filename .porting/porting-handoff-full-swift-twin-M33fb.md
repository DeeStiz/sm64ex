# SM64 Modern Full Swift Twin — M33fb Handoff

## Scope

M33fb migrates `bhvBreakBoxTriangle` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves forward-velocity/gravity movement,
face-angle velocity rotation, the 18-frame repeat lifecycle, and owner-state
teardown.

## Evidence

- Focused Swift/C break-box triangle fingerprint: `0x5a7497ff09f8798d`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x6a413ab27ad0998a`, 534 rows, 229 Swift value/owner
  routes, 305 explicit C adapters.
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
