# SM64 Modern Full Swift Twin — M33el Handoff

## Scope

M33el migrates `bhvAnimatedTexture` through a Swift 6 value kernel and
generation-safe owner bridge. It preserves the general-actor list ownership,
home-position snap, authored physics fields, per-tick `oAnimState` increment,
and the `ANIMATE_TEXTURE(oAnimState, 2)` global-frame cadence.

## Evidence

- Focused Swift/C animated-texture fingerprint: `0x091c01d58b64a017`.
- Behavior dispatch smoke: `0x681ceb2358bf2e21`.
- Behavior manifest: `0xe9b3a1a5c4fc5379`, 534 rows, 207 Swift value/owner
  routes, 327 explicit C adapters.
- Engine-runtime smoke and full live-route oracle replay pass; C replay matches
  Swift and the expected divergence fixture still reports `first_divergence=3`.
- Route-shard replay, timebase audit, Metal 4 source contract, strict Xcode
  build with `SWIFT_VERSION=6` and `SWIFT_STRICT_CONCURRENCY=complete`, shell
  syntax, and `git diff --check` pass.
- Metal 4 production was attempted separately but remains blocked by the
  existing host LaunchServices `kLSNoExecutableErr (-10827)` launch boundary;
  the prior M34b production capture remains authoritative.

## Open gates

Native runtime promotion, physical-device rendering, GPU validation/capture,
performance and thermal evidence, release signing, and human parity acceptance
remain open. The host crash occurs before `NSApplication`/engine startup and is
not evidence of an animated-texture or Metal rendering fault.

## Next

Continue compact particle/ambient/platform routes, then migrate broader
collision/global/environment families. Keep each route behind a fixed-width
Swift/C contract, dispatch identity, manifest owner entry, focused smoke, and
full-gate rerun.
