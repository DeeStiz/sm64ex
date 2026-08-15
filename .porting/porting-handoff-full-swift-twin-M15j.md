# Porting Handoff: SM64 Modern Full Swift Twin M15j

## Scope

M15j adds water knockback and plunge routing in
`MarioWaterDiveAction.swift`.

- Forward/backward water knockback preserves animation, stationary slowdown,
  health-gated water-death routing, and action-argument invincibility.
- Plunge preserves held/metal/diving state flags, timer and velocity ending,
  water-action/flutter/metal-fall transitions, splash/fall/bubble particles,
  and air-entry rumble.

## Validation

- `script/test_mario_water_dive.sh` — matching Swift/C fingerprint
  `0x597fbd0121403035`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Water collision/current, animation/audio installation, particle and rumble
  delivery, object ownership, and warp effects remain explicit owner-thread
  effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15k should extract whirlpool capture and death timing, then begin the
metal-water standing/walking/falling/jump family.
