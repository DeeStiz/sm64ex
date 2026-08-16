# SM64 Modern Full Swift Twin — M22ao Handoff

## Scope

M22ao registers the existing Water Bomb spawner, bomb, and parent-relative
shadow identities in the shared `SM64BehaviorDispatchBridge`. The same-frame
general-actor route preserves source spawner-to-bomb/shadow allocation order,
falling-bomb action state, shadow follow state, and generation-safe owner
delivery receipts. The source shadow identity numerically aliases the spawner
identity, so both resolve through the same fail-closed route.

This closes the Water Bomb family identity route only. The focused shared
fixture exercises allocation and callback order for all three nodes; the
standalone object bridge remains the authority for collision/water admission,
bounce/explode timing, shadow hiding, audio/screen-shake presentation, and
deletion timing. Remaining adapters and whole-game parity remain open. The
behavior inventory remains 534 rows with 73 known Swift value/owner identities
and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C thirty-six-route
  fingerprint `0xc7b2a0dd41f3eda3`; spawner, bomb, and shadow callbacks run in
  one general-actor traversal with two children allocated by the spawner.
- `script/test_water_bomb_object_bridge.sh` — standalone Swift/C Water Bomb
  fingerprint `0x2c7546919aa992ae`; spawner timing, bomb gravity/bounce/explode,
  cannon particles, shadow follow/hide, owner deletion, and cleanup contracts
  remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22ao-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ao-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Water Bomb collision/water admission, audio/screen-shake,
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
