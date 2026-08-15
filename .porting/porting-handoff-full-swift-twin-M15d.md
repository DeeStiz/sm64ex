# Porting Handoff: SM64 Modern Full Swift Twin M15d

## Scope

M15d adds dive, air-throw, and forward/backward rollout callers in
`MarioDiveAirAction.swift`.

- Dive pitch descent, object-grab handoff, head-stuck/dive-slide/dive-pickup
  landings, wall reflection, vertical clamp/star, and lava routing are
  explicit.
- Air-throw action-timer increment, held-object throw event, landing action,
  wall stop, and lava routing are explicit.
- Forward/backward rollout initialization, animation phase/end state, landing
  stop, wall stop, and spin-sound timing are explicit.

## Validation

- `script/test_mario_dive_air.sh` — matching Swift/C fingerprint
  `0xa8ef1786df366a81`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Collision, object grab/throw, action installation, sound, particles, and
  graphics-angle writes remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15e should extract twirling and water-jump/held-water-jump callers, then
continue with burning jump/fall, lava boost, and submerged action families.
