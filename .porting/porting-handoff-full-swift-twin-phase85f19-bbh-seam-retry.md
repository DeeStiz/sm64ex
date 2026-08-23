# Phase 85f19 — BBH display-list seam retry

Date: 2026-08-22

## Verdict

**FAIL CLOSED — no source-defined pointer-free BBH owner/packet receipt was
found.** The requested shard remains planned. This retry inspected the
authored source, geo parents, generated duplicate rows, and existing packet
observers only. It did not add an observer, accessor, test, tool, manifest
row, report, ledger entry, admission claim, synthetic object, or commit.

## Candidate and fresh inventory

The model-source row remains:

```text
shard=0x000670ec2a57dfa8
domain=display_list
identity=bbh_seg7_dl_0700D7E0
source=levels/bbh/areas/1/15/model.inc.c
input_seed=0xe67a7d3fdeeb0610
save_seed=0xb23fbdac569992f9
expected_domains=render_packet
status=planned
```

The isolated Swift 6 reachability/manifest rerun used
`/private/tmp/sm64-phase85f19-bbh.SffDau/` and reproduced the existing
authoritative counts and hashes:

```text
inventory_rows=7420
manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
```

The scanner emits the same symbol twice:

```text
display_list|bbh_seg7_dl_0700D7E0|levels/bbh/areas/1/15/model.inc.c|declared|display-list declaration
display_list|bbh_seg7_dl_0700D7E0|levels/bbh/header.h|declared|display-list declaration

0x000670ec2a57dfa8|...|levels/bbh/areas/1/15/model.inc.c|...|planned
0xda2a003e465c29ed|...|levels/bbh/header.h|...|planned
```

The model row is the only authored definition. The header row is an `extern`
declaration and must remain rejected as independent provenance.

## Authored nested-list and owner evidence

`levels/bbh/areas/1/15/model.inc.c` is unchanged from Phase 85f6
(`sha256=f20b33940b4eb169998c3fc8e0c715676b5706cc825dc30f6284725e572664b6`)
and contains two related source lists:

- Lines 40–60 define the translation-unit-local
  `static const Gfx bbh_seg7_dl_0700D6F0[]` (`0x0700D6F0–0x0700D7E0`):
  `SETTIMG(spooky_0900B000)`, `LOADSYNC`, `LOADBLOCK`, two vertex loads
  (`bbh_seg7_vertex_0700D500` and `bbh_seg7_vertex_0700D600`), twelve
  `TRI2` commands, and `ENDDL` (18 commands, 24 triangles).
- Lines 62–78 define the public candidate
  `const Gfx bbh_seg7_dl_0700D7E0[]` (`0x0700D7E0–0x0700D850`): 14 state/
  texture commands, one `G_DL` at line 72 to the static child, and `ENDDL`.
  The outer list has no direct triangle command; its drawing closure is the
  nested child.

The geo source directly references the candidate six times, all on
`LAYER_TRANSPARENT`, from `geo_bbh_0006E8`, `geo_bbh_000768`,
`geo_bbh_000950`, `geo_bbh_000A60`, `geo_bbh_000CE8`, and `geo_bbh_000D20`
(`levels/bbh/areas/1/geo.inc.c:35,69,190,242,359,372`). The authored
`GEO_DISPLAY_LIST` macro stores only a display-list pointer and layer
(`include/geo_commands.h:313-321`). At runtime,
`geo_append_display_list(void *displayList, s16 layer)` receives only those
two values (`src/game/rendering_graph_node.c:181-195`); the
`GraphNodeDisplayList` also stores only `displayList` (`src/engine/graph_node.h:261-265`).
Thus the current owner boundary cannot retain which of the six geo parents
selected the same list.

The nested child is not declared by `levels/bbh/header.h`; source inspection
and the existing archive symbol table show it is local (`_bbh_seg7_dl_0700D6F0`)
while only `_bbh_seg7_dl_0700D7E0` is external. No BBH source accessor or
packet observer exists. The existing owner invokes only the four route
observers for the earlier door/castle candidates
(`src/game/rendering_graph_node.c:188-195`), and none recognizes BBH.

## Existing packet-observer boundary

The existing display-list observers all use the authored-parent pattern:
they identify one parent pointer, prove a `G_DL` child by C-side pointer
comparison, then copy a bounded child list into a fixed-width packet while
normalizing resource operands (`src/pc/sm64_modern_display_list_*_route_identity.c`).
That pattern cannot be applied to this candidate as-is:

1. The live geo owner receives `bbh_seg7_dl_0700D7E0` directly, not a unique
   authored display-list parent containing it.
2. The child `bbh_seg7_dl_0700D6F0` is `static`, so the observer has no
   source-defined symbol/accessor against which to fence the `G_DL` operand.
3. Normalizing only the outer `G_DL` word would leave the actual texture,
   vertex, and triangle closure unproven. The stable source resources that
   need a value receipt are `0x0700D6F0`, `0x0900B000`, `0x0700D500`, and
   `0x0700D600`; host `Gfx` operands are `uintptr_t` (`include/PR/gbi.h:
   1706-1741`) and cannot cross the seam.

The generic Swift `SM64DisplayListPacketBuilder` is not a substitute:
`SM64Modern/DisplayListPacket.swift:409-412` records `G_DL` as an opaque
`resourceID` and does not resolve or prove the nested source list. The
existing BBH geo identity probe is likewise a fixed-width root-scene probe
and explicitly defers schema-4 display-list pairing
(`script/test_bbh_geo_route_identity.sh`, `tests/sm64_modern_bbh_geo_route_identity.c`).

## Exact blocker and next evidence

No source-defined pointer-free BBH packet receipt is present in the current
checkout. A qualifying retry needs a source-owned C seam (normally an
accessor/owner function in the model translation unit, with its declaration
and build dependency) that:

1. binds the model definition row, rejects the header declaration row, and
   proves the direct `geo_append_display_list` invocation;
2. validates the outer 14-command list and the complete 18-command nested
   child against authored source identity;
3. normalizes every pointer-bearing texture, nested-list, and vertex operand
   into fixed-width source resource IDs before any Swift/Metal observer sees
   it; and
4. supplies parent/room provenance or an equivalent source-defined token for
   the six direct geo parents.

Only after that seam exists should an independent C/Swift schema-4 pair,
Debug/ASan/Release/rerun byte equality, negative fences, and isolated
admission be attempted. No canonical manifest, route report, ledger,
history, shared docs, source, test, tool, or build configuration was changed
by this retry.
