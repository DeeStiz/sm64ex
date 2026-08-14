# Porting Handoff: SM64 Modern Full Swift Twin M14j

## Scope

M14j wires an optional `SM64MarioSlopeInput` through `SM64MarioWalkingAction` so the C order is preserved: ground-speed callback first, slope acceleration second, then ground-step velocity/face-yaw and walk/wall effects. Existing callers may omit the snapshot while the collision migration is still staged.

The slice also extracts `set_steep_jump_action` kinematics into `SM64Modern/MarioSteepJump.swift`, preserving the stored steep-jump yaw, canonical trig projection, forward-speed reduction, final face yaw, and held-object drop intent.

## Validation

- `script/test_mario_walking_slope.sh` — walking/slope integration fingerprint
- `script/test_mario_steep_jump.sh` — steep-jump projection fingerprint
- `script/test_mario_walking_action.sh`
- Swift 6 strict-concurrency focused tests and independent C contracts
- `git diff --check`
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build are required before commit.

## Boundary notes

- The slope snapshot is optional so existing C-bridge callers can continue supplying post-slope collision velocity until the owner-thread state application is migrated.
- Steep-jump action entry and object drop remain effect/application work; this milestone owns only the deterministic scalar projection.
- Local build/test evidence does not establish physical input feel, visual slope alignment, haptics, or human acceptance.

## Next slice

M14k should port moving punch and its ground-step/airborne transition, then extract braking/decelerating and turning actions with shared action-entry application.
