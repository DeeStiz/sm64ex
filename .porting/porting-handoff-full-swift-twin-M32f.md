# Full Swift Twin M32f Handoff

## Scope

M32f closes the input-service unchecked-sendability escape. AppKit and
GameController callbacks remain platform-owned, while engine sampling consumes
lock-protected value snapshots and haptic operations use their own lock.

## Implementation

- Converted `AppleInputService` to a plain final class.
- Kept keyboard, mouse, and controller snapshots behind the existing input
  lock; kept haptic generator/engine state behind the dedicated haptic lock.
- Removed service capture from `GameViewController` notification closures.
- Routed focus notifications through `MainActor.assumeIsolated` and a small
  MainActor-owned helper so AppKit isolation is explicit.
- Preserved the native input ABI and existing focus/haptics behavior; no
  mutable platform object is marked `Sendable`.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32f-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32f-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports six remaining `@unchecked Sendable` classes,
  down from seven before M32f.

This is a shared-state ownership closure, not proof of physical controller or
haptic behavior, adversarial callback stress, whole-engine Swift authority,
Metal 4 production qualification, or human acceptance.

## Next slice

Audit `GameplayParityCoordinator` next. Remove its unchecked annotation only
after its mutable trace file/session state has an explicit owner-thread token
or a value-only producer/consumer boundary, then rerun the strict native build
and complete matrix before touching the remaining persistence, renderer,
shader-compiler, and host annotations.
