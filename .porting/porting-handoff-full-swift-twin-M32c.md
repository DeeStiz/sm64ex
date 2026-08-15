# Full Swift Twin M32c Handoff

## Scope

M32c removes the unchecked-sendability annotation from the schema-4 trace file
session. The session is mutable owner-thread state; only the C ABI stream
callbacks touch it through an explicitly audited pointer shim.

## Implementation

- Converted `SM64ModernOracleTraceSession` to a plain final class.
- Documented the owner-thread invariant and the callback boundary next to the
  session definition.
- Kept the C stream function pointers, `Unmanaged` context recovery, file
  reads/writes, active-state lifecycle, and trace fingerprint behavior intact.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32c-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32c-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports nine remaining `@unchecked Sendable` classes;
  this is a reduction from twelve before M32a.

This is a safety-boundary closure, not proof of concurrent callback stress or
whole-engine trace parity. The remaining service/renderer/host annotations,
schema-4 inventory/replay, full Swift authority, Metal validation/GPU capture,
distribution, and human acceptance remain open.

## Next slice

Add a strict owner-thread token to one mutable migration service and its C API
callbacks, then remove its unchecked-sendability annotation only after direct
and rejected-token paths are tested.
