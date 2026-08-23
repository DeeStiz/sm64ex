# Full Swift Twin Handoff — Phase 85f49 WDW Area-1 Reachability Audit

Date: 2026-08-23

## Verdict

**REACHABILITY BLOCKED / FAIL CLOSED / NO ADMISSION.** The source-authored
Castle Inside painting destination reaches WDW, but the normal owner-thread
lifecycle immediately moves Mario from WDW area 1 to area 2. The authored
`bhvWdwExpressElevator` and its static sibling are therefore never present in
the area observed by the bounded contract, and `bhvWdwExpressElevator` cannot
execute. No alternate source-authored, non-direct, non-synthetic recipe was
found that enters or keeps area 1 long enough for the behavior to tick.

No source, manifest, canonical report, route ledger, or prior handoff was
changed by this audit. The only repository artifact created is this handoff.

## Source-authored route

Castle Inside area 2 owns the three WDW painting entries:

```text
levels/castle_inside/script.c:102-104
PAINTING_WARP_NODE(0x18, LEVEL_WDW, 0x01, 0x0A, WARP_NO_CHECKPOINT)
PAINTING_WARP_NODE(0x19, LEVEL_WDW, 0x01, 0x0A, WARP_NO_CHECKPOINT)
PAINTING_WARP_NODE(0x1A, LEVEL_WDW, 0x01, 0x0A, WARP_NO_CHECKPOINT)
```

The opt-in owner-thread gate in `src/game/game_init.c:647-674` first uses
the existing Castle area-2 node `0x35`, then requests the compiled painting
destination `LEVEL_WDW / area 1 / node 0x0A` with `initiate_warp`. This uses the
normal warp/level-load lifecycle; it does not register a level, inject an
object, call a behavior helper, select the static sibling, or synthesize a
receipt. The gate runs from `game_loop_one_iteration()` after level-script
execution and remains opt-in through
`SM64_MODERN_AUTOMATED_CASTLE_WDW_ELEVATOR`.

WDW area 1's authored list at `levels/wdw/script.c:95-110` contains both
required objects:

```text
line 40: bhvWdwExpressElevatorPlatform at (1024,3277,-2112)
line 41: bhvWdwExpressElevator         at (1024,3277,-1663)
```

It also defines self warp nodes `0x0A`, `0x0B`, and `0x0C` (lines 99-101),
but its area boundary is:

```text
line 106: INSTANT_WARP(index 1, destArea 2, 0, 0, 0)
```

Area 2 has only the reverse boundary (`line 118`, instant-warp index 0 to
area 1), its area-2 objects, and no express-elevator pair. All authored
external WDW entries found in the source are Castle painting nodes `0x18`-
`0x1A`, and all target node `0x0A`; no external authored entry targets WDW
area-1 node `0x0B` or `0x0C`.

## Why the route lands in area 2

The WDW destination node `0x0A` is backed by the source
`bhvSpinAirborneWarp` object at `(3395,3580,384)` in area 1, not by an
elevator coordinate. `init_mario_after_warp()` copies that warp object's
position into Mario's spawn state and loads the requested area
(`src/game/level_update.c:371-394`). On the next ordinary play-mode update,
`play_mode_normal()` calls `check_instant_warp()` before
`area_update_objects()` (`src/game/level_update.c:982-990`). The spawn is on
the authored area-1 instant-warp surface, so the index-1 entry changes the
active area to WDW area 2 (`src/game/level_update.c:533-565`).

This ordering explains the observed result: area 1 is loaded transiently,
then its boundary is processed before the area-1 object list receives a
behavior tick. The observer in
`src/game/behaviors/express_elevator.inc.c:6-53` is called only after the
dynamic source reducer; it cannot produce a receipt in area 2. The observer
itself rejects any trace attempt outside WDW area 1 in
`src/pc/sm64_modern_wdw_elevator_route_identity.c:69-75`.

## Alternate-recipe audit

The only authored Castle-to-WDW route is the painting-node family above, and
each member resolves to node `0x0A`, so changing between `0x18`, `0x19`, and
`0x1A` cannot avoid the area-1 boundary. The area-1 `0x0B`/`0x0C` nodes are
internal WDW reciprocal warps with no authored incoming destination from
another level. Starting WDW through its `MARIO_POS` level entry would be a
different direct level-selection/load recipe, and forcing a different spawn
or preserving area 1 across the boundary would require coordinate/physics
manipulation. Neither is an allowed bounded source-authored route here.

Accordingly, no safe non-direct recipe exists in the inspected source graph.
The correct next step is to leave this candidate planned and wait for a
source-authored lifecycle change that genuinely reaches area 1; do not target
area 2, bypass the instant warp, inject the elevator, use the static sibling,
or emit fixture evidence.

## Bounded runtime probe

The existing fail-closed matrix was run from the shared worktree with a fresh
native Debug build and the real owner-thread lifecycle:

```text
SM64_WDW_ELEVATOR_ROUTE_BUILD_PARENT=/tmp/sm64-modern-wdw-area1-reachability-verified \
  bash script/test_wdw_express_elevator_route_pair.sh

wdw_express_elevator_route_unreachable level=11 area=2 dynamic=0 static=0
SM64 Modern WDW express elevator route pair blocked reachability=0
source_lifecycle=castle_inside_painting_node_0x18_to_wdw_area1
dynamic_receipt=absent static_sibling_substitution=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

The script's process exit was independently captured as `77`. The contract
does not create/open `wdw-express-elevator-c.trace` until both authored area-1
objects are found; therefore no C trace, Swift trace, or trace SHA-256 exists
for this blocked run (`trace=not-created`, `records=0`). For reproducibility,
the captured runtime logs are:

```text
matrix.log sha256=0d6210c4605bfd01ec0f31d4eea74771c4386fc1063c5aa615ba23a0aeb8d2ec
debug.log  sha256=7a49ec7ab890c0024f401936c2b556cefa2d4cdc0f0272e2e9db665a29fc7de1
```

Because reachability failed before trace opening, the Debug/ASan/Release/
rerun byte-parity and negative-artifact matrix was correctly not run or
admitted.

## Validation and retained state

```text
git -c core.fsmonitor=false diff --check: exit 0
matrix process exit: 77
canonical ledger mutation: 0
manifest mutation: 0
admission: 0
```

The retained Phase 85f47 route seam remains the implementation baseline; this
phase adds only the reachability finding and exact blocked-probe evidence.
