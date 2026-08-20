# SM64 Modern Full Swift Twin — M33io Handoff

## Scope

M33io adds the Beta trampoline top/spring family
(`bhvBetaTrampolineTop`, `bhvBetaTrampolineSpring`). The owner preserves top
child creation, Mario-on-platform reset, parent transform copying, the
75-unit spring offset, and the authored compression scale formula.

## Evidence

- Focused C↔Swift contract: `betaTrampolineFingerprint=0xcd064d83a22e382d`.
- Trampoline dispatch/child smoke, engine runtime, live-route oracle,
  route-shard replay, timebase, manifest, Metal source, shell, and hygiene
  gates pass.
- Manifest: `0xcd0d8a9166173a35`, 534 rows, 382 Swift routes, 152 C adapters.
- Regenerated strict Swift 6 Xcode Debug build passes at
  `build/sm64-modern-m33io-xcode` with `** BUILD SUCCEEDED **`.

## Open gates

Full 7,419-row qualification, remaining NPC/environment actors, whole-engine
Swift authority, native/device launch, actual content/visual parity, GPU/
performance/thermal, release, and human acceptance remain open. LaunchServices
still returns `kLSNoExecutableErr (-10827)` before AppKit/engine startup.

## Next

Continue remaining NPC/environment families and rerun the complete post-slice
verifier.
