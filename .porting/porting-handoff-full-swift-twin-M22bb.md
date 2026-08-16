# SM64 Modern Full Swift Twin — M22bb Handoff

## Scope

M22bb closes the behavior-manifest accounting gap for two source declarations
that already have live owner dispatch routes. `bhvHeaveHoThrowMario` now maps
to `HeaveHoObjectBridge`, and `bhvPokeyBodyPart` now maps to
`PokeyObjectBridge`. This is an accounting-only change: it does not create a
second scheduler, alter the shared dispatcher, or claim collision and
presentation consumers that are not yet migrated.

The inventory remains 534 behavior rows, with 80 `swift_value_owner` routes and
454 explicit `unmigrated_c_adapter` rows.

## Evidence

- `script/test_behavior_manifest.sh` — Swift/C manifest fingerprint
  `0x103cb984bb585a21`; 534 rows, 80 Swift routes, and 454 explicit C
  adapters.
- `script/test_behavior_dispatch_bridge.sh` — the unchanged strict Swift/C
  dispatch fingerprint remains `0xad08314b577b6419`.
- `script/test_engine_runtime.sh`, `script/test_live_route_oracle.sh`, and
  `script/test_live_route_promotion.sh` — engine-context and schema-4 live
  route contracts pass.
- `/tmp/sm64-modern-m22bb-build.log` — regenerated native Swift 6 Debug build,
  `BUILD SUCCEEDED`.
- `/tmp/sm64-modern-m22bb-final-matrix.log` — all 206 script indices replayed
  with each script's declared interpreter, `runs=206 failures=0`.
- `git diff --check` — clean; strict-concurrency audit reports zero
  `@unchecked Sendable` declarations in the audited runtime.

## Remaining work

1. Continue exact source-backed identity reconciliation while keeping generic
   smoke/star/coin and unrelated static surfaces explicitly unmigrated until
   their owners exist.
2. Migrate the remaining 454 reachable adapters/transient children, or record
   an explicitly approved compatibility exception for each one.
3. Complete Heave Ho throw-Mario and Pokey body-part collision/presentation
   consumers and whole-game parity before calling either route fully
   integrated.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict parity-shard
   qualification, Metal 4 production validation, and release/human gates.

## Next command

Inspect the next reachable identity against its source behavior and existing
owner bridge. Add only a source-backed route or manifest mapping, then repeat
the focused Swift/C contracts, regenerated native build, shebang-aware matrix,
strict audit, and handoff checks before committing.
