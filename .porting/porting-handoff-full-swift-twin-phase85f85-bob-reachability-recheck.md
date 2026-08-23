# Full Swift Twin Handoff — Phase 85f85 Bob Reachability Recheck

Date: 2026-08-23

## Verdict

**READ-ONLY RECHECK / AUTHORED ROUTE STILL UNREACHABLE / FAIL-CLOSED EXIT 77.**
The existing Bob seesaw route-pair harness was rerun against the committed
`d06d84850bd0dd7e81e625b0ef23503d0c17c0c4` seam (an ancestor of `HEAD`) using
only a fresh build root. The normal owner-thread Castle Inside painting route
still did not produce a Bob area-1 seesaw object:

```text
seesaw_platform_route_unreachable level=1 area=1 object=0
SM64 Modern Bob seesaw route blocked reachability=0
source_lifecycle=castle_inside_painting_to_bob_area1
selected_model=MODEL_BOB_SEESAW_PLATFORM parameter=3
synthetic_trace=0 direct_level_load=0 object_injection=0 variant_substitution=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

The process exit was `77`. The reachability gate stopped the matrix before
ASan, optimized Release, persistent rerun, Swift pairing, or negative-fixture
admission checks. No C or Swift trace was created: the fresh root has no
`seesaw-platform-c.trace`, and no pair/variant trace files were produced.

## Fresh-root command and evidence

```text
SM64_SEESAW_PLATFORM_ROUTE_PAIR_ROOT=/private/tmp/sm64-phase85f85-bob-reachability.AbW9Kc \
  bash script/test_seesaw_platform_route_pair.sh
```

The fresh root contained only the Debug build, Debug save/configuration,
contract tool, and `debug.log`; `debug.log` records the reachability line
above. No source, manifest, report, canonical ledger, fixture, or shared
status surface was changed.

## Follow-up

The real authored Castle Inside → Bob area-1 owner-thread route remains the
blocker. Provide a source-authored input/lifecycle path that reaches Bob area
1, then rerun the same harness from another fresh root. Do not direct-load Bob,
inject an object, call a behavior helper, synthesize a trace, or substitute a
seesaw variant. C/Swift pairing and admission remain deferred until a positive
source receipt exists.

## Validation

```text
git -c core.fsmonitor=false diff --check (seam-owned route paths)  passed
```

Only this handoff was created by Phase 85f85. No staging, commit, push,
publication, or destructive cleanup was performed.
