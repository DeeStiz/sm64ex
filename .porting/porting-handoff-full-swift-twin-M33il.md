# SM64 Modern Full Swift Twin — M33il Handoff

## Scope

M33il adds the parent-transform `bhvBowserBodyAnchor` owner. It preserves
Bowser position/angle copying, action/subaction interaction switching,
opacity/held-state tangibility, hitbox/subtype fields, and interaction reset
through generation-safe parent IDs.

## Evidence

- Focused C↔Swift contract: `bowserBodyAnchorFingerprint=0x395f16ac7663392a`.
- Body-anchor parent/interaction dispatch smoke, engine runtime, live-route
  oracle, route-shard replay, timebase, manifest, Metal source, shell, and
  hygiene gates pass.
- Manifest: `0x21a7de5da556d219`, 534 rows, 377 Swift routes, 157 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33il-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining parent-linked actors, whole-engine
Swift authority, native/device launch, actual content/visual parity, GPU/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue parent-linked Bowser/NPC actors and rerun the complete post-slice
verifier.
