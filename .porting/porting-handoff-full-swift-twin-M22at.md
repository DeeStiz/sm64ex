# SM64 Modern Full Swift Twin — M22at Handoff

## Scope

M22at registers the existing Bowser-bomb owner bridge in the shared
`SM64BehaviorDispatchBridge` for the bomb and smoke behavior identities. The
general-actor route preserves bomb state, same-frame flame/spawn requests,
smoke identity, and generation-safe owner delivery. The source explosion
identity intentionally remains on the generic explosion route because the
canonical identity aliases that route; this is an explicit dispatch seam, not
a duplicate owner. Collision, camera/audio, and presentation consumers remain
typed external boundaries.

This closes the Bowser-bomb and smoke identity dispatch slice only. The focused
shared fixture exercises the bomb callback and smoke route identity; the
standalone object bridge remains the authority for collision, explosion/smoke
presentation, and downstream Bowser arena consumers. Remaining adapters and
whole-game parity remain open. The behavior inventory remains 534 rows with 73
known Swift value/owner identities and 461 explicit
`unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C forty-one-route
  fingerprint `0x5224e91ce4f4e6fe`; Bowser bomb dispatches through the shared
  route, preserves the bomb effect, and leaves the canonical explosion alias
  on the generic explosion route.
- `script/test_bowser_bomb.sh` — standalone Swift/C Bowser-bomb fingerprint
  `0x1570ecd9d93c5b41`; bomb ticking, flame request, smoke identity, and
  generation-safe owner cleanup remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22at-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22at-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Bowser bomb/explosion/smoke collision, presentation, and arena
   consumers before claiming full gameplay parity; preserve the explicit
   generic-explosion identity alias until a single canonical owner is proven.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge or exact child identity, add its
external-tick boundary and fail-closed route, then repeat the focused Swift/C,
runtime/oracle, regenerated native build, shebang-aware matrix, strict audit,
and handoff checks before committing.
