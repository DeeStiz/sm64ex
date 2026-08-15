# Porting Handoff: SM64 Modern Full Swift Twin M16k

## Scope

M16k adds value-only cutscene and FOV state in
`SM64Modern/CameraCutscene.swift` and `SM64Modern/CameraFOV.swift`.

- Cubic B-spline camera movement preserves C control-point coefficients,
  speed-derived progress, sentinel termination, segment wrapping, and negative
  coordinates.
- Shot clocks preserve stop-bit admission, duration rollover, shot increment,
  and inclusive event-window predicates.
- FOV function modes preserve C target selection/approach increments and the
  frame's shake offset-before-decay ordering, phase wrapping, and decay reset.
- The owner thread receives vectors/FOV values and remains responsible for
  event delivery, render mutation, and audio/effect dispatch.

## Validation

- `script/test_camera_cutscene_fov.sh` — matching Swift/C fingerprint
  `0x0fa052c32482bd3a`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `xcodegen generate`, the full script matrix, and the native macOS Debug
  build are required before the local checkpoint.
- `git diff --check`.

## Boundary notes

- Covered-Mario status-3 wall routing, owner-thread cutscene event delivery,
  pitch/yaw/roll shake channels beyond FOV, fixed/parallel/boss/spiral/water/
  behind/C-up callback bodies, and whole-mode negative-coordinate replay remain
  open.
- This slice does not claim cutscene assets, dialog/audio sequencing, or
  physical camera presentation parity.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

Finish M16k with a Swift owner-thread camera tick that composes wall avoidance,
mode descriptors, spline/FOV results, and effect intents; add the covered-Mario
status-3 and negative-coordinate replay fixtures, then begin M17 progression
actors.
