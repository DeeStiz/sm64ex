# SM64 Modern Full Swift Twin — M22k Handoff

## Scope

M22k registers the existing `bhvBoo` owner bridge in
`SM64BehaviorDispatchBridge`. The shared owner-thread scheduler now dispatches
Amp and Boo in general-actor list order before the default-list pendulum and
respawner routes, preserves Boo's generation-safe transform,
opacity/tangibility/deletion state, and returns Boo effects and owner-thread
deliveries in the tick receipt. Unknown identities remain explicit
`unmigrated` events; no C-shaped fallback is implied.

This closes a fourth live owner route only. It does not close the remaining
reachable adapters, real audio/render/collision consumers, progression/save
authority, or whole-game parity.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C four-route
  fingerprint `0xace102e11ae86895`; Amp/Boo general-actor ordering, pendulum
  and respawner dispatch, same-list child traversal, transfer fields, and
  deletion delivery match.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the shared dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22k-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22k-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22k-matrix-01.log` through `-09.log`).
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge in the shared
   dispatch table and attach level spawns through exact behavior identity.
2. Migrate the remaining 461 reachable adapters, or record an explicitly
   approved compatibility exception for each one.
3. Add real audio, camera, collision, renderer, progression, and save
   consumers, then compare complete C-vs-Swift object/effect/render traces.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Register the next exact Swift owner identity in `SM64BehaviorDispatchBridge`,
preserve explicit `unmigrated` events for unknown identities, add an
independent Swift/C ordering fixture, and rerun the focused contracts, native
build, and complete 206-script matrix before promoting the next milestone.
