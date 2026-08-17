# Full Swift Twin M31o Handoff

## Scope

M31o promotes the direct slide/hoot transition callback for modes 9 and 15.
Swift owns only the immutable placement values. C remains the authority for
the full slide/hoot frame route: floor and death-plane policy, camera smoothing,
hoot distance changes, C-button behavior, collision, and Lakitu presentation.

## Implementation

- Routed `update_slide_or_0f_camera` through the existing camera evaluator.
- Reused `SM64CameraModeCallbacks.slideHoot` for the exact face-yaw plus
  mode-offset yaw, 800-unit distance, 125-unit offsets, 0x1555 pitch, and
  returned Mario yaw.
- Kept the fallback mode selection owner-thread and finite-output checks
  shared with the earlier camera callback seams.

## Validation evidence

- `script/test_camera_geometry.sh`, `script/test_camera_mode_callbacks.sh`,
  `script/test_camera_migration.sh`, `script/test_camera_mode_state.sh`,
  `script/test_engine_runtime.sh`, `make abi-smoke`, and `git diff --check`
  pass.
- Regenerated native arm64 Swift 6 Debug build succeeds at
  `/tmp/sm64-modern-camera-slide-build.log`.
- Fresh signed bounded launch `/tmp/sm64-modern-m31o-live.log` reports the
  Swift camera bridge and live camera-selection updates before Metal frame one,
  then `platform_shutdown`, `engine_thread_finished status=0`, and
  `application_stopped`. The startup route does not enter an authored
  slide/hoot transition, so no live callback telemetry is claimed.

## Evidence boundary

This is transition-callback value authority, not full slide/hoot parity. The
per-frame floor/death-plane/hoot route, collision, remaining behind/C-up/fixed/
parallel/boss/water callbacks, cutscenes, route breadth, physical feel,
audio/frontend/rendering authority, distribution, and human acceptance remain
open.

## Next slice

Exercise a real slide/hoot authored route against the C camera state, or move
to the next callback family while preserving the same owner-thread, finite ABI,
fallback, and native evidence gates.
