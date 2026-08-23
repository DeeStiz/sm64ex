# Full Swift Twin Handoff — Phase 85f104 Donut Platform Seam

Date: 2026-08-23

## Verdict

**STATIC SEAM COMPLETE / RUNTIME RECEIPT ABSENT / NO ADMISSION.** The private
schema-4 Donut Platform route seam compiles under strict C11 flags and
preserves the source-authored Rainbow Ride parent/child identities, all 31
copied child positions, the parent bitmask, squared-distance gate, collision
identity, and child lifecycle scalar fields. No native object, parent pointer,
behavior script, or Mario pointer crosses the seam.

The phase does not wire the observer into `bhv_donut_platform_spawner_update`
or `bhv_donut_platform_update`, direct-load/warp RR, inject a platform, call a
behavior helper, create a trace, mutate a report/ledger/manifest, or claim
admission. The only acceptable runtime path remains Castle Inside node `0x2A`
to RR area 1.

## Owned files and validation

- `src/pc/sm64_modern_donut_platform_route_identity.h`
- `src/pc/sm64_modern_donut_platform_route_identity.c`
- `tests/sm64_modern_donut_platform_route_contract.c`
- `script/test_donut_platform_route_static.sh`

The static contract passed:

```text
donutPlatformRouteFingerprint=0x8470fe2a9a74008b
SM64 Modern Donut Platform route C contract passed
SM64 Modern Donut Platform static route contract passed
semantic_parent_child_identity=1 source_31_child_table=1 pointer_free=1
runtime_receipt=absent castle_to_rr_reachability=unproven
admission=0 canonical_ledger_mutation=0 manifest_mutation=0
```

`bash -n`, strict C11 syntax/compile (`-Wall -Wextra -Werror`,
`NON_MATCHING=1`, `AVOID_UB=1`, `VERSION_US`), source/helper/pointer fences,
and owned-path `git diff --check` passed. The fingerprint is static contract
evidence only, not C/Swift parity or runtime receipt evidence.

## Source boundary

The authored parent is `LEVEL_RR`, area 1, ACT 1, model `MODEL_NONE`, position
`(0,0,0)`, behavior parameter `0x00000000`, and semantic behavior
`bhvDonutPlatformSpawner`, created by `levels/rr/script.c:40`. Its native
behavior iterates `sDonutPlatformPositions[0...30]` and spawns
`MODEL_RR_DONUT_PLATFORM` / `bhvDonutPlatform` only when
`1,000,000 < marioSqDist < 4,000,000`. The child owner uses the copied parent
bit, collision model `rr_seg7_collision_donut_platform`, deletion/ground
outcomes, and source explosion/coin/sound ordering.

## Required next evidence

1. Exercise Castle Inside painting node `0x2A` through the ordinary owner
   lifecycle and capture the real parent plus source-ordered children; no
   synthetic load, helper call, injection, or coordinate matching.
2. Add a C-owner observer after authored child calls and decode only fixed-width
   parent/child state, source index, mask, distance, collision, effect, and
   deletion records into the existing Swift Donut Platform value owner.
3. Require independent Debug C/Swift, ASan, optimized Release, and fresh
   rerun byte equality plus wrong-level/child, duplicate, partial,
   fixture-only, pointer-derived, and persistent-rerun rejection fences before
   any isolated admission or serial merge.

The designated report remains 26/7,394 (`26/7420 = 0.350404313%`) with SHA
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`; the
write-once backup remains 25/7,395 (`25/7420 = 0.336927224%`) with SHA
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`. M34,
M35, implementation, human-acceptance, and full-goal floors remain 0%.
