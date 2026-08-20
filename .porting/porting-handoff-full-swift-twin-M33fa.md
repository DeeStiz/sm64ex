# SM64 Modern Full Swift Twin — M33fa Handoff

## Scope

M33fa migrates `bhvCloudPart` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves parent-center/radius placement,
phase oscillation, the cloud-part height table, parent yaw, Fwoosh scale cap,
and unload deletion.

## Evidence

- Focused Swift/C cloud-part fingerprint: `0x7f284c51b78d4f79`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x8967b85d2730602b`, 534 rows, 228 Swift value/owner
  routes, 306 explicit C adapters.
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

Continue the cloud parent or remaining compact particle behaviors, then migrate
broader collision/global/environment behavior families. Keep every route behind
a fixed-width Swift/C contract, dispatch identity, manifest owner entry,
focused smoke, and full-gate rerun.
