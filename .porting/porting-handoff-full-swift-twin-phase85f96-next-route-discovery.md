# Full Swift Twin Handoff — Phase 85f96 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next distinct
source-owned lifecycle candidate is Whomp's Fortress' authored
`bhvWhompKingBoss` subject. Its area-1 script creates the King Whomp boss for
`ACT_1`, and the source owner has a complete scalar action, collision,
interaction, cutscene, effect, and reward lifecycle. The existing Swift value
owner preserves the King variant, health, action/timer state, movement values,
effect intents, and reward-star semantic child without exposing native
pointers. A future receipt can bind the exact authored boss tuple and reward
child by source identity and ordinal.

This is a source-authored boss lifecycle, not a generic enemy or collision
probe. This phase did not reuse the excluded DDD, WDW, TTC, Bob, Spindrift,
Spindel, Snowman-wind, JRB treasure, Castle-traversal, BBH, environment-effect,
generic-water, or intro families. No native WF load, direct helper call,
synthetic Whomp spawn, object injection, trace, source edit,
manifest/report/ledger mutation, or admission was done.

## Frozen manifest boundary

The current source tree was scanned with the existing reachability and route
manifest tools under the isolated temporary root
`/private/tmp/sm64-phase85f96-next-route-discovery.EJAFQ1/`:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
manifest_cmp=identical_to_retained_build_manifest
domains=audio_asset:295 behavior:534 collision:64 display_list:5918 geo_layout:66 level_script:34 oracle_hook:14 render_callback:219 rng:136 save_mutation:120 text:4 transition:16
```

The selected generated row resolves exactly once and remains planned:

```text
0x28e0617bfc286cbe|behavior|bhvWhompKingBoss|data/behavior_data.c|0x425f2ecc0685117a|0xa811784982556e63|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The source behavior coverage manifest is unchanged:

```text
behavior_manifest_rows=534
swift_value_owner=511
unmigrated_c_adapter=23
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
behavior_manifest_cmp=identical_to_retained_build_manifest
selected_mapping=bhvWhompKingBoss|data/behavior_data.c|swift_value_owner|WhompObjectBridge|King Whomp variant owner route
```

The designated local canonical route report remains the Phase 85f81
write-once artifact at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`,
SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, with
7,420 rows, 26 terminal `passed`, and 7,394 `planned`
(`26/7420 = 0.350404313%`). The selected row is exactly one
`planned|0|0|0|` ledger row.

The historical backup remains byte-distinct and untouched at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`, with
25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`). The selected backup row is also exactly one
`planned|0|0|0|` row. Neither report was opened for write.

## Authored source lifecycle

The generated row is the source-authored behavior program at
`data/behavior_data.c:3260-3280`:

```text
bhvWhompKingBoss:
    BEGIN(OBJ_LIST_SURFACE)
    SET_INT(oBehParams2ndByte, 1)
    SET_INT(oHealth, 3)
    GOTO(bhvSmallWhomp + 1 + 1)

bhvSmallWhomp common body:
    OR_INT(oFlags, COMPUTE_ANGLE_TO_MARIO | COMPUTE_DIST_TO_MARIO |
           SET_FACE_YAW_TO_MOVE_YAW | UPDATE_GFX_POS_AND_ANGLE)
    LOAD_ANIMATIONS(oAnimations, whomp_seg6_anims_06020A04)
    LOAD_COLLISION_DATA(whomp_seg6_collision_06020A0C)
    ANIMATE(0)
    SET_OBJ_PHYSICS(0, -400, -50, 0, 0, 200, 0, 0)
    SET_HOME()
    BEGIN_LOOP()
        CALL_NATIVE(bhv_whomp_loop)
    END_LOOP()
```

The native owner is `src/game/behaviors/whomp.inc.c:17-258`. The source
action machine performs the King intro/camera and dialog gate (action 0),
chase/turn/pound/fall/land transitions (actions 1-6), the King ground-pound
health and shake lifecycle, and the defeat dialog/reward path (actions 8-9).
The common owner updates floor/walls, moves with the authored `-20` step,
conditionally hides by Mario height, and loads the collision model. The King
branch starts with health `3`; each valid ground pound emits the source sound,
mist/triangle-break/camera-shake intents, and decrements health. On the final
defeat dialog it hides and becomes intangible, raises Y by `100`, emits the
King death sound and a star at `(180, 3880, 340)`, then enters the boss-wait
state and stops boss music at timer `60`.

The direct authored subject is the first entry (source ordinal `0`) of
`levels/wf/script.c:84-91`:

```text
OBJECT_WITH_ACTS(
    model=MODEL_WHOMP,
    position=(0, 3584, 0),
    face_angles=(0, 0, 0),
    behavior_parameter=0x00000000,
    behavior=bhvWhompKingBoss,
    acts=ACT_1
)
```

`levels/wf/script.c:142-160` opens the authored WF area 1, links
`script_func_local_4` along with the source terrain and macro objects, and
`levels/wf/script.c:162-165` runs the ordinary `MARIO_POS` plus
`CALL`/`CALL_LOOP(lvl_init_or_update)` lifecycle. The source resources remain
the Whomp actor model/geo and `whomp_seg6_collision_06020A0C`; they are not
replaced by a neighboring small Whomp. The normal Castle Inside painting
entries `levels/castle_inside/script.c:39-41` target `LEVEL_WF`, area 1, node
`0x0A`; this is only the authored input recipe. No Castle traversal, direct
level registration, coordinate selection, or object injection was performed.

The C owner uses `gSecondCameraFocus`, `gMarioObject`, and source object
references internally for camera, Mario-relative pound effects, and platform
relations. Those relationships are not receipt identity. The observer must
copy their scalar outcomes and semantic effect intents without publishing
`o`, `gMarioObject`, `gMarioState`, camera globals, temporary `Vec3f` storage,
or spawned-object pointers.

## Existing pointer-free Swift owner route

`SM64Modern/WhompEnemy.swift:3-379` contains the value-only King/normal
variant state, fixed-width action enum, scalar input record, effect bitset,
and reducer. Its King path mirrors health, sub-actions, timers, camera/music
intents, damage, shake, defeat, and boss-wait behavior. Inputs such as Mario
ground pound, on-platform, landing, dialog completion, distance, angle, and
far-below state are booleans or fixed-width values.

`SM64Modern/WhompObjectBridge.swift:3-24,25-38` records generation-safe
`SM64ObjectID` values, the King variant, copied state, and semantic effect
records. Its shared scheduler path at `:139-198` keeps list traversal on the
owner thread. The update path at `:200-399` reduces copied state, optionally
consumes scalar collision/movement results, routes effect intents, and creates
the reward star through a semantic parent `SM64ObjectID` with the authored
model, behavior identity, and `(180,3880,340)` position. Record synchronization
at `:420-473` copies transforms, action/timer, health, hitbox, tangibility,
floor/move flags, and velocities rather than native addresses.

`SM64Modern/BehaviorDispatchBridge.swift:1357-1395,6590-6595` routes the
existing Whomp behavior identity to the shared Whomp owner. This dispatch
identity is shared by normal and King variants, so a future source receipt
must add and validate the authored source identity `bhvWhompKingBoss` plus
the exact WF tuple; a generic Whomp identity, a `bhvSmallWhomp` sibling, or a
matching coordinate is not sufficient.

The focused value contract sources are
`tests/sm64_modern_whomp_boss_owner_contract.c` and
`tests/sm64_modern_whomp_boss_owner_smoke.swift`, wired by
`script/test_whomp_boss_owner.sh`. This discovery inspected those contracts
and the owner sources but did not run the synthetic `spawnWhomp` smoke. A
static scan of the owner/value contract files found no `Unsafe*`,
`OpaquePointer`, `withUnsafe`, `.pointee`, `AnyObject`, `Unmanaged`, native
`Object *`, `gMarioObject`, or `parentObj` token.

## Potential pointer-free receipt seam

The future implementation may add private observers immediately around the
source-owned `bhv_whomp_loop` boundary:

- At the source subject boundary, copy the semantic behavior identity
  `bhvWhompKingBoss`, simulation tick, level/area/act, source object ordinal,
  model, source position/yaw/behavior parameter, King variant, pre/post
  action and sub-action, timer, health, home/position, move/face angles,
  angle velocity, forward/vertical velocity, shake value, hidden/tangible/
  deletion state, and source booleans for distance/angle/floor/landing,
  Mario ground pound/platform, dialog, squished, and far-below outcomes.
- Copy the source floor/wall and movement results as fixed-width collision
  fields: floor height/type/room, move flags, position, velocity, and forward
  velocity. The observer must observe the real owner after the source
  `cur_obj_update_floor_and_walls` → action → `cur_obj_move_standard(-20)`
  ordering, not call either helper itself.
- Copy semantic effect records with source event identity and ordering:
  intro boss music/camera focus/scale, chase/turn/pound/fall, landing sound
  and shake, King damage/death sound, mist/triangle break, hide/intangible,
  reward-star intent, and boss-music stop. The reward child must be bound as
  source child ordinal `1`, behavior `bhvStar`, model `MODEL_STAR`, and exact
  position `(180,3880,340)`; it must not expose a native parent or child
  pointer.

The receipt decoder should accept only the authored King source identity and
the exact WF area-1 tuple, require `oBehParams2ndByte=1` and health `3` at
initialization, preserve source event ordering, and reject normal/small
Whomp identities, wrong acts, wrong level/area, duplicate or missing reward
children, pointer-derived identity, generic collision records, and synthetic
spawns. `SM64WhompObjectBridge.spawnWhomp` remains a local owner helper only;
it is not a source route and must not be used to fabricate a trace.

## Exact next evidence

1. Follow the ordinary source-authored Castle painting input into WF area 1
   through node `0x06`, `0x07`, or `0x08`, then require a receipt for the
   exact `bhvWhompKingBoss` tuple and `ACT_1` lifecycle. Do not direct-load
   WF, invoke `bhv_whomp_loop` from a probe, call a collision/movement helper
   from a probe, spawn a synthetic Whomp, select by coordinates, or inject a
   reward star.
2. Add semantic source identity and a value-only schema-4 receipt at the
   owner boundary. Preserve source scheduler ordering and bind the reward
   star by copied source ordinal/semantic identity, not pointers. Keep the
   C collision, Mario relation, camera, dialog, sound, particle, and star
   helpers authoritative.
3. Decode the receipt into the existing King `WhompEnemy`/
   `WhompObjectBridge` route. Require independent Debug C/Swift,
   AddressSanitizer C, optimized Release, and fresh-root rerun artifacts with
   equal source identity, seeds, header fingerprints, ticks, records, and
   bytes. Exercise tamper, truncated/partial, single-artifact, wrong-variant,
   wrong-subject, duplicate-child, fixture-only, and persistent-rerun
   rejection before any isolated admission report.
4. Only a separately authorized serial merge may change the designated
   7,420-row report or route ledger. M34 display/cadence/thermal, M35
   signing/notarization/Gatekeeper, physical movement, and human acceptance
   remain independent gates.

## Validation and boundaries

Read-only/static or isolated manifest checks performed:

```text
isolated reachability/route manifest generation: 7420 rows; hashes above
isolated behavior manifest: 534 rows, 511 Swift owners, 23 C adapters
selected route row count: exactly 1; status=planned
selected behavior mapping count: exactly 1; swift_value_owner
selected canonical and backup ledger rows: exactly 1 each; both planned
canonical report counts: 26 passed, 7394 planned
backup report counts: 25 passed, 7395 planned
owner/value contract source scan: no native pointer or unsafe-value tokens
```

No native WF lifecycle probe, source observer, schema-4 route pair,
synthetic owner smoke, Debug/ASan/Release route rerun, admission,
manifest/report/ledger mutation, shared-document update, staging, commit, or
push was performed. Existing dirty and untracked worktree changes were
preserved.

## Strict source hashes

```text
tools/SM64OracleReachabilityTool.swift                  a4fe67874cb1be883ce19359726c888ab4a927394df92a3520d35ee5d6c3338a
tools/SM64RouteShardManifestTool.swift                  70aa71fc632e4e457036875e04f97f077acc87cde7bb345687c69ef902cc1323
tools/SM64BehaviorCoverageManifestTool.swift            61fb6bdf833743a12ab25e428b7d0fb6b631adef62a2cf5c0c1332da1d12e745
data/behavior_data.c                                    dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/whomp.inc.c                          6648e23e0c08229907de5957cab57cbf3ac37f2e82422c0238ffee5aab074939
levels/wf/script.c                                      27c5845a040c9baf61de8a473d6434918ea55a1d078cd0d3ff9b562e921b99c2
levels/castle_inside/script.c                           61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
actors/whomp/collision.inc.c                            a8f12a78b0a014be96f66553b074eb1c85515eb3ae52b1a30e6a712d60b6b3d7
actors/whomp/geo.inc.c                                  3f8d2ca556328a1843b38cf0085f67c833be5685a5cf74d928fbf1bbb07bd725
SM64Modern/WhompEnemy.swift                             04cb2533d1ef7c6d96b1fa3968fdebf0dc0a4aee1dfd54c94744a6b261052ec0
SM64Modern/WhompObjectBridge.swift                      d7f8ac7536557da72a47ba70b9d195d63c257ee5bc63b355880f8d6e1b8f32e5
SM64Modern/WhompCollision.swift                         2428d3e997b5c1c75dd7dafba403807bdd78e3499d2bce471d18c41dfedb37b5
SM64Modern/BehaviorDispatchBridge.swift                 a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
tests/sm64_modern_whomp_boss_owner_contract.c            869a16f882655fc001ee8ef2266e8998e996488bc189ff7d280052973381b3b5
tests/sm64_modern_whomp_boss_owner_smoke.swift           c4efcf62ddd8d5aed160c0075bf2aafa3593bd06c9aac399eaca042e063bec98
script/test_whomp_boss_owner.sh                          07cdb9ca173dcf46d339c04bd5bc8106b1af3bab1f8052bc51272c9d2b16f35f
```
