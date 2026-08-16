# SM64 Modern Full Swift Twin — M22ba Handoff

## Scope

M22ba registers Tuxie's two terminal child identities in the existing mother
owner route. The source `bhvPenguinBaby` and `bhvUnused20E0` scripts are both
`BREAK()` terminal behaviors reached by the mother's held-child state machine.
The shared dispatcher now records both under `TuxiesMotherObjectBridge`, so
the mother remains the sole owner-thread scheduler and no child scheduler is
invented.

This closes identity/manifest accounting only. Held-child collision,
presentation, whole-engine behavior execution, and whole-game parity remain
open. The behavior inventory remains 534 rows, with 78 `swift_value_owner`
routes and 456 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_dispatch_bridge.sh` — strict Swift/C dispatch
  fingerprint `0xad08314b577b6419`; both terminal identities select route 41,
  `tuxiesMother`.
- `script/test_behavior_manifest.sh` — Swift/C manifest fingerprint
  `0xe7718dc2db19ec7c`; 534 rows, 78 Swift routes, and 456 explicit C
  adapters.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — Swift 6 engine-context and schema-4
  live-route contracts pass.
- `/tmp/sm64-modern-m22ba-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22ba-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Continue exact source-backed identity reconciliation while keeping generic
   smoke/star and unrelated static surfaces explicitly unmigrated until their
   owners exist.
2. Migrate the remaining 456 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Tuxie's held-child collision/presentation consumers and whole-game
   parity before calling the route fully integrated.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next reachable identity against its source behavior and existing
owner bridge. Add only a source-backed route and manifest mapping, then repeat
the focused Swift/C contracts, regenerated native build, shebang-aware matrix,
strict audit, and handoff checks before committing.
