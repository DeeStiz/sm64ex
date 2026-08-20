# SM64 Modern Full Swift Twin — M33fd Handoff

## Scope

M33fd adds the five BREAK-only behavior identities `bhvUnused05A8`,
`bhvUnused1820`, `bhvUnused1F30`, `bhvUnused2A10`, and `bhvUnused2A54` through
one Swift 6 no-op owner route. It preserves script-break semantics without
deactivation or field mutation.

## Evidence

- Focused Swift/C no-op behavior fingerprint: `0x162a8345ecfd7fc0`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x6827a243c28f53af`, 534 rows, 235 Swift value/owner
  routes, 299 explicit C adapters.
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
