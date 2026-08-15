# Full Swift Twin M31c Handoff

## Scope

M31c makes domain cutover explicit and moves the already-qualified progression
actor reducer behind the owner-thread Swift engine context. The route is still
value-only: durable persistence and all other unmigrated domains remain an
explicit C fallback.

## Implementation

- Added `SM64ModernSwiftEngineDomainReadiness` with a closed list of Swift-owned
  context domains and computed C-fallback requirements.
- Added `SM64ModernSwiftProgressionReceipt` and wired
  `SM64ProgressionRuntime` through `SM64ModernSwiftEngineContext`.
- Reset progression state together with engine state at level initialization
  and shutdown; invalid lifecycle phases reject progression events.
- Extended the strict runtime smoke with progression dependencies, readiness
  assertions, a red-coin event receipt, and reset assertions.

## Validation evidence

- `script/test_engine_runtime.sh` passes under Swift 6 with complete strict
  concurrency diagnostics.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m31c-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31c-build.log`.
- `git diff --check` passes.

This is a domain seam, not whole-engine Swift authority. Persistence, broad
gameplay/content, audio, rendering, distribution, physical behavior, and
human acceptance are not closed by this milestone.

## Next slice

Use the same readiness/receipt boundary for the next qualified input or Mario
route, connect progression receipts to the live schema-4 owner-thread trace,
and keep fallback selection per-domain until a complete title-to-shutdown
trace runs with no engine/gameplay C callback.
