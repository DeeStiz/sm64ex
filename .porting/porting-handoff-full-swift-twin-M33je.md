# SM64 Modern Full Swift Twin — M33je Handoff

## Scope

M33je consolidates `bhvFish`, `bhvFish2`, `bhvFish3`, `bhvFishGroup`, and
`bhvLargeFishGroup` into one Swift group/child owner. The route preserves
5/20-child variant selection, distance-gated spawning, default-list ordering,
water-level approach, yaw targeting, flee cycling, and parent retirement.

## Evidence

- Dispatch/group smoke, manifest, Metal 4 source, engine runtime, live-route
  oracle, route-shard replay, timebase, shell syntax, and `git diff --check`
  pass.
- Manifest: 534 rows, 416 Swift-owned, 118 C adapters,
  fingerprint `0xa27b63f0f9f51b67`.
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
