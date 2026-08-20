# SM64 Modern Full Swift Twin — M33iz Handoff

## Scope

M33iz adds `bhvButterfly` as a Swift three-state actor owner. The reducer and
generation-safe bridge preserve rest/follow/return-home transitions, canonical
yaw/pitch approach, the 7-unit flight step, home snap, phase-driven vertical
motion, and animation-state edges.

## Evidence

- Focused C↔Swift contract:
  `butterflyFingerprint=0x337978782426bd62`.
- Dispatch smoke, manifest, Metal 4 source, engine runtime, live-route
  oracle, route-shard replay, timebase, shell syntax, and `git diff --check`
  pass.
- Manifest: 534 rows, 404 Swift-owned, 130 C adapters,
  fingerprint `0x643b79fd4cb0b6b4`.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-coffin-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining NPC/environment/menu/camera actors,
whole-engine Swift authority, native/device launch, actual content/visual
parity, GPU/performance/thermal, release, and human acceptance remain open.
The host LaunchServices/AppKit registration failure remains separate from
source/build evidence.

## Next

Continue the remaining source-ordered C adapter families, adding focused
C↔Swift contracts and live shard coverage before closing M33.
