# SM64 Modern Full Swift Twin — M22al Handoff

## Scope

M22al registers the existing Bowser key cutscene owner bridge for both the
unlock-door and course-exit behavior identities in the shared
`SM64BehaviorDispatchBridge`. The level-list route preserves the source
scale/animation/timer curves, publishes generation-safe records, and marks
completed keys for end-of-frame retirement. Camera and dialog ownership remain
explicit external seams; unknown identities remain fail-closed as
`unmigrated` events.

This closes the Bowser key cutscene behavior identity route only. The focused
shared fixture covers the course-exit scale/animation path; the standalone
object bridge remains the authority for the complete unlock-door/course-exit
curves and deletion timing. Remaining adapters and whole-game parity remain
open. The behavior inventory remains 534 rows with 73 known Swift value/owner
identities and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C thirty-three-route
  fingerprint `0x51b2a75e575c8448`; the course-exit key dispatches in the shared
  level-list traversal.
- `script/test_bowser_key_cutscene.sh` — standalone Swift/C fingerprint
  `0x94f233de3ce2784f`; unlock-door/course-exit scale, animation, timer, and
  deletion contracts remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22al-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22al-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Bowser key camera/dialog, progression/warp, and real cutscene
   presentation consumers before claiming full gameplay parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge, add its external-tick boundary and
exact behavior identities, then repeat the focused Swift/C, runtime/oracle,
regenerated native build, shebang-aware matrix, strict audit, and handoff
checks before committing.
