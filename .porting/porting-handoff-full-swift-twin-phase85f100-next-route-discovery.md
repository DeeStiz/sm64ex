# Full Swift Twin Handoff — Phase 85f100 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next distinct
source-owned lifecycle candidate is Tiny-Huge Island's authored
`bhvFirePiranhaPlant` group in area 1. Its source behavior has a real
hide/grow/attack/death-spin/flame/reward lifecycle, and the area-1 script
creates five direct variant-1 subjects with stable source tuples. The
existing Swift value owner preserves the scalar action, scale, active-cap,
health, death-spin, animation-frame, and flame-child state without exposing
native pointers. A future receipt can bind the exact source subject ordinal
and the five-plant reward group by copied semantic identity.

This is a source-authored THI actor group, not a generic Piranha Plant,
generic flame, water query, or collision-only probe. This phase did not reuse
the excluded DDD, WDW, TTC, Bob, Spindrift, Spindel, Snowman-wind, JRB
treasure, Whomp, Castle-traversal, BBH, environment-effect, generic-water,
or intro families. No native THI load, direct warp, helper call, synthetic
plant or flame spawn, object injection, trace, source edit, manifest/report/
ledger mutation, or admission was done.

## Frozen manifest boundary

The current source tree was scanned with the existing reachability and route
manifest tools under the isolated temporary root
`/private/tmp/sm64-phase85f100-next-route-discovery.DUNECb/`:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
manifest_cmp=identical_to_retained_build_manifest
domains=audio_asset:295 behavior:534 collision:64 display_list:5918 geo_layout:66 level_script:34 oracle_hook:14 render_callback:219 rng:136 save_mutation:120 text:4 transition:16
```

The selected generated row resolves exactly once and remains planned:

```text
0x783b75ac5fc8435f|behavior|bhvFirePiranhaPlant|data/behavior_data.c|0x8e1f0f0d3931007f|0x94e28005922c3d0c|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The source behavior coverage manifest is unchanged:

```text
behavior_manifest_rows=534
swift_value_owner=511
unmigrated_c_adapter=23
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
behavior_manifest_cmp=identical_to_retained_build_manifest
selected_mapping=bhvFirePiranhaPlant|data/behavior_data.c|swift_value_owner|FirePiranhaPlantObjectBridge|fire Piranha Plant route
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
(`25/7420 = 0.336927224%`). Its selected row is also exactly one
`planned|0|0|0|` row. Neither report was opened for write.

## Authored source lifecycle

The generated behavior row is the source-authored program at
`data/behavior_data.c:5771-5783`:

```text
BEGIN(OBJ_LIST_GENACTOR)
OR_INT(oFlags, COMPUTE_ANGLE_TO_MARIO | COMPUTE_DIST_TO_MARIO |
       SET_FACE_YAW_TO_MOVE_YAW | UPDATE_GFX_POS_AND_ANGLE)
DROP_TO_FLOOR()
LOAD_ANIMATIONS(oAnimations, piranha_plant_seg6_anims_0601C31C)
ANIMATE(0)
SET_HOME()
HIDE()
CALL_NATIVE(bhv_fire_piranha_plant_init)
BEGIN_LOOP()
    CALL_NATIVE(bhv_fire_piranha_plant_update)
END_LOOP()
```

The native owner is
`src/game/behaviors/fire_piranha_plant.inc.c:1-146`. Initialization selects
the authored neutral scale from the upper behavior parameter (`2.0` for the
area-1 variant), installs the bounce-top hitbox, sets variant-1 health to `1`
and loot to `2`, and resets the source active/killed group counters. The
hidden action preserves the source death-spin and scale-down path, makes the
plant intangible at zero scale, enforces the source `active < 2` cap and
`100 < distance < 800` wake gate, and emits the source appear sound. The grow
action preserves the authored scale target, timer windows, yaw approach, and
frame-56 flame emission. The update then applies the source attack result;
health, death-spin, tangibility, and source respawn/deletion outcomes remain
C-owned.

The authored group is `levels/thi/script.c:33-47`, linked into THI area 1 at
`:113-120` and the ordinary `MARIO_POS`/`CALL`/`CALL_LOOP(lvl_init_or_update)`
lifecycle at `:157-160`. The five source subjects occupy zero-based source
ordinals `4...8` within `script_func_local_4`:

```text
ordinal=4 model=MODEL_PIRANHA_PLANT position=(-6336,-2047,-3861) face=(0,0,0) behavior_parameter=0x00010000 behavior=bhvFirePiranhaPlant
ordinal=5 model=MODEL_PIRANHA_PLANT position=(-5740,-2047,-6578) face=(0,0,0) behavior_parameter=0x00010000 behavior=bhvFirePiranhaPlant
ordinal=6 model=MODEL_PIRANHA_PLANT position=(-6481,-2047,-5998) face=(0,0,0) behavior_parameter=0x00010000 behavior=bhvFirePiranhaPlant
ordinal=7 model=MODEL_PIRANHA_PLANT position=(-5577,-2047,-4961) face=(0,0,0) behavior_parameter=0x00010000 behavior=bhvFirePiranhaPlant
ordinal=8 model=MODEL_PIRANHA_PLANT position=(-6865,-2047,-4568) face=(0,0,0) behavior_parameter=0x00010000 behavior=bhvFirePiranhaPlant
```

The normal Castle Inside painting entries
`levels/castle_inside/script.c:117-119` target `LEVEL_THI`, area 1, node
`0x0A` through nodes `0x27`, `0x28`, and `0x29`; they are the authored input
recipe only. No painting traversal or forced THI selection was performed.
After five variant plants reach the source killed-count threshold, the C
owner emits the authored star at `(-6300,-1850,-6300)`, marks the source
object for deletion/respawn handling, and retains the source event ordering.
The reward is a semantic child intent, not a published native star pointer.

The source flame call is `obj_spit_fire` with the variant-scaled offsets
`(30,140)`, scale `2.5`, model `MODEL_RED_FLAME_SHADOW`, current/target
speeds `20/15`, and pitch `0x1000`; the source helper creates the
`bhvSmallPiranhaFlame` child. The observer must copy that child intent after
the real C owner call and must not call `obj_spit_fire` from a probe.

## Existing pointer-free Swift owner route

`SM64Modern/FirePiranhaPlantBehavior.swift:3-95` is the fixed-width value
reducer for the hide/grow actions. It carries neutral scale, scale, action,
timer, movement yaw, Mario-relative inputs, active count, health, variant,
death-spin values, animation frame, rendering/attack gates, and killed count.
Its output carries the scalar action/scale/health state, flame-spawn edge,
deletion edge, and updated killed count.

`SM64Modern/FirePiranhaPlantObjectBridge.swift:3-39` stores copied state by
generation-safe `SM64ObjectID`, writes only value object-pool fields, and
routes a semantic flame child through `SM64SmallPiranhaFlameObjectBridge`.
`defaultBehaviorIdentity=0x6268_5F66_7070` is dispatch wiring only; it is not
proof of the source behavior identity. The shared dispatcher selects the
owner at `SM64Modern/BehaviorDispatchBridge.swift:1891-1892` and ticks it at
`:7048-7049`. The direct `spawnFirePiranhaPlant` helper at `:4314-4315` is a
local synthetic owner helper with a variant-0 default and is not a source
route; it must not be used to fabricate a receipt.

The focused value sources are
`tests/sm64_modern_fire_piranha_plant_contract.c` and
`tests/sm64_modern_fire_piranha_plant_smoke.swift`, with matching isolated
fingerprint `0x93bc09750aba7202`. A static scan of the owner/value contract
files found no `Unsafe*`, `OpaquePointer`, `withUnsafe`, `.pointee`,
`AnyObject`, `Unmanaged`, native `Object *`, `gMarioObject`, `parentObj`,
`spawn_object`, `spawn_default_star`, or `obj_spit_fire` token.

The current value owner is not yet a source receipt. It does not publish the
semantic `bhvFirePiranhaPlant` identity, the exact THI source tuple or ordinal,
the five-subject group identity/order, source audio/tangibility/attack
outcomes, or the source reward-star child. Those are the bounded receipt
requirements below.

## Potential pointer-free receipt seam

The future implementation may add private observers immediately around the
existing source-owned `bhv_fire_piranha_plant_init` and
`bhv_fire_piranha_plant_update` boundaries:

- Copy the semantic behavior identity `bhvFirePiranhaPlant`, simulation tick,
  owner sequence, level/area/act, source script identity, source ordinal,
  model, position/home, face/move yaw, and exact behavior parameter. Require
  `behavior_parameter=0x00010000`, variant `1`, neutral scale `2.0`, health
  `1` at initialization, and the five authored group ordinals `4...8`.
- Copy pre/post action and timer, scale/neutral scale, active flag, source
  active/killed group counters, health/loot/respawn state, death-spin timer
  and velocity, animation state/frame, hidden/tangible state, attack result,
  hitbox values, angle/distance gates, and movement yaw. Collision/attack
  results must come from the real source owner after its authored ordering;
  the observer must not call a collision helper or reconstruct the global
  active cap in Swift.
- Copy semantic effect records in source order: appearance, shrink/defeat,
  flame-blown, child-flame spawn parameters, tangibility/deletion, and the
  five-plant reward edge. Bind a flame child to its parent source ordinal,
  event ordinal, semantic `bhvSmallPiranhaFlame` identity, model, and copied
  parameters; bind the reward to group identity, semantic `bhvStar`,
  `MODEL_STAR`, and exact position `(-6300,-1850,-6300)`. No native object,
  parent, child, or temporary hitbox pointer may cross the seam.

The Swift decoder should feed the copied scalar receipt into the existing
`SM64FirePiranhaPlantBehavior`/`SM64FirePiranhaPlantObjectBridge` route while
preserving source group counter resets and owner-thread ordering. It must
reject normal `bhvPiranhaPlant`, generic flame/water records, a wrong model or
variant, wrong level/area/act, wrong source ordinal/position/parameter,
duplicate or missing group subjects, duplicate flame/reward children,
pointer-derived identities, fixture-only records, and synthetic
`spawnFirePiranhaPlant` output.

## Exact next evidence

1. Follow the ordinary Castle Inside painting route through nodes `0x27`,
   `0x28`, or `0x29` into THI area 1 and require a receipt for the exact
   authored five-subject group. Do not direct-load THI, force a warp, invoke
   `bhv_fire_piranha_plant_*`, `obj_check_attacks`, `obj_spit_fire`, or
   `spawn_default_star` from a probe; do not inject objects or select a plant
   by coordinates.
2. Add a private value-only schema-4 receipt at the real C owner boundary.
   Preserve source helper ordering and decode the copied source group,
   collision/attack, object-state, script-event, flame-child, and reward
   records into the existing Swift owner. Require semantic source identity
   before accepting the existing dispatch token.
3. Require independent Debug C/Swift, AddressSanitizer C, optimized Release,
   and fresh-root rerun artifacts with equal source identity, group ordinals,
   seeds, headers, ticks, records, and bytes. Exercise tamper, truncated or
   partial, single-artifact, wrong-variant, wrong-subject, duplicate-child,
   fixture-only, and persistent-rerun rejection before any isolated
   admission report.
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
route manifest cmp retained build manifest: passed
behavior manifest cmp retained build manifest: passed
Swift fire Piranha Plant value smoke: passed
  firePiranhaPlantFingerprint=0x93bc09750aba7202
C fire Piranha Plant value contract: passed
  firePiranhaPlantFingerprint=0x93bc09750aba7202
bash -n script/test_fire_piranha_plant.sh: passed
Swift owner/value contract pointer/helper token audit: passed
selected designated and backup ledger rows: planned|0|0|0|
git diff --check (tracked worktree): passed
git diff --no-index --check /dev/null (this added handoff): passed with no diagnostics
```

No native THI lifecycle probe, source observer, schema-4 route pair,
Debug/ASan/Release route rerun, admission, manifest/report/ledger mutation,
shared-document update, staging, commit, or push was performed. Existing
dirty and untracked worktree changes were preserved.

## Strict source hashes

```text
tools/SM64OracleReachabilityTool.swift                  a4fe67874cb1be883ce19359726c888ab4a927394df92a3520d35ee5d6c3338a
tools/SM64RouteShardManifestTool.swift                  70aa71fc632e4e457036875e04f97f077acc87cde7bb345687c69ef902cc1323
tools/SM64BehaviorCoverageManifestTool.swift            61fb6bdf833743a12ab25e428b7d0fb6b631adef62a2cf5c0c1332da1d12e745
data/behavior_data.c                                    dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/fire_piranha_plant.inc.c             09247045643c5285a5c00e1077bbcf826e5f3997aa2c4aca630f5ca66d318298
levels/thi/script.c                                     295cfdaf34e9f9f5127cef1aeff828d2ecc2308dd250929f011729c7692014d3
levels/thi/leveldata.c                                   3bfe9d45bc00e85c9830e20707d381c375e09df6a347312f68dc867cf4cece0e
levels/castle_inside/script.c                            61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
SM64Modern/FirePiranhaPlantBehavior.swift               e56bfc077324cb96e2f5541245f17ef470c9c40a8e90699d689cedda36a69114
SM64Modern/FirePiranhaPlantObjectBridge.swift           4e28dbc4a356e7f6abb301cc2f6f777009d5e7b29a05022fe6faa8d9c7ecbbc5
SM64Modern/BehaviorDispatchBridge.swift                 a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
tests/sm64_modern_fire_piranha_plant_contract.c          0d94d101b8e4a222d1cb94cac19898cbbc56ef4ea84c5f2f46e28ce8c032935e
tests/sm64_modern_fire_piranha_plant_smoke.swift         9518ebc5f4a96b526e71879118ae6c1a026b72c5b1a488cbf91ef755e4221b54
```
