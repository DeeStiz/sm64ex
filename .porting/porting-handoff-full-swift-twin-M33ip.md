# SM64 Modern Full Swift Twin — M33ip Handoff

## Scope

M33ip adds the Beta holdable four-state owner (`bhvBetaHoldableObject`). The
route preserves free/held/thrown/dropped render transitions, fixed throw
velocity, drop reset, holdable hitbox/physics fields, and generation-safe
lifecycle.

## Evidence

- Focused C↔Swift contract: `betaHoldableFingerprint=0xb158eeb0609e333f`.
- Holdable dispatch/state smoke, engine runtime, live-route oracle,
  route-shard replay, timebase, manifest, Metal source, shell, and hygiene
  gates pass.
- Manifest: `0xdf3dec4581b174de`, 534 rows, 383 Swift routes, 151 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33ip-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining NPC/environment actors, whole-engine
Swift authority, native/device launch, actual content/visual parity, GPU/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue remaining NPC/environment families and rerun the complete post-slice
verifier.
