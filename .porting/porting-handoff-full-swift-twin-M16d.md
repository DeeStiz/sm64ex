# Porting Handoff: SM64 Modern Full Swift Twin M16d

## Scope

M16d adds the camera collision owner boundary in `CameraCollision.swift`.

- Smooth camera-height approach preserves snap mode, increment clamping, and
  reached/moving state.
- Wall resolution composes immutable surface-world queries, preserves camera
  wall filtering, pushed coordinates, collision counts, first-wall IDs, and a
  camera-collided admission bit.

## Validation

- `script/test_camera_collision.sh` — matching Swift/C fingerprint
  `0xc627d9d41a9ce661`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Wall-avoidance yaw, camera-mode callback geometry, floor/ceiling height
  policy, shake/FOV mutation, cutscene timers, audio/HUD delivery, and render
  mutation remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16e should compose radial/behind-Mario/C-up mode callbacks with the collision
and geometry snapshots, then add camera shake/FOV and cutscene state.
