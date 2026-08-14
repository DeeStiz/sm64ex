# Porting Handoff: SM64 Modern Full Swift Twin M14s

## Scope

M14s extracts the light-held walking, heavy-held walking, and held
decelerating moving actions into `MarioHeldWalkingAction.swift`.

- Light-held walking preserves jumping-box dispatch, interaction-drop to
  walking, held sliding, throwing, held jump, held deceleration, crouch-slide
  drop, 0.4 magnitude scaling, hold-walk animation bands, freefall, wall cap,
  and dust intent.
- Heavy-held walking preserves heavy throw, drop-on-slide, heavy-idle exit,
  0.1 magnitude scaling, 10-speed wall cap, freefall drop, and heavy-walk
  animation acceleration.
- Held deceleration preserves drop/slide/throw/jump/crouch/analog exits,
  one-unit deceleration, held-idle transition, light-object walking animation,
  and very-slippery wall reflection.

All action, animation, object-drop, particle, reflection, and step-sound
changes are returned as owner-thread intents; no raw held-object pointer crosses
the value boundary.

## Validation

- `script/test_mario_held_walking.sh` — matching Swift/C fingerprint
  `0x064307036136b02e`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Jumping-box identity, object-drop delivery, sound playback, and animation
  frame progression remain owner-thread integration seams.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14t should port shell-ground speed/action and shell-specific wall/air exits,
then ground knockback/landing and burning-ground actions can close the bulk of
the remaining moving-action family before M15.
