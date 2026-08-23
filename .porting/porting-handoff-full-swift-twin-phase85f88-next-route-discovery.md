# Full Swift Twin Handoff — Phase 85f88 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next distinct
source-owned lifecycle candidate is Snowman's Land's authored `bhvSLSnowmanWind`
owner. It has one generated behavior row, one direct area-1 object, an ordinary
Castle Inside painting destination, and an existing fixed-width Swift value and
owner bridge. The source owner can be observed with copied scalar state and
effect intents; no native pointer needs to cross that boundary. This phase did
not add an observer, execute the SL lifecycle, create a trace, mutate source,
manifest, designated or backup report, ledger, shared documentation, or
history.

The candidate is not the already-audited DDD, WDW, TTC, Bob, Spindrift,
Spindel, Castle-traversal, BBH, environment-effect, generic-water, or intro
route. In particular, this is a `behavior` row for the authored Snowman wind
owner, not one of the previously audited `envfx_*` RNG/collision rows or a
generic water query.

## Frozen manifest boundary

The current source tree was scanned with the existing reachability and route
manifest tools under the isolated temporary root
`/private/tmp/sm64-phase85f88-next-route-discovery.hpEjlo/`:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
domains=audio_asset:295 behavior:534 collision:64 display_list:5918 geo_layout:66 level_script:34 oracle_hook:14 render_callback:219 rng:136 save_mutation:120 text:4 transition:16
```

The selected generated row resolves exactly once and remains planned:

```text
0xa98dae7d4d4559ab|behavior|bhvSLSnowmanWind|data/behavior_data.c|0x55770e09d66b130b|0x7bd3187854922858|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The source behavior coverage manifest is unchanged:

```text
behavior_manifest_rows=534
swift_value_owner=511
unmigrated_c_adapter=23
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
selected_mapping=bhvSLSnowmanWind|data/behavior_data.c|swift_value_owner|SnowmanWindObjectBridge|Snowman wind/dialog route
```

The designated local canonical route report remains the Phase 85f81
write-once artifact at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`,
SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, with
7,420 rows, 26 terminal `passed`, and 7,394 `planned` (`26/7420 =
0.350404313%`). The historical backup remains byte-identical at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`, with
25 terminal `passed` and 7,395 `planned` (`25/7420 = 0.336927224%`). Neither
artifact was opened for write.

## Authored source lifecycle

The generated row is the source-authored behavior program at
`data/behavior_data.c:3489-3502`:

```text
BEGIN(OBJ_LIST_DEFAULT)
OR_INT(oFlags, COMPUTE_ANGLE_TO_MARIO | COMPUTE_DIST_TO_MARIO |
       UPDATE_GFX_POS_AND_ANGLE)
SET_HOME()
BEGIN_LOOP()
    CALL_NATIVE(bhv_sl_snowman_wind_loop)
END_LOOP()
```

`src/game/behaviors/sl_snowman_wind.inc.c:5-45` is the native owner. At timer
zero it captures the authored yaw. In the idle sub-action it temporarily tests
the source-defined textbox center `(1100, 3328, 1164)` and advances when
`cur_obj_can_mario_activate_textbox(1000.0f, 30.0f, 0x7FFF)` succeeds. The
talking sub-action consumes the authored `DIALOG_153` result through
`cur_obj_update_dialog(2, 2, DIALOG_153, 0)`. In the blowing state it limits
the move yaw to `0x1500` from the original yaw, spawns twelve strong-wind
particles at scale `3.0f`, and emits `SOUND_AIR_BLOW_WIND` while Mario is within
the source distance/height gates.

The direct authored subject is the second entry (zero-based source order 1)
of `levels/sl/script.c:31-37`, in `script_func_local_3`:

```text
MODEL_NONE
position=(700, 3428, 700)
face_angles=(0, 30, 0)
behavior_parameter=0x00000000
behavior=bhvSLSnowmanWind
```

`levels/sl/script.c:67-87` links that object list into area 1's normal level
lifecycle, terrain, and `lvl_init_or_update` loop. The ordinary source route is
present at `levels/castle_inside/script.c:114-116` through painting warp nodes
`0x24`, `0x25`, and `0x26`, each targeting `LEVEL_SL`, area 1, node `0x0A`.
This is a route recipe only; no direct SL load, behavior call, object injection,
or forced warp was performed. `levels/sl/geo.c:14-29` supplies the authored
camera/render-object graph, while the selected behavior itself does not use an
authored collision-data pointer.

## Existing pointer-free Swift owner route

`SM64Modern/SnowmanWindBehavior.swift:3-39` mirrors the owner using only
fixed-width integers, finite floats, and Boolean interaction/effect inputs. It
preserves the idle-to-talking-to-blowing sub-action transitions, original-yaw
clamp, dialog ID `153`, twelve-particle effect count, and wind-sound edge.
The isolated C/Swift value contract passed with fingerprint
`0x0bb6ba5b32436749`.

`SM64Modern/SnowmanWindObjectBridge.swift:3-30` stores copied state keyed by a
generation-safe `SM64ObjectID`, mutates only value object-pool records, and
emits `SM64SnowmanWindObjectEffectRecord`. Its fixed-width owner identity is
`0x6268_765F_736C77`; it retains no C object, behavior-script, Mario, particle,
or collision pointer. The strict Swift owner surface audit found no native
pointer tokens. `BehaviorDispatchBridge.swift:1767-1770,6946-6949` routes this
identity through the shared `.wind` lane and then selects the Snowman wind
owner. That shared lane is not source-route proof.

The native actor snapshot identity table in
`src/pc/sm64_modern_gameplay_parity.c:117-296` has no semantic
`bhvSLSnowmanWind` entry. Until a route-specific source observer is added, an
ordinary snapshot can fall back to the build-layout-dependent anchor-relative
behavior value. That fallback must not be accepted as a C/Swift route identity.

## Potential pointer-free receipt seam

The future implementation may add a private observer immediately around the
existing `bhv_sl_snowman_wind_loop` owner boundary. The observer should copy
only source-owned values:

- semantic `bhvSLSnowmanWind` identity, simulation tick, owner sequence,
  level/area, object slot/generation, and the exact authored subject tuple
  `(script_func_local_3, source_order=1, MODEL_NONE, (700,3428,700),
  face_yaw=30, behavior_parameter=0)`,
- pre/post `oSubAction`, `oTimer`, original yaw, move yaw, angle-to-Mario,
  distance-to-Mario, Mario Y, and home Y,
- the source textbox probe position/result and dialog ID/result, and
- the source effect intents: strong-wind particle count/scale/offset and the
  semantic `SOUND_AIR_BLOW_WIND` edge.

The observer must not publish `o`, `gMarioObject`, a behavior-script pointer,
the temporary object-position storage, or any spawned-particle pointer. The
source C helper, dialog/textbox machinery, particle allocation, and sound
delivery remain authoritative. The generated row declares
`{script_events, object_state, collision_queries, effects}`; a future route
must obtain any required query receipt from the actual authored owner and must
not recycle generic envfx/generic-water records or fabricate a collision row
to satisfy that inventory contract.

The Swift side should decode the copied receipt into the existing
`SM64SnowmanWindBehavior`/`SM64SnowmanWindObjectBridge`, bind the exact SL
subject, and reject a generic `.wind` record, neighboring Snowman/Penguin
object, duplicate source order, or pointer-derived behavior identity.

## Exact next evidence

1. Follow the normal owner-thread Castle Inside SL painting route into area 1
   and require a positive receipt for the exact `script_func_local_3` subject
   above. Do not direct-load SL, call `bhv_sl_snowman_wind_loop` or dialog/
   particle helpers from a probe, inject the object, use the adjacent
   `bhvSLWalkingPenguin` or `bhvStrongWindParticle` object, or synthesize a
   trace record.
2. Add the semantic C source identity and a value-only schema-4 receipt seam.
   Preserve the actual textbox/dialog/effect boundaries and reject missing
   source identity, wrong subject, generic `.wind` identity, missing query or
   effect receipts, and duplicate subject records.
3. Require independent Debug C/Swift, AddressSanitizer C, optimized Release,
   and fresh-root rerun artifacts with equal source identity, seeds, header
   fingerprints, ticks, records, and bytes. Exercise tamper, truncated/
   partial, single-artifact, wrong-subject, duplicate, fixture-only, and
   persistent-rerun rejection before any isolated admission report.
4. Only a separately authorized serial merge may change the designated
   7,420-row report or route ledger. M34 display/cadence/thermal, M35
   signing/notarization/Gatekeeper, physical movement, and human acceptance
   remain independent gates.

## Validation and boundaries

Read-only/static or isolated value checks performed:

```text
isolated reachability/route manifest generation: 7420 rows; hashes above
isolated behavior manifest: 534 rows, 511 Swift owners, 23 C adapters
selected route row count: exactly 1; status=planned
selected behavior mapping count: exactly 1; swift_value_owner
source behavior, SL area-1 subject, Castle painting entries, and owner-hook checks: passed
Swift 6 Snowman wind value smoke: passed
  snowmanWindFingerprint=0x0bb6ba5b32436749
C Snowman wind value contract: passed
  snowmanWindFingerprint=0x0bb6ba5b32436749
shell syntax check for script/test_snowman_wind.sh: passed
Swift owner pointer-token audit: passed
```

No native SL lifecycle probe, source observer, schema-4 route pair,
Debug/ASan/Release route rerun, admission, manifest/report/ledger mutation,
shared-document update, staging, commit, or push was performed. Existing dirty
and untracked worktree changes were preserved.

## Strict source hashes

```text
tools/SM64OracleReachabilityTool.swift                  a4fe67874cb1be883ce19359726c888ab4a927394df92a3520d35ee5d6c3338a
tools/SM64RouteShardManifestTool.swift                  70aa71fc632e4e457036875e04f97f077acc87cde7bb345687c69ef902cc1323
tools/SM64BehaviorCoverageManifestTool.swift            61fb6bdf833743a12ab25e428b7d0fb6b631adef62a2cf5c0c1332da1d12e745
data/behavior_data.c                                    dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/sl_snowman_wind.inc.c                bfed01ae0e12964cd15f7bc3e8d822c3f0cf52a8db387c12bd5e0fea094ba6ea
levels/sl/script.c                                      1538dfef8ccac9cf713e5b3596234f19a1b5da594afafe9ca5fbfb66851a0ec5
levels/sl/leveldata.c                                   e7b35e89e234b640eb885ce14ad27cb18fda23114bce37f02b70b9278fef920d
levels/sl/geo.c                                         e0616361d06b6cbe838d0db0291071640030673e4c07f08d515bec2a75761f0b
levels/castle_inside/script.c                           61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
include/object_constants.h                              50757b32af0e8efd0dd3e935175973693daca27b2ad49367cb099ea472e06385
SM64Modern/SnowmanWindBehavior.swift                   4994e64496cab63e1c1a84defb4e8f7b8d1d8a54c37f04da2ad5819747544de1
SM64Modern/SnowmanWindObjectBridge.swift               5ca064d0ac72cfad9a39631c3c13862e5ed3adda6ef42f961cfcd6cc7c1b693e
SM64Modern/BehaviorDispatchBridge.swift                 a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
src/pc/sm64_modern_gameplay_parity.c                   3e948371481b2cd1372797b0d200aeb0737fbaad42294c7522035a645423f974
tests/sm64_modern_snowman_wind_contract.c               bb23e959656adef170dc6f0a49d5422abf34ac9150329c4e53550541bdc2597a
tests/sm64_modern_snowman_wind_smoke.swift              a003f893e7e9450dd73f53141922bee6cd0cc573bfef35e169a2c5973502cbb0
script/test_snowman_wind.sh                             fc9ca6269c8f8f6573f1899428cee0cf42c0e38c29c80d633108112536b7a778
```
