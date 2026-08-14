# Porting Handoff — Full Swift Twin M14d

## Scope completed

M14d extracts `anim_and_audio_for_walk` into the pointer-free
`SM64MarioWalkAnimation` state machine. It preserves the C speed bands for
start-tiptoe, tiptoe, walking, running, and quicksand movement; fixed-point
animation acceleration; action-timer transitions; the running pitch target and
`approach_s32` easing; and the frame-window step-sound decision. The result
emits a sound kind (`terrain`, `tiptoe`, `quicksand`, or `metal`) as an intent,
so audio delivery remains outside the deterministic value kernel.

## Validation

- `script/test_mario_walk_animation.sh` passed under Swift 6 strict concurrency
  with `marioWalkAnimationFingerprint=0xff8426f5cb1d3b4d` matching the
  independent C contract.
- The complete `script/test_*.sh` matrix passed, including M14a–M14c
  fingerprints and the existing gameplay contracts.
- The regenerated Xcode project built the macOS arm64 Debug target successfully
  with isolated derived data in `/tmp/SM64ModernM14dDerivedData`.
- `git diff --check` passed before handoff.

## Deliberate boundary

This slice does not claim animation asset playback, actual sound/particle
delivery, stationary/walking action dispatch, wall push/sidle, live Swift
runtime authority, or visual/device parity. The C engine remains the runtime
authority and differential oracle.

## Next slice

Compose the ground-step and walk-animation outputs into a stationary/idle and
walking action-body boundary. Add C-matching action exits, wall push/sidle
decisions, and explicit movement/audio/particle effect packets before moving
to punch and slide bodies.
