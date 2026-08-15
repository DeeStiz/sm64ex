# Porting Handoff: SM64 Modern Full Swift Twin M16a

## Scope

M16a adds the camera math boundary in `CameraPrimitives.swift`.

- C-button arbitration preserves mutually exclusive directional state,
  held-button clearing, masking, and edge ordering.
- Asymptotic and symmetric float/signed-angle approaches preserve reached
  flags, divisor-zero behavior, signed increments, and overshoot clamps.
- Spherical angles, XZ rotation, and pitch clamp preserve canonical table
  trig/atan2, distance, negative-coordinate behavior, and reconstructed points.

## Validation

- `script/test_camera_primitives.sh` — matching Swift/C fingerprint
  `0xe71dca12bbf8bb32`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Camera owner state, surface/wall queries, collision resolution, mode
  transitions, cutscene timers, audio/HUD effects, and render mutation remain
  explicit owner-thread responsibilities.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16b should port the immutable camera state/mode transition boundary, including
Mario/Lakitu/fixed/C-up status, radial/behind-mario mode selection, and camera
movement flags before adding collision and shake effects.
