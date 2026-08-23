# Full Swift Twin Handoff — Phase 85f71 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next disjoint
source-owned candidate is the Snowman's Land Spindrift behavior,
`bhvSpindrift`. Its authored area-1 macro list contains a stable first
Spindrift subject, the normal level-script lifecycle, and an existing scalar
Swift value/owner route. The source collision and Mario-relation inputs can be
reduced to fixed-width values at the owner boundary. This phase performed no
native lifecycle execution, source change, manifest/report/ledger mutation,
shared-document update, staging, commit, or push.

The already-audited DDD camera, WDW express elevator, TTC 2D rotator, Bob
seesaw, Castle traversal, BBH nested display-list, environment-particle,
generic-water, and intro-transition families were not reused.

## Frozen manifest boundary

The current source tree was regenerated under the isolated temporary root
`/tmp/sm64-phase85f71-discovery.1QLe6e/`:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
manifest_cmp=identical
```

The isolated domain counts are:

```text
audio_asset=295 behavior=534 collision=64 display_list=5918
geo_layout=66 level_script=34 oracle_hook=14 render_callback=219
rng=136 save_mutation=120 text=4 transition=16
```

The behavior coverage manifest remains source-faithful:

```text
behavior_manifest_rows=534
swiftValueOwner=511
unmigratedCAdapter=23
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
```

The retained canonical route report remains 25 terminal `passed` rows and
7,395 `planned` rows, with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3`.
The selected row is still planned:

```text
0x028a122a6b0f0fa2|behavior|bhvSpindrift|data/behavior_data.c|0x5e0c9eb1fc5e5d4e|0x2c46ca0bcefa8587|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The selected behavior mapping is exactly one Swift value-owner row:

```text
bhvSpindrift|data/behavior_data.c|swift_value_owner|SpindriftObjectBridge|Spindrift enemy action/movement route
```

## Authored source lifecycle

The generated behavior row resolves to
`data/behavior_data.c:1589-1600`:

```text
BEGIN(OBJ_LIST_GENACTOR)
OR_INT(oFlags, COMPUTE_DIST_TO_MARIO | SET_FACE_YAW_TO_MOVE_YAW |
       UPDATE_GFX_POS_AND_ANGLE)
LOAD_ANIMATIONS(oAnimations, spindrift_seg5_anims_05002D68)
ANIMATE(0)
SET_OBJ_PHYSICS(30, -400, 0, 0, 0, 200, 0, 0)
SET_HOME()
SET_INT(oInteractionSubtype, INT_SUBTYPE_TWIRL_BOUNCE)
BEGIN_LOOP()
    CALL_NATIVE(bhv_spindrift_loop)
END_LOOP()
```

The native owner is `src/game/behaviors/spindrift.inc.c:3-39`. It installs the
authored hitbox, enters the attacked/death action when
`cur_obj_set_hitbox_and_die_if_attacked` reports a hit, updates floor/walls,
approaches the forward velocity and target yaw in action 0, runs the
20-tick reverse/reset action 1, and finishes with the source
`cur_obj_move_standard(-60)` step. The `gMarioObject` relation is used only to
derive the scalar target yaw at line 26; the behavior and collision helpers
must remain C-authoritative.

`include/macro_presets.h:181` maps the authored `macro_spindrift` preset to
`bhvSpindrift`, `MODEL_SPINDRIFT`, and parameter `0`. The first selected
source subject is `levels/sl/areas/1/macro.inc.c:22`, with source order `0`
and position `(-3760,1120,1240)`; the same macro list contains ten additional
Spindrift siblings at lines 23-30 and 33-34. A future route must retain the
source order/position tuple and must not substitute a neighboring sibling.

`levels/sl/script.c:67-87` loads area 1, links
`sl_seg7_area_1_macro_objs`, terrain, and the normal owner lifecycle;
`MARIO_POS` plus `CALL`/`CALL_LOOP(lvl_init_or_update)` are at lines 104-106.
The ordinary authored Castle Inside painting entries
`levels/castle_inside/script.c:114-116` target `LEVEL_SL`, area 1, node
`0x0A`; they are the future input route, not a direct level load or an
injected object. No generic water query, environment-particle path, or
excluded Castle traversal is used by this candidate.

## Existing pointer-free Swift owner route

`SM64Modern/SpindriftBehavior.swift:3-30` accepts and returns only fixed-width
value fields: action/timer, object/home vectors, yaw/velocity, scalar Mario
distance/angle inputs, attack state, and normalized hitbox/effect outputs.
Its C/Swift value contract passed with fingerprint
`0x9ac8294303fff174`.

`SM64Modern/SpindriftObjectBridge.swift:5-32` stores copied state keyed by
`SM64ObjectID`, mutates only the value object pool, and emits an immutable
`SM64SpindriftObjectEffectRecord`. Its owner identity is
`0x6268_765F_737064`; `BehaviorDispatchBridge.swift:1399` routes that identity
through the shared `.bomp` dispatch lane and line 6595 invokes the Spindrift
owner. That shared Swift dispatch is not source-route identity proof: the
native `behavior_identity()` table in
`src/pc/sm64_modern_gameplay_parity.c` currently has no `bhvSpindrift` semantic
entry, so an unmodified native actor snapshot can fall back to a
build-layout-dependent behavior pointer delta.

## Potential pointer-free receipt seam

The next implementation may add a private source observer at the existing
`bhv_spindrift_loop` owner boundary. It should copy, without retaining native
addresses:

- semantic `bhvSpindrift` identity, simulation tick, owner sequence, level and
  area, source subject slot/generation, source order, model, and behavior
  parameter;
- action/timer, position/home, move yaw, forward velocity, move flags, and
  normalized pre/post state around `cur_obj_move_standard(-60)`;
- the source-computed lateral-home distance, Mario distance, target/home yaw,
  attacked/interact status, and the fixed hitbox values; and
- the reset-interaction and dying-sound effect bits emitted by the source
  owner.

The observer must not publish `o`, `gMarioObject`, `sSpindriftHitbox`, a floor
or wall surface pointer, a behavior-script pointer, or any pointer-derived
identity. It must leave `cur_obj_set_hitbox_and_die_if_attacked`, floor/wall
resolution, `obj_angle_to_object`, and `cur_obj_move_standard` authoritative.
The Swift side should decode the copied receipt into the existing value owner,
bind the first authored SL subject, and reject an unbound generic enemy record,
neighboring source order, or shared `.bomp` identity without source binding.

## Exact next evidence

1. Follow the normal owner-thread Castle Inside painting destination to SL
   area 1 and require a positive receipt for the first authored Spindrift
   tuple above. Do not direct-load `LEVEL_SL`, inject a macro object, call
   `bhv_spindrift_loop` or a collision helper from a probe, select a sibling,
   or synthesize a trace record.
2. Add the semantic C source identity and a value-only schema-4 receipt seam.
   Require the generated behavior domains
   `{script_events, object_state, collision_queries, effects}` and preserve
   source action 0 movement, attacked action 1, and reset timing.
3. Decode the copied values with the existing Swift owner and require exact
   C/Swift records in fresh Debug, ASan, optimized Release, and a fresh-root
   rerun. Match source subject, seeds, header fingerprints, ticks, records,
   and bytes; do not normalize a pointer delta.
4. Exercise tamper, truncated/partial, single-artifact, wrong-sibling,
   duplicate, fixture-only, and persistent-rerun rejection before creating an
   isolated admission report. Only a separately authorized serial merge may
   change the canonical 7,420-row report or route ledger.

M34 display/cadence/thermal, M35 signing/notarization/Gatekeeper, physical
feel, and human acceptance remain independent gates.

## Validation and boundaries

Read-only/static or isolated checks performed:

```text
isolated reachability/manifest generation: 7420 rows; hashes above
second manifest comparison: byte-identical
isolated behavior manifest: 534 rows, 511 Swift owners, 23 C adapters
selected row count: exactly 1; status=planned
source route static checks: passed; macro_objects=11; painting_entries=3
bash-equivalent isolated Spindrift C/Swift value contract: passed
  spindriftFingerprint=0x9ac8294303fff174
```

No native SL lifecycle probe, source observer, schema-4 route pair,
Debug/ASan/Release route rerun, admission, manifest mutation, canonical
merge, shared-document update, staging, commit, or push was performed.
Existing dirty and untracked worktree changes were preserved.

## Strict source hashes

```text
data/behavior_data.c                              dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/spindrift.inc.c                d784d95e3d7c528f94bc19684c127712fefd5f2409d8fa24569275f7b3091839
include/macro_presets.h                            e9e7413df612292c91eff230f945f17037f1197592eef1dbf776788907db4d5e
levels/sl/script.c                                 1538dfef8ccac9cf713e5b3596234f19a1b5da594afafe9ca5fbfb66851a0ec5
levels/sl/areas/1/macro.inc.c                      049335536a281e1a91eb8de98dba83d2ab640e29476ea7f163cfd7e2cbd8b76e
levels/castle_inside/script.c                      61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
SM64Modern/SpindriftBehavior.swift                 3d8fe6ac1b52a17a1c4a7b89747dc5526d928045be1709130940166324a130ee
SM64Modern/SpindriftObjectBridge.swift             a899f096e23dc1bbd0b87175854239cdb3e33293afebd7c6d4bc254cb850f778
SM64Modern/BehaviorDispatchBridge.swift            a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
script/test_spindrift.sh                            6e5a7ae26c15b3bb4f9656d95b6ab370247af7a71d7fd6034c24db23c150414a
tests/sm64_modern_spindrift_contract.c              debe5e9d9d9d2b7c81af616a7a8e5506ac023dd621de4d14aa399bf337ad6d56
tests/sm64_modern_spindrift_smoke.swift             668b71a163d4b9eb5a121d9f2bd7b3c0c95a6e15a6e32985d1c6cddccd791d68
```
