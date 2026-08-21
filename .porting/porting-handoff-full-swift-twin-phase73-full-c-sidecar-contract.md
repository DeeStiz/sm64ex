# Full Swift Twin Handoff — Phase 73 Full C Sidecar Contract

Date: 2026-08-21

## Verdict

**COMPLETED / NOT PROMOTED.** The pairing-route C sidecar now accepts the
nine-record full Swift trace and emits the same source-backed schema-4 records
without changing fingerprints, the manifest, the route ledger, or admission
state. The route remains unqualified until the separate pairing audit and
route-admission gates are rerun by the parent.

## Change

`tests/sm64_modern_live_route_oracle_contract.c` now distinguishes pairing
full mode from pairing input-only mode:

- Pairing full mode accepts exactly nine records and emits ticks 1–9:
  domain 1 record `0x31000001` at ticks 1–3, domain 2 records
  `0x32000001`/`0x33000001` at ticks 4–5, domain 10 record `0x17000002`
  with flags `67174529` at tick 6, domain 3 record `0x31000002` at tick 7,
  domain 1 input record `1` at tick 8, and domain 11 render record `5` at
  tick 9. The pairing input values for ticks 1–3 match the current source
  trace (`0x8000/0`, `1/0x8001`, and `0x8000/0x8000`).
- Pairing full mode marks the source-backed domain 1 / record 1 coverage row,
  preserving the six common fingerprints and exact coverage check.
- Pairing input-only mode remains exactly two records at ticks 2–3.
- Non-pairing full mode retains its eight-record fixture and tamper divergence
  at record index 3.

`script/test_live_route_oracle.sh` now reports the pairing full-mode tamper
boundary as `first_divergence=1` while retaining the non-pairing value of 3.

No manifest, route ledger, fingerprint, promotion, or commit was created by
this phase; the parent owns the automatic local commit.

## Evidence

Pairing full route:

```text
SM64_MODERN_PAIRING_ROUTE=1 ./script/test_live_route_oracle.sh full
SM64 Modern live route Swift trace passed records=9 mode=full
SM64 Modern live route C oracle replay passed records=9 first_divergence=none
SM64 Modern live route C oracle divergence detected status=diverged first_divergence=1
SM64 Modern live route oracle smoke passed mode=full c_swift_replay=1 first_divergence=1 records=9
```

Pairing input-only regression:

```text
SM64_MODERN_PAIRING_ROUTE=1 ./script/test_live_route_oracle.sh input-only
SM64 Modern live route Swift trace passed records=2 mode=input-only
SM64 Modern live route C oracle replay passed records=2 first_divergence=none
SM64 Modern live route oracle smoke passed mode=input-only c_swift_replay=1 records=2 window_ticks=2 coverage=1
```

Direct post-fix non-pairing C replay and tamper regression:

```text
SM64 Modern live route C oracle replay passed records=8 first_divergence=none
SM64 Modern live route C oracle divergence detected status=diverged first_divergence=3
```

`bash -n script/test_live_route_oracle.sh` and `git diff --check` passed.

## Next admissible work

Rerun the parent-owned C/Swift pairing audit and tamper checks against the
nine-record full trace, then decide whether the route satisfies the existing
admission contract. This phase does not promote a route row or alter the
canonical route denominator.
