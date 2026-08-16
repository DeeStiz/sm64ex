# SM64 Modern Full Swift Twin — M22v Handoff

## Scope

M22v registers the existing `bhvWhomp` owner bridge in the shared
`SM64BehaviorDispatchBridge`. The surface-list route is visited before the
general-actor routes by the shared scheduler, preserves Whomp initialize and
reset-home state, and emits an explicit owner-thread delivery record. Unknown
identities remain fail-closed. Optional surface collision, boss camera/audio,
and reward-star consumers stay behind their existing bridge seams; the shared
route intentionally runs the value-only path without those consumers.

This closes a fifteenth live owner route only. The focused fixture exercises a
normal Whomp in initialize state and verifies cross-list ordering. Standalone
Whomp contracts continue to cover collision/movement, boss presentation, and
reward-star behavior; those consumers are not claimed as whole-level
integration. Real collision/camera/audio/render consumers, the remaining
adapters, and whole-game parity remain open.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C fifteen-route
  fingerprint `0x439f38bbc24dc402`; Whomp is dispatched in the surface list
  before Amp/Boo/Bob-omb/Bird/Swoop/Piranha Plant/Big Boo/Fly Guy/Bullet Bill/
  Goomba/Spiny/Snufit, while respawner and transient children preserve their
  explicit unmigrated events.
- `script/test_whomp_object_bridge.sh` — standalone Whomp value/owner
  fingerprint `0x672073b350af199a`; initialize, chase/pound/death, owner
  delivery, and C differential remain matched.
- `script/test_whomp_object_movement_bridge.sh` and
  `script/test_whomp_boss_owner.sh` — collision/movement and King Whomp
  presentation/reward contracts remain matched outside the shared value-only
  route.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the Whomp dependency set.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22v-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22v-final-matrix.log` — complete matrix,
  `runs=206 failures=0` (bounded chunk logs are
  `/tmp/sm64-modern-m22v-matrix-01.log` through `-09.log`).
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
