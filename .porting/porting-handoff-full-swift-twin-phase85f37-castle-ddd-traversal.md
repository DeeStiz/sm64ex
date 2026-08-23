# Full Swift Twin Handoff — Phase 85f37 Castle-to-DDD Traversal Discovery

Date: 2026-08-22

## Verdict

**FAIL-CLOSED — NO DETERMINISTIC SOURCE-AUTHORED OWNER-THREAD TRAVERSAL IS
AVAILABLE.** The authored path from the current Castle Grounds startup into
Castle area 3's DDD painting and then DDD area 1 is present, but the existing
automated input/state-machine recipes do not perform the required movement,
door interactions, or painting entry. The bounded camera-water lifecycle
probe therefore retained zero native camera event-307 receipts. No C/Swift
pair, route admission, manifest/report/ledger update, or runtime acceptance is
claimed.

## Authored traversal chain

The source chain is unambiguous:

- `levels/castle_grounds/script.c:95-135` is the authored Castle Grounds
  entry and starts Mario at `(-1328, 260, 4664)`. Its warp nodes `0x00` and
  `0x01` target Castle area 1 nodes `0x00` and `0x01`.
- The real door path is owner-thread interaction, not a level-load shortcut.
  `src/game/behaviors/door.inc.c:46-80` turns an interaction into a door
  action; `src/game/mario_actions_cutscene.c:935-967` reaches
  `level_trigger_warp(m, WARP_OP_WARP_DOOR)` at the authored door action
  boundary; `src/game/level_update.c:778-784,874-883` reads the used door's
  source node and resolves its compiled destination.
- Castle area 1's authored door objects and nodes are in
  `levels/castle_inside/script.c:18-32`. The basement-side doors at lines
  `27-28` carry source nodes `0x05`/`0x06`, whose nodes at lines `31-32`
  target Castle area 3 nodes `0x00`/`0x01`.
- Castle area 3's authored DDD painting nodes are
  `levels/castle_inside/script.c:162-179`: painting IDs `0x15`, `0x16`, and
  `0x17` each target `LEVEL_DDD`, area `0x01`, node `0x0A`.
- The DDD entry surface is the real `bhvDddWarp` object at
  `levels/castle_inside/script.c:290-300`. Its collision behavior selects
  `inside_castle_seg7_collision_ddd_warp` in
  `src/game/behaviors/ddd_warp.inc.c:3-8`; the painting surfaces
  `SURFACE_PAINTING_WARP_E8/E9/EA` are authored at
  `levels/castle_inside/areas/3/collision.inc.c:2528-2568`.
- `src/game/level_update.c:644-682` converts those authored floor surfaces
  into the area painting-warp node and initiates the normal delayed level
  warp. The DDD painting owner/state is source-authored in
  `levels/castle_inside/painting.inc.c:1545-1568` and advanced by
  `paintings_update_dynamics()` / `move_ddd_painting()` in
  `src/game/paintings.c:1085-1133,1221-1255`.
- The destination is the authored `levels/ddd/script.c:63-97` area-1 entry;
  its camera is `GEO_CAMERA(2, ...)` at
  `levels/ddd/areas/1/geo.inc.c:14-24` (`CAMERA_MODE_OUTWARD_RADIAL`). The
  event-307 source witness is the real `find_water_level` call and observer at
  `src/game/camera.c:2465-2487`.

## Existing input and bootstrap recipes

The available owner-thread automation is not a Castle traversal recipe:

- `src/game/game_init.c:662-696` exposes the existing opt-in selectors. The
  ordinary gameplay selector starts the authored Castle Grounds bootstrap;
  other selectors choose independent Bob-omb, CotMC, BBH, RR, JRB, HMC, SL,
  or Castle-area-2 fixtures. There is no DDD selector and no selector that
  sequences Castle Grounds door -> Castle area 1 -> area 3 -> DDD painting.
- `SM64Modern/AppleInputService.swift:270-310` provides only bounded menu
  Start/A pulses and, when `SM64_MODERN_AUTOMATED_GAMEPLAY` is enabled, a
  constant `left_stick_x=16000`, `left_stick_y=0`. It has no directional
  phases, door interaction/button phases, or painting-entry state machine.
  The front-end bridge explicitly sets `debug_level_select=0` at
  `SM64Modern/AppleInputService.swift:377-389`.
- The existing camera-water contract's C input callback is zeroed at
  `tests/sm64_modern_camera_water_route_pair_contract.c:167-177`; it runs only
  two owner-thread lifecycle steps at lines `397-406`. It is therefore a
  bounded startup reachability witness, not a traversal recipe. The earlier
  720-step transition recipe is likewise documented as blocked in
  `.porting/porting-handoff-full-swift-twin-phase85am-transition-route.md`.

No direct level register/load was used as a traversal operation; no debug
selector, forced camera mode, synthetic object/Sushi injection, coordinate
matching, or direct `find_water_level`/other helper call was used.

## Bounded read-only probe

Command:

```text
SM64_CAMERA_WATER_PAIR_ROOT=/private/tmp/phase85f37-castle-ddd-traversal \
  ./script/test_camera_water_route_pair.sh
```

The existing source-lifecycle probe returned exit status `77` and reported:

```text
camera_water_route_init status=0 oracle=0 parity=0
camera_water_route_step index=0 status=0 oracle=0 parity=0
camera_water_route_step index=1 status=0 oracle=0 parity=0
camera_water_route_debug oracle_end=0 result_status=0 actual=1797 retained=0 non_recipe=0 failures=0
camera_water_route_blocked authored_ddd_area1_reached=0 route_records=0 non_recipe=0 reason=ordinary_lifecycle_recipe_did_not_reach_ddd_area1
SM64 Modern camera-water route pair blocked fail_closed=1
reason=ordinary_owner_thread_lifecycle_did_not_reach_authored_ddd_area1
synthetic_receipt=0 direct_level_load=0 forced_camera_mode=0 sushi_injection=0
canonical_manifest_mutation=0 canonical_ledger_mutation=0
```

The source C trace remained header-only (`72` bytes), so camera event `307`
did not appear. The blocked rerun was byte-identical. The native trace hashes
were:

| artifact | bytes | SHA-256 |
| --- | ---: | --- |
| `/private/tmp/phase85f37-castle-ddd-traversal/camera-water-c.trace` | 72 | `a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512` |
| `/private/tmp/phase85f37-castle-ddd-traversal/camera-water-c-blocked-rerun.trace` | 72 | `a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512` |

The generated Swift one-record schema witness and tamper/partial/single-file
checks are negative-fence machinery only; they are not evidence of a native
DDD traversal or event-307 receipt.

## Validation and unblock

- `./script/test_camera_water_route_pair.sh` — exit `77`, fail-closed as
  expected; blocked rerun and negative fences passed.
- `git -c core.fsmonitor=false diff --check` — passed after the handoff was
  written.
- No source, Swift, test, script, manifest, report, ledger, or project file
  was changed; this handoff is the only repository artifact added by this
  phase.

The exact unblock is an ordinary source-authored owner-thread input recipe
that crosses the Castle Grounds door, reaches the authored Castle area-1
basement door and area 3, walks onto one of the DDD painting floor surfaces,
and lets the normal painting/warp state machine enter DDD area 1. Until that
recipe exists, do not rerun route admission or mutate canonical artifacts.
