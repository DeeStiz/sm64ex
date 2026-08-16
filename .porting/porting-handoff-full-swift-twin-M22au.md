# SM64 Modern Full Swift Twin — M22au Handoff

## Scope

M22au registers the existing Tuxie's-mother owner bridge in the shared
`SM64BehaviorDispatchBridge` for the `bhvTuxiesMother` general-actor identity.
The route preserves the mother action/subaction reducer, generation-safe
record synchronization, graph-eye selection output, and owner-thread
dialog/audio/star delivery receipts.

The carried `bhvSmallPenguin` identity intentionally remains on the existing
small-penguin route. Mother-owned baby/unused behavior transitions remain
explicit seams because the parent bridge does not silently claim the child
behavior VM or its collision/held consumers. This closes the Tuxie's-mother
parent identity dispatch slice only; remaining adapters and whole-game parity
remain open. The behavior inventory remains 534 rows with 73 known Swift
value/owner identities and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C forty-two-route
  fingerprint `0xa114f54c82f5b270`; `bhvTuxiesMother` dispatches through the
  shared route and the small-penguin child identity remains on its own route.
- `script/test_tuxies_mother_object_bridge.sh` and
  `script/test_tuxies_mother_eyes_object_bridge.sh` — standalone Swift/C
  fingerprints `0xbe32e199efb473f8` and `0xfbaf45212b54a77d`; mother dialog,
  child/reward state, and graph-eye owner delivery remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22au-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22au-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete the Tuxie's-mother child behavior, held/collision, dialog/audio,
   graph-node presentation, and reward consumers before claiming full gameplay
   parity; preserve the explicit small-penguin and baby/unused child seams.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge or exact child identity, add its
external-tick boundary and fail-closed route, then repeat the focused Swift/C,
runtime/oracle, regenerated native build, shebang-aware matrix, strict audit,
and handoff checks before committing.
