# SM64 Modern Full Swift Twin — M33fi Handoff

## Scope

M33fi migrates the shared `bhvWarp`, `bhvFadingWarp`, and `bhvWarpPipe`
callbacks through a Swift 6 value/owner route. It preserves behavior-byte
radius decoding, including the normal `50` radius, fading `85` radius,
ten-times-byte values, and `0xFF`/`10000` sentinel; 50-unit hitbox height;
fading subtype; pipe collision intent; and per-tick interaction reset.

## Evidence

- Focused Swift/C warp fingerprint: `0xd94ed7a7d5b6bd96`.
- Behavior manifest: `0xc96df469e7e1bb21`, 534 rows, 241 Swift value/owner
  routes, 293 explicit C adapters.
- `script/test_warp.sh` covers normal, fading, sentinel, byte-scaled, and pipe
  variants with matching Swift/C fingerprints.
- Dispatch smoke verifies all three identities, hitbox outputs, pipe collision
  intent, and interaction reset. Coverage, engine-runtime, live-route oracle,
  route-shard replay, timebase, Metal 4 source, shell syntax, and hygiene gates
  pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fi-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue compact warp/star/cutscene and collision/environment families while
preserving the per-route value kernel, owner bridge, independent C oracle,
dispatch/manifest identity, live trace, strict Swift 6 build, Metal contract,
and evidence ledger.
