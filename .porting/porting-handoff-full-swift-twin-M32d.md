# Full Swift Twin M32d Handoff

## Scope

M32d removes the unchecked-sendability annotation from the mutable progression
migration service and makes its owner-thread invariant executable. This protects
the Swift shadow reducer and save adapter at the C callback boundary without
changing the ABI or event semantics.

## Implementation

- Converted `SwiftProgressionMigrationService` to a plain final class.
- Added a pthread owner identity captured at construction.
- Asserted that identity in `initialize`, `makeAPI`, and `record`, covering
  direct use and the `@convention(c)` callback path.
- Retained the existing `SM64OwnerThreadEEPROMAdapter` token checks for every
  durable commit/reload operation.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32d-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32d-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports eight remaining `@unchecked Sendable` classes,
  down from twelve before M32a.

This is an owner-boundary closure, not proof of adversarial cross-thread stress
or whole-engine Swift authority. Remaining service/renderer/host annotations,
schema-4 inventory/replay, full gameplay migration, Metal validation/GPU
capture, distribution, and human acceptance remain open.

## Next slice

Choose the next mutable service boundary—Apple input or Swift gameplay—and
replace its unchecked annotation with a value-only snapshot plus explicit owner
token, keeping the C callback as a leaf shim and adding a rejected-token smoke.
