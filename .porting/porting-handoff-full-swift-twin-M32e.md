# Full Swift Twin M32e Handoff

## Scope

M32e removes the unchecked-sendability annotation from the Swift gameplay
migration service. The service is created before the engine thread exists, so
it binds its owner identity on the first engine-thread parity reset and checks
that identity for every subsequent callback and evidence read.

## Implementation

- Converted `SwiftGameplayService` to a plain final class.
- Added a pthread owner identity that binds in `resetEvidence` and rejects
  unbound or foreign-thread calls.
- Applied the check to Mario button, Mario ground-speed, Bob-omb release,
  candidate-transform, and evidence paths.
- Kept the existing C callback function pointers and immutable C POD input/output
  copies unchanged.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32e-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32e-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports seven remaining `@unchecked Sendable` classes,
  down from twelve before M32a.

This is an owner-boundary closure, not proof of adversarial cross-thread stress
or whole-engine Swift authority. Remaining persistence/input/parity/
renderer/host/compiler annotations, schema-4 inventory/replay, full gameplay
migration, Metal validation/GPU capture, distribution, and human acceptance
remain open.

## Next slice

Audit `AppleInputService` and its focus/notification callbacks. Separate the
immutable keyboard/controller snapshot from platform event registration state,
then remove its unchecked annotation only after the owner-thread delivery path
has an explicit token and a rejected-token smoke.
