# SM64 Modern Full Swift Twin — M22ay Handoff

## Scope

M22ay closes the behavior-manifest accounting seam for the already-proven Big
Boo staircase route. The reachable `bhvBooBossSpawnedBridge` identity now maps
to `BigBooObjectBridge`, matching the shared dispatcher route whose parent
bridge allocates the three level-list staircase records and applies their
source transforms. No new scheduler or compatibility alias is introduced.

This is accounting closure only. Staircase collision/presentation consumers,
whole-engine behavior execution, and whole-game parity remain open. The
behavior inventory remains 534 rows, with 74 `swift_value_owner` routes and
460 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_manifest.sh` — Swift/C manifest fingerprint
  `0xcafe6a658d2f3342`; 534 rows, 74 Swift routes, and 460 explicit C
  adapters.
- `script/test_behavior_dispatch_bridge.sh` and
  `script/test_big_boo_object_bridge.sh` — the existing forty-two-route
  dispatch fingerprint and standalone parent/staircase owner contract remain
  green.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass.
- `/tmp/sm64-modern-m22ay-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ay-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register/migrate the next reachable owner or exact child route, preserving
   one owner-thread scheduler for composite parents.
2. Migrate the remaining 460 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Big Boo staircase collision/presentation consumers and whole-game
   parity before calling the route fully integrated.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next reachable behavior family with an existing Swift value/owner
kernel, add its manifest mapping and shared dispatch route only when the owner
bridge is real, then repeat the focused contracts, regenerated native build,
shebang-aware matrix, strict audit, and handoff checks before committing.
