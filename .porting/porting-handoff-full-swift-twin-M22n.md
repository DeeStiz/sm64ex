# SM64 Modern Full Swift Twin — M22n Handoff

## Scope

M22n registers the existing `bhvSwoop` owner bridge in the shared
`SM64BehaviorDispatchBridge`. The owner-thread scheduler dispatches Amp, Boo,
Bob-omb, Bird, and Swoop in general-actor list order, preserves Swoop's
animate/idle state and generation-safe records, and leaves the Bob-omb smoke
child and respawner replacement child as explicit `unmigrated` events. Unknown
identities remain fail-closed; no route silently receives a C-shaped fallback.

This closes a seventh live owner route only. It does not close the remaining
reachable adapters, spawner/child breadth, real audio/render/collision
consumers, progression/save authority, or whole-game parity.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C seven-route
  fingerprint `0xb093af8af4cfa2d5`; Amp/Boo/Bob-omb/Bird/Swoop general-actor
  order, default-list pendulum/respawner traversal, compatibility-child
  identities, and owner delivery match.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the shared dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22n-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22n-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22n-matrix-01.log` through `-09.log`).
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge in the shared
   dispatch table and attach level spawns through exact behavior identity.
2. Migrate the remaining 461 reachable adapters and transient children, or
   record an explicitly approved compatibility exception for each one.
3. Add real audio, camera, collision, renderer, progression, and save
   consumers, then compare complete C-vs-Swift object/effect/render traces.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Register the next exact Swift owner identity in `SM64BehaviorDispatchBridge`,
preserve explicit `unmigrated` events for unknown identities, add an
independent Swift/C ordering fixture, and rerun the focused contracts, native
build, and complete 206-script matrix before promoting the next milestone.
