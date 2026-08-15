# Porting Handoff: SM64 Modern Full Swift Twin M14z

## Scope

M14z extracts `act_burning_ground` into `MarioBurningGroundAction.swift`.

- A-press, burn-timer expiry, and water extinguish preserve their early-return
  ordering and action transitions.
- Speed clamp/approach, analog face-yaw easing, optional slope acceleration,
  and four-quarter ground-step behavior are value-computed from snapshots.
- Burning-fall versus standing-death action ordering, unsigned health
  decrement, running animation acceleration, fire/eye/rumble, step/lava, and
  flame-out effects are explicit owner-thread results.

## Validation

- `script/test_mario_burning_ground.sh` — matching Swift/C fingerprint
  `0x567054bfcd6a1988`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Collision queries, slope snapshots, action installation, health storage,
  audio, particles, eye state, and rumble delivery remain explicit boundaries.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15 should start the airborne/submerged action family, beginning with shared
air-action stepping and the non-shell airborne callers, while M14 effect
adapters and dispatch wiring remain tracked for closure.
