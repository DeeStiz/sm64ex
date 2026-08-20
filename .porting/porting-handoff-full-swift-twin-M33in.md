# SM64 Modern Full Swift Twin — M33in Handoff

## Scope

M33in adds the Beta chest bottom/lid family (`bhvBetaChestBottom`,
`bhvBetaChestLid`). The owner preserves 300-unit opening admission, 0x400
pitch steps, bubble/sound child spawn, parent-relative lid ownership, hitbox
fields, and generation-safe cleanup while reusing WaterAirBubble.

## Evidence

- Focused C↔Swift contract: `betaChestFingerprint=0x52df92ff78e81e61`.
- Beta-chest dispatch/child smoke, engine runtime, live-route oracle,
  route-shard replay, timebase, manifest, Metal source, shell, and hygiene
  gates pass.
- Manifest: `0x4728179210c55d8f`, 534 rows, 380 Swift routes, 154 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33in-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining NPC/environment actors, whole-engine
Swift authority, native/device launch, actual content/visual parity, GPU/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue remaining NPC/environment families and rerun the complete post-slice
verifier.
