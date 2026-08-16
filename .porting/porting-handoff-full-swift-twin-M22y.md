# SM64 Modern Full Swift Twin — M22y Handoff

## Scope

M22y registers the existing `bhvBully` owner bridge for small and big
variants in the shared `SM64BehaviorDispatchBridge`. The general-actor route
updates both variants in source list order, preserves chase/patrol state and
generation-safe object records, and keeps owner-thread delivery explicit.
Unknown identities remain fail-closed as `unmigrated` events.

This closes a nineteenth live owner route only. The focused fixture exercises
small/big variant ordering, source action state, the shared scheduler's
transient respawner/Bob-omb/Skeeter children, and a second tick. The standalone
differential remains the authority for Bully minion-parent, collision,
reward/presentation, and death branches; real collision, camera/audio,
renderer, progression/save consumers, remaining adapters, and whole-game
parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C nineteen-route
  fingerprint `0x0795fa60e1764868`; small and big Bully identities dispatch in
  source order alongside the existing routes, with transient children and
  owner deliveries explicitly preserved.
- `script/test_bully_object_bridge.sh` — standalone Bully fingerprint
  `0x8d7dc5c6315293c4`; value-kernel and owner differential remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the Bully dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22y-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22y-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22y-matrix-01.log` through `-09.log`).
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
