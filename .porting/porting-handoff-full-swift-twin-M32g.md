# Full Swift Twin M32g Handoff

## Scope

M32g closes the gameplay parity coordinator's unchecked-sendability escape.
The coordinator is created and driven on the engine owner thread, owns the
mutable trace file/session state, and exposes only the narrow C stream callback
leaf through an unmanaged context pointer.

## Implementation

- Converted `GameplayParityCoordinator` to a plain final class.
- Captured a construction pthread token and asserted it at parity API setup,
  tick boundaries, shutdown, and both C stream callback entry points.
- Kept the `Unmanaged`/`@convention(c)` stream callbacks as the explicit unsafe
  ABI boundary; no `FileHandle` or reducer state is marked `Sendable`.
- Preserved record/replay/shadow/promotion behavior and existing C parity API
  contracts.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32g-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32g-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports five remaining `@unchecked Sendable` classes,
  down from six before M32g.

This is an owner-thread trace-session closure, not proof of adversarial
callback stress, full trace inventory/replay, whole-engine Swift authority,
Metal 4 production qualification, or human acceptance.

## Next slice

Audit the two owner-thread persistence adapters in `ProgressionPersistence.swift`.
They should either receive the same explicit owner-token contract or be reduced
to value-only persistence operations before their unchecked annotations are
removed. Then rerun the strict build and complete matrix.
