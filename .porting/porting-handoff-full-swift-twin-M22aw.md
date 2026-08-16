# SM64 Modern Full Swift Twin — M22aw Handoff

## Scope

M22aw registers the distinct `bhvBowserBombExplosion` mine-flame identity in
the shared `SM64BehaviorDispatchBridge`. The existing Bowser-bomb bridge owns
the explosion timer/scale/animation reducer, same-frame Bowser smoke child
allocation, and generation-safe cleanup. The collision-spawned generic
`bhvExplosion` identity remains on the generic explosion route; these are
separate source identities and are not conflated.

This closes mine-flame identity selection only. Full mine-flame/smoke
collision, presentation, and Bowser arena consumers remain open. The behavior
inventory remains 534 rows with 73 known Swift value/owner identities and 461
explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C forty-two-route
  identity fingerprint `0xfb78737bee799bd1`; the Bowser mine-flame identity
  selects the Bowser-bomb owner route while generic explosion remains distinct.
- `script/test_bowser_bomb.sh` — standalone Swift/C Bowser-bomb fingerprint
  `0x1570ecd9d93c5b41`; bomb, mine-flame, smoke, timer, and child cleanup
  contracts remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22aw-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22aw-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and exact child
   identity, keeping composite parents on one owner-thread scheduler.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Bowser mine-flame/smoke collision, presentation, and arena
   consumers before claiming full gameplay parity; retain the generic
   explosion route as a separate canonical source identity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge or exact child identity, add its
external-tick boundary and fail-closed route, then repeat the focused Swift/C,
runtime/oracle, regenerated native build, shebang-aware matrix, strict audit,
and handoff checks before committing.
