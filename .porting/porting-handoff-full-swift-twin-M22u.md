# SM64 Modern Full Swift Twin — M22u Handoff

## Scope

M22u registers the existing `bhvSnufit` owner bridge in the shared
`SM64BehaviorDispatchBridge`. The owner-thread scheduler dispatches Amp, Boo,
Bob-omb, Bird, Swoop, Piranha Plant, Big Boo, Fly Guy, Bullet Bill, Goomba,
Spiny, and Snufit in general-actor list order. The route also recognizes
Snufit's bowling-ball child identity, preserves orbit/idle/tangible state, and
keeps bullet deletion on the owner-thread sink. Unknown identities remain
fail-closed.

This closes a fourteenth live owner route only. The focused fixture exercises
an idle Snufit; bowling-ball allocation and bounce/deletion remain covered by
the standalone bridge differential and are not claimed as complete whole-level
integration. Real collision/camera/audio/render consumers, the remaining
adapters, and whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C fourteen-route
  fingerprint `0xde74954a659b8760`; Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/
  Big Boo/Fly Guy/Bullet Bill/Goomba/Spiny/Snufit general-actor order,
  default-list pendulum/respawner traversal, and compatibility-child
  identities match.
- `script/test_snufit_object_bridge.sh` — standalone Snufit orbit/shoot,
  three-shot bowling-ball allocation, bounce/deletion, and owner-delivery
  differential remains `0xf6221010ed5e3f78`.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the shared dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22u-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22u-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22u-matrix-01.log` through `-09.log`).
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach
   level spawns through exact behavior identity, including composite parents
   whose child bridges currently own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
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
