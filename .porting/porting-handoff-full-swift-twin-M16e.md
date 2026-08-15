# Porting Handoff: SM64 Modern Full Swift Twin M16e

## Scope

M16e adds the pure behind-Mario camera control kernel in
`CameraBehindKernel.swift`.

- Active-angle distance/focus offsets preserve Mario-mode zoom bounds.
- Water/metal and normal pitch increments preserve C's action-dependent
  branch.
- C-left/right/up/down goals preserve ordering, distance approach, yaw offset,
  pitch targets, side-rotation timer, sound timer, and minimum distance.
- Signed asymptotic/symmetric angle approaches preserve wrapping and timer
  behavior.

## Validation

- `script/test_camera_behind.sh` — matching Swift/C fingerprint
  `0x00bc64108d4f037c`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Camera-mode world bounds, collision feedback, mode transition ownership,
  shake/FOV mutation, cutscene timers, audio/HUD delivery, and render mutation
  remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16f should compose the behind-Mario control result with camera geometry and
collision snapshots, then add C-up enter/exit state and the first camera-shake
and FOV intent descriptors.
