# SM64 Modern Full Swift Twin — M22ak Handoff

## Scope

M22ak registers the existing Koopa shell owner bridge for the level-list shell
(`bhvKoopaShell`) and underwater shell identities in the shared
`SM64BehaviorDispatchBridge`. The general-actor route advances the underwater
free/tangible reducer while the level-list route remains available for the
same generation-safe owner bridge. Effect-only sparkle, wave, drop, flame, and
mist children plus deletion receipts remain explicit owner-thread effects.
Unknown identities remain fail-closed as `unmigrated` events.

This closes the Koopa shell behavior identity route only. The focused shared
fixture covers the underwater free/tangible path; the standalone object bridge
remains the authority for shell movement, riding, collision inputs, transient
child allocation, and deletion behavior. Remaining adapters and whole-game
parity remain open. The behavior inventory remains 534 rows with 73 known
Swift value/owner identities and 461 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C thirty-two-route
  fingerprint `0x6de28a477071254e`; the underwater shell dispatches in the
  shared general-actor traversal with the tangible effect preserved.
- `script/test_koopa_shell_object_bridge.sh` — standalone Swift/C object-bridge
  fingerprint `0x3dee340d1e85a07e`; shell/underwater action, movement, riding,
  child allocation, and deletion contracts remain matched.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass with the expanded dispatcher dependencies.
- `script/test_behavior_manifest.sh` — fingerprint
  `0x9bb2863444c51d6d`; 534 rows, 73 `swift_value_owner` routes, and 461
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22ak-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ak-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Register every remaining already-proven Swift owner bridge and attach level
   spawns through exact behavior identity, including composite parents whose
   child bridges still own separate scheduler shadows.
2. Migrate the remaining 461 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Koopa shell movement/ride/collision and real transient-child,
   presentation, audio, and progression consumers before claiming full
   gameplay parity.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next unregistered owner bridge, add its external-tick boundary and
exact behavior identities, then repeat the focused Swift/C, runtime/oracle,
regenerated native build, shebang-aware matrix, strict audit, and handoff
checks before committing.
