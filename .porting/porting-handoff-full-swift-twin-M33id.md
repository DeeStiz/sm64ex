# SM64 Modern Full Swift Twin — M33id Handoff

## Scope

M33id ports the shared Grindel/Thwomp action machine for `bhvGrindel`,
`bhvThwomp`, and `bhvThwomp2`. The Swift owner preserves behavior-byte wait
admission, random wait/pause timers, gravity and home-height landing, nearby
landing sound/shake, variant scale/drawing setup, collision identities, and
surface collision-owner registration.

## Evidence

- Focused C↔Swift contract: `thwompFingerprint=0x69cbaa275918d295`.
- Dispatch, engine runtime, live-route oracle, route-shard replay, timebase,
  manifest, Metal source, shell, and hygiene gates pass.
- Manifest: `0x92867b41d99a059b`, 534 rows, 367 Swift routes, 167 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33ic-xcode` with `** BUILD SUCCEEDED **`.
- The post-slice `./script/build_and_run.sh --verify` run executes the full
  focused ABI/content/audio/render/behavior matrix, including
  `bompFingerprint=0x60f27e7f0e517b6f` and
  `thwompFingerprint=0x69cbaa275918d295`, then reaches `** BUILD SUCCEEDED **`.
  Its only failing step is the final native app open, recorded at
  `/tmp/sm64-modern-m33id-full-verify.log` as LaunchServices
  `kLSNoExecutableErr (-10827)`.

## Open gates

All 7,419 route shards, whole-engine Swift authority, native/device launch,
actual collision geometry, GPU/visual/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue dynamic collision/global actors and maintain independent C fingerprints
for every family.
