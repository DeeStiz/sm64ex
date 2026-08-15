# Porting Handoff: SM64 Modern Full Swift Twin M15m

## Scope

M15m adds pole and ceiling-net action callers in
`MarioPoleHangingAction.swift`.

- Pole holding, climbing, slow/fast grabs, handstand transition, and top-of-
  pole actions preserve input priority, yaw/position approach, animation
  acceleration, and placement exits.
- Start-hanging, hanging, and moving-net actions preserve timer/release/
  ground-pound priority, handstand/net animation selection, movement speed,
  ceiling exit routing, step sound, and rumble intents.

## Validation

- `script/test_mario_pole_hanging.sh` — matching Swift/C fingerprint
  `0x523f3186a24063d9`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Pole/ceiling collision, object ownership, camera state, animation/audio
  installation, and particle/haptic delivery remain explicit owner-thread
  effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15n should extract ledge-grab/ledge-climb and cannon launch/aim callers, then
close the remaining automatic-action dispatch seams.
