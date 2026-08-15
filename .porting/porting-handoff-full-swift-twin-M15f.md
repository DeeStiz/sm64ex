# Porting Handoff: SM64 Modern Full Swift Twin M15f

## Scope

M15f adds burning jump/fall and lava-boost callers in
`MarioBurningLavaAction.swift`.

- Burning jump/fall owns timer and health decrement/clamp, landing action,
  animation selection, fire/lava sound, particle, and rumble intents.
- Lava boost owns no-input slowdown, canonical lava control, floor-burn
  reboost, bounce/landing state, wall reflection, lava-wall restart, hurt
  counters, held-object drop, and death/eye/particle effects.

## Validation

- `script/test_mario_burning_lava.sh` — matching Swift/C fingerprint
  `0x603935556c748d22`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Collision, action installation, audio, camera, particles, eye state, rumble,
  warp, and object mutation remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15g should extract submerged water-idle/action-end, swimming, water punch/
throw, shock/death/plunge, and metal-water movement families before climbing,
hanging, cannon, and automatic callers.
