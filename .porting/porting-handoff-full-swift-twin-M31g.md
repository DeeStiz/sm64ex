# Full Swift Twin M31g Handoff

## Scope

M31g connects the Swift context receipts to the schema-4 oracle contract. The
context creates canonical fixed-width records and retains them for replayable
tests; the native owner-thread sink forwards those records to the C oracle API
as explicit sidecar ticks after the C lifecycle tick closes.

## Implementation

- Added schema-4 `SM64OracleTraceRecord` emission for input, Mario input/action,
  progression, and scheduler state receipts.
- Added trace sequence/hash/status/reset ownership to
  `SM64ModernSwiftEngineContext`; sink failures fence the context.
- Installed an `EngineHost` owner-thread sink that calls the C oracle record API
  only when a live schema-4 session is active and isolates each Swift record in
  a sidecar tick.
- Extended the strict runtime smoke with fixed-width record ordering, hash,
  sink-delivery, and reset assertions.

## Validation evidence

- `script/test_engine_runtime.sh` passes under Swift 6 with complete strict
  concurrency diagnostics.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m31g-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31g-build.log`.
- `git diff --check` passes.

This is schema-4 sidecar wiring, not full trace qualification. C still owns
the unmigrated domains; whole-inventory replay, visual/audio parity, physical
behavior, distribution, and human acceptance remain open.

## Next slice

Run a bounded native record/replay with the sidecar enabled, pin the expected
record ordering and tick accounting, then promote one receipt domain only
after C/Swift first-divergence diagnostics agree.
