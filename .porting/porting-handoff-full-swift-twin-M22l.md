# SM64 Modern Full Swift Twin — M22l Handoff

## Scope

M22l registers the existing `bhvBobomb` owner bridge in
`SM64BehaviorDispatchBridge`. The shared owner-thread scheduler dispatches
Amp, Boo, and Bob-omb in general-actor list order, preserves Bob-omb
fuse/chase state, materializes the transient smoke child, and returns the
child's owner deletion delivery while leaving its behavior identity explicitly
`unmigrated`. Unknown identities remain fail-closed; no C-shaped fallback is
implied.

This closes a fifth live owner route only. It does not close the remaining
reachable adapters, transient-child routes, real audio/render/collision
consumers, progression/save authority, or whole-game parity.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C five-route
  fingerprint `0xcead05b9ae997287`; Amp/Boo/Bob-omb general-actor ordering,
  default-list pendulum/respawner traversal, smoke-child identity, transfer
  fields, and owner deletion delivery match.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the shared dispatcher dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22l-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22l-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22l-matrix-01.log` through `-09.log`).
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge in the shared
   dispatch table and attach level spawns through exact behavior identity.
2. Migrate the remaining 461 reachable adapters and transient children, or
   record an explicitly approved compatibility exception for each one.
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
