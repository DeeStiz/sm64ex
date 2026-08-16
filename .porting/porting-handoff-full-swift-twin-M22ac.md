# SM64 Modern Full Swift Twin — M22ac Handoff

## Scope

M22ac registers the existing Pokey owner bridge and its five body-part
identities in the shared `SM64BehaviorDispatchBridge`. The general-actor route
now allocates the parent and all five body parts during one live traversal,
preserves parent alive-part counters and stable body indices, synchronizes
generation-safe child records, and leaves deletion cleanup on the owner
thread. Unknown identities remain fail-closed as `unmigrated` events.

This closes a twenty-third live owner route only. The focused shared fixture
covers initial parent allocation, same-frame body callbacks, exact identity
ordering, and parent/body effect records. The standalone differential remains
the authority for Pokey wall/turn, unload, replenish, attacked-part, and
head-death branches; real collision admission, full progression, camera/audio,
renderer, save, remaining adapters, and whole-game parity remain open. The
behavior inventory remains 534 rows with 73 known Swift value/owner identities
and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twenty-three-route
  fingerprint `0xa49eac378862bfbc`; Pokey parent and five body parts dispatch
  in one live general-actor traversal.
- `script/test_pokey_object_bridge.sh` — standalone Swift/C Pokey fingerprint
  `0x0dc81376f8b50092`; parent/body value and owner differential remains
  matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22ac-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ac-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Pokey collision admission, full body attack/replenish progression,
   and camera/audio/renderer/progression/save consumers before claiming full
   behavior parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Register the next exact Swift owner identity in `BehaviorDispatchBridge`,
preserve explicit `unmigrated` events for unknown identities, add an
independent Swift/C ordering fixture, and rerun the focused contracts, native
build, and complete 206-script matrix before promoting the next milestone.
