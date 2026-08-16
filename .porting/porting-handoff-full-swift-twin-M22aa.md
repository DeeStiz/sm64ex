# SM64 Modern Full Swift Twin — M22aa Handoff

## Scope

M22aa registers the existing Chain Chomp owner bridge and its five metallic
segment identities in the shared `SM64BehaviorDispatchBridge`. The
general-actor route allocates the parent and all five segments during one live
traversal, preserves stable parent-relative segment records, synchronizes
segment effects after the parent callback, and keeps unload/deletion delivery
on the owner thread. Unknown identities remain fail-closed as `unmigrated`
events.

This closes a twenty-first live owner route only. The focused fixture exercises
parent allocation, five same-frame child callbacks, exact behavior identity
ordering, and segment effect synchronization. The standalone differential
remains the authority for lunge/turn/attack/release and unload branches; real
collision, camera/audio, renderer, progression/save consumers, remaining
adapters, and whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twenty-one-route
  fingerprint `0xc0f2496d23f9991c`; Chain Chomp parent and five segment
  identities dispatch in one live general-actor traversal.
- `script/test_chain_chomp_object_bridge.sh` — standalone Chain Chomp
  fingerprint `0x89d7ec70d95560c8`; value-kernel and owner differential remain
  matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the Chain Chomp dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22aa-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22aa-final-matrix.log` — all 206 script indices replayed
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
