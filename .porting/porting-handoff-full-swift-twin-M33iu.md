# SM64 Modern Full Swift Twin — M33iu Handoff

## Scope

M33iu adds `bhvBlueFish` as a Swift aquarium actor owner. The typed reducer
and generation-safe bridge preserve deterministic dive/turn/ascend/turn-back
timing, random angle/velocity inputs, canonical trig movement, animation
acceleration, and parent-duplicate retirement.

## Evidence

- Focused C↔Swift contract:
  `blueFishFingerprint=0xe56ef70774bdd136`.
- Dispatch smoke, manifest, Metal 4 source, engine runtime, live-route
  oracle, route-shard replay, timebase, shell syntax, and `git diff --check`
  pass.
- Manifest: 534 rows, 397 Swift-owned, 137 C adapters,
  fingerprint `0xc4dd70d2c40c27ad`.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-coffin-xcode` with `** BUILD SUCCEEDED **`.
- The full verifier reaches the same successful build and stops only at the
  known host LaunchServices open (`kLSNoExecutableErr -10827`) in
  `/tmp/sm64-modern-m33iu-full-verify-final.log`.

## Open gates

Full 7,419-row qualification, remaining NPC/environment/menu/camera actors,
whole-engine Swift authority, native/device launch, actual content/visual
parity, GPU/performance/thermal, release, and human acceptance remain open.
The host LaunchServices/AppKit registration failure remains separate from
source/build evidence.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
