# Full Swift Twin Handoff — Phase 85f52 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next disjoint
source-owned candidate is the Tick Tock Clock 2D rotator behavior,
`bhvTTC2DRotator`. Its authored TTC area-1 macro list creates two clock hands
and three small plus three large 2D cogs, and its existing Swift kernel/owner
route is fixed-width and pointer-free. This phase selected one authored clock
hand variant for the future route, did not execute the native TTC lifecycle,
and did not mutate any source, manifest, canonical report, route ledger,
shared documentation, or history.

## Frozen manifest boundary

The current generated route inventory was regenerated under an isolated
temporary root and compared byte-for-byte with the retained manifest:

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

The retained canonical report remains 25 terminal `passed` rows and 7,395
`planned` rows, with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The selected row is still planned:

```text
0x1af5669b06931d93|behavior|bhvTTC2DRotator|data/behavior_data.c|0x304f0fbb8a3c6e63|0xe1463a87da336540|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The current behavior-manifest contract also remains source-faithful:

```text
behavior_manifest_rows=534
swiftValueOwner=511
unmigratedCAdapter=23
behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
```

## Authored source lifecycle

The generated behavior row resolves to `data/behavior_data.c:5542-5551`:

```text
BEGIN(OBJ_LIST_SURFACE)
LOAD_COLLISION_DATA(ttc_seg7_collision_clock_main_rotation)
OR_INT(oFlags, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE)
SET_FLOAT(oCollisionDistance, 1800)
CALL_NATIVE(bhv_ttc_2d_rotator_init)
BEGIN_LOOP()
    CALL_NATIVE(bhv_ttc_2d_rotator_update)
END_LOOP()
```

The source owner is `src/game/behaviors/ttc_2d_rotator.inc.c:39-88`. Init
selects the authored hand/cog speed table from `oBehParams2ndByte` and the
real `gTTCSpeedSetting`; update performs the yaw approach, timer gate,
target/increment mutation, and random-direction draws. The hand branch alone
calls the existing `load_object_collision_model()` at line 86. The future
observer must copy values at this source owner boundary and must never publish
`o`, a collision pointer, or any other native address.

`include/macro_presets.h:340-343` binds the authored presets as follows:

```text
macro_ttc_clock_hand -> bhvTTC2DRotator, MODEL_TTC_CLOCK_HAND, parameter 0
macro_ttc_small_gear -> bhvTTC2DRotator, MODEL_TTC_SMALL_GEAR, parameter 1
macro_ttc_large_gear -> bhvTTC2DRotator, MODEL_TTC_LARGE_GEAR, parameter 1
```

`levels/ttc/areas/1/macro.inc.c:40-41` contains two authored clock-hand
objects, and lines 56-61 contain three small and three large gear objects.
The selected future subject is the first clock hand at line 40
(`yaw=225`, position `(0,6011,0)`, parameter `0`); the second hand is a
same-source alternate subject, while the cog objects are deliberately not a
substitute because they do not take the hand collision branch.

`levels/ttc/script.c:57-73` loads the clock-hand and gear models, opens
area 1, links the authored macro list through `MACRO_OBJECTS`, and runs the
normal terrain/level lifecycle. `MARIO_POS` and `CALL_LOOP(lvl_init_or_update)`
are present at lines 76-78. The ordinary source-authored Castle Inside
painting entries `0x21`-`0x23` target `LEVEL_TTC`, area 1, node `0x0A` at
`levels/castle_inside/script.c:111-113`; those entries are the future input
route, not a direct level load. No DDD camera, Castle traversal, WDW area-1,
BBH nested display-list, environment-particle, generic-water, or intro-
transition route was reused.

## Existing pointer-free Swift owner route

M33az already provides the value owner in
`SM64Modern/TTC2DRotatorBehavior.swift` and
`SM64Modern/TTC2DRotatorObjectBridge.swift`:

- `SM64TTC2DRotatorBehavior.initialize` and `update` consume and return only
  `Int32`, `Int16`, `Bool`, and fixed-width value fields. Random decisions are
  explicit inputs, so the source `random_u16`/`random_mod_offset` results can
  be copied into a replay receipt rather than regenerated from a Swift-local
  RNG.
- `SM64TTC2DRotatorObjectBridge` stores value state keyed by
  `SM64ObjectID`, mutates only copied object-pool records, and emits an
  immutable `SM64TTC2DRotatorObjectEffectRecord`. It contains no C object,
  surface, behavior-script, or renderer pointer.
- `BehaviorDispatchBridge.swift:1638-1639` maps the owner identity
  `0x6268_765F_747232` to dispatch route `.ttc2DRotator` (route value 53), and
  `:6791-6792` invokes the owner update through that route. This identity and
  the authored hand model/parameter must remain separate from the cog variant.

The isolated value contract passed without a native lifecycle probe:

```text
bash script/test_ttc_2d_rotator.sh
ttc2DRotatorFingerprint=0x86f4ab9de3f5c3ab
SM64 Modern TTC 2D rotator C contract matched
```

This proves only the existing C/Swift value kernel and owner input shape. It
does not prove that the selected authored hand object has emitted a live
schema-4 receipt.

## Exact next evidence

1. Use the normal owner-thread Castle Inside painting route (`0x21`, `0x22`,
   or `0x23`) into TTC area 1. Require a positive source-owned object receipt
   for the authored clock-hand subject with semantic behavior identity,
   `MODEL_TTC_CLOCK_HAND`, `oBehParams2ndByte == 0`, the authored subject slot,
   and its source-provided yaw/position. Do not direct-load `LEVEL_TTC`, call
   `spawnTTC2DRotator`/`spawnRotator`, inject a macro object, call either C
   behavior helper from a probe, or synthesize a trace record.
2. Add a narrow source observer only at the existing init/update owner
   boundary. Copy fixed-width values for tick, level/area, source subject
   slot/generation, model, behavior parameter, `gTTCSpeedSetting`, timer,
   min-time, face/target yaw, increment/speed, random-direction timer, each
   source random draw, angle-velocity result, and the hand collision/effect
   receipt. Keep the C reducer, collision model, and script lifecycle
   authoritative. Add a semantic `bhvTTC2DRotator` identity before any trace
   comparison if the generic object snapshot would otherwise expose a
   pointer-derived identity.
3. Decode those copied values into the existing Swift value owner and bind
   only the selected hand source identity. Require the schema-4 expected
   domains `script_events`, `object_state`, `collision_queries`, and `effects`;
   reject a cog-only window, a neighboring behavior, duplicate subject,
   pointer-derived identity, or a generic object trace with no source binding.
4. Require independent Debug C/Swift, ASan C, optimized C, and fresh-rerun
   traces with identical source identity, seeds, header fingerprints, ticks,
   records, and bytes. Then exercise tamper, truncated/partial,
   single-artifact, wrong-variant, duplicate, and persistent-rerun rejection
   before writing an isolated admission report. Only a separately authorized
   serial merge may change the canonical 7,420-row report or route ledger.

M34 display/cadence/thermal, M35 signing/notarization/Gatekeeper, physical
feel, and human acceptance remain independent gates.

## Validation and boundaries

Read-only/static or isolated checks performed:

```text
isolated reachability/manifest generation: 7420 rows; hashes above
retained manifest byte comparison: passed
bash script/test_behavior_manifest.sh: passed
bash script/test_ttc_2d_rotator.sh: passed
authored macro/lifecycle/owner rg checks: passed
```

No native TTC lifecycle probe, source observer, schema-4 pair, ASan/Release
route rerun, admission, manifest mutation, canonical merge, shared-document
update, staging, commit, or push was performed. Existing dirty and untracked
worktree changes were preserved.

## Strict source hashes

```text
data/behavior_data.c                                      dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/ttc_2d_rotator.inc.c                  a443873f13aee52dde654e4a5291f3a6c12d55be86a3e871d058fd4579a0dfe6
include/macro_presets.h                                  e9e7413df612292c91eff230f945f17037f1197592eef1dbf776788907db4d5e
levels/ttc/script.c                                      dc0f0a6b5f32d2ad6b0ede15f9d132bf70be6e3a3cec7876f42115bb4c6c3d31
levels/ttc/areas/1/macro.inc.c                           09e98e8045b48a302082c24320f64420e7aeb8c34f527824cb57a54ab935776d
levels/castle_inside/script.c                            61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
SM64Modern/TTC2DRotatorBehavior.swift                   1d21c7154e9f1f7ceb6c0e594b18fba0dd95aeddea00bac1b76f1803502c8606
SM64Modern/TTC2DRotatorObjectBridge.swift               5a375289fbd657ee878430bdea6c3862417b2767a3e838dc7976a0097edf0998
SM64Modern/BehaviorDispatchBridge.swift                 a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
script/test_ttc_2d_rotator.sh                            3552768eb8961cbd1004d946b7652af242a8f8a549fa4a73849f6830d0675d20
tests/sm64_modern_ttc_2d_rotator_contract.c              a9b5a6ce7c0ed7b842281dc0d72f95399998af3dec6533a04789c987bb2e73f2
tests/sm64_modern_ttc_2d_rotator_smoke.swift             3508e271d56886d71377b3cd56cd6df4e3fd949fc8cf98b057c5917456d3b19b
```
