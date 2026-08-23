# Full Swift Twin Handoff — Phase 85f73 Spindrift Seam Execute

Date: 2026-08-23

## Verdict

**IMPLEMENTATION COMPLETE / REAL REACHABILITY BLOCKED / NO ADMISSION.** The
private source-owned Snowman's Land Spindrift schema-4 seam, semantic
bhvSpindrift identity, independent Swift mirror, focused C/Swift contract,
and fail-closed matrix are present. The ordinary owner-thread lifecycle did
not reach the source-authored Castle Inside painting destination into
Snowman's Land area 1, so no Spindrift receipt or route trace was opened.

The required blocked result is exit 77. No direct SL load/register, macro
injection, behavior/collision helper call, sibling substitution, coordinate
match, synthetic trace, manifest mutation, canonical report mutation,
admission, staging, commit, or push was performed.

## Source boundary

src/game/behaviors/spindrift.inc.c copies scalar state at the end of the
existing source owner update, after the authoritative
cur_obj_move_standard(-60) call. It preserves the existing hitbox/death
helper, floor/wall resolution, Mario relation, forward-velocity/yaw reducer,
recoil action, and recovery timing. The observer receives only fixed-width
state and IEEE-754 float bit patterns; no Object, behavior-script, graph-node,
collision, floor, wall, or Mario pointer crosses the seam.

src/pc/sm64_modern_gameplay_parity.c publishes the semantic bhvSpindrift
identity (0xa672404b3a35d7c8) and enables schema-4 object snapshots for
Snowman's Land. The private route identity is
src/pc/sm64_modern_spindrift_route_identity.h/.c.

## Route identity

    shard=0x028a122a6b0f0fa2
    input_seed=0x5e0c9eb1fc5e5d4e
    save_seed=0x2c46ca0bcefa8587
    source_identity=0x5e0c9eb1fc5e5d4e
    owner_identity=0x2c46ca0bcefa8587
    semantic_behavior=0xa672404b3a35d7c8
    recipe=Castle Inside painting nodes 0x24/0x25/0x26 -> SL area 1 node 0x0A
    source_object=levels/sl/areas/1/macro.inc.c:first macro_spindrift
    source_order=0
    model=MODEL_SPINDRIFT (0x54)
    behavior_parameter=0
    schema4_domains=script,object,collision,effect

The C observer binds once to the first source callback while the trace is
active; later authored Spindrifts remain siblings and are ignored. The
receipt records source/action/timer/movement, source-computed Mario/home
relations, interaction/recovery bits, and fixed hitbox/effect values.

## Validation

Passed:

    xcrun swiftc -parse-as-library -swift-version 6
      -Xfrontend -strict-concurrency=complete
      independent route mirror compiled
    bash -n script/test_spindrift_route_pair.sh
    focused C contract compiled by the route matrix with -Wall -Wextra -Werror
    owned-path git diff --check

Fresh matrix root:

    /tmp/sm64-spindrift-route-run/run.au0eai

The native Debug owner-thread run ended:

    spindrift_route_unreachable level=1 area=1 spindrifts=0
    SM64 Modern Spindrift route pair blocked reachability=0
    source_lifecycle=castle_inside_painting_nodes_0x24_0x25_0x26_to_sl_area1
    first_spindrift_receipt=absent sibling_substitution=0 fixture_only=0
    admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77

Because the first authored Spindrift was absent, the matrix correctly did
not open a C trace or run the dependent ASan, optimized Release, persistent
rerun byte comparison, Swift record pairing, tamper, partial, wrong-sibling,
duplicate, or single-artifact runtime checks. The script contains those
checks for the first future positive reachability run; this blocked run
produced no native C/Swift trace evidence.

## Files owned by this phase

- src/pc/sm64_modern_spindrift_route_identity.h
- src/pc/sm64_modern_spindrift_route_identity.c
- src/game/behaviors/spindrift.inc.c
- src/pc/sm64_modern_gameplay_parity.c (semantic identity and SL object snapshots)
- tests/sm64_modern_spindrift_route_pair_contract.c
- tests/sm64_modern_spindrift_route_swift_smoke.swift
- script/test_spindrift_route_pair.sh
- this handoff

Unrelated dirty and untracked worktree changes, public ABI, canonical
manifests/reports, route ledgers, and prior handoffs were left untouched.

## Follow-up blocker

Re-run the matrix only after the ordinary source-authored Castle Inside
painting lifecycle genuinely establishes SL area 1 and keeps its first
Spindrift alive long enough for the observer to emit a receipt. Do not
replace that lifecycle with a direct level request, injected macro, helper
probe, coordinate shortcut, or sibling object.
