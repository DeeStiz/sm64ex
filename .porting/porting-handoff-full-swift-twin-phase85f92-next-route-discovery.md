# Full Swift Twin Handoff — Phase 85f92 Next Source-Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next distinct
source-owned lifecycle candidate is Jolly Roger Bay's authored
`bhvTreasureChestsJrb` root. Its area-1 script creates the four-step JRB
treasure-chest puzzle through the real source root and its source-owned child
bottom/top objects. The existing Swift value owner preserves the JRB variant,
source child creation order, scalar puzzle state, interaction results, and
effect intents without exposing native pointers. A future receipt can bind the
root and generated children by semantic identity plus source child ordinal.

This is a gameplay puzzle lifecycle, not a generic-water query: the JRB water
terrain is only the authored level context. This phase did not reuse the
excluded DDD, WDW, TTC, Bob, Spindrift, Spindel, Snowman-wind,
Castle-traversal, BBH, environment-effect, generic-water, or intro families.
No native JRB load, direct helper call, synthetic child, object injection,
trace, source edit, manifest/report/ledger mutation, or admission was done.

## Frozen manifest boundary

The current source tree was scanned with the existing reachability and route
manifest tools under the isolated temporary root
`/tmp/sm64-phase85f92-next-route-discovery.zxrx2i/`:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
domains=audio_asset:295 behavior:534 collision:64 display_list:5918 geo_layout:66 level_script:34 oracle_hook:14 render_callback:219 rng:136 save_mutation:120 text:4 transition:16
```

The selected generated row resolves exactly once and remains planned:

```text
0x246e8a98cbad9a7a|behavior|bhvTreasureChestsJrb|data/behavior_data.c|0xdabdb60d09b49c76|0xa7542dab4dd782bf|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The source behavior coverage manifest is unchanged:

```text
behavior_manifest_rows=534
swift_value_owner=511
unmigrated_c_adapter=23
behavior_manifest_sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
behaviorManifestFingerprint=0x5e5d8c00a7fab8a3
selected_mapping=bhvTreasureChestsJrb|data/behavior_data.c|swift_value_owner|TreasureChestObjectBridge|JRB treasure-chest root and four-step puzzle route
```

The designated local canonical route report remains the Phase 85f81
write-once artifact at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`,
SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, with
7,420 rows, 26 terminal `passed`, and 7,394 `planned`
(`26/7420 = 0.350404313%`). The selected shard is one ledger row and remains
`planned|0|0|0|`.

The historical backup remains byte-distinct and untouched at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`, with
25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`). Neither report was opened for write.

## Authored source lifecycle

The generated row is the source-authored program at
`data/behavior_data.c:5015-5023`:

```text
BEGIN(OBJ_LIST_DEFAULT)
OR_INT(oFlags, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE)
DROP_TO_FLOOR()
CALL_NATIVE(bhv_treasure_chest_jrb_init)
BEGIN_LOOP()
    CALL_NATIVE(bhv_treasure_chest_jrb_loop)
END_LOOP()
```

The root owner is `src/game/behaviors/treasure_chest.inc.c:144-173`. Its
source init creates four bottom children in order with the authored tuples:

```text
source child 1: (-1700, -2812, -1150), yaw=0x7FFF, behavior_parameter=1
source child 2: (-1150, -2812, -1550), yaw=0x7FFF, behavior_parameter=2
source child 3: (-2400, -2812, -1800), yaw=0x7FFF, behavior_parameter=3
source child 4: (-1800, -2812, -2100), yaw=0x7FFF, behavior_parameter=4
```

The root initializes its sequence to `1` and JRB mode to `1`. The
source-authored root advances to action 1 when the fourth answer changes the
sequence to `5`, then at timer `60` emits mist and the JRB star at
`(-1800,-2500,-1700)` and enters action 2. The bottom owner at
`src/game/behaviors/treasure_chest.inc.c:60-102` owns facing/distance gates,
right/wrong sequence mutation, temporary tangible state, Mario push, and
interaction clearing. The top owner at `:18-58` owns the lid pitch and the
JRB open-sound/orange-number edges. All child creation and parent links remain
source-owned; the future receipt must name source child order rather than
publish `o`, `parentObj`, `gMarioObject`, or any spawned-object pointer.

`levels/jrb/script.c:18-38` places the direct root at
`script_func_local_1`'s 17th entry (zero-based source order 16):

```text
MODEL_NONE
position=(-1800, -2812, -2100)
face_angles=(0, 0, 0)
behavior_parameter=0x02000000
behavior=bhvTreasureChestsJrb
```

`levels/jrb/script.c:144-158` links `script_func_local_1`, terrain,
macro objects, and the normal area-1 lifecycle, including
`lvl_init_or_update` after the area definitions at `:173-176`. The ordinary
source route is `levels/castle_inside/script.c:42-44`, painting nodes `0x09`,
`0x0A`, and `0x0B` to JRB area 1 node `0x0A`. These are route instructions
only; no painting traversal or direct JRB selection was performed.

## Existing pointer-free Swift owner route

`SM64Modern/TreasureChestBehavior.swift:52-321` is the value-only reducer for
the JRB root, bottom interaction, and top-lid lifecycle. It uses fixed-width
integers, finite floats, booleans, enums, and effect bitsets. The JRB mode is
explicitly represented by `SM64TreasureChestVariant.jrb` and maps to mode `1`.

`SM64Modern/TreasureChestObjectBridge.swift:32-658` keeps generation-safe
`SM64ObjectID` records, source root/child roles, parent IDs, source child
ordering, and copied scalar state. Its JRB identity is
`0x6268_765F_74726A`; the bottom and top identities remain separate. The
bridge preserves the source scheduler order (all bottoms, then the root, then
tops), the four authored JRB placements, parent sequence/wrong-lock state,
and immutable effect records. The isolated Swift/C value contract passed with
fingerprint `0x2dc072092ddbe3ed`.

`SM64Modern/BehaviorDispatchBridge.swift:1419-1423,6540-6620` recognizes the
JRB root and child identities and routes registered chest objects through the
shared treasure-chest owner. Dispatch registration is owner wiring only; it is
not source-authored route proof. The source identity still must be published
by an observer at the actual C owner boundary.

## Potential pointer-free receipt seam

The future implementation may add private observers immediately around the
existing source-owned root and child boundaries:

- At `bhv_treasure_chest_jrb_init`/`bhv_treasure_chest_jrb_loop`, copy the
  semantic `bhvTreasureChestsJrb` identity, simulation tick, owner sequence,
  level/area, exact root subject tuple, pre/post action and timer, puzzle
  sequence/wrong-lock values, JRB mode, source child count/order/tuples, and
  root effect intents (puzzle jingle, mist, star, and star position).
- At `bhv_treasure_chest_bottom_init`/`bhv_treasure_chest_bottom_loop`, copy
  semantic bottom identity, root source identity, child ordinal and
  behavior parameter, source position/yaw, pre/post action/timer, Mario
  distance/facing result, parent sequence/wrong-lock values, intangible state,
  interaction result, and right/wrong-answer, push, sound, and clear intents.
- At `bhv_treasure_chest_top_loop`, copy semantic top identity, root/child
  ordinals, pre/post action/timer/pitch, parent-bottom action, and the
  source sound/bubble/orange-number intents.

The C child spawns, parent links, hitbox, interaction helpers, sound delivery,
mist/star spawn, and JRB script lifecycle remain authoritative. The observer
must not call `bhv_treasure_chest_jrb_init`, `spawn_treasure_chest`, or any
child helper from a probe; retain `Object *`, `gMarioObject`, `parentObj`,
environment pointers, and spawned-object pointers; infer the root from a
generic treasure-chest identity; or use a standard/ship chest as a JRB
substitute. The Swift decoder should bind exactly the authored JRB root and
four source child ordinals, reject a DDD/ship root or generic shared identity,
and require the route row's expected domains
`{script_events, object_state, collision_queries, effects}` before any future
pair or admission.

## Exact next evidence

1. Follow the normal owner-thread Castle Inside JRB painting route through
   node `0x09`, `0x0A`, or `0x0B` into area 1 and require a receipt for the
   exact root tuple above plus all four source child ordinals. Do not direct-
   load JRB, invoke a chest helper from a probe, add a chest, select a
   coordinate-only subject, or synthesize a trace record.
2. Add semantic source identities and a value-only schema-4 receipt at the
   source root/bottom/top boundaries. Preserve source list ordering and bind
   parent/child relationships by copied source ordinals, not pointers. Reject
   missing source identity, wrong variant, wrong child order, duplicate child,
   generic water/environment records, partial child sets, and pointer-derived
   identity.
3. Decode the receipt into the existing JRB `TreasureChestBehavior`/
   `TreasureChestObjectBridge` route. Require independent Debug C/Swift,
   AddressSanitizer C, optimized Release, and fresh-root rerun artifacts with
   equal source identity, seeds, header fingerprints, ticks, records, and
   bytes. Exercise tamper, truncated/partial, single-artifact,
   wrong-variant, duplicate, fixture-only, and persistent-rerun rejection
   before any isolated admission report.
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
selected canonical and backup ledger rows: exactly 1 each; both planned
source behavior, JRB root tuple, area lifecycle, and Castle painting recipe: checked
strict Swift 6 TreasureChest value smoke: passed
  treasureChestFingerprint=0x2dc072092ddbe3ed
C11 TreasureChest value contract: passed
  treasureChestFingerprint=0x2dc072092ddbe3ed
Swift/C isolated value fingerprint: matched
owner source scan: no Unsafe*/OpaquePointer/withUnsafe/.pointee/AnyObject code tokens
```

No native JRB lifecycle probe, source observer, schema-4 route pair,
Debug/ASan/Release route rerun, admission, manifest/report/ledger mutation,
shared-document update, staging, commit, or push was performed. Existing dirty
and untracked worktree changes were preserved.

## Strict source hashes

```text
tools/SM64OracleReachabilityTool.swift                  a4fe67874cb1be883ce19359726c888ab4a927394df92a3520d35ee5d6c3338a
tools/SM64RouteShardManifestTool.swift                  70aa71fc632e4e457036875e04f97f077acc87cde7bb345687c69ef902cc1323
tools/SM64BehaviorCoverageManifestTool.swift            61fb6bdf833743a12ab25e428b7d0fb6b631adef62a2cf5c0c1332da1d12e745
data/behavior_data.c                                    dad9dfb91b7e1b57e6d6c8615fb748eba9abafa0b3ec3ce1011e60f180379213
src/game/behaviors/treasure_chest.inc.c                 77b32413a810854c6882fcbfcfd85f4eb601a93c34b696d66d73566758a3f752
levels/jrb/script.c                                     f0ae72e5a2a8ca387f25ceb8f8852e8096ec04972592ae9f2cbede948800de2f
levels/jrb/leveldata.c                                  f679359f5a86524759c842bd3ec3c50f80acb2362334b418f7c72f601c31a313
levels/jrb/geo.c                                        533bd3c63eeb57bd6c207e6b3f6b76e66eea4c2ef9ef310d687afd26194791c6
levels/castle_inside/script.c                           61b8346b311f41508208e73e03318129f42ff46adbbb485978f7b5638faa7a6a
SM64Modern/TreasureChestBehavior.swift                  81cc0df27d5827638e467f773857251ea2be0cadd4b18a279c707667dd832908
SM64Modern/TreasureChestObjectBridge.swift              1753155ff02eac84a051e8092902120c376559f2711c7bd42b89a83613db0d37
SM64Modern/BehaviorDispatchBridge.swift                 a9a441b8dab6df00ce06139dee74927e46ba5432603af5d6d3756b1eef7bd227
tests/sm64_modern_treasure_chest_contract.c              69357a404364902c7b3c660a0b05891acf2239dac46995f52051bbce639992f1
tests/sm64_modern_treasure_chest_smoke.swift             808ed5c45ea2d0bfd928e426ba9679ca6bc0c33e689baba7e8917a9cd586b399
script/test_treasure_chest.sh                           6d2649e29bdec2c7d547b3ba708f00b6298f07d744c425e6b6b9120b29896457
```
