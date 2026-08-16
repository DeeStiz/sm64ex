# SM64 Modern Full Swift Twin — M22av Handoff

## Scope

M22av registers Fly Guy's transient flame identity in the shared
`SM64BehaviorDispatchBridge`. Both `bhvFlyGuy` and `bhvFlyguyFlame` select the
existing `SM64FlyGuyObjectBridge`, which already owns the flame state, parent
link, generation-safe unload, and pointer-free flame reducer. The dispatch
boundary does not create a second child scheduler.

This closes the Fly Guy flame identity selection slice only. Flame
presentation/collision consumers and whole-game parity remain open. The
behavior inventory remains 534 rows with 73 known Swift value/owner identities
and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C forty-two-route
  identity fingerprint `0xe2b0ee534039fb99`; the flame identity shares the
  Fly Guy owner route.
- `script/test_fly_guy_object_bridge.sh` — standalone Swift/C Fly Guy owner
  fingerprint `0x2fbf98eca64a5496`; parent/flame state, spit-fire allocation,
  flame ticking, and deletion remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22av-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22av-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and exact child
   identity, keeping composite parents on one owner-thread scheduler.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Fly Guy flame presentation/collision consumers and whole-game
   behavior parity before calling the route fully integrated.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge or exact child identity, add its
external-tick boundary and fail-closed route, then repeat the focused Swift/C,
runtime/oracle, regenerated native build, shebang-aware matrix, strict audit,
and handoff checks before committing.
