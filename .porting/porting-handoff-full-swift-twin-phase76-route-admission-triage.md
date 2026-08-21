# SM64 Modern Full Swift Twin — Phase 76 route-admission triage handoff

## Scope

Phase 76 adds a read-only triage pass for the retained composite schema-4
trace. It parses the generated canonical route-shard manifest and
`build/sm64-modern-live-route-oracle/full.trace`, reports every manifest row
whose complete expected `(domain, record_kind)` key set is present, and keeps
the promotion decision fail-closed. It does not rewrite the trace, synthesize
records, mutate the route ledger, or promote a row.

## Implementation

- `tools/SM64RouteShardAdmissionTriageTool.swift` is a deterministic Swift 6
  strict-concurrency tool. It reports the trace record/tick window, observed
  keys, each fully covered candidate, unexpected keys, and the independent
  route-identity/C↔Swift evidence blockers.
- `script/test_route_shard_admission_triage.sh` compiles the tool against the
  existing schema-4/manifest value types and runs it against the current
  manifest and retained composite trace.

The composite trace is not a manifest-row trace: its schema-4 fingerprints
identify one captured composite run, but do not bind its records to a single
manifest domain/identity/source row. The retained C sidecar replay is an
exact tamper contract, not an independently recorded C trace for each
manifest row. Those are evidence boundaries, not reasons to alter the trace
or ledger.

## Validation

Run:

```sh
./script/test_route_shard_admission_triage.sh
bash -n script/test_route_shard_admission_triage.sh
git diff --check
```

The wrapper must exit 0 while reporting `admissible_candidates=0` and
`ledger_mutated=0` for the current composite trace. Any future candidate is
still required to pass the canonical live executor/worker-result/merge path
with independent C and Swift evidence before promotion.

## Open gates

This phase does not increase live route admission. The canonical route ledger,
M34 awake-host production evidence, M35 signed/notarized distribution,
clean-machine Gatekeeper verification, and fresh-save human 120-star
acceptance remain open.
