# SM64 Modern Full Swift Twin — M22x Handoff

## Scope

M22x registers the existing `bhvSkeeter` owner bridge and its stable
`bhvSkeeterWave` child identity in the shared `SM64BehaviorDispatchBridge`.
The general-actor route updates the Skeeter parent and four water-wave
children in source list order, preserves water-surface wave spawning and
parent-relative transforms, and keeps deletion delivery on the owner thread.
The external-tick seam prevents a nested scheduler traversal while retaining
the standalone bridge's frame-based wave decay. Unknown identities remain
fail-closed.

This closes an eighteenth live owner route only. The focused fixture exercises
water-surface wave allocation, cross-list ordering, stable child IDs, and a
second tick of wave decay. The standalone differential remains the authority
for ground walk, wall bounce, lunge, attack/deletion, and random-turn branches;
real collision, camera/audio, renderer, progression/save consumers, remaining
adapters, and whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C eighteen-route
  fingerprint `0x15d862badc7d4b2c`; Skeeter and four-wave identities are
  dispatched after Chuckya, with parent/child ordering and transient respawner
  and Bob-omb children explicitly preserved.
- `script/test_skeeter_object_bridge.sh` — standalone Skeeter parent/wave
  fingerprint `0x171e3016f6b728d2`; value-kernel and owner differential remain
  matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the Skeeter dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22x-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22x-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22x-matrix-01.log` through `-09.log`).
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges currently own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Add real audio, camera, collision, renderer, progression, and save
   consumers, then compare complete C-vs-Swift object/effect/render traces.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Register the next exact Swift owner identity in `BehaviorDispatchBridge`,
preserve explicit `unmigrated` events for unknown identities, add an
independent Swift/C ordering fixture, and rerun the focused contracts, native
build, and complete 206-script matrix before promoting the next milestone.
