# Porting Handoff: SM64 Modern Full Swift Twin M14x

## Scope

M14x extracts `common_air_knockback_step` and its backward/forward, hard,
thrown, and soft-bonk callers into `MarioAirKnockbackAction.swift`.

- Wall-kick preemption preserves the A-edge, wall-kick timer, previous-action
  gate, 180-degree face-yaw intent, and no-sound early return.
- Fixed backward/forward speeds and inherited thrown/soft-bonk speeds preserve
  land-action, hard-fall action, and action-argument selection.
- Thrown actions preserve hurt-counter landing arguments, 0.98 speed decay,
  and thrown-forward pitch intent; hard-fall and normal landing are explicit.
- Air wall hits preserve backward-air animation, bonk reflection, upward
  velocity clamp, and reversed speed; lava walls preserve the lava-boost
  transition; soft bonk preserves rumble admission.

## Validation

- `script/test_mario_air_knockback.sh` — matching Swift/C fingerprint
  `0x0ea208e60764a6a6`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Air collision queries, fall-damage/stuck checks, sound-played flags, action
  installation, and physical wall/lava effects remain owner-thread seams.
- Shell-air and burning-ground action bodies remain open.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14y should extract shell-air and burning-ground actions, then close remaining
stationary/moving effect adapters before M15.
