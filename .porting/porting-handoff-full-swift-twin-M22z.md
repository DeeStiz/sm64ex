# SM64 Modern Full Swift Twin — M22z Handoff

## Scope

M22z registers the existing `bhvEnemyLakitu` owner bridge in the shared
`SM64BehaviorDispatchBridge` and injects the shared Spiny owner bridge into
the composite. The spawner-list route runs before surface and general-actor
lists, allocates a same-frame Spiny in the live general-actor list, preserves
the parent/previous-object link and held relative transform, and applies
Spiny-to-Lakitu count bookkeeping after the shared callback sequence. Unknown
identities remain fail-closed as `unmigrated` events.

This closes a twentieth live owner route only. The focused fixture exercises
spawner-before-surface ordering, same-frame child traversal, stable parent and
child IDs, shared Spiny dispatch, and the second-tick held state. The
standalone differential remains the authority for Lakitu reveal/wall-reflect,
throw timing, attack/deletion, and the full Spiny parent interaction branches;
real collision, camera/audio, renderer, progression/save consumers, remaining
adapters, and whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twenty-route
  fingerprint `0xcc8bfca9af4c557b`; Enemy Lakitu dispatches in the spawner
  list, allocates a same-frame Spiny child, and shares the Spiny owner route.
- `script/test_enemy_lakitu_object_bridge.sh` — standalone Enemy Lakitu
  fingerprint `0xb2fd32a3d8fda71f`; value-kernel and composite owner
  differential remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the Enemy Lakitu dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22z-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22z-final-matrix.log` — all 206 script indices replayed
  in bounded batches, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges currently own separate scheduler shadows.
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
