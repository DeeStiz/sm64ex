# Full Swift Twin Handoff — Phase 85f58 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next disjoint
source-owned candidate is the Bob-omb Battlefield seesaw platform behavior,
`bhvSeesawPlatform`. Its authored Bob area-1 object has a real behavior
program, collision/model selection, level lifecycle, and ordinary Castle
painting entry. The existing Swift value kernel and owner bridge reduce the
source state to fixed-width values; the source pointer relation
`gMarioObject->platform == o` can be copied as a boolean. This phase changed
no source, manifest, cumulative report, route ledger, shared documentation,
or canonical history.

The selected subject is deliberately the Bob area-1 instance, not the
parameter variants in BitS or any generic object with a matching platform
shape. The excluded DDD camera, WDW elevator, TTC 2D rotator, Castle
traversal, BBH nested display-list, environment-particle, generic-water, and
intro-transition families were not reused.

## Frozen manifest boundary

The current source tree was scanned and the route manifest was generated in
an isolated `/tmp` root. The immutable inventory boundary is:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
behavior_manifest_rows=534
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
behavior_manifest_fingerprint=0x5e5d8c00a7fab8a3
swift_value_owner_rows=511
explicit_c_adapter_rows=23
```

The selected generated row is:

```text
0xb280cfa26a343b48|behavior|bhvSeesawPlatform|data/behavior_data.c|0x67b6bca284c190b0|0xeabfbddf911ea319|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The retained canonical report remains 25 terminal `passed` rows and 7,395
`planned` rows, with report SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The selected row remains `planned`; no report or ledger transition was
attempted.

## Authored source lifecycle

The manifest row resolves to the source behavior program
`data/behavior_data.c:5396-5404`:

```text
BEGIN(OBJ_LIST_SURFACE)
OR_INT(oFlags, COMPUTE_ANGLE_TO_MARIO | COMPUTE_DIST_TO_MARIO |
       SET_FACE_YAW_TO_MOVE_YAW | UPDATE_GFX_POS_AND_ANGLE)
CALL_NATIVE(bhv_seesaw_platform_init)
BEGIN_LOOP()
    CALL_NATIVE(bhv_seesaw_platform_update)
    CALL_NATIVE(load_object_collision_model)
END_LOOP()
```

The source owner is `src/game/behaviors/seesaw_platform.inc.c:18-61`.
Initialization selects `sSeesawPlatformCollisionModels[oBehParams2ndByte]`
and only applies the 2,000 collision-distance override for parameter `2`.
The update first applies the current pitch velocity, emits the authored
rocking-sound intent when its magnitude exceeds `10`, then either rotates
toward Mario or runs the return-to-zero `oscillate_toward` path. The owner
uses `gMarioObject->platform == o` only as a relation test; the pointer and
the collision-data pointer in init are internal source state and must not be
published.

The selected authored subject is `levels/bob/script.c:19-25`:

```text
MODEL_BOB_SEESAW_PLATFORM
position=(-2303,717,1024)
face_yaw=45
behavior_parameter=0x00030000  # oBehParams2ndByte = 3
behavior=bhvSeesawPlatform
```

Bob's level entry loads the model at `levels/bob/script.c:56-75`, links that
object list into area 1 at `:77-80`, and runs the normal owner lifecycle at
`:100-103` (`MARIO_POS`, `CALL`, and `CALL_LOOP` to
`lvl_init_or_update`). The ordinary source-authored Castle painting nodes
`levels/castle_inside/script.c:33-35` target `LEVEL_BOB`, area 1, node
`0x0A`; they are the future input route, not a direct level load or object
injection. The selected collision and geometry resources are
`levels/bob/seesaw_platform/collision.inc.c` and `geo.inc.c`.

## Existing pointer-free Swift owner route

`SM64Modern/SeesawPlatformBehavior.swift:3-98` is a value-only counterpart
of the source init/update. Its input and output are `Int32`, `Int16`, `Float`,
`UInt8`, optional `Float`, and `Bool`; the collision-model selection and all
pitch math are deterministic values. The existing independent C/Swift value
contract passed with fingerprint `0x84664f609b940e32`.

`SM64Modern/SeesawPlatformObjectBridge.swift:3-117` stores copied state by
`SM64ObjectID`, forwards `record.platform != nil` as the boolean relation,
updates only the copied object-pool record, and emits an immutable effect
record. `defaultBehaviorIdentity` is the fixed-width value
`0x006268765f737377`; `BehaviorDispatchBridge.swift:1620-1621` maps it to the
`.seesawPlatform` route. The bridge has a `spawnSeesawPlatform` convenience
for isolated value/owner tests, but a future native route must bind the
source-created object and must not call that helper, allocate a replacement,
or infer the subject from a generic object record.

The generic C object snapshot still falls back to an anchor-relative behavior
value for this source: `src/pc/sm64_modern_gameplay_parity.c:117-135` has no
semantic `bhvSeesawPlatform` mapping. That is an implementation blocker to
record explicitly, not a reason to normalize a pointer-derived value in a
trace.

## Potential pointer-free receipt seam

The next implementation may add a private source observer at the existing
`bhv_seesaw_platform_init`/`bhv_seesaw_platform_update` owner boundary. It
should copy only fixed-width values:

- semantic source identity, simulation tick, owner sequence, level/area, and
  a stable authored subject tuple (Bob area 1, source order, model, position,
  face yaw, and generation-safe object subject);
- `oBehParams2ndByte`, selected collision-model index, and the scalar
  collision-distance override, never `collisionData`;
- face pitch and pitch velocity before and after update, distance/angle-to-
  Mario, move-angle yaw, the source `marioOnPlatform` boolean, and the
  source sound intent; and
- the existing source object/collision/effect/script receipt fields required
  by schema 4.

The C reducer, `load_object_collision_model`, source sound path, and authored
level script remain authoritative. The observer must not call
`bhv_seesaw_platform_init`, `bhv_seesaw_platform_update`, or any collision
helper from a probe; retain `o`, `gMarioObject`, and collision pointers; add a
synthetic object; direct-load Bob; or write a fabricated trace record. The
Swift side should decode copied values into the existing owner and reject
BitS parameter/subject variants, pointer-derived identities, and an
unbound generic platform record.

## Exact next evidence

1. Follow the normal owner-thread Castle painting route into Bob area 1 and
   require a positive source-owned receipt for the selected tuple above. A
   fresh Debug run must show the real `bhvSeesawPlatform` subject and its
   source `oBehParams2ndByte == 3`; no synthetic helper call or direct level
   registration is allowed.
2. Decode that receipt with the existing value owner and bind the semantic
   source identity before comparing records. Require the generated expected
   domains `{script_events, object_state, collision_queries, effects}` and
   reject missing collision/effect records, a BitS sibling, a neighboring
   platform behavior, a duplicate subject, or a pointer-relative behavior
   value.
3. Require independent Debug C/Swift, AddressSanitizer C, optimized Release,
   and fresh-root rerun records with matching source tuple, seeds, header
   fingerprints, ticks, domains, records, and bytes. Only then exercise
   tamper, truncated/partial, single-artifact, wrong-subject, duplicate, and
   persistent-rerun rejection before any isolated admission report.
4. A separately authorized serial merge would be required to change the
   canonical 7,420-row report or route ledger. M34 display/cadence/thermal,
   M35 signing/notarization/Gatekeeper, physical feel, and human acceptance
   remain independent gates.

## Validation performed

Read-only/static and isolated value checks passed:

```text
isolated reachability/manifest generation: 7420 rows; hashes above
isolated behavior manifest: 534 rows, 511 Swift owners, 23 C adapters
selected manifest row count: exactly 1; status=planned
source behavior program, Bob object tuple, Bob area lifecycle, and Castle
  painting-node rg/awk checks: passed
isolated Swift 6 strict C/Swift seesaw value contract: passed
  seesawPlatformFingerprint=0x84664f609b940e32
git diff --check: passed for this added handoff
```

No native Bob lifecycle probe, source observer, schema-4 pair, sanitizer or
Release route rerun, admission, manifest mutation, canonical merge, staging,
commit, or push was performed. Existing dirty and untracked worktree changes
were preserved.

## Strict source hashes

```text
data/behavior_data.c                              dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/seesaw_platform.inc.c          1dbdfdde491864c2f4682bb3103ae4f1a6fb57755242b1250ee54eefc9e8c492
levels/bob/script.c                                ec6e681d1e9f5fc6b1367c1dd92f9fb40700047b1241ec938b9647eef0f469fd
levels/castle_inside/script.c                      61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
levels/bob/seesaw_platform/collision.inc.c        a24976341a7b64dcb894684baa407f8e7fbe6022fcfe87962e194aed2576028f
levels/bob/seesaw_platform/geo.inc.c              2e252f19915028676df31d6a96895ff0967f7744e904e7720f3be56b76f9f732
SM64Modern/SeesawPlatformBehavior.swift            417a1a00eea33991262a8895836a3578f22d73ad60f041a78556b52983a06260
SM64Modern/SeesawPlatformObjectBridge.swift        0e157b6277f2cf4c3593f5a0e69aa7695de851f2437f5b88ee5358bc882b6295
SM64Modern/BehaviorDispatchBridge.swift             a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
script/test_seesaw_platform.sh                     c8db1aa188940560842820159b2ff9425c5f85d2bc80c8828c17eef17a9ae3cc
tests/sm64_modern_seesaw_platform_contract.c        baaddd42984c9472f46057d744ffaf774f586ce765dfab6c9f47e0c9ff0c7f8a
tests/sm64_modern_seesaw_platform_smoke.swift      9fc725af8b715ce9c192fd6e6aa7ff8f94d99982937b99bfff545b8715808f0d
```
