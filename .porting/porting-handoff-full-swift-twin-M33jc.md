# SM64 Modern Full Swift Twin — M33jc Handoff

## Scope

M33jc adds haunted-bookend spawner and flying-child owners for
`bhvBookendSpawn` and `bhvFlyingBookend`. The typed owner preserves the
40-frame near/facing spawn gate, child action-3 launch transition, forward
movement, and parent/list ordering.

## Evidence

- Dispatch/child smoke, manifest, Metal 4 source, engine runtime, live-route
  oracle, route-shard replay, timebase, shell syntax, and `git diff --check`
  pass.
- Manifest: 534 rows, 410 Swift-owned, 124 C adapters,
  fingerprint `0xeb6e950bc1b8415d`.
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
