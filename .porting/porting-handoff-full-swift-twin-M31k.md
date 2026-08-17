# Full Swift Twin M31k Handoff

## Scope

M31k promotes the camera selection/angle state seam to Swift authority. The C
camera continues to own geometry, collision, mode callbacks, cutscenes, and
Lakitu/render presentation; no Camera or Surface pointer crosses the boundary.

## Implementation

- Added `SM64ModernCameraMigrationApiV1`, an owner-thread fixed-width ABI for
  selection, movement, sound, status, and transition state.
- Added a C migration install/authority guard and routed `cam_select_alt_mode`
  and `set_cam_angle` through the Swift callback when authority is enabled.
- Added `SwiftCameraMigrationService`, which applies the existing
  `SM64CameraModeStateMachine` value kernel, validates headers/reserved bytes,
  fences foreign-thread use, and emits first-call/periodic telemetry.
- Added `cameraSelection` to the closed Swift/C ledger; full `camera` remains
  an explicit C compatibility bridge until geometry and cutscene routes are
  separately qualified.

## Validation evidence

- `script/test_camera_migration.sh` passes the ABI install, authority,
  callback, reserved-byte fence, and uninstall contract.
- `script/test_camera_mode_state.sh` and `script/test_engine_runtime.sh` pass
  with complete Swift 6 strict concurrency.
- Regenerated native arm64 Debug build succeeds at
  `/tmp/sm64-modern-camera-selection-build.log`.
- Fresh Apple M5 Max launch telemetry reports
  `camera_selection_bridge_installed abi=1 authority=swift geometry_authority=c`,
  a live `swift_camera_selection_update`, Metal frame one, clean platform
  shutdown, `engine_thread_finished status=0`, and `application_stopped`.
  Captured log: `/tmp/sm64-modern-m31k-live.log`.
- `git diff --check` passes for the focused slice.

## Evidence boundary

This proves a live owner-thread camera selection/angle cutover only. It does
not prove full camera geometry, collision avoidance, C-up/cutscene behavior,
camera feel, physical controller/display acceptance, audio/frontend/rendering
authority, full route breadth, distribution, or human acceptance.

## Next slice

Continue camera geometry and mode callbacks behind value-only world inputs, or
finish a separate frontend/audio authority domain only when its real C path,
owner-thread boundary, and native evidence are complete. Do not mark the full
camera domain Swift-owned from this bounded seam.
