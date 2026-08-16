# SM64 Modern Full Swift Twin — M22h Handoff

## Scope

M22h adds `SM64BehaviorDispatchBridge`, the first shared owner-thread
behavior-identity dispatch pass. A single live scheduler selects the proven
`bhvDecorativePendulum` and `bhvRespawner` bridges, preserves default-list
insertion order when the respawner appends a child, and records the child's
unmapped behavior identity as an explicit `unmigrated` event. No unknown
identity silently receives a fake Swift callback.

This is a two-route dispatch seam, not whole-engine behavior closure. The
remaining reachable adapters, C compatibility authority, real audio/render
consumers, and whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C mixed-route
  fingerprint `0x9445d688831ca6c7`; pendulum → respawner → unknown-child
  ordering, same-list child traversal, transfer fields, and deletion delivery
  match.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22h-build.log` — regenerated Xcode sources/native Debug
  build, `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22h-final-matrix.log` — complete matrix,
  `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Expand the shared dispatch table to every mapped Swift owner and make the
   engine context use it as the default object callback.
2. Migrate the remaining 461 reachable adapters, or record an explicitly
   approved compatibility exception for each one.
3. Add real audio, camera, collision, renderer, progression, and save
   consumers, then compare complete C-vs-Swift object/effect/render traces.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Extend `SM64BehaviorDispatchBridge` with the next reachable Swift owner route,
attach it by exact behavior identity, preserve fail-closed `unmigrated` events,
then rerun its Swift/C contract, regenerated native Debug build, and complete
206-script matrix before promoting the next local milestone.
