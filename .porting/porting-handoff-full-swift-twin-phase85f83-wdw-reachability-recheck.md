# Full Swift Twin Handoff — Phase 85f83 WDW Express-Elevator Reachability Recheck

Date: 2026-08-23

## Verdict

**FAIL-CLOSED AT AUTHORED SOURCE REACHABILITY; NO ADMISSION.** The existing
WDW express-elevator route-pair script was rerun from a fresh build root
against the committed `380f14ae` receipt seam. The source-authored Castle
Inside painting route requests WDW area 1, but the observed lifecycle is
already in WDW area 2 before the dynamic express-elevator owner emits a
receipt. The run therefore exits 77 without substituting the static sibling,
creating fixture evidence, or admitting a route pair.

The shared checkout's unrelated pre-existing `game_init.c` hunks were
preserved; no seam-owned WDW source was changed for this recheck.

## Fresh runtime evidence

Command:

```text
SM64_WDW_ELEVATOR_ROUTE_BUILD_PARENT=<fresh-root>/builds \
  bash script/test_wdw_express_elevator_route_pair.sh
```

The script's real owner-thread lifecycle reported:

```text
wdw_express_elevator_route_unreachable level=11 area=2 dynamic=0 static=0
SM64 Modern WDW express elevator route pair blocked reachability=0
source_lifecycle=castle_inside_painting_node_0x18_to_wdw_area1
dynamic_receipt=absent static_sibling_substitution=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

The authored route is `Castle Inside area 2 painting node 0x18 -> LEVEL_WDW
area 1`; the runtime result is `LEVEL_WDW` (`11`) area `2`. No dynamic or
static receipt was present. The debug trace path was not created with a
nonzero payload, so the script correctly stopped before ASan, Release,
rerun, Swift pairing, or negative-artifact checks.

## Scope and fences

- The existing script was run without changing its source, the 380f14ae seam,
  any manifest, canonical ledger, report, or other documentation.
- No static-sibling substitution, synthetic object, helper call, coordinate
  match, fixture record, C/Swift pair, or admission was produced.
- The script's fail-closed branch ran its owned-path `git diff --check`; the
  designated handoff file also passes the post-write `git diff --check`.

## Unblock condition

Rerun only after the source-authored Castle Inside -> WDW area-1 lifecycle
keeps the dynamic elevator object in area 1 long enough for the owner loop to
emit a receipt. Do not target WDW area 2, inject an object, or use the static
sibling as a reachability substitute.
