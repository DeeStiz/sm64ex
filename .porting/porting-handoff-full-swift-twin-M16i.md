# Porting Handoff: SM64 Modern Full Swift Twin M16i

## Scope

M16i adds the value-only camera wall-avoidance boundary in
SM64Modern/CameraWallAvoidance.swift.

- C camera yaw classification and avoid-yaw tie-breaking are preserved.
- The eight 0.125 camera-line probes retain coarse/fine radius growth and
  first/last wall identity capture.
- Near-wall status and the C status-1 avoid-yaw intent are emitted without
  mutating the collision world.
- Behind-surface, range-behind, and short-surface predicates mirror the
  camera.c helpers.
- The immutable Swift surface world is the only query authority; owner-thread
  code remains responsible for installing flags and yaw.

## Validation

- script/test_camera_wall_avoidance.sh — matching Swift/C fingerprint
  0x58afd73253bd0a2d.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- xcodegen generate, the full script matrix, and native macOS Debug build are
  required before the local checkpoint.
- git diff --check.

## Boundary notes

- Covered-Mario status-3 routing needs a dedicated multi-surface fixture.
- Bounded-mode callback ownership, cutscene timelines, audio/HUD delivery,
  render mutation, and whole-mode negative-coordinate replay remain open.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16j should add data-driven bounded-mode callback descriptors for radial,
outward-radial, parallel, fixed, eight-direction, slide, cannon, boss,
spiral-stairs, water-surface, and close modes.
