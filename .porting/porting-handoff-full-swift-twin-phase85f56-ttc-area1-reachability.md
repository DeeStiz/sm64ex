# Full Swift Twin Handoff — Phase 85f56 TTC Area-1 Reachability Audit

Date: 2026-08-23

## Verdict

**REACHABILITY BLOCKED / FAIL CLOSED / NO ADMISSION.** The bounded native
owner-thread probe ended with `level=14 (LEVEL_TTC), area=2, hands=0`, so the
authored TTC area-1 clock-hand pair was never present in the observed state.
The process exit was `77`; no C trace was opened, no Swift trace was written,
and no pair, admission, manifest, report, or canonical-ledger evidence was
produced.

The Phase 85f53 implementation commit is `7651f380`. The TTC lifecycle gate
in `src/game/game_init.c` was already a dirty-worktree change before this
audit and was left untouched. The only repository artifact created by this
phase is this handoff.

## Source-authored Castle route

Castle Inside area 2 owns the three TTC painting entries:

```text
levels/castle_inside/script.c:111-113
PAINTING_WARP_NODE(0x21, LEVEL_TTC, 0x01, 0x0A, WARP_NO_CHECKPOINT)
PAINTING_WARP_NODE(0x22, LEVEL_TTC, 0x01, 0x0A, WARP_NO_CHECKPOINT)
PAINTING_WARP_NODE(0x23, LEVEL_TTC, 0x01, 0x0A, WARP_NO_CHECKPOINT)
```

Those nodes are in `script_func_local_2`, which is linked only by Castle
Inside `AREA(/*index*/ 2, ...)` at `levels/castle_inside/script.c:272-285`.
The Castle area-1 script does not own this painting family. The normal
source-authored non-direct recipe is therefore: enter Castle Inside area 2,
stand on a real painting-warp surface, and let
`initiate_painting_warp()` select the compiled node. That function requires
the real `gCurrentArea->paintingWarpNodes` and Mario floor state
(`src/game/level_update.c:641-693`); this bounded probe did not fabricate
either condition.

The current opt-in gate does not execute that painting lifecycle. Its existing
dirty hunk in `src/game/game_init.c:687-705` does the following on the owner
thread:

```text
Castle area 1 -> initiate_warp(LEVEL_CASTLE, 2, 0x35, 0)
Castle area 2 -> initiate_warp(LEVEL_TTC, 1, 0x0A, 0)
```

The first request is an authored Castle area transition to area-2 node `0x35`.
The second request is a direct cross-level `initiate_warp`, not consumption of
painting node `0x21`, `0x22`, or `0x23`. `initiate_warp()` classifies a
same-level area change separately from a cross-level change
(`src/game/level_update.c:615-632`), so this gate intentionally visits Castle
area 2 and then bypasses the source painting entry.

## TTC area boundary and authored objects

`levels/ttc/script.c:62-73` declares exactly one level area:

```text
AREA(/*index*/ 1, ttc_geo_0003B8)
    WARP_NODE(0x0A, LEVEL_TTC, 0x01, 0x0A, WARP_NO_CHECKPOINT)
    WARP_NODE(0xF0, LEVEL_CASTLE, 0x02, 0x35, WARP_NO_CHECKPOINT)
    WARP_NODE(0xF1, LEVEL_CASTLE, 0x02, 0x67, WARP_NO_CHECKPOINT)
    MACRO_OBJECTS(ttc_seg7_macro_objs)
END_AREA()
```

There is no TTC `AREA(2, ...)` and no TTC `INSTANT_WARP`. The nested
`levels/ttc/areas/1/1`, `/2`, and `/3` paths are model-data includes under
area 1, not level-area declarations. Consequently, the probe's
`LEVEL_TTC / area=2` state is not a source-authored TTC area-2 instant-warp
destination. It indicates that the direct gate did not establish a
source-valid TTC area-1 owner state before the warm-up window ended; the audit
does not reinterpret it as TTC reachability.

The source macro list contains the required subjects:

```text
levels/ttc/areas/1/macro.inc.c:40-41  two macro_ttc_clock_hand objects
levels/ttc/areas/1/macro.inc.c:56-58  three macro_ttc_small_gear objects
levels/ttc/areas/1/macro.inc.c:59-61  three macro_ttc_large_gear objects
```

`include/macro_presets.h:340,342-343` maps all six objects to
`bhvTTC2DRotator`; the hand variant is `MODEL_TTC_CLOCK_HAND` with parameter
`0`, while the cog variants use parameter `1`. The source hand collision
branch is only taken for the hand parameter
(`src/game/behaviors/ttc_2d_rotator.inc.c:101-143`). The selected first hand
therefore cannot be replaced by either cog sibling.

## Why the bounded route lands at area 2

The runtime result was:

```text
ttc_2d_rotator_route_unreachable level=14 area=2 hands=0
```

The gate first requests Castle area 2 to reach the room where nodes `0x21`-
`0x23` are authored, then issues the direct TTC warp from that area. The
resulting state reports the TTC level number but an area index that TTC's own
level script never declares. The source graph therefore provides no evidence
that TTC area 1 was retained long enough to load its macro list or execute
`bhvTTC2DRotator`. The contract's warm-up gate requires
`gCurrLevelNum == LEVEL_TTC`, `gCurrentArea->index == 1`, and at least two
source-authored hand objects before it opens the trace
(`tests/sm64_modern_ttc_2d_rotator_route_pair_contract.c:370-397`). Those
preconditions remained false.

No separate source-authored non-direct recipe was found that the bounded
owner-thread harness can use to keep TTC area 1 alive. Nodes `0x21`-
`0x23` are the only authored Castle-to-TTC painting family found; proving
them would require a real area-2 painting entry through Mario's source
painting/floor lifecycle, not a direct level warp, coordinate match, helper
call, macro injection, cog substitution, or synthetic receipt. That positive
route remains unproven and is the unblock condition for this candidate.

## Bounded runtime probe

The existing fail-closed route matrix was run from the shared worktree with a
fresh native Debug build:

```text
SM64_TTC_ROTATOR_ROUTE_BUILD_PARENT=/tmp/phase85f56-ttc-area1-reachability \
  bash script/test_ttc_2d_rotator_route_pair.sh

ttc_2d_rotator_route_unreachable level=14 area=2 hands=0
SM64 Modern TTC 2D rotator route pair blocked reachability=0
source_lifecycle=castle_inside_painting_nodes_0x21_0x22_0x23_to_ttc_area1
first_clock_hand_receipt=absent cog_substitution=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

The process exit was independently observed as `77`. The run root was
`/tmp/phase85f56-ttc-area1-reachability/run.o7h275` and its `debug.log` has
SHA-256:

```text
f02fce868a20241a24b7eec0f264b6fce01ce3bce77b7181b38509001673881d
```

The contract does not create/open `ttc-2d-rotator-c.trace` until the first
authored hand and its sibling are found. The run therefore has
`trace=not-created`, `records=0`, and no C or Swift trace SHA-256. ASan,
Release, rerun byte parity, Swift pairing, and negative-artifact fences were
correctly not attempted after the real reachability precondition returned 77.

## Validation and retained state

```text
bash -n script/test_ttc_2d_rotator_route_pair.sh: passed (matrix preflight)
bounded matrix process exit: 77
trace creation: not-created
canonical ledger mutation: 0
manifest mutation: 0
admission: 0
git -c core.fsmonitor=false diff --check: passed with no diagnostics
```

No source, manifest, canonical report, route ledger, shared documentation,
or prior handoff was changed. Do not target TTC area 2, bypass the painting
lifecycle, inject a macro object, call a behavior helper from a probe, select
a cog sibling, or emit fixture evidence. Re-run only after a source-authored
Castle area-2 painting route genuinely establishes TTC area 1 and keeps the
first clock hand alive long enough for its owner update to emit a receipt.
