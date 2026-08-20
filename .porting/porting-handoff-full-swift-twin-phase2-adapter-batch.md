# SM64 Modern Full Swift Twin — Phase 2 Adapter Batch Handoff

## What was done

This bounded batch adds focused value/owner implementations and C parity
contracts for Mad Piano, Sushi Shark plus its collision child, the Ukiki/Macro-
Ukiki/cage/cage-star/MIPS/Toad/menu-button family, Squarish Path Moving,
Pushable Metal Box, and Tilting Bowser Lava Platform. The Mad Piano route is
centrally wired into `BehaviorDispatchBridge`; the other five slices are
intentionally local-only until their central dispatch and coverage wiring is
integrated.

The worker-result writer and serial merge tool now have strict Swift 6 smoke
coverage. The full Debug Xcode project build includes all new Swift sources.

## Ground-truth checks

Passed:

- `./script/test_mad_piano.sh` — `0x02bff984a89b5be6`.
- `./script/test_npc_menu.sh` — `0x4ff30b57a3db6922`.
- `./script/test_pushable_metal_box.sh` — `0x1f8d2f13bc790860`.
- `./script/test_squarish_path_moving.sh` — `0x9cbe6c17eb977926`.
- `./script/test_sushi_shark.sh` — `0x829e2dcf1c565b1a`.
- `./script/test_tilting_bowser_lava_platform.sh` — `0x05b5b2089849cc23`.
- `./script/test_route_shard_worker_result.sh`.
- `./script/test_behavior_manifest.sh` — 534 rows, 489 Swift owners, 45 C
  adapters, fingerprint `0xb292402a519b1ea1`.
- `./script/test_behavior_coverage.sh`.
- `./script/test_behavior_dispatch_bridge.sh` — fingerprint
  `0x681ceb2358bf2e21`.
- `./script/test_engine_runtime.sh`.
- Regenerated Xcode project and Debug build succeeded with
  `CODE_SIGNING_ALLOWED=NO`.
- `bash -n` and `git diff --check` pass.

## What's deferred

- Central dispatch/coverage integration for the Sushi Shark, NPC/menu,
  Squarish Path Moving, Pushable Metal Box, and Tilting Bowser Lava Platform
  slices.
- The remaining 45 `unmigrated_c_adapter` rows.
- Real worker-result production from every live route shard; the writer and
  merge tools currently validate the protocol but do not execute the engine.
- Full 7,419-shard live execution, sanitizer/optimized reruns, M34 visual and
  device closure, M35 release packaging, and human acceptance.

## Known issues and watch-for

- Do not count local-only route smokes as Swift-authority or live route proof.
- Keep the central dispatch/manifest integration serial; route-local files are
  safe to develop in parallel only while their identity mappings remain absent.
- Regenerate `SM64Modern.xcodeproj` from `project.yml` after adding sources; do
  not hand-edit the generated project.
- Preserve external worker reports and raw traces outside Git; do not commit
  ROM-derived content.

## Skills needed next

`porting-methodology`, `porting-validate`, `porting-handoff`, strict Swift 6
concurrency/build skills, then the relevant live-route/oracle and Metal 4
validation skills.
