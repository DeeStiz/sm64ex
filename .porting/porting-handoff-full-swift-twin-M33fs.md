# SM64 Modern Full Swift Twin — M33fs Handoff

## Scope

M33fs migrates `bhvCcmTouchedStarSpawn` through a Swift 6 global-trigger
owner route. It preserves the CCM slide flag gate, authored trigger
reposition, exact default-star home coordinates, generation-safe child
`bhvStarSpawnCoordinates` allocation, 500×500 trigger hitbox, and trigger
retirement.

## Evidence

- Focused Swift/C CCM touched-star fingerprint: `0x3b5fc80d0d29ed1d`.
- Behavior manifest: `0x8b6520b382b6243c`, 534 rows, 265 Swift value/owner
  routes, 269 explicit C adapters.
- `script/test_ccm_touched_star_spawn.sh` covers idle and triggered paths,
  reposition, exact star home coordinates, and matching Swift/C fingerprints.
- Dispatch smoke verifies identity routing, trigger output, child-star home
  state, and retirement. Coverage, engine-runtime, live-route oracle,
  route-shard replay, timebase, Metal 4 source, shell syntax, and hygiene gates
  pass.
- Regenerated strict Xcode Debug build passes with `SWIFT_VERSION=6` and
  `SWIFT_STRICT_CONCURRENCY=complete` in
  `build/sm64-modern-m33fs-xcode` (`** BUILD SUCCEEDED **`).

## Open gates

Full 7,419-row shard execution, zero-unmigrated-adapter closure, native
runtime promotion, physical-device rendering, GPU validation/capture,
performance/thermal evidence, release signing/notarization, and visual/audio/
controller/human parity acceptance remain open. The host LaunchServices
database still rejects even known system app opens with
`kLSNoExecutableErr (-10827)`; the supplied crash is in HIServices during
`NSApplication.shared`, before `AppDelegate`/engine startup.

## Next

Continue hidden-star, door/switch, and remaining collision/effect families
while preserving the value/owner/C-oracle/dispatch/manifest/live-trace/
strict-build/Metal-contract evidence loop.
