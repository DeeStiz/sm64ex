# SM64 Modern Full Swift Twin — M33im Handoff

## Scope

M33im adds the parent-linked `bhvBowserTailAnchor` owner. It preserves the
tangible/collision-cooldown/intangible actions, parent intangible-timer writes,
90-unit parent-relative offset, hitbox, and per-tick interaction reset through
generation-safe IDs.

## Evidence

- Focused C↔Swift contract: `bowserTailAnchorFingerprint=0xf4c20714deadfd91`.
- Tail-anchor parent/collision dispatch smoke, engine runtime, live-route
  oracle, route-shard replay, timebase, manifest, Metal source, shell, and
  hygiene gates pass.
- Manifest: `0x333d1f9a04d86a7d`, 534 rows, 378 Swift routes, 156 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33im-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining parent-linked actors, whole-engine
Swift authority, native/device launch, actual content/visual parity, GPU/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue remaining Bowser/NPC parent-linked actors and rerun the complete
post-slice verifier.
