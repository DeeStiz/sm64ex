# Porting Handoff: SM64 Modern Full Swift Twin M16h

## Scope

M16h adds the pure linear C-up transition boundary in
SM64Modern/CameraCUpTransition.swift.

- Mario-relative transition focus is interpolated and reconstructed in world
  space.
- Distance, pitch, and yaw follow the C frame/max interpolation rules.
- Canonical table-backed trig reconstructs the camera position from the
  interpolated polar state.
- Head rotation is reset to zero every transition frame.
- Frame advancement and completion match the C increment-frame-equals-max
  boundary; invalid zero-duration transitions fail closed.

## Validation

- script/test_camera_cup_transition.sh — matching Swift/C fingerprint
  0xbac37f596d67742c.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- xcodegen generate, the full script matrix, and the native macOS Debug build
  are required before the local checkpoint.
- git diff --check.

## Boundary notes

- Bounded-mode callback ownership, camera wall-avoidance, cutscene timelines,
  audio/HUD delivery, and render mutation remain owner-thread work.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16i should add the bounded-mode callback descriptors and camera wall-avoidance
yaw kernel, then close M16 with negative-coordinate whole-mode differential
traces before starting M17 progression actors.
