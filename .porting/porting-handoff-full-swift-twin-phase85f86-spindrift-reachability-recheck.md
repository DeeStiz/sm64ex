# Full Swift Twin Handoff — Phase 85f86 Spindrift Reachability Recheck

Date: 2026-08-23

## Verdict

**REACHABILITY BLOCKED / FAIL CLOSED / NO ADMISSION.** The existing Spindrift
route pair was rerun against the committed Phase 85f73 seam (`eb3fbf8a`,
`feat: add Spindrift receipt seam`) from a fresh isolated build root. The
ordinary owner-thread lifecycle did not establish the authored Castle Inside
painting destination in Snowman's Land area 1: the native preflight reported
`level=1 area=1 spindrifts=0`. The process exited `77`.

The matrix result was:

```text
spindrift_route_unreachable level=1 area=1 spindrifts=0
SM64 Modern Spindrift route pair blocked reachability=0
source_lifecycle=castle_inside_painting_nodes_0x24_0x25_0x26_to_sl_area1
first_spindrift_receipt=absent sibling_substitution=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

No source, manifest, designated or backup report, route ledger, shared
documentation, or prior handoff was changed. The only repository artifact
created by this phase is this handoff.

## Authored route boundary

The route pair's source boundary remains the three authored Castle Inside
painting nodes:

```text
levels/castle_inside/script.c:114-116
PAINTING_WARP_NODE(0x24, LEVEL_SL, 0x01, 0x0A, WARP_NO_CHECKPOINT)
PAINTING_WARP_NODE(0x25, LEVEL_SL, 0x01, 0x0A, WARP_NO_CHECKPOINT)
PAINTING_WARP_NODE(0x26, LEVEL_SL, 0x01, 0x0A, WARP_NO_CHECKPOINT)
```

The selected source subject is the first authored `macro_spindrift` in
Snowman's Land area 1 (`levels/sl/areas/1/macro.inc.c:22`, source order 0,
`MODEL_SPINDRIFT`, behavior parameter 0). The pair requires the real
owner-thread lifecycle to load SL area 1 and discover all 11 authored
Spindrifts before opening a trace. It does not direct-load SL, register a
level, inject a macro, call a behavior or collision helper, use coordinates,
or select a sibling.

## Fresh-root runtime evidence

The existing matrix was run with an isolated parent and fresh `run.*` root:

```text
SM64_SPINDRIFT_ROUTE_BUILD_PARENT=/tmp/sm64-spindrift-recheck.dOKe1n \
  bash script/test_spindrift_route_pair.sh
```

The independently captured blocked run used:

```text
run_root=/tmp/sm64-spindrift-recheck.dOKe1n/run.9SmvbQ
debug.log sha256=f4b59bb53775216f8fc22c25bbb3730b146d39449ab3bb46a03a5e74d7a701b8
recheck-second.log sha256=699a4a6eac2b49ca066ef346031dc6f43e3d8a4c5199f7926580b75b1d4c2062
process_exit=77
```

Trace creation was correctly gated by authored reachability:

```text
spindrift-c.trace=absent
spindrift-c-asan.trace=absent
spindrift-c-release.trace=absent
spindrift-c-rerun.trace=absent
spindrift-swift.trace=absent
records=0
trace=not-created
sibling_substitution=0
```

Because the source-authored Castle-to-SL precondition remained false, the
dependent ASan, optimized Release, persistent rerun, Swift pairing, tamper,
partial, wrong-sibling, duplicate, and single-artifact checks were correctly
not attempted or admitted. The next unblock is a genuine source-authored
Castle painting lifecycle that reaches SL area 1 and keeps its first
Spindrift alive long enough for the owner observer to emit a receipt.

## Validation

```text
bash -n script/test_spindrift_route_pair.sh: passed by matrix preflight
matrix process exit: 77
authored Castle -> SL result: blocked at level=1 area=1, spindrifts=0
trace creation: not-created
sibling substitution: 0
admission: 0
canonical ledger mutation: 0
manifest mutation: 0
git -c core.fsmonitor=false diff --check: passed with no diagnostics
```
