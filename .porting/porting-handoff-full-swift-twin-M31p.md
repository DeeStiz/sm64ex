# Full Swift Twin M31p Handoff

## Scope

M31p promotes the direct C-up placement callback for mode 6. Swift owns the
pure placement values; C remains authoritative for C-up input/head rotation,
entry and exit transitions, collision, sound effects, and Lakitu presentation.

## Implementation

- Marked mode 6 as a pure callback in the Swift descriptor table.
- Reused `SM64CameraCUp.update` for the 250-unit focus/position placement with
  the live C-up pitch and mode-offset yaw.
- Routed `update_c_up` through the existing finite evaluator and preserved the
  C fallback for inactive/unsupported/invalid callbacks.
- Extended the Swift/C callback smoke to cover the C-up descriptor and result.

## Validation evidence

- `script/test_camera_mode_callbacks.sh` passes at
  `cameraModeCallbacksFingerprint=0x08345ea7e6c05fde`.
- `script/test_camera_geometry.sh`, `script/test_camera_migration.sh`,
  `script/test_camera_mode_state.sh`, `script/test_engine_runtime.sh`,
  `make abi-smoke`, and `git diff --check` pass.
- Regenerated native arm64 Swift 6 Debug build succeeds at
  `/tmp/sm64-modern-camera-cup-build.log`.
- The bounded signed launch uses the live Swift camera-selection seam, renders
  Metal frame one, and shuts down with status 0; it does not enter C-up and
  therefore does not claim live callback telemetry.

## Evidence boundary

This is C-up placement authority, not full C-up parity. Stick/head input,
entry/exit interpolation, wall avoidance, collision, sound, cutscenes, route
breadth, physical feel, audio/frontend/rendering authority, distribution, and
human acceptance remain open.

## Next slice

Promote the behind-Mario state callback with explicit camera-state inputs and
keep geometry/collision and sound delivery in C, then qualify an authored C-up
route on a real level.
