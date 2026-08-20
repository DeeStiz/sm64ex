# SM64 Modern Full Swift Twin — M33ih Handoff

## Scope

M33ih adds `bhvHorizontalGrindel` as a Swift collision/movement owner. The
route preserves ground-entry impact, target-yaw approach/reversal, 300-unit
home branching, 60-frame wait, jump velocity/gravity, face-yaw offset, scale,
collision identity, and surface-owner registration.

## Evidence

- Focused C↔Swift contract: `horizontalGrindelFingerprint=0x741c6bdcff466761`.
- Horizontal-Grindel dispatch/collision smoke, engine runtime, live-route
  oracle, route-shard replay, timebase, manifest, Metal source, shell, and
  hygiene gates pass.
- Manifest: `0x1ce029ec622e6820`, 534 rows, 373 Swift routes, 161 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33ih-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, whole-engine Swift authority, native/device
launch, actual collision/visual parity, GPU/performance/thermal, release, and
human acceptance remain open. LaunchServices still returns
`kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue remaining dynamic collision/global actors and then run the complete
post-slice verifier.
