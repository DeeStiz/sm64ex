# Full Swift Twin Handoff — Phase 85f68 Dry-Run Immutability Fix

Date: 2026-08-23

## Scope

The Phase 85f64 serial-merge coordinator had already validated proof artifact
hashes, but its post-run immutability snapshot tracked only manifest, report,
and proof paths. This fix carries the validated proof artifact URLs returned by
preflight into that snapshot, so every referenced trace/log artifact is hashed
before and after the dry-run.

No retained report, manifest, ledger, fixture, public documentation, or
source/runtime artifact was changed. The fix is preparatory; the subsequent
dry-run still requires fresh pendulum roots and remains non-publishing.

## Validation boundary

The changed Swift tool typechecks under strict Swift 6 and the existing shell
harness remains syntax-valid. `git diff --check` passed. Parent will run the
updated coordinator with Phase 85f67's explicit fresh pendulum matrix and
admission roots; no canonical publication is authorized by this fix.
