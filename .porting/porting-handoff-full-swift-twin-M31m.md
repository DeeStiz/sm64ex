# Full Swift Twin M31m Handoff

## Scope

M31m extends the camera migration boundary from selection and transition state
to the first pure value callbacks. Swift evaluates Mario/free-roam modes 4, 7,
and 16 plus inside-cannon mode 10. C remains the authority for collision,
height/slope queries, cutscenes, unsupported mode callbacks, and final Lakitu
presentation.

## Implementation

- Added a finite fixed-width callback input/output ABI beside the existing
  camera state migration table.
- Routed `update_mario_camera` and `update_in_cannon` through the evaluator;
  the C adapter maps `Vec3f` outputs back into each callback's legacy pointer
  order and returns Swift's semantic yaw.
- Added owner-thread `SwiftCameraMigrationService.evaluate`, which calls the
  existing `SM64CameraModeCallbacks` kernel and publishes output flags for
  cannon pointer swapping and pan-ahead semantics.
- Added ABI-side output validation for headers, reserved fields, flags, finite
  vectors, and distance. Missing/unsupported/invalid callbacks safely retain
  the original C path.

## Validation evidence

- `script/test_camera_migration.sh` passes with
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`, including a C evaluator
  callback, finite output, swapped-output flag, and malformed-input fence.
- `script/test_camera_mode_callbacks.sh`, `script/test_camera_mode_state.sh`,
  `script/test_engine_runtime.sh`, `make abi-smoke`, and `git diff --check`
  pass.
- Regenerated native arm64 Swift 6 Debug build succeeds at
  `/tmp/sm64-modern-camera-callback-build-2.log`.
- A fresh signed bounded launch reports the Swift camera bridge, Metal frame
  one, `platform_shutdown`, `engine_thread_finished status=0`, and
  `application_stopped`. The startup route uses a different authored camera
  mode, so it does not claim live mode-4/mode-10 callback telemetry.

## Evidence boundary

This is pure callback-value authority, not full camera parity. Geometry,
collision, camera height/slope inputs, fixed/parallel/boss/water callbacks,
cutscenes, route breadth, physical camera feel, audio/frontend/rendering
authority, distribution, and human acceptance remain open.

## Next slice

Exercise a real authored mode-4 or mode-10 route through the native host and
qualify its geometry/collision handoff against C, or continue the next camera
callback family with the same finite ABI, owner-thread, replay, and native
evidence gates.
