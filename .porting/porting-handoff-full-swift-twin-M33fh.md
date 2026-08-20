# SM64 Modern Full Swift Twin — M33fh Handoff

## Scope

M33fh migrates `bhvCelebrationStar` through a Swift 6 level-list parent route.
The value/owner path preserves star and Bowser-key initialization, Mario-relative
orbit, sparkle-child allocation, diameter growth/shrink, the timer-40
face-camera transition, variant-specific scale, live Mario-yaw alignment, and
timer-59 retirement. The existing `bhvCelebrationStarSparkle` bridge owns the
generation-safe child records.

## Evidence

- Focused Swift/C celebration-star fingerprint: `0xeee35755ab0382d6`.
- Behavior manifest: `0x2b2006e0351baeba`, 534 rows, 238 Swift value/owner
  routes, 296 explicit C adapters.
- `script/test_celebration_star.sh` covers initialization, orbit, sparkle
  spawn, diameter transition, face-camera alignment, Bowser-key scale/roll,
  and timer-59 retirement with matching Swift/C fingerprints.
- Dispatch smoke verifies route identity, parent orbit, child attachment, and
  live child generation. Coverage, engine-runtime, live-route oracle,
  route-shard replay, timebase, Metal 4 source, shell syntax, and hygiene gates
  pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fh-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue the remaining star/warp/cutscene and collision/environment families,
keeping each route behind the same value kernel, owner bridge, C oracle,
dispatch/manifest identity, live trace, strict Swift 6 build, Metal contract,
and explicit evidence ledger.
