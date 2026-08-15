# Porting Handoff: SM64 Modern Full Swift Twin M16c

## Scope

M16c adds the immutable camera height/focus/radial geometry boundary in
`CameraGeometry.swift`.

- Floor/water-derived position and focus offsets preserve metal-water,
  pole-specific bounds, and C's clamp ordering.
- `focusOnMario` preserves canonical table trig, combined Lakitu pitch, and
  the SM64 +Z-forward distance/angle convention.
- Slope-look pitch preserves the wall-misc and 100-unit boundary branches.
- Radial placement preserves center-relative yaw, area yaw, height offsets,
  focus/position offsets, and negative-coordinate behavior.

## Validation

- `script/test_camera_geometry.sh` — matching Swift/C fingerprint
  `0x9bc38f9c51aae152`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Surface queries, wall resolution, bounded-camera callbacks, camera collision
  ownership, shake/FOV mutation, cutscene timers, audio/HUD delivery, and
  render mutation remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16d should compose the camera wall/floor collision owner boundary and bounded
radial/behind-Mario mode callbacks from immutable collision snapshots before
adding shake/FOV and cutscene state.
