# Porting Handoff: SM64 Modern Full Swift Twin M16f

## Scope

M16f adds C-up state/update and camera shake/FOV descriptors in
`CameraCUp.swift`.

- C-up entry preserves the stored Mario-relative position and focus offset.
- Head movement preserves stick scaling, pitch/yaw clamps, and three-quarter
  head rotation constraints.
- C-up placement preserves the canonical 250-unit +Z-forward camera geometry.
- Shake plans preserve attack, ground-pound, fall-damage, and water/land damage
  channel amplitudes, decay, increments, movement-speed intents, and FOV intent.

## Validation

- `script/test_camera_cup.sh` — matching Swift/C fingerprint
  `0xdeab0f4855d88e31`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- C-up wall/floor/ceiling search, transition ownership, realtime shake/FOV
  installation, audio/HUD delivery, cutscene timers, and render mutation
  remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, or human acceptance.

## Next slice

M16g should add C-up exit search/transition descriptors and cutscene camera
state, then close the camera milestone with negative-coordinate whole-mode
differential traces before starting M17 progression actors.
