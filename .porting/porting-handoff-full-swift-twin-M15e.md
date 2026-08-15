# Porting Handoff: SM64 Modern Full Swift Twin M15e

## Scope

M15e adds twirling and water-jump/held-water-jump callers in
`MarioTwirlingWaterAction.swift`.

- Twirling owns yaw-velocity approach, wrapped twirl yaw, animation phase,
  sound timing, lava-control projection, landing, wall reflection, and lava
  routing.
- Water jump owns the minimum forward speed, single-jump animation, landing,
  ledge-grab animation/action/camera routing, wall reset, and lava routing.
- Held water jump adds held-object drop priority, held-jump animation and
  landing action, wall reset, and lava routing.

## Validation

- `script/test_mario_twirling_water.sh` — matching Swift/C fingerprint
  `0x95de89cf4ef7956b`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Collision, action installation, camera changes, animation installation,
  sound, particles, and held-object mutation remain explicit owner-thread
  effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15f should extract burning jump/fall, lava boost, and submerged action
families, then continue with climbing, hanging, cannon, and automatic callers.
