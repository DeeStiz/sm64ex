# Full Swift Twin M31e Handoff

## Scope

M31e composes the owner-thread normalized controller state through the
qualified `SM64MarioInputCore` route. A/B frame timers are held in Swift
context state and the result is emitted as an immutable receipt; collision,
camera, full action dispatch, haptics, and physical devices remain outside
this seam.

## Implementation

- Added `SM64ModernSwiftMarioInputReceipt` and owner-thread Mario A/B timer
  state to `SM64ModernSwiftEngineContext`.
- Added `updateMarioInput` using `SM64MarioInputCore.update` and promoted the
  `marioInput` readiness domain.
- Reset the Mario timer state and receipt at level initialization and
  shutdown.
- Extended the strict runtime smoke with A-edge, magnitude, yaw, and timer
  assertions.

## Validation evidence

- `script/test_engine_runtime.sh` passes under Swift 6 with complete strict
  concurrency diagnostics.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m31e-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31e-build.log`.
- `git diff --check` passes.

This is a Mario input value seam, not full gameplay authority. Camera,
collision, action dispatch, save persistence, audio, rendering, distribution,
physical input, and human acceptance remain open.

## Next slice

Use the Mario-input receipt to enter one already-qualified action-selection
route, begin schema-4 receipt emission from the Swift context, and keep
fallback admission explicit until a complete title-to-shutdown trace is
Swift-owned.
