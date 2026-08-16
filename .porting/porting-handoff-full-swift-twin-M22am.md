# SM64 Modern Full Swift Twin — M22am Handoff

## Scope

M22am registers the existing generic explosion owner bridge and its water-bubble
and ground-smoke child identities in the shared
`SM64BehaviorDispatchBridge`. The destructive-list route preserves the source
initialization sound/camera presentation, fade/animation state, explicit bubble
seed inputs, smoke lifetime, and generation-safe owner delivery receipts.
Unknown identities remain fail-closed as `unmigrated` events.

This closes the generic explosion behavior identity route only. The focused
shared fixture covers the first destructive-list initialization callback with
sound/camera presentation; the standalone object bridge remains the authority
for water bubble allocation, ground smoke, collision/hitbox fields, and
deletion timing. Remaining adapters and whole-game parity remain open. The
behavior inventory remains 534 rows with 73 known Swift value/owner identities
and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C thirty-four-route
  fingerprint `0x27dd12efd4a84c8d`; the generic explosion dispatches in the
  destructive-list traversal and returns two typed presentation intents.
- `script/test_explosion.sh` — standalone Swift/C explosion fingerprint
  `0x29e3dc6674824f4a`; initialization, water bubbles, ground smoke, hitbox,
  presentation, and deletion contracts remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22am-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22am-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete explosion bubble/smoke presentation, water/collision, audio,
   camera-shake, and durable progression consumers before claiming full
   gameplay parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge, add its external-tick boundary and
exact behavior identities, then repeat the focused Swift/C, runtime/oracle,
regenerated native build, shebang-aware matrix, strict audit, and handoff
checks before committing.
