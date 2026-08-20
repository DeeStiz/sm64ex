# SM64 Modern Full Swift Twin — M33iy Handoff

## Scope

M33iy adds the `bhvChirpChirp`/`bhvChirpChirpUnused` spawner aliases and
`bhvBub` child movement owner. The typed reducer and generation-safe bridge
preserve the 1,500-unit spawn gate, parent action cycle, water-level vertical
approach, Mario/home yaw targeting, flee transition, interaction particle
edge, and parent-deletion cleanup.

## Evidence

- Focused C↔Swift contract:
  `bubFingerprint=0xe3586252d673cd41`.
- Dispatch/child-order smoke, manifest, Metal 4 source, engine runtime,
  live-route oracle, route-shard replay, timebase, shell syntax, and
  `git diff --check` pass.
- Manifest: 534 rows, 403 Swift-owned, 131 C adapters,
  fingerprint `0x101aaca428f2c0f6`.
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
