# SM64 Modern Full Swift Twin — M22s Handoff

## Scope

M22s registers the existing `bhvGoomba` owner bridge in the shared
`SM64BehaviorDispatchBridge`. The owner-thread scheduler dispatches Amp, Boo,
Bob-omb, Bird, Swoop, Piranha Plant, Big Boo, Fly Guy, Bullet Bill, and Goomba
in general-actor list order. The route also recognizes the existing Goomba
triplet-spawner identity, preserves the bridge's owner-thread walk, attack,
respawn-request, and generation-safe child seams, and never starts a nested
scheduler traversal. Unknown identities remain fail-closed.

This closes a twelfth live owner route only. The focused shared-dispatch
fixture exercises a regular Goomba; triplet-spawner and child behavior remain
covered by the standalone Goomba differential and are not claimed as complete
whole-level integration. The remaining adapters, real consumers, and
whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twelve-route
  fingerprint `0x69155cdafd4ea63e`; Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/
  Big Boo/Fly Guy/Bullet Bill/Goomba general-actor order, default-list
  pendulum/respawner traversal, and explicit compatibility-child identities
  match.
- `script/test_goomba_object_bridge.sh` — standalone Goomba regular/huge/tiny,
  collision/attack, triplet-spawner, respawn-request, and owner-delivery
  differential remains `0xf2f6f39a90915ec3`.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the shared dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22s-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22s-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22s-matrix-01.log` through `-09.log`).
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge in the shared
   dispatch table and attach level spawns through exact behavior identity.
2. Integrate Goomba triplet-spawner allocation into the shared dispatch smoke
   and then migrate the remaining 461 reachable adapters/transient children,
   or record an explicitly approved compatibility exception for each one.
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
