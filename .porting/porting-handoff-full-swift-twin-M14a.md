# Porting Handoff — Full Swift Twin M14a

## Scope completed

M14a ports the common stationary cancel decision layer used by idle,
crouching, and start-crouching actions. The Swift value boundary preserves C's
priority ordering for steep-floor/off-floor/slide/first-person/analog/button
inputs, quicksand/poison/low-health/snow transitions, walking face-yaw intent,
punch action arguments, and held-object drop intent. Decisions are emitted as
values; action entry is applied through the M13e transition kernel.

## Validation

- `script/test_mario_action_cancels.sh` passed under Swift 6 strict concurrency
  with `marioActionCancelsFingerprint=0xb988f8d93a8da2cf` matching the
  independent C contract.
- The smoke covers all priority branches exercised by the common idle,
  crouching, and start-crouching paths.
- `git diff --check` passed before handoff.

## Deliberate boundary

Ground-step physics, animation frame progression, sound/particle emission,
full stationary/moving action bodies, collision response, and interaction
dispatch remain open. This slice does not claim gameplay authority or visual
parity.

## Next slice

Add the grounded action body boundary beginning with idle/walking/crouching
step results and explicit animation/audio/particle intents, then extend it to
moving punch and slide transitions.
