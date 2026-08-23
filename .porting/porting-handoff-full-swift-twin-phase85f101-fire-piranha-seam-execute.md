# Full Swift Twin Handoff — Phase 85f101 Fire Piranha Plant Seam

Date: 2026-08-23

## Verdict

**STATIC SEAM COMPLETE / RUNTIME RECEIPT ABSENT / NO ADMISSION.** The private
schema-4 Fire Piranha Plant route identity seam compiles with the project's
non-matching C flags and rejects pointer/helper tokens. It preserves semantic
identities for `bhvFirePiranhaPlant`, `bhvSmallPiranhaFlame`, `bhvStar`, the
two authored hitboxes, the THI area-1 subject tuple, the five source ordinals,
the variant-scaled flame parameters, and the five-plant reward position.

This phase intentionally does not wire the observer into
`bhv_fire_piranha_plant_init` or `bhv_fire_piranha_plant_update`, does not
direct-load or warp THI, inject objects, call `obj_spit_fire` or
`spawn_default_star`, or write a trace, route ledger, manifest, or admission
report. The ordinary Castle Inside painting route remains the only acceptable
runtime path.

## Owned files and validation

- `src/pc/sm64_modern_fire_piranha_plant_route_identity.h`
- `src/pc/sm64_modern_fire_piranha_plant_route_identity.c`
- `tests/sm64_modern_fire_piranha_plant_route_contract.c`
- `script/test_fire_piranha_plant_route_static.sh`

The static contract command passed:

```text
firePiranhaPlantRouteFingerprint=0xab99743d61a6e50a
SM64 Modern Fire Piranha Plant route C contract passed
SM64 Modern Fire Piranha Plant static route contract passed
semantic_identity=1 pointer_free=1 source_tuple_fences=1
runtime_receipt=absent castle_to_thi_reachability=unproven
admission=0 canonical_ledger_mutation=0 manifest_mutation=0
```

`bash -n`, strict C11 syntax/compile (`-Wall -Wextra -Werror`,
`NON_MATCHING=1`, `AVOID_UB=1`, `VERSION_US`), source-route grep fences, and
owned-path `git diff --check` all passed. The contract fingerprint is a
static identity check only; it is not a C/Swift parity or runtime receipt.

## Source boundary retained from Phase 85f100

The authored route is THI `LEVEL_THI`, area 1, ACT 1, behavior parameter
`0x00010000`, variant 1, model `MODEL_PIRANHA_PLANT`, source ordinals 4–8,
with authored positions:

```text
4: (-6336,-2047,-3861)
5: (-5740,-2047,-6578)
6: (-6481,-2047,-5998)
7: (-5577,-2047,-4961)
8: (-6865,-2047,-4568)
```

For the variant-1 owner, the source flame call resolves to offsets
`(0,60,280)`, scale `5.0`, model `MODEL_RED_FLAME_SHADOW`, speeds `20/15`,
and pitch `0x1000`. The source reward is semantic `bhvStar`,
`MODEL_STAR`, at `(-6300,-1850,-6300)` after the fifth killed subject.

## Required next evidence

1. Exercise the ordinary Castle Inside painting nodes `0x27`, `0x28`, or
   `0x29` into THI area 1 and capture the exact five-subject group without
   synthetic loading or coordinate selection.
2. Add the observer call at the real C owner boundary, after authored child
   calls, and copy only fixed-width source state/effect values into the seam.
3. Produce equal Debug C/Swift, ASan C, optimized Release, and fresh-rerun
   traces with semantic source identity, group ordinals, and byte equality;
   run wrong-variant, wrong-subject, duplicate-child, partial, tamper,
   fixture-only, pointer-derived, and persistent-rerun rejection fences.
4. Only a separately authorized serial merge may change the designated
   7,420-row report. M34 display/cadence/thermal, M35 signing/notarization/
   Gatekeeper, physical movement, and human acceptance remain independent
   gates.

## Evidence boundary

The route remains planned in the designated canonical report (26 passed,
7,394 planned; `26/7420 = 0.350404313%`) and its write-once backup (25 passed,
7,395 planned; `25/7420 = 0.336927224%`). No route row changed. Conservative
M34, M35, full-goal, and human-acceptance floors remain 0%.
