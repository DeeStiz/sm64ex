# SM64 Modern Full Swift Twin — M22bc Handoff

## Scope

M22bc registers the source `bhvBobombBuddyOpensCannon` identity in the existing
Bob-omb Buddy owner route. This source script runs the same native Buddy loop
as `bhvBobombBuddy` with `oBobombBuddyRole = 1`; the Swift bridge already
models that cannon role in its value state. The new stable identity therefore
reuses the owner route and does not create a second scheduler.

This closes identity/dispatch and manifest accounting only. Cannon-role
collision, dialog/camera/audio presentation, whole-engine execution, and
whole-game parity remain open. The inventory remains 534 behavior rows, with
81 `swift_value_owner` routes and 453 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C dispatch
  fingerprint `0x681ceb2358bf2e21`; the cannon-role identity selects route 24,
  `bobombBuddy`.
- `script/test_behavior_manifest.sh` — Swift/C manifest fingerprint
  `0x6c4d82af10c767ba`; 534 rows, 81 Swift routes, and 453 explicit C
  adapters.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — engine-context and schema-4 live
  route contracts pass.
- `/tmp/sm64-modern-m22bc-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22bc-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Continue exact source-backed identity reconciliation while keeping generic
   smoke/star/coin and unrelated static surfaces explicitly unmigrated until
   their owners exist.
2. Migrate the remaining 453 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete cannon-role collision and camera/dialog/audio consumers before
   calling this variant fully integrated.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next reachable identity against its source behavior and existing
owner bridge. Add only a source-backed route or manifest mapping, then repeat
the focused Swift/C contracts, regenerated native build, shebang-aware matrix,
strict audit, and handoff checks before committing.
