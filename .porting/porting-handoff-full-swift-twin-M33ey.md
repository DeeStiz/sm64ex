# SM64 Modern Full Swift Twin — M33ey Handoff

## Scope

M33ey migrates pure script routes `bhvRandomAnimatedTexture` and `bhvUnused0DFC`
through a shared Swift 6 value/owner path. It preserves graph offsets, initial
animation state, per-frame animation progression, object-list ownership, and
the six-frame deactivation lifecycle.

## Evidence

- Focused Swift/C simple-animation fingerprint: `0x6d651eeaf51053c4`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x7c74a6098b2f8d58`, 534 rows, 226 Swift value/owner
  routes, 308 explicit C adapters.
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
