# Full Swift Twin Handoff — Phase 85f107 Pokey Seam

Date: 2026-08-23

## Verdict

**STATIC SEAM COMPLETE / RUNTIME RECEIPT ABSENT / NO ADMISSION.** The private
Pokey parent/body-part schema compiles with strict C11 flags and preserves the
source-authored SSL macro tuples, five child ordinals, head/body models,
vertical offsets, alive mask/count, semantic `bhvPokey`/
`bhvPokeyBodyPart` identities, and body-part hitbox identity. No native object,
parent pointer, behavior script, or Mario pointer crosses the seam.

The observer is not wired into `bhv_pokey_update` or
`bhv_pokey_body_part_update`; this phase did not direct-load/warp SSL, inject a
child, call a behavior helper, create a trace, mutate a report/ledger/manifest,
or claim admission. The only acceptable runtime path remains the ordinary
Castle→SSL area-1 route.

## Owned files and validation

- `src/pc/sm64_modern_pokey_route_identity.h`
- `src/pc/sm64_modern_pokey_route_identity.c`
- `tests/sm64_modern_pokey_route_contract.c`
- `script/test_pokey_route_static.sh`

The static contract passed:

```text
pokeyRouteFingerprint=0x26090919531bbf4d
SM64 Modern Pokey route C contract passed
SM64 Modern Pokey static route contract passed
semantic_parent_child_identity=1 source_5_child_offsets=1 pointer_free=1
runtime_receipt=absent castle_to_ssl_reachability=unproven
admission=0 canonical_ledger_mutation=0 manifest_mutation=0
```

`bash -n`, strict C11 syntax/compile (`-Wall -Wextra -Werror`,
`NON_MATCHING=1`, `AVOID_UB=1`, `VERSION_US`), source/helper/pointer fences,
and owned-path `git diff --check` passed. The fingerprint is static evidence
only, not C/Swift parity or runtime receipt evidence.

## Source boundary

The selected parent row is `0x132a22db8f8e0945` with seeds
`0x88bd956f3e11b0e` / `0x2b82b65e014d17b6`; the child row is
`0x41715ab876625588`. SSL area-1 `macro_pokey` source tuples are
`(4602,40,4622)`, `(5057,143,256)`, `(-6858,8,-3711)`, and
`(-5372,64,3083)`, all yaw 0, with model `MODEL_NONE` and parameter 0.
The owner creates child ordinals 0–4 at offsets 480/360/240/120/0; ordinal 0
uses `MODEL_POKEY_HEAD`, ordinals 1–4 use `MODEL_POKEY_BODY_PART`, and the
initial alive mask is `0x1F`. Attack removal, replenishment after timer 100,
far-distance unload, floor/wall movement, and source effect ordering remain
C-owned requirements.

## Required next evidence

1. Follow only the ordinary Castle→SSL area-1 lifecycle and capture the real
   parent and source-ordered children; reject SSL siblings and coordinate
   selection.
2. Add a C-owner observer after authored child calls and decode fixed-width
   parent/child state, masks, ordinals, collision, effect, and deletion values
   into the existing Swift `PokeyObjectBridge`.
3. Require independent Debug C/Swift, ASan, optimized Release, and fresh
   rerun byte equality plus wrong-level/child, duplicate, partial,
   fixture-only, pointer-derived, and persistent-rerun rejection fences before
   any isolated admission or serial merge.

The designated report remains 26/7,394 (`26/7420 = 0.350404313%`) with SHA
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`; the
write-once backup remains 25/7,395 (`25/7420 = 0.336927224%`) with SHA
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`. M34,
M35, implementation, human-acceptance, and full-goal floors remain 0%.
