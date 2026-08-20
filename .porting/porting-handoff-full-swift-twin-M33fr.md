# SM64 Modern Full Swift Twin — M33fr Handoff

## Scope

M33fr adds shared Swift 6 spawned-star trajectory routes for
`bhvSpawnedStar` and `bhvSpawnedStarNoLevelExit`. The path preserves
transparent model selection, Mario/no-exit home setup, gravity launch/settle/
wait/idle actions, sparkle-spawner children, power-star/environment/star-
appears intents, time-stop boundaries, tangible landing, rotation decay, and
interaction retirement.

## Evidence

- Focused Swift/C spawned-star fingerprint: `0xb755cd8968059736`.
- Behavior manifest: `0x4aeb916bbd03ab16`, 534 rows, 264 Swift value/owner
  routes, 270 explicit C adapters.
- `script/test_spawned_star.sh` covers transparent initialization, launch
  motion, sparkle/effect intent, cutscene-clear, no-exit state, and interaction
  retirement with matching Swift/C fingerprints.
- Dispatch smoke verifies both identities, transparent model selection, intro
  time-stop ownership, and sparkle-child-capable owner wiring. Coverage,
  engine-runtime, live-route oracle, route-shard replay, timebase, Metal 4
  source, shell syntax, and hygiene gates pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fr-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue hidden-star/door/switch and remaining collision/effect families while
preserving the value/owner/C-oracle/dispatch/manifest/live-trace/strict-build/
Metal-contract evidence loop.
