# Full Swift Twin M31l Handoff

## Scope

M31l extends M31k's camera selection seam to the value-only transition state
machine. Swift owns mode/previous-mode selection, transition flags and frames,
and the associated C-up/distance/yaw/pan/cannon reset values. C remains the
authority for world geometry, collision, cutscenes, camera callbacks, and
Lakitu presentation.

## Implementation

- Added ABI commands for `transition_next_state` and
  `transition_to_camera_mode` to the existing camera migration table.
- Routed the C transition functions through the owner-thread adapter and
  applied checked Swift outputs back to the C compatibility globals and
  camera mode fields without passing pointers to Swift.
- Applied `SM64CameraModeStateMachine.transitionNextState` and
  `transitionToCameraMode` in `SwiftCameraMigrationService`, with explicit
  command validation and owner-thread fencing.
- Kept `cameraSelection` Swift-owned while the full `camera` domain remains an
  explicit C compatibility bridge.

## Validation evidence

- `script/test_camera_migration.sh` now exercises both transition commands in
  addition to install/authority/query and malformed-input fencing.
- `script/test_camera_mode_state.sh`, `script/test_engine_runtime.sh`, native
  ABI smoke, and `git diff --check` pass.
- Regenerated native arm64 Debug build succeeds at
  `/tmp/sm64-modern-camera-transition-build-2.log`.
- Fresh Apple M5 Max launch `/tmp/sm64-modern-m31l-live.log` reports the Swift
  camera bridge and selection callback before Metal frame one, then drains
  with `platform_shutdown`, `engine_thread_finished status=0`, and
  `application_stopped`. The startup route does not author every camera mode
  transition, so the two transition commands are proven by the independent
  ABI callback smoke rather than claimed as live route breadth.

## Evidence boundary

This is transition-state authority, not full camera parity. Geometry/collision
queries, all mode callbacks, C-up/cutscene shots, camera feel, physical input,
audio/frontend/rendering authority, route breadth, distribution, and human
acceptance remain open.

## Next slice

Qualify a real authored mode/geometry route against C and Swift before marking
the full camera domain Swift-owned; otherwise continue with the next product
domain only with the same owner-thread, ABI, replay, and native evidence gates.
