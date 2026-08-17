# Full Swift Twin M31n Handoff

## Scope

M31n extends the M31m callback evaluator with explicit geometry snapshots for
radial, outward-radial, and eight-direction camera modes (1, 2, and 14).
Swift owns only the pure placement math. C remains responsible for surface
queries, authored special-area bounds, collision, pan-ahead integration,
cutscenes, and Lakitu presentation.

## Implementation

- Added finite floor/water/pole/slope fields and explicit geometry-presence
  flags to `SM64ModernCameraCallbackInputV1`.
- The C camera adapter captures the same floor/water/pole facts used by
  `calc_y_to_curr_floor` and `look_down_slopes`, including the look-ahead
  surface normal/type and optional pole object dimensions.
- Swift maps those snapshots into `SM64CameraHeightInput` and
  `SM64CameraSlopeInput`, so the existing height-offset, water, pole, and
  slope-pitch kernels produce the callback placement.
- C keeps Bob/WDW/THI radial bounds and DDD eight-direction clamping on the
  compatibility path, preserves pan-ahead order, and leaves unsupported modes
  untouched.

## Validation evidence

- `script/test_camera_geometry.sh` passes with
  `cameraGeometryFingerprint=0x9bc38f9c51aae152`.
- `script/test_camera_migration.sh`, `script/test_camera_mode_callbacks.sh`,
  `script/test_camera_mode_state.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, and `git diff --check` pass.
- Regenerated native arm64 Swift 6 Debug build succeeds at
  `/tmp/sm64-modern-camera-geometry-build-2.log`.
- Fresh opt-in Bob-omb launch `/tmp/sm64-modern-m31n-bobomb-live.log` reports
  the Swift camera bridge and Metal frame one, then cleanly logs
  `platform_shutdown`, `engine_thread_finished status=0`, and
  `application_stopped`. Bob-omb's source-authored radial bound intentionally
  keeps its callback on C, so no live Swift radial callback is claimed.

## Evidence boundary

This is a pure geometry callback seam, not full camera parity. Surface
collision, special-area bounds beyond the explicit fallback list, remaining
behind/C-up/slide/fixed/parallel/boss/water callbacks, cutscenes, route breadth,
physical camera feel, audio/frontend/rendering authority, distribution, and
human acceptance remain open.

## Next slice

Qualify a real non-exception radial or eight-direction level route to capture
live Swift callback telemetry and compare camera state against C, or continue
with the next callback family using the same explicit geometry and owner-thread
evidence gates.
