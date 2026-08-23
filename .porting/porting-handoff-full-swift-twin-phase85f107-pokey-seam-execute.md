# Full Swift Twin Handoff — Phase 85f107 Pokey Seam Execute

Date: 2026-08-23

## Verdict

**STATIC SEAM COMPLETE / RUNTIME RECEIPT ABSENT / NO ADMISSION.** The private
schema-4 Pokey parent/body-part contract now preserves the source-authored
Castle Inside -> SSL area-1 route, all four `macro_pokey` parent tuples, the
parent parameter `0`, five source-ordered `bhvPokeyBodyPart` children, head
and body models, offsets `480/360/240/120/0`, alive mask/count, attack,
replenish, unload, collision/effect/deletion ordering, semantic identities,
and generation-safe parent links. The C validator and independent Swift
mirror are fixed-width value contracts only; no native pointer, behavior
address, helper call, child injection, coordinate selection, or Mario state
crosses the boundary.

The ordinary owner-thread lifecycle was not made to reach SSL area 1 in this
static phase. No trace, native receipt, C/Swift runtime pairing, report,
ledger, backup, manifest, admission, or canonical merge was created or
mutated. A future bounded route attempt must use Castle Inside painting nodes
`0x0F`, `0x10`, or `0x11`; if that authored route remains unreachable it must
fail closed with exit `77` and no trace artifact.

## Owned seam

- `src/pc/sm64_modern_pokey_route_identity.h` defines source/owner route IDs,
  semantic `bhvPokey` / `bhvPokeyBodyPart` identities, the named
  `sPokeyBodyPartHitbox` identity, source parent/child tables, fixed-width
  schema-4 input/receipt values (including parent and child source/owner IDs),
  event phases, and effect/gate flags.
- `src/pc/sm64_modern_pokey_route_identity.c` copies the four SSL parent
  tuples and five child tuples and validates source order, models, offsets,
  parent generation links, action/gate fields, collision identity, and
  collision -> effect -> deletion ordering.
- `tests/sm64_modern_pokey_route_contract.c` is an independent strict C11
  contract. It checks all source tuples and child models/offsets, validates a
  source-authored sample, and rejects a wrong parent generation and wrong
  child model.
- `tests/sm64_modern_pokey_route_swift_smoke.swift` independently mirrors
  the fixed-width values and schema-4 envelope, checks the same source order
  and parent/child identity rules, and rejects generation, model, and semantic
  child-identity tampering without creating a trace.
- `script/test_pokey_route_static.sh` fences the authored Castle -> SSL route,
  source macro/behavior gates, pointer/helper tokens, strict C/Swift builds,
  and owned-path whitespace. It reports runtime reachability as unproven and
  keeps admission and canonical mutation at zero.

## Validation evidence

Passed:

```text
bash -n script/test_pokey_route_static.sh
SM64_POKEY_STATIC_BUILD_ROOT=/private/tmp/sm64-modern-pokey-static \
  ./script/test_pokey_route_static.sh
pokeyRouteFingerprint=0x82add98bad10547e
SM64 Modern Pokey route C contract passed
pokeyRouteSwiftFingerprint=0x6276741935432706
SM64 Modern Pokey route Swift smoke passed
schema4=1 parent_child_identity=1 generation_link=1
SM64 Modern Pokey static route pair passed
source_authored=1 macro_parent_tuples=4 child_tuples=5
semantic_parent_child_identity=1 generation_safe_parent_link=1 schema4_receipt=1
attack_replenish_unload_collision_effect_deletion=1 pointer_free=1
runtime_receipt=absent castle_to_ssl_reachability=unproven
reachability_exit=77_if_unreachable admission=0 canonical_ledger_mutation=0 manifest_mutation=0
```

The script uses only strict C11 syntax/link compilation and strict Swift 6
mirror compilation. No broad native build, ASan run, optimized Release run,
runtime route capture, or physical/visual acceptance claim is made in this
execute phase.

## Required next evidence

1. Traverse the ordinary Castle Inside painting route into SSL area 1 and
   capture the real parent plus five source-ordered children; do not direct
   load/warp SSL, invoke `bhv_pokey_*`, inject a child, choose by coordinates,
   or substitute another SSL actor.
2. At the real C owner boundary, copy scalar parent/child state after the
   authored callbacks and emit schema-4 script/object/collision/effect
   records using the IDs in this seam.
3. Require independent Debug C/Swift, ASan, optimized Release, fresh-rerun
   byte equality, and wrong-level/child, duplicate, partial, tamper,
   fixture-only, pointer-derived, and persistent-rerun rejection fences before
   any isolated admission or serial canonical merge.

Unrelated dirty worktree changes were preserved. This phase intentionally did
not commit.
