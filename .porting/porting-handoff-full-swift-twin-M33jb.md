# SM64 Modern Full Swift Twin — M33jb Handoff

## Scope

M33jb extends the existing Boo owner through `bhvBooWithCage`. The route
preserves cage-specific hitbox/scale, shared chase/bounce/death actions, and
the 12-star cage-child initialization gate.

## Evidence

- Dispatch/cage smoke, manifest, Metal 4 source, engine runtime, live-route
  oracle, route-shard replay, timebase, shell syntax, and `git diff --check`
  pass.
- Manifest: 534 rows, 408 Swift-owned, 126 C adapters,
  fingerprint `0xe116735ea26da581`.
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
