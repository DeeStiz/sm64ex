# Full Swift Twin Handoff — Phase 85f76 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next disjoint
source-owned candidate is the Shifting Sand Land Spindel behavior,
`bhvSpindel`. Its authored SSL area-2 object has a stable source tuple and a
small scalar state machine. The existing Swift value owner already mirrors
the phase/rotation values and exposes sound/camera-shake intent without
native pointers. This phase did not run the native SSL lifecycle, add an
observer, mutate any source, manifest, report, ledger, shared documentation,
or history.

`bhvSpindel` is deliberately not the already-audited Snowman's Land
`bhvSpindrift` route: the source behavior, level, object tuple, manifest row,
and Swift owner are distinct. The excluded DDD, WDW, TTC, Bob, Spindrift,
Castle traversal, BBH, environment-effect, generic-water, and intro families
were not reused.

## Frozen manifest boundary

The authoritative route inventory and manifest were regenerated from the
current source tree under the isolated temporary root
`/private/tmp/sm64-phase85f76-spindel-discovery.PIkvEU/`:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
domains=audio_asset:295 behavior:534 collision:64 display_list:5918 geo_layout:66 level_script:34 oracle_hook:14 render_callback:219 rng:136 save_mutation:120 text:4 transition:16
```

The selected generated row resolves exactly once and remains planned:

```text
0xdc93743116807bec|behavior|bhvSpindel|data/behavior_data.c|0x4b8e5a734fe76b34|0x4b4378861cfabced|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The current behavior-coverage contract is also unchanged:

```text
behavior_manifest_rows=534
swift_value_owner=511
unmigrated_c_adapter=23
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
selected_mapping=bhvSpindel|data/behavior_data.c|swift_value_owner|SpindelObjectBridge|Spindel phase/rotation route
```

## Authored source lifecycle

The manifest row is the source-authored behavior program at
`data/behavior_data.c:4380-4388`:

```text
BEGIN(OBJ_LIST_SURFACE)
OR_INT(oFlags, SET_FACE_ANGLE_TO_MOVE_ANGLE | UPDATE_GFX_POS_AND_ANGLE)
LOAD_COLLISION_DATA(ssl_seg7_collision_spindel)
CALL_NATIVE(bhv_spindel_init)
BEGIN_LOOP()
    CALL_NATIVE(bhv_spindel_loop)
    CALL_NATIVE(load_object_collision_model)
END_LOOP()
```

The native owner is `src/game/behaviors/spindel.inc.c:3-78`:

- init copies the authored Y coordinate into `oHomeY` and zeros the phase
  and direction fields;
- `bhv_spindel_loop` owns the phase `0..19` / `-1` cooldown cycle, timer
  reset, direction toggle, speed divisor, Z displacement, pitch velocity,
  and absolute sine-derived Y displacement; and
- the source emits the roll sound through `cur_obj_play_sound_2` and the
  small camera shake through `set_camera_shake_from_point` at the same owner
  boundary.

The object is authored in `levels/ssl/script.c:41-56`,
`script_func_local_4`, at line 47 (zero-based local-list ordinal 5):

```text
MODEL_SSL_SPINDEL
position=(-2458, 2109, -1430)
face_yaw=0
behavior_parameter=0x00000000
behavior=bhvSpindel
```

`levels/ssl/script.c:115-131` opens area 2 and links
`script_func_local_4` at line 126, so the object is created by the ordinary
area-2 level script rather than a probe. The resource ownership is authored
by `levels/ssl/leveldata.c:35,44` (model and collision includes) and
`levels/ssl/geo.c:22` (Spindel geo include). The normal source route starts
at the Castle Inside SSL painting nodes
`levels/castle_inside/script.c:173-175`, which target SSL area 1. SSL area 1
has the authored `bhvWarp` object with parameter `0x14` at
`levels/ssl/script.c:93-100`, and its `WARP_NODE(0x14)` targets SSL area 2;
that is the future input/lifecycle recipe, not a direct level load or object
injection.

## Existing pointer-free Swift owner route

`SM64Modern/SpindelBehavior.swift:3-72` is a value-only counterpart of the
source init/loop. It consumes and returns fixed-width integers, finite
floating-point values, `SM64ObjectVector3`, and two Boolean effect intents.
The Swift reducer preserves the source cooldown, phase transition, direction,
divisor, Z/Y motion, pitch update, roll-sound threshold, and camera-shake
boundary.

`SM64Modern/SpindelObjectBridge.swift:3-27` stores value state by
generation-safe `SM64ObjectID`, mutates only copied object-pool records, and
emits `SM64SpindelObjectEffectRecord`. Its fixed-width owner identity is
`0x6268_765F_73706C`; no C object, collision pointer, behavior-script
pointer, or surface pointer crosses this Swift surface. The isolated value
contract passed with fingerprint `0x2f02c221a0c4104e`.

`SM64Modern/BehaviorDispatchBridge.swift:1740-1741,6892-6896` currently
places the Spindel identity on the shared `.tumblingBridge` dispatch lane,
then selects `spindel.updateInline` by the exact identity. That dispatch lane
is an owner routing detail, not source-route proof. The native generic object
snapshot's `behavior_identity()` table has no `bhvSpindel` semantic mapping;
unknown behavior scripts fall back to the anchor-relative value at
`src/pc/sm64_modern_gameplay_parity.c:294-296`, which must not be accepted as
cross-build route identity.

## Potential pointer-free receipt seam

The next implementation may add a private source observer immediately at the
existing `bhv_spindel_init` / `bhv_spindel_loop` owner boundary. It should
copy only fixed-width values:

- semantic `bhvSpindel` identity, simulation tick, owner sequence,
  level/area, and a stable authored subject tuple (SSL area 2,
  `script_func_local_4`, ordinal 5, `MODEL_SSL_SPINDEL`, position, face yaw,
  and behavior parameter);
- init `homeY`, then timer, phase (`oSpindelUnkF4`), direction
  (`oSpindelUnkF8`), position X/Y/Z, move pitch, Z velocity, and pitch
  velocity before/after the source update;
- the source threshold/effect results for the Spindel roll sound and small
  camera shake; and
- a source-named collision-model receipt for
  `ssl_seg7_collision_spindel`, never the collision-data address.

The C reducer, `load_object_collision_model`, sound path, camera-shake path,
and level script remain authoritative. The observer must not publish `o`, a
behavior-script pointer, a collision pointer, `gMarioObject`, or a
pointer-derived behavior identity. The Swift side should decode the copied
receipt into `SM64SpindelBehavior`/`SM64SpindelObjectBridge`, bind only the
authored SSL subject, and reject a generic tumbling-bridge record or a
neighboring SSL object without source binding.

## Exact next evidence

1. Follow the normal owner-thread Castle Inside SSL painting route into area 1
   and the authored SSL area-1 `0x14` warp into area 2. Require a positive
   source-owned receipt for the exact Spindel tuple above. Do not direct-load
   SSL, call `bhv_spindel_init`/`bhv_spindel_loop` or a collision helper from a
   probe, add a Spindel, use a neighboring Grindel/pyramid-wall object, or
   synthesize a trace record.
2. Add the semantic C source identity and decode the value-only receipt into
   the existing Swift owner. Require the manifest's expected domains
   `{script_events, object_state, collision_queries, effects}` and reject a
   generic shared `.tumblingBridge` identity, a pointer-relative identity,
   missing collision/effect receipts, or a duplicate SSL subject.
3. Require independent Debug C/Swift, AddressSanitizer C, optimized Release,
   and fresh-root rerun artifacts with equal source identity, seeds, header
   fingerprints, ticks, records, and bytes. Exercise tamper, truncated/
   partial, single-artifact, wrong-subject, duplicate, fixture-only, and
   persistent-rerun rejection before any isolated admission report.
4. Only a separately authorized serial merge may change the canonical 7,420-
   row report or route ledger. M34 display/cadence/thermal, M35 signing/
   notarization/Gatekeeper, physical movement, and human acceptance remain
   independent gates.

## Validation and boundaries

Read-only/static or isolated value checks passed:

```text
isolated Swift 6 strict reachability/manifest generation: 7420 rows
selected manifest row count: exactly 1; status=planned
source behavior, SSL area-2 object, model/collision/geo includes,
Castle painting -> SSL area-1 -> authored area-2 warp, and owner-hook checks: passed
bash script/test_behavior_manifest.sh: passed
  behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
  rows=534 swiftValueOwner=511 unmigratedCAdapter=23
bash script/test_spindel.sh: passed
  spindelFingerprint=0x2f02c221a0c4104e
Swift/C Spindel contract matched
Swift owner surface pointer check: passed
```

No native SSL lifecycle probe, source observer, schema-4 C/Swift pair,
Debug/ASan/Release route rerun, admission, manifest/report/ledger mutation,
shared-document update, staging, commit, or push was performed. Existing
dirty and untracked worktree changes were preserved.

## Strict source hashes

```text
data/behavior_data.c                              dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/spindel.inc.c                  38c9ebb06267c5d9f83230c07f120ce59eeb35aa14f2768d2af0c9544c86314a
levels/ssl/script.c                                b70c6f43f3736cc54eab1f80efe34ebed6ea962742e11f1f43389da078ba3af4
levels/ssl/leveldata.c                             e0a565bd9845dd71e6ed4de041c9b6352d768cad6e06d2b3dc0804dd16266e34
levels/ssl/geo.c                                   33d42db61421ab73475d0a25fda2b0d6d99645bb4b96b1804a302e4d9a5c3887
levels/ssl/spindel/model.inc.c                     04b35cdbd9fc4224b88ceae5aa0490bc0653a680b101ba1abd39c298962bf05a
levels/ssl/spindel/geo.inc.c                       914dc8c0dcd1ed8d0cb5fb0ef6c0fea8aa0a417f0b6e5e5b5e60e53906f7f817
levels/ssl/spindel/collision.inc.c                cb5d55fe1620730e01dc24b2bc97eec8f378bcb8b0cbe337a0820ed1358011b7
levels/castle_inside/script.c                      61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
SM64Modern/SpindelBehavior.swift                   7093ab03b62f068b701eef9348b4ee46f58bc47c4ab8ac1200c950478babc265
SM64Modern/SpindelObjectBridge.swift               5b1313384909ea6eb759f864e9da991b13dfefca2017c6501db5a7a13e66d960
SM64Modern/BehaviorDispatchBridge.swift             a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
script/test_spindel.sh                             6cf2908c4cfc0d2cbd579a49d11bee0d040e938b5c187b9238cfe026123ce36d
tests/sm64_modern_spindel_contract.c               ddfa41c1eb96c79460bc7ac7d0579d36357a89a126ec2ce144e1d740e1c0939e
tests/sm64_modern_spindel_smoke.swift              9de9c19317d91b9455869904cd8fde235d676a8cd83ae9300e5fb115a6df711b
```

