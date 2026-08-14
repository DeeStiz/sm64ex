# Porting Handoff: SM64 Modern Full Swift Twin M14g

## Scope

M14g composes the C `act_walking` decision boundary in `SM64Modern/MarioWalkingAction.swift`.

The Swift boundary preserves the C cancellation order:

1. above-slide plus slide/backward/downhill transition;
2. first-person braking or decelerating, including wall-facing action state;
3. landing-jump intent (deferred to the dedicated landing helper);
4. speed-kick dive versus moving punch;
5. unknown-input braking;
6. analog-stick turn-around;
7. crouch-slide;
8. grounded speed, four-quarter ground step, walk animation, or wall response.

The returned value carries action IDs/arguments, updated speed/yaw, post-slope velocity input, animation/audio IDs, wall effects, dust, object-drop intent, and the explicit ledge-climb/body-tilt effect intents. It does not claim ownership of `set_jump_from_landing`, `apply_slope_accel`, `check_ledge_climb_down`, or `tilt_body_walking`; those remain named follow-on seams.

## Validation

- `script/test_mario_walking_action.sh`
- Swift 6 strict-concurrency smoke and independent C contract fingerprint: `marioWalkingActionFingerprint=0xe351adc13483b7a2`
- `git diff --check`
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build are required before commit.

## Boundary notes

- `mario_drop_held_object` is represented as an owner-thread effect intent and is true for every `act_walking` entry, matching the C body order.
- The landing-jump helper is represented by `.jumpFromLanding` with no guessed action ID because its choice depends on prior action, double-jump timer, cap, quicksand, steep-floor, and held-object state.
- Collision input supplies velocity after the separate slope-acceleration phase; the dispatch still owns the C `update_walking_speed` forward-speed/yaw callback and composes its result into the ground-step and animation boundaries.
- Device visual feel, haptics, and human acceptance are not established by these local tests.

## Next slice

M14h should extract the landing-jump selection and the smallest shared slope-acceleration/facing-downhill helpers, then wire the walking result into the owner-thread Mario state transition application. After that, continue with moving punch, braking/decelerating, turning, and slide bodies before broadening to airborne actions.
