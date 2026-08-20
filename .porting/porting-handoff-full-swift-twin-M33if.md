# SM64 Modern Full Swift Twin — M33if Handoff

## Scope

M33if adds `bhvBigBoulder` as a Swift rolling-sphere owner. The route preserves
initial 40-unit launch, 70-unit cap, rolling face pitch, damage hitbox,
20,000-unit collision distance, scale/graph offset, impact sound/mist edges,
and below-world retirement.

## Evidence

- Focused C↔Swift contract: `boulderFingerprint=0x4e41a388291ec45d`.
- Boulder dispatch/hitbox smoke, engine runtime, live-route oracle,
  route-shard replay, timebase, manifest, Metal source, shell, and hygiene
  gates pass.
- Manifest: `0x3c0ee295ed374325`, 534 rows, 371 Swift routes, 163 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33if-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

The big-boulder generator remains unmigrated. Full 7,419-row qualification,
whole-engine Swift authority, native/device launch, actual collision/visual
parity, GPU/performance/thermal, release, and human acceptance remain open.
LaunchServices still returns `kLSNoExecutableErr (-10827)` before AppKit.

## Next

Continue the boulder generator and remaining dynamic collision/global actors.
