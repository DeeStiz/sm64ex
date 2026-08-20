# SM64 Modern Full Swift Twin — M33ij Handoff

## Scope

M33ij adds `bhvUnusedParticleSpawn` as a collision-triggered purple-particle
owner. Ground or Mario collision retires the source object and allocates ten
generation-safe children through the existing purple-particle bridge; ground
retirement alone emits no particles.

## Evidence

- Focused C↔Swift contract: `unusedParticleSpawnFingerprint=0x93b3d7b3f9b4a249`.
- Dispatch child smoke, engine runtime, live-route oracle, route-shard replay,
  timebase, manifest, Metal source, shell, and hygiene gates pass.
- Manifest: `0xafc74c8d351f29c7`, 534 rows, 375 Swift routes, 159 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33ij-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining dynamic actors, whole-engine Swift
authority, native/device launch, actual content/visual parity, GPU/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue remaining dynamic collision/global actors and rerun the complete
post-slice verifier.
