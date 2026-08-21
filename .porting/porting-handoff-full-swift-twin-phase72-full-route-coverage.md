# Full Swift Twin Handoff — Phase 72 Full Pairing-Route Coverage

Date: 2026-08-21

## Verdict

**OPEN / NOT ADMITTED.** The full pairing route now includes the real
source-backed `firstInput` receipt using the normalized schema-4 sidecar
record identity `(domain=1, recordID=1, sequence=0)`. This removes the
pre-write coverage failure without changing fingerprints, manifest rows, or
the route ledger. The route remains fail-closed because the existing C
pairing sidecar contract is the retained two-record input window, while the
full route intentionally preserves all source records and therefore emits
nine records.

## Change

`tests/sm64_modern_live_route_oracle_smoke.swift` now appends the normalized
`pairingRouteRecord(from: firstInput, simulationTick: nextTick)` only on the
non-input-only pairing path. The existing input-only branch still constructs
the two-record ticks 2–3 window from the real first and second receipts. The
full path retains the context records and Mario-face route record; it does not
synthesize records or relax the coverage guard.

## Evidence

Full pairing route command:

```text
SM64_MODERN_PAIRING_ROUTE=1 ./script/test_live_route_oracle.sh full
```

The Swift side now writes the trace and reports:

```text
SM64 Modern live route Swift trace passed records=9 mode=full
record tick=8 domain=1 kind=2 record=0x0000000000000001 sequence=0
```

The next C-sidecar boundary rejects the intentional cardinality mismatch
before replay:

```text
expected two-record input route schema-4 trace
exit=2
```

This is not an admitted parity result and did not change the canonical route
ledger. The full C contract did not reach a record-level divergence because
its current two-record input-window contract rejects nine preserved records.

Input-only regression remains exact:

```text
SM64_MODERN_PAIRING_ROUTE=1 ./script/test_live_route_oracle.sh input-only
SM64 Modern live route C oracle replay passed records=2 first_divergence=none
SM64 Modern live route oracle smoke passed mode=input-only c_swift_replay=1 records=2 window_ticks=2 coverage=1
```

Direct C replay/tamper checks on that retained route passed:

```text
SM64 Modern live route C oracle replay passed records=2 first_divergence=none
SM64 Modern live route C oracle divergence detected status=diverged first_divergence=1
```

The broader C/Swift pairing audit also passed, including exact replay and
tamper rejection:

```text
SM64 Modern C/Swift pairing audit passed
current_route_shard_admitted=1
real_route_alignment_attempted=1 records=2 ticks=3 exact_bytes=1 common_fingerprints=6 coverage=1
bounded_common_input_admitted=1 records=1 exact_bytes=1 coverage=1 c_replay=1 swift_tamper=1 c_tamper=1 route_tamper_rejected=1
```

`git diff --check` passed. No manifest, fingerprint, ledger, promotion, or
commit was created by this phase; the parent owns the automatic local commit.

## Next admissible work

Choose and implement an independent C-sidecar contract for the full route
that preserves the nine source records and emits their source-backed values,
or retain this route as a coverage-only audit. Do not mark a second live row
or promote the full route until C and Swift agree on record cardinality,
ordering, ticks, sequence, fingerprints, coverage, and canonical bytes.
