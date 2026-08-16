# SM64 Modern Full Swift Twin — M22af Handoff

## Scope

M22af registers the existing Bowser shockwave and Bowser key owner bridges in
the shared `SM64BehaviorDispatchBridge`. The general-actor shockwave route and
level-list key route advance their value reducers in shared scheduler order,
preserve generation-safe effect records, and return owner-thread deletion
receipts. Unknown identities remain fail-closed as `unmigrated` events.

This closes two accessory behavior identity routes only. The focused shared
fixture covers shockwave interaction/fade effects and level-list key sparkle,
airborne, scale, and graph-offset effects. Standalone differential contracts
remain the authority for the full Bowser controller/arena, collision,
presentation, progression/save, and cutscene consumers; remaining adapters and
whole-game parity remain open. The behavior inventory remains 534 rows with 73
known Swift value/owner identities and 461 explicit `unmigrated_c_adapter`
rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C twenty-seven-route
  fingerprint `0x9a877c03788fbd70`; both Bowser accessory routes dispatch in
  the shared scheduler traversal.
- `script/test_bowser_shockwave.sh` — standalone Swift/C shockwave fingerprint
  `0x4dbf62c6e6d1688d`; reducer, interaction window, and owner bridge match.
- `script/test_bowser_key.sh` — standalone Swift/C key fingerprint
  `0xcd796d923af75c27`; reducer, effects, and owner bridge match.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22af-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22af-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Bowser controller/arena integration, collision and presentation
   consumers, progression/save/cutscene transitions, and real audio/camera
   wiring before claiming full parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge, add its external-tick boundary and
exact behavior identities, then repeat the focused Swift/C, runtime/oracle,
regenerated native build, shebang-aware matrix, strict audit, and handoff
checks before committing.
