# Porting Handoff — Full Swift Twin M14e

## Scope completed

M14e adds `SM64MarioStationaryAction`, a pointer-free body boundary for
`act_idle`, `act_crouching`, and `act_start_crouching`. It consumes the already
ported common-cancel decision, preserves C's idle head-cycle and sleep checks,
wall-idle animation, snow shiver transition, crouch/start-crouch animation
selection, animation-end transition, held-object drop intent, and stationary
ground-step admission.

## Validation

- `script/test_mario_stationary_action.sh` passed under Swift 6 strict
  concurrency with `marioStationaryActionFingerprint=0x48ffb3f0f86182fb`
  matching the independent C contract.
- The complete `script/test_*.sh` matrix passed, including M14a–M14d
  fingerprints and the existing gameplay contracts.
- The regenerated Xcode project built the macOS arm64 Debug target successfully
  with isolated derived data in `/tmp/SM64ModernM14eDerivedData`.
- `git diff --check` passed before handoff.

## Deliberate boundary

This slice does not claim live runtime authority, animation asset playback,
actual ground collision invocation, sound/particle delivery, wall push/sidle,
punch/slide bodies, or visual/device parity. The C engine remains the runtime
authority and differential oracle.

## Next slice

Compose the cancellation, ground-step, walk-animation, and stationary-body
values into the walking action path. Add C-matching wall push/sidle decisions,
then port punch and slide body transitions with explicit effect packets.
