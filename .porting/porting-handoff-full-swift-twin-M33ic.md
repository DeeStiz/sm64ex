# SM64 Modern Full Swift Twin — M33ic Handoff

## Scope

M33ic ports the shared small/large Bomp action machine for `bhvSmallBomp` and
`bhvLargeBomp`. The owner preserves random-start timer admission,
wait/poke-out/extend/retract thresholds, variant-specific speeds, fixed X
clamps, yaw reversals, surface collision identities, and sound edges.

## Evidence

- Focused C↔Swift contract: `bompFingerprint=0x60f27e7f0e517b6`.
- Dispatch, engine runtime, live-route oracle, route-shard replay, timebase,
  manifest, Metal source, shell, and hygiene gates pass.
- Manifest: `0xfce7473eb9a9c811`, 534 rows, 364 Swift routes, 170 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33gk-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Post-slice full verifier, 7,419 route shards, whole-engine Swift authority,
native/device launch, actual collision geometry, GPU/visual/performance/
thermal, release, and human acceptance remain open. LaunchServices still
returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue dynamic collision/global/environment actors and keep each family
independently C-fingerprinted.
