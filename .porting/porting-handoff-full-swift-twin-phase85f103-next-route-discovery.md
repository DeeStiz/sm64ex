# Full Swift Twin Handoff — Phase 85f103 Next Route Discovery

Date: 2026-08-23

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next distinct
source-authored candidate is Rainbow Ride area 1's `bhvDonutPlatformSpawner`
at route row `0x0114376397887ece`. Its source behavior owns a 31-position
distance-gated child-platform spawner, and the existing Swift
`DonutPlatformObjectBridge` already has value owners for the spawner and
`bhvDonutPlatform` child. This phase only freezes the source contract; it
does not execute RR or claim a receipt.

## Frozen manifest boundary

The retained manifests were read without mutation:

```text
route rows (excluding header)=7420
route manifest sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
behavior rows (excluding header)=534
behavior manifest sha256=83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb
selected row=0x0114376397887ece|behavior|bhvDonutPlatformSpawner|data/behavior_data.c|0x27d6933446a8918a|0xf4deeec2364eb433|collision_queries,effects,object_state,script_events|planned
```

The selected behavior mapping is:

```text
bhvDonutPlatformSpawner|data/behavior_data.c|swift_value_owner|DonutPlatformObjectBridge|Donut Platform 31-child distance spawner route
```

The designated local canonical report remains the Phase 85f81 write-once
artifact with 7,420 rows, 26 terminal `passed`, and 7,394 `planned`
(`26/7420 = 0.350404313%`), SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
The backup remains 25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`), SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The selected row is exactly one `planned` ledger row in both artifacts; no
report or ledger was opened for write.

## Authored source lifecycle

The source script is `data/behavior_data.c:5996-6002`:

```text
BEGIN(OBJ_LIST_SPAWNER)
OR_INT(oFlags, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE)
BEGIN_LOOP()
    CALL_NATIVE(bhv_donut_platform_spawner_update)
END_LOOP()
```

Rainbow Ride area 1 creates the authored parent at
`levels/rr/script.c:40`:

```text
model=MODEL_NONE
position=(0,0,0)
face=(0,0,0)
behavior_parameter=0x00000000
behavior=bhvDonutPlatformSpawner
```

The normal Castle Inside painting route is node `0x2A` to `LEVEL_RR`, area 1,
node `0x0A`; no direct load, warp, object injection, or helper call was used.
The native owner iterates source positions `sDonutPlatformPositions[0...30]`,
computes Mario squared distance, and spawns `MODEL_RR_DONUT_PLATFORM` /
`bhvDonutPlatform` children only when `1,000,000 < distance² < 4,000,000`.
The child clears its parent bit on ground/despawn or emits the source
explosion/coin/sound path before deletion. These source child ordinals,
parent bitmask, distance thresholds, generation-safe parent link, collision
model, effect ordering, and deletion outcomes are the receipt requirements.

## Required next evidence

1. Follow only Castle Inside node `0x2A` into RR area 1 and observe the real
   parent plus source-ordered child spawns; do not direct-load RR, call
   `bhv_donut_platform_spawner_update`/`bhv_donut_platform_update`, inject a
   platform, or select a child by coordinates.
2. Add a private value-only schema-4 receipt around the real C owner boundary,
   preserving the 31-child source order, parent bitmask, squared-distance
   gates, semantic `bhvDonutPlatformSpawner`/`bhvDonutPlatform` identities,
   collision/effect/deletion records, and generation-safe parent identity.
3. Require independent Debug C/Swift, ASan, optimized Release, and fresh
   rerun bytes plus negative wrong-level, wrong-child, duplicate, partial,
   fixture-only, pointer-derived, and persistent-rerun fences before any
   isolated admission or serial merge.

M34 display/cadence/thermal, M35 signing/notarization/Gatekeeper, physical
movement, and human acceptance remain independent gates. Conservative M34,
M35, implementation, human, and full-goal floors remain 0%.
