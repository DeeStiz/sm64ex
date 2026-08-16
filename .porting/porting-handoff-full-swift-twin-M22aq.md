# SM64 Modern Full Swift Twin — M22aq Handoff

## Scope

M22aq registers the existing Mr. I eye and persistent iris owner bridge in the
shared `SM64BehaviorDispatchBridge`. The route preserves source eye-to-iris
allocation, identity-specific general-actor/default list order, idle/tangible
state, and generation-safe owner delivery receipts. Unknown identities remain
fail-closed as `unmigrated` events.

This closes the Mr. I eye/body identity route only. The focused shared fixture
exercises eye initialization and the persistent iris callback in one scheduler
traversal; the standalone object bridge remains the authority for transient
particle emission, collision, camera/dialog/music, reward, and deletion
consumers. Remaining adapters and whole-game parity remain open. The behavior
inventory remains 534 rows with 73 known Swift value/owner identities and 461
explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C thirty-eight-route
  fingerprint `0xb5967a4a609f387f`; Mr. I eye dispatches before its persistent
  iris child and both identities use the same owner route.
- `script/test_mr_i_object_bridge.sh` — standalone Swift/C Mr. I fingerprint
  `0x18b1a7bddb65a836`; idle/tracking/turning/death, particle, body, and cleanup
  contracts remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22aq-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22aq-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Mr. I particle/collision, camera/dialog/music, reward, attack,
   and durable progression consumers before claiming full gameplay parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge, add its external-tick boundary and
exact behavior identities, then repeat the focused Swift/C, runtime/oracle,
regenerated native build, shebang-aware matrix, strict audit, and handoff
checks before committing.
