# SM64 Modern Full Swift Twin — M22an Handoff

## Scope

M22an registers the existing Moneybag owner bridge for both the visible
general-actor identity and the hidden level-list coin identity in the shared
`SM64BehaviorDispatchBridge`. The route preserves source death/appear state,
object-list placement, generation-safe retirement, and explicit owner delivery
receipts. Unknown identities remain fail-closed as `unmigrated` events.

This closes the Moneybag behavior identity route only. The focused shared
fixture exercises the first death callback and verifies the hidden identity
maps to the same route; the standalone object bridge remains the authority for
loot/mist allocation, collision/hitbox fields, hidden-coin transformation, and
deletion timing. Remaining adapters and whole-game parity remain open. The
behavior inventory remains 534 rows with 73 known Swift value/owner identities
and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C thirty-five-route
  fingerprint `0x0f13ddc8b41d0d0c`; visible Moneybag dispatches in the
  general-actor traversal and the hidden identity resolves to the same route.
- `script/test_moneybag_object_bridge.sh` — standalone Swift/C Moneybag
  fingerprint `0x3fc38246b5faee0f`; appear/death state, loot/mist children,
  hidden transform, hitbox, presentation, and deletion contracts remain
  matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22an-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22an-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Moneybag loot/mist, hidden transformation, collision, audio,
   presentation, and durable progression consumers before claiming full
   gameplay parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge, add its external-tick boundary and
exact behavior identities, then repeat the focused Swift/C, runtime/oracle,
regenerated native build, shebang-aware matrix, strict audit, and handoff
checks before committing.
