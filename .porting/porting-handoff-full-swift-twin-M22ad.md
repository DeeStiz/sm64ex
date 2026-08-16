# SM64 Modern Full Swift Twin — M22ad Handoff

## Scope

M22ad registers the existing Scuttlebug owner bridge and both exact behavior
identities in the shared `SM64BehaviorDispatchBridge`. The spawner-list route
now creates the general-actor child during the same live scheduler traversal;
the child is dispatched immediately after the spawner, with generation-safe
records and owner-thread effect delivery retained. Unknown identities remain
fail-closed as `unmigrated` events.

This closes a twenty-fourth live owner route only. The focused shared fixture
covers the cross-list timer gate, same-frame child allocation, exact identity
ordering, and spawner/child effect records. The standalone differential
remains the authority for Scuttlebug chase, alert, turn, knockback, attack,
recovery, and deletion branches; real collision admission, full progression,
camera/audio, renderer, save, remaining adapters, and whole-game parity remain
open. The behavior inventory remains 534 rows with 73 known Swift value/owner
identities and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twenty-four-route
  fingerprint `0xd76fe2277f9b8226`; the spawner and child dispatch in one
  cross-list traversal.
- `script/test_scuttlebug_object_bridge.sh` — standalone Swift/C Scuttlebug
  fingerprint `0x7204b63131e2054b`; value and owner behavior remains matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22ad-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ad-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Scuttlebug collision admission, full attack/recovery progression,
   and camera/audio/renderer/progression/save consumers before claiming full
   behavior parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered composite owner bridge, add its external-tick
boundary and exact behavior identities, then repeat the focused Swift/C,
runtime/oracle, regenerated native build, shebang-aware matrix, strict audit,
and handoff checks before committing.
