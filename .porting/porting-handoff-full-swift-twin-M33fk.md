# SM64 Modern Full Swift Twin — M33fk Handoff

## Scope

M33fk extends the shared Swift 6 warp owner route to `bhvExitPodiumWarp`.
The surface-list route preserves the authored 50-unit hitbox, 8,000-unit
collision-distance admission, podium collision-data identity, and per-tick
interaction reset without changing the existing normal/fading/pipe behavior.

## Evidence

- Focused Swift/C warp fingerprint: `0x17d388ad293f702f`.
- Behavior manifest: `0x039fb580fe5b74ce`, 534 rows, 256 Swift value/owner
  routes, 278 explicit C adapters.
- Warp smoke covers normal, fading, sentinel, byte-scaled, pipe, and
  exit-podium variants with matching Swift/C fingerprints.
- Dispatch smoke verifies all four warp identities, hitbox outputs, collision
  intent/data identity, and interaction reset. Coverage, engine-runtime,
  live-route oracle, route-shard replay, timebase, Metal 4 source, shell
  syntax, and hygiene gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fk-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue compact global/environment and star/warp families, then run the
broader route-shard qualification while preserving the value/owner/C-oracle/
dispatch/manifest/live-trace/strict-build/Metal-contract evidence loop.
