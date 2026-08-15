# Porting Handoff: SM64 Modern Full Swift Twin M15n

## Scope

M15n adds ledge-grab/ledge-climb and cannon aim/launch action callers in
`MarioLedgeCannonAction.swift`.

- Ledge grab, slow climb, climb-down, and fast climb preserve timer,
  analog/A/space priority, animation transitions, release boundaries,
  climb/landing/whoa effects, and ledge placement intent.
- Cannon entry, active aiming, and launch preserve cannon placement,
  interaction marking, pitch/yaw limits, canonical launch position and
  velocity, Mario visibility, and rumble intent.

## Validation

- `script/test_mario_ledge_cannon.sh` — matching Swift/C fingerprint
  `0x7241fd2d5600eccc`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Ledge/cannon collision, object ownership, camera state, animation/audio
  installation, and particle/haptic delivery remain explicit owner-thread
  effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15o should extract the remaining automatic-action dispatch callers and close
the M15 action-family inventory before moving to the camera system.
