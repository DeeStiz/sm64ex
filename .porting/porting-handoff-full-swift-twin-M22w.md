# SM64 Modern Full Swift Twin — M22w Handoff

## Scope

M22w registers the existing `bhvHeaveHo` owner bridge and its stable throw
child identity in the shared `SM64BehaviorDispatchBridge`. The general-actor
route updates the Heave Ho parent and child in source list order, preserves
submerged/tangible/hidden state, and keeps throw consumption in a pointer-free
value child state. Unknown identities remain fail-closed.

This closes a sixteenth live owner route only. The focused fixture exercises a
submerged parent and its throw child and verifies cross-list ordering. The
standalone differential remains the authority for wind-up/chase/throw branches;
real collision, camera/audio, renderer, progression/save consumers, remaining
adapters, and whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C sixteen-route
  fingerprint `0x60a85f947da2a12`; Heave Ho and throw-child identities are
  dispatched after Snufit, with parent/child ordering and transient respawner
  and Bob-omb children explicitly preserved.
- `script/test_heave_ho_object_bridge.sh` — standalone Heave Ho parent/throw
  child fingerprint `0x9c4a7443f2c09281`; value-kernel and owner differential
  remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the Heave Ho dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22w-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22w-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22w-matrix-01.log` through `-09.log`).
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
