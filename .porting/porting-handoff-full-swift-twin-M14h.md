# Porting Handoff: SM64 Modern Full Swift Twin M14h

## Scope

M14h extracts `set_jump_from_landing` into `SM64Modern/MarioLandingJump.swift`.

The value kernel preserves the C branch order:

1. quicksand landing action, with held-object variant;
2. steep-floor jump selection and drop/kinematics intents;
3. zero double-jump timer or squish override to a normal jump;
4. jump/freefall/side-flip landing to double jump;
5. double-jump landing to wing-cap flying triple jump, speed-gated triple jump, or normal jump;
6. default normal jump.

Every successful result resets the double-jump timer. Steep-jump kinematics and owner-thread action application remain explicit boundaries.

## Validation

- `script/test_mario_landing_jump.sh`
- Swift 6 strict-concurrency smoke and independent C contract fingerprint
- `git diff --check`
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build are required before commit.

## Boundary notes

- Quicksand action selection does not drop the held object; the C path selects the held quicksand landing action.
- The steep branch emits `shouldDropHeldObject` and `shouldRunSteepJumpPhysics`; the future physics seam owns yaw/velocity projection and then calls the action-entry boundary.
- This local contract does not establish physical controls, haptics, animation feel, or human acceptance.

## Next slice

M14i should extract the small `mario_facing_downhill`/`mario_floor_is_steep` slope predicates and `apply_slope_accel`, then feed them into the walking dispatcher. Continue with moving punch, braking/decelerating, turning, and slide action bodies afterward.
