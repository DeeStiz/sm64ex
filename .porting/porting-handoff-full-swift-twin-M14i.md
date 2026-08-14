# Porting Handoff: SM64 Modern Full Swift Twin M14i

## Scope

M14i extracts the scalar slope domain in `SM64Modern/MarioSlope.swift`:

- `mario_facing_downhill` with strict `(-0x4000, 0x4000)` yaw bounds;
- `mario_floor_is_slope` for slide, very-slippery, slippery, default, and not-slippery classes;
- `mario_floor_is_steep` with the C-facing-downhill guard;
- `apply_slope_accel` class acceleration, soft-ground-knockback exception, forward-speed sign, face-yaw projection, and sand/wind update intents.

## Validation

- `script/test_mario_slope.sh`
- Swift 6 strict-concurrency smoke and independent C contract fingerprint
- `git diff --check`
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build are required before commit.

## Boundary notes

- The caller supplies floor class, terrain type, normals, and angles as an immutable terrain snapshot.
- Moving-sand and windy-ground updates are emitted as intents; their object/effect delivery remains owner-thread work.
- This does not yet wire slope output into the walking dispatcher; M14j should do that while extracting the shared steep-jump kinematics.

## Next slice

M14j should feed this slope result into walking speed/ground-step velocity and extract `set_steep_jump_action` kinematics, then proceed through moving punch, braking/decelerating, turning, and slide bodies.
