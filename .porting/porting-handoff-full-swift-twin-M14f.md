# Porting Handoff — Full Swift Twin M14f

## Scope completed

M14f extracts `push_or_sidle_wall` into `SM64MarioWallResponse`. The value
boundary preserves the C forward-speed cap and yaw-projected velocity, canonical
wall-angle delta thresholds, pushing versus left/right sidestep animation,
fixed-point displacement acceleration, unknown-31 flag, wall-facing action
argument, floor-slope roll, and step/slide sound and dust intents.

## Validation

- `script/test_mario_wall_response.sh` passed under Swift 6 strict concurrency
  with `marioWallResponseFingerprint=0xaa779bfa42025915` matching the
  independent C contract.
- The complete `script/test_*.sh` matrix passed, including M14a–M14e
  fingerprints and all existing gameplay contracts.
- The regenerated Xcode project built the macOS arm64 Debug target successfully
  with isolated derived data in `/tmp/SM64ModernM14fDerivedData`.
- `git diff --check` passed before handoff.

## Deliberate boundary

This slice does not claim collision query ownership, ledge climbing, animation
asset playback, actual audio/particle delivery, live Swift runtime authority,
or visual/device parity. The C engine remains the runtime authority and
differential oracle.

## Next slice

Compose cancellation, ground-step, walk-animation, stationary-body, and
wall-response values into the walking action path. Then port C punch/slide
transitions and their hitbox/effect intents.
