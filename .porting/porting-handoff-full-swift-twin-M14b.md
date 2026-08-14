# Porting Handoff — Full Swift Twin M14b

## Scope completed

M14b extracts the C `update_walking_speed` callback into the pointer-free
`SM64MarioGroundSpeed` Swift value kernel. It preserves the slow-floor speed
cap, quicksand scaling, forward-velocity acceleration/deceleration and clamp,
approach-based face-yaw rotation, and responsive-cheat override. Non-finite
float inputs are rejected at the Swift ABI boundary, while the callback keeps
the existing output shape and candidate-tick bookkeeping.

## Validation

- `script/test_mario_ground_speed.sh` passed under Swift 6 strict concurrency
  with `marioGroundSpeedFingerprint=0x0b68615db78628c2` matching the
  independent C contract.
- The adjacent gameplay-tick, action, action-cancel, cap, and terrain contracts
  passed with their existing fingerprints.
- The complete `script/test_*.sh` matrix passed; expected negative content-pack
  diagnostics remained contained by their smoke script.
- The regenerated Xcode project built the macOS arm64 Debug target successfully
  with isolated derived data in `/tmp/SM64ModernM14bDerivedData`.
- `git diff --check` passed before handoff.

## Deliberate boundary

This slice does not claim live Swift runtime authority, grounded-step physics,
animation frame progression, sound/particle emission, collision response,
interaction dispatch, or visual/device parity. The C engine remains the runtime
authority and differential oracle until the later runtime-wiring and action
body milestones.

## Next slice

Add the grounded action-body boundary beginning with `perform_ground_step`,
explicit movement/animation/audio/particle intents, and C-matching stationary
and walking state transitions. Then extend the same value/effect boundary to
punch, slide, and held-object interactions.
