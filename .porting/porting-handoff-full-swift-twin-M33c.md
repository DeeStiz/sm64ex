# Full Swift Twin M33c Handoff

## Scope

M33c connects one existing Swift owner-thread route to the real schema-4 C
oracle. The route exercises normalized input, Mario input/action selection,
progression, object allocation, and one scheduler step. The bridge's explicit
sidecar tick/sequence normalization is part of the compared contract.

## Implementation

- `tests/sm64_modern_live_route_oracle_smoke.swift` builds the route with
  `SM64ModernSwiftEngineContext`, writes seven normalized schema-4 records, and
  prints every record identity/value/hash for first-divergence diagnostics.
- `tests/sm64_modern_live_route_oracle_contract.c` feeds the same deterministic
  C route vector through `sm64_modern_oracle_trace.c` in replay mode. The good
  run matches all seven records; a deliberate Mario-input value mutation is
  rejected at record index 3.
- `script/test_live_route_oracle.sh` builds both sides with Swift 6 complete
  strict-concurrency and C warnings-as-errors.

## Validation evidence

- Swift route trace: seven records, sidecar ticks 1 through 7, sequence 0 per
  sidecar tick.
- C replay: `matched=7`, `first_divergence=none`.
- Tampered replay: `status=diverged`, `first_divergence=3`.
- Full matrix: `runs=135 failures=0`,
  `/tmp/sm64-modern-m33c-matrix.log`.
- `git diff --check` passes.

## Boundary

This proves one live Swift route and the C oracle comparison mechanics only. It
does not close the other gameplay/content domains, whole-inventory execution,
save/audio/render parity, sanitizer qualification, Metal 4 production, or
distribution/human acceptance.

## Next slice

M33d should make the live-route harness consume selected manifest rows and
persist their actual trace/coverage results, then extend the same comparison
to the next migrated actor/effect route while preserving first-divergence
diagnostics and fail-closed status transitions.
