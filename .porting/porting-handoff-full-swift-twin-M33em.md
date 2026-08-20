# SM64 Modern Full Swift Twin — M33em Handoff

## Scope

M33em migrates `bhvSparkle` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves the unimportant object-list route,
the source script's nine `oAnimState` increments from an initial `-1`, and its
immediate deactivation after the setup repeat.

## Evidence

- Focused Swift/C sparkle fingerprint: `0xfc140e57a3aaa42a`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0x3454398b0bbdfc78`, 534 rows, 208 Swift value/owner
  routes, 326 explicit C adapters.
- Engine-runtime smoke and full live-route oracle replay pass; C replay matches
  Swift and the expected divergence fixture still reports `first_divergence=3`.
- Route-shard replay, timebase audit, Metal 4 source contract, strict Xcode
  build with `SWIFT_VERSION=6` and `SWIFT_STRICT_CONCURRENCY=complete`, shell
  syntax, and `git diff --check` pass.

## Open gates

Native runtime promotion, physical-device rendering, GPU validation/capture,
performance and thermal evidence, release signing, and human parity acceptance
remain open. The current host cannot open even a known system app through
LaunchServices (`kLSNoExecutableErr -10827`), and the supplied crash occurs in
`HIServices` during `NSApplication.shared` before `AppDelegate`/engine startup.

## Next

Continue the compact sparkle/particle family, then migrate broader
collision/global/environment behavior families. Every route must retain a
fixed-width Swift/C contract, dispatch identity, manifest owner entry, focused
smoke, and full-gate rerun.
