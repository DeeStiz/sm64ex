# Full Swift Twin — M31q Handoff

## Outcome

Behind-Mario camera mode 3 now crosses the existing fixed-width camera
callback ABI into Swift. The C adapter supplies the current camera geometry,
Mario pose, C-button state, mode/action flags, and behind-Mario timer; Swift
evaluates the value-only state kernel and returns placement plus state updates.
The C camera remains responsible for transition-pointer safety, authored
WDW/THI yaw clamps, sound dispatch, pan-ahead, collision, and final Lakitu
presentation.

## Owned changes

- `include/sm64_modern.h` extends camera callback input/output with camera
  state, C-button state, and state flags.
- `src/pc/sm64_modern_camera_migration.c` validates those fields at the ABI
  boundary.
- `SM64Modern/CameraMigration.swift` maps the fixed-width state into and out
  of Swift values.
- `SM64Modern/CameraModeCallbacks.swift` promotes mode 3 and composes
  `SM64CameraBehindKernel` with the existing geometry kernel.
- `src/game/camera.c` snapshots behind-Mario state and preserves the C-only
  sound, clamp, collision, and transition guards.
- `tests/sm64_modern_camera_mode_callbacks_smoke.swift` and
  `tests/sm64_modern_camera_mode_callbacks_contract.c` add the mode-3
  independent contract; `script/test_camera_mode_callbacks.sh` compiles the
  kernel.

## Validation evidence

- `./script/test_camera_mode_callbacks.sh` —
  `cameraModeCallbacksFingerprint=0x7f786dcb5db3aae3`; Swift smoke and C
  contract match.
- `./script/test_camera_migration.sh` —
  `cameraMigrationFingerprint=0x9e3779b97f4a7d11`.
- `./script/test_camera_geometry.sh` —
  `cameraGeometryFingerprint=0x9bc38f9c51aae152`.
- `./script/test_camera_mode_state.sh` —
  `cameraModeStateFingerprint=0x80ec629967e739dc`.
- `./script/test_engine_runtime.sh` and `make -j2 abi-smoke` pass.
- Regenerated Swift 6/macOS 27 Debug build succeeds in
  `/tmp/sm64-modern-camera-behind-build.log`.
- Signed Apple M5 Max launch
  `/tmp/sm64-modern-m31q-live-4.log` reaches `metal_device_ready` with
  `api=Metal4`, presents frame one, completes 360 fixed steps with zero
  scheduler/audio drops, and shuts down with `engine_thread_finished status=0`
  and `application_stopped`.

## Boundary and next work

This is deterministic callback and owner-thread evidence, not proof of a
physical behind-Mario route, subjective camera feel, visual parity, or human
acceptance. Continue with the remaining camera families (water, boss, fixed,
parallel, spiral, and cutscene paths), then promote audio, frontend, and
rendering authority before M33 route breadth and M34/M35 production gates.

