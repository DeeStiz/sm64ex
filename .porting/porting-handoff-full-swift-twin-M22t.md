# SM64 Modern Full Swift Twin — M22t Handoff

## Scope

M22t registers the existing `bhvSpiny` owner bridge in the shared
`SM64BehaviorDispatchBridge`. The owner-thread scheduler dispatches Amp, Boo,
Bob-omb, Bird, Swoop, Piranha Plant, Big Boo, Fly Guy, Bullet Bill, Goomba, and
Spiny in general-actor list order, preserves Spiny walk/turn state and
owner-thread deletion delivery, and leaves Lakitu parent allocation as an
explicit upstream seam. Unknown identities remain fail-closed.

This closes a thirteenth live owner route only. It does not claim composite
Enemy Lakitu parent allocation, real collision/camera/audio/render consumers,
the remaining adapters, or whole-game parity.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C thirteen-route
  fingerprint `0xb68bdd56670dcdc6`; Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/
  Big Boo/Fly Guy/Bullet Bill/Goomba/Spiny general-actor order, default-list
  pendulum/respawner traversal, and explicit compatibility-child identities
  match.
- `script/test_spiny_enemy.sh` — standalone Spiny walk, Lakitu throw/land,
  attack, unload, owner-delivery, and attack-table differential remains
  `0xf7737180e4f09b3f`.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the shared dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22t-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22t-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22t-matrix-01.log` through `-09.log`).
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Attach Enemy Lakitu parent allocation and its Spiny children to the shared
   dispatcher without duplicating scheduler traversal.
2. Register every remaining already-proven Swift owner bridge and migrate the
   remaining 461 reachable adapters/transient children, or record an
   explicitly approved compatibility exception for each one.
3. Add real audio, camera, collision, renderer, progression, and save
   consumers, then compare complete C-vs-Swift object/effect/render traces.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Register the next exact Swift owner identity in `BehaviorDispatchBridge`,
preserve explicit `unmigrated` events for unknown identities, add an
independent Swift/C ordering fixture, and rerun the focused contracts, native
build, and complete 206-script matrix before promoting the next milestone.
