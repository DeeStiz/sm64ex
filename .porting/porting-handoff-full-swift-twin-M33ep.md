# SM64 Modern Full Swift Twin — M33ep Handoff

## Scope

M33ep migrates `bhvCoinSparkles` and `bhvGoldenCoinSparkles` through Swift 6
value kernels and generation-safe owner bridges. It preserves the coin
sparkle's eight-step animation, 0.6 scale and 25-unit graph offset, the golden
coin's three random-offset child allocations, hidden parent rendering, and
one-tick parent teardown.

## Evidence

- Focused Swift/C fingerprints: `0xe192c79c177d4d5b` and
  `0xd56058c8905ae623`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xf175efe87066d794`, 534 rows, 212 Swift value/owner
  routes, 322 explicit C adapters.
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

Continue compact particle/star families, then migrate broader
collision/global/environment behavior families. Keep every route behind a
fixed-width Swift/C contract, dispatch identity, manifest owner entry, focused
smoke, and full-gate rerun.
